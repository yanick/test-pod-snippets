package Test::Pod::Snippets;

use warnings;
use strict;
use Carp;

use Object::InsideOut;
use Test::Pod::Snippets::Parser;

our $VERSION = '0.02';

my @parser_of   :Field;
my @do_verbatim :Field :Default(1) :Arg(get_verbatim);

sub _init :Init {
    my $self = shift;

    $parser_of[ $$self ] = Test::Pod::Snippets::Parser->new;
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub generate_snippets {
    my( $self, @files ) = @_;
    my $i = 1;

    print "generating snippets\n";

    for ( @files ) {
        my $testfile = sprintf "t/pod-snippets-%02d.t", $i++;
        print "\t$_ => $testfile\n";
        
        open my $fh, '>', $testfile 
                or die "can't open $testfile for writing: $!\n";
        print {$fh} $self->extract_snippets( $_ );
        close $fh;
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub extract_from_string {
    my ( $self, $string ) = @_;
    open my $pod_fh, '<', \$string;
    return $self->extract_snippets( $pod_fh );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub extract_snippets {
    my( $self, $file ) = @_;

    my $filename_call = 'GLOB' ne ref $file;

    if( $filename_call and not -f $file ) {
        croak "$file doesn't seem to exist";
    }

    my $output;
    open my $fh, '>', \$output;

    if ( $filename_call ) {
        $parser_of[ $$self ]->parse_from_file( $file, $fh );
    } 
    else {
        $parser_of[ $$self ]->parse_from_filehandle( $file, $fh );
    }

    my $filename = $filename_call ? $file : 'unknown';

    return <<"END_TESTS";
use Test::More qw/ no_plan /;
#use Test::Group;

no warnings;
no strict;    # things are likely to be sloppy

#test $filename => sub {

ok 1 => 'the tests compile';   

$output

ok 1 => 'we reached the end!';
#};

END_TESTS

}

sub snippets_ok {
    my( $self, $file ) = @_;

    my $code = $self->extract_snippets( $file );

    eval $code;

    warn $@ if $@;

    return not $@;
}


1; # End of Test::Pod::Snippets

__END__

=head1 NAME

Test::Pod::Snippets - Generate tests from pod code snippets

=head1 SYNOPSIS

    use Test::Pod::Snippets;

    my $tps = Test::Pod::Snippets->new();
    $tps->generate_snippets( @pm_and_pod_files );

=head1 DESCRIPTION

=over 

=item Fact 1

In a perfect world, a module's full API should be covered by an extensive
battery of testcases neatly tucked in the distribution's C<t/> directory. 
But then, in a perfect world each backyard would have a marshmallow tree and
postmen would consider their duty to circle all the real good deals in pamphlets
before stuffing them in your mailbox. Obviously, we're not living in a perfect
world.

=item Fact 2

Typos and minor errors in module documentation. Let's face it: it happens to everyone. 
And while it's never the end of the world and is prone to rectify itself in
time, it's always kind of embarassing. A little bit like electronic zits on
prepubescent docs, if you will.

=back

Test::Pod::Snippets's goal is to address those issues. Quite simply, 
it extracts verbatim text off pod documents -- which it assumes to be 
code snippets -- and generate test files out of them.

=head1 HOW TO USE TEST::POD::SNIPPETS IN YOUR DISTRIBUTION

If you are using Module::Build, add the following
to your Build.PL:

=for test ignore

  my $builder = Module::Build->new(
    # ... your M::B parameters
    PL_files  => { 'script/test-pod-snippets.PL' => q{}  },
    add_to_cleanup      => [ 't/pod-snippets-*.t' ],
  );

Then create the file F<script/test-pod-snippets.PL>, which should contains

    use Test::Pod::Snippets;

    my $tps = Test::Pod::Snippets->new;

    $tps->generate_snippets( qw#
        lib/your/module.pm
        lib/your/documentation.pod
    #);

=for test

And you're set! Running B<Build> should now generate one test file
for each given module.

If you prefer to generate the tests yourself, skip the modifications
to F<Build.PL> and call F<test-pod-snippets.PL> from the distribution's
main directory.

=head1 SYNTAX

By default, Test::Pod::Snippets considers all verbatim pod text to be 
code snippets. To tell T::P::S to ignore subsequent pieces of verbatim text,
add a C<=for test ignore> to the pod. Likely, to return to the normal behavior, 
insert C<=for test>. For example:

=for test ignore

    A sure way to make your script die is to do:

    =for test ignore

        $y = 0; $x = 1/$y;

    The right (or safe) way to do it is rather:

    =for test

        $y = 0; $x = eval { 1/$y };
        warn $@ if $@;


C<=for test> and C<=begin test ... =end test> can also be used to
add code that should be include in the tests but not in the documentation.

Example:

    The right way to do it is:

        $y = 0; $x = eval { 1/$y };

        =for test
           # make sure an error happened
           is $x => undef;
           ok length($@), 'error is reported';

=for test

=begin test

ok 1 => 'begin works!';

=end test

=head1 METHODS

=head2 new

    $tps = Test::Pod::Snippets->new

=for test ;    

Creates a new B<Test::Pod::Snippets> object.

=head2 generate_snippets

    $tps->generate_snippets( @source_files )

=for test ;    

For each file in I<@source_files>, extracts the code snippets from
the pod found within and create the test file F<t/code-snippets-xx.t>.

=head2 extract_snippets 

=for test
    $file = 'lib/Test/Pod/Snippets.pm';

    $test_script = $tps->extract_snippets( $file )

Returns the code of a test script containing the code snippets found
in I<$file>.

=head1 AUTHOR

Yanick Champoux, C<< <yanick at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-pod-snippets at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pod-Snippets>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

=for test ignore

    perldoc Test::Pod::Snippets

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Pod-Snippets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Pod-Snippets>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pod-Snippets>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Pod-Snippets>

=back

=head1 SEE ALSO

Adam Kennedy's L<Test::Inline>. Whereas I<Test::Pod::Snippets> extracts
tests out of the modules' documentation, I<Test::Inline> 
allows to insert tests within a module, side-by-side with its code 
and documentation. 

For example, the following code using I<Test::Pod::Snippets>

    =head2 shout()

    Shoutify the passed string.

        # set $x to 'CAN YOU HEAR ME NOW?'
        my $x = shout( 'can you hear me now?' );

        =for test
        is $x => 'CAN YOU HEAR ME NOW?';

is equivalent to this code, using I<Test::Inline>:

    =head2 shout()

    Shoutify the passed string.

        # set $x to 'CAN YOU HEAR ME NOW?'
        my $x = shout( 'can you hear me now?' );

    =begin testing
    my $x = shout( 'can you hear me now?' );
    is $x => 'CAN YOU HEAR ME NOW?';
    =end testing


=head1 COPYRIGHT & LICENSE

Copyright 2006, 2007 Yanick Champoux, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

