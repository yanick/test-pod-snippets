package Test::Pod::Snippets;

use warnings;
use strict;
use Carp;

use Object::InsideOut;
use Test::Pod::Snippets::Parser;
use Module::Locate qw/ locate /;
use Params::Validate qw/ validate_with validate /;

our $VERSION = '0.05';

#<<<
my @parser_of   :Field :Get(parser);

my @do_verbatim  :Field 
                 :Default(1)         
                 :Arg(verbatim)  
                 :Get(is_extracting_verbatim)
                 :Set(extracts_verbatim)
                 ;

my @do_methods   :Field 
                 :Default(0)         
                 :Arg(methods)   
                 :Get(is_extracting_methods)
                 :Set(extracts_methods)
                 ;

my @do_functions :Field 
                 :Default(0)         
                 :Arg(functions)
                 :Get(is_extracting_functions)
                 :Set(extracts_functions)
                 ;
#>>>
                 
my @object_name  :Field :Default('$thingy') :Arg(object_name);

sub _init :Init {
    my $self = shift;

    $self->init_parser;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub init_parser {
    my $self = shift;
    $parser_of[ $$self ] = Test::Pod::Snippets::Parser->new;
    $parser_of[ $$self ]->{tps} = $self;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_object_name {
    my $self = shift;
    return $object_name[ $$self ];
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

sub generate_test {
    my $self = shift;

    my %param = validate( @_, { 
            pod => 0,  
            file => 0,
            fh => 0,
            module => 0,
            standalone => 0,
            testgroup => 0,
            sanity_tests => { default => 1 },
        } );

    my @type = grep { $param{$_} } qw/ pod file fh module /;

    croak "method requires one of those parameters: pod, file, fh, module" 
        unless @type;

    if ( @type > 1 ) {
        croak "can only accept one of those parameters: @type";
    }

    my $code = $self->parse( $type[0], $param{ $type[0] } );

    if ($param{standalone} or $param{testgroup} ) {
        $param{sanity_tests} = 1;
    }

    if( $param{sanity_tests} ) {
        no warnings qw/ uninitialized /;
       $code = <<"END_CODE";
ok 1 => 'the tests compile';   

$code

ok 1 => 'we reached the end!';
END_CODE
    }

    if ( $param{testgroup} ) {
        my $name = $param{file}   ? $param{file} 
                 : $param{module} ? $param{module}
                 : 'unknown'
                 ;
        $code = qq#use Test::Group; #
              . qq#Test::Group::test "$name" => sub { $code }; #;
    }

    my $plan = $param{standalone} ? '"no_plan"' : '' ;

    return <<"END_CODE";
use Test::More $plan;
{
no warnings;
no strict;    # things are likely to be sloppy

$code
}
END_CODE

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


sub parse {
    my ( $self, $type, $input ) = @_;

    my $output;
    open my $output_fh, '>', \$output;

    if ( $type eq 'pod' ) {
        my $copy = $input;
        $input = undef;
        open $input, '<', \$copy;
        $type = 'fh';
    }

    if ( $type eq 'module' ) {
        my $location = locate $input
            or croak "$input not found in \@INC";
        $input = $location;
        $type = 'file';
    }

    $self->init_parser;

    if ( $type eq 'file' ) {
        $self->parser->parse_from_file( $input, $output_fh );
    }
    elsif( $type eq 'fh' ) {
        $self->parser->parse_from_filehandle( $input, $output_fh );
    }
    else {
        die "type $type unknown";
    }

    return $output;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~,

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

no warnings;
no strict;    # things are likely to be sloppy

ok 1 => 'the tests compile';   

$output

ok 1 => 'we reached the end!';

END_TESTS

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub runtest {
    my ( $self, @args ) = @_;

    my $code = $self->generate_test( @args );

    eval $code;

    if ( $@ ) {
        croak "couldn't compile test: $@";
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub snippets_ok {
    my( $self, $file ) = @_;

    my $code = $self->extract_snippets( $file );

    eval $code;

    warn $@ if $@;

    return not $@;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub generate_test_file {
    my $self = shift;

    my %param = validate_with( params => \@_,
        spec => { output => 0 },
        allow_extra => 1,
    );

    unless( $param{output} ) {
        my $i;
        my $name;
        do { 
            $i++; 
            $name = sprintf "tps-%04d.t", $i 
        } while -f $name;

        $param{output} = $name;
    }

    my $filename = $param{output};

    croak "file '$filename' already exists" if -f $filename;

    open my $fh, '>', $filename 
        or croak "can't create file '$filename': $!";

    delete $param{output};

    print {$fh} $self->generate_test( %param );

    return $filename;
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1; # End of Test::Pod::Snippets

__END__

=head1 NAME

Test::Pod::Snippets - Generate tests from pod code snippets

=head1 SYNOPSIS

    use Test::More tests => 3;

    use Test::Pod::Snippets;

    my $tps = Test::Pod::Snippets->new;

    my @modules = qw/ Foo Foo::Bar Foo::Baz /;

    $tps->runtest( module => $_, testgroup => 1 ) for @modules;


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

The easiest way is to create a test.t file calling Test::Pod::Snippets
as shown in the synopsis.  If, however, you don't want to 
add T:P:S to your module's dependencies, you can 
add the following to your Build.PL:

=for test ignore

  my $builder = Module::Build->new(
    # ... your M::B parameters
    PL_files  => { 'script/test-pod-snippets.PL' => q{}  },
    add_to_cleanup      => [ 't/tps-*.t' ],
  );

Then create the file F<script/test-pod-snippets.PL>, which should contains

    use Test::Pod::Snippets;

    my $tps = Test::Pod::Snippets->new;

    my @files = qw#
        lib/your/module.pm
        lib/your/documentation.pod
    #;
    
    print "generating tps tests...\n";
    print $tps->generate_test_file( $_ ), "created\n" for @files;
    print "done\n";

=for test

And you're set! Running B<Build> should now generate one test file
for each given file.

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

=head2 new( I< %options > )

Creates a new B<Test::Pod::Snippets> object. The method accepts
the following options:

=over

=item verbatim => I<$boolean>

If set to true, incorporates the pod's verbatim parts to the test.

Set to true by default.

=item functions => I<$boolean>

If set to true, extracts function definitions from the pod.
More specifically, Test::Pod::Snippets looks for a pod section 
called FUNCTIONS, and assumes the title of all its 
subsections to be functions. 

For example, the pod

=for test ignore

    =head1 FUNCTIONS

    =head2 play_song( I<$artist>, I<$song_title> )

    Play $song_title from $artist.

    =head2 set_lighting( I<$intensity> )

    Set the room's light intensity (0 is pitch black 
    and 1 is supernova white, -1 triggers the stroboscope).

would generate the code

    @result = play_song( $artist, $song_title );
    @result = set_lightning( $intensity );

Pod markups are automatically stripped from the headers. 

=for test

=item methods  => I<$boolean>

Same as C<functions>, but with methods. In this
case, Test::Pod::Snippets looks for a pod section called METHODS.
The object used for the tests is assumed to be '$thingy' 
(but can be overriden using the argument C<object_name>,
and its class must be given by a variable '$class'.

For example, the pod

    =head1 METHODS

    =for test
        $class = 'Amphibian::Frog';

    =head2 new( $name )

    Create a new froggy!

    =head2 jump( $how_far )

    Make it jumps.

will produces

    $class = 'Amphibian::Frog';
    $thingy = $class->new( $name );
    @result = $thingy->jump( $how_far );

=item object_name => I<$identifier>

The name of the object (with the leading '$') to be
used for the methods if the T:P:S object is set to 
extract methods.

=back

=head2 is_extracting_verbatim

=head2 is_extracting_functions

=head2 is_extracting_methods

Returns true if the object is configured to
extract that part of the pod, false otherwise.

=head2 extracts_verbatim( I<$boolean> )

=head2 extracts_functions( I<$boolean> )

=head2 extracts_methods( I<$boolean> )

Configure the object to extract (or not) the given
pod parts.


=head2 generate_test( $input_type => I<$input>, %options )

Extracts the pod off I<$input> and generate tests out of it.
I<$input_type> can be 'file' (a filename), 
'fh' (a filehandler), 'pod' (a string containing pod) or
'module' (a module name).

The method returns the generate tests as a string.

The method accepts the following options:

=over

=item standalone => I<$boolean>

If standalone is true, the generated
code will be a self-sufficient test script. 
Defaults to 'false'.

    # create a test script out of the module Foo::Bar
    open my $test_fh, '>', 't/foo-bar.t' or die;
    print {$test_fh} $tps->generate_test( 
        module     => 'Foo::Bar',
        standalone => 1 ,
    );

=item sanity_tests => I<$boolean>

If true (which is the default), two tests are added to the
very beginning and end of the extracted code, like so:

    ok 1 => 'the tests compile';   
    $extracted_code
    ok 1 => 'we reached the end!';

=item testgroup => I<$boolean>

If true, the extracted code will be wrapped in a L<Test::Group> 
test, which will report a single 'ok' for the whole series of test
(but will give more details if something goes wrong).  Is set
to 'false' by default.

=back

=head2 generate_test_file( $input_type => I<$input>, %options )

Does the same as C<generate_test>, but save the generated
code in a file. The name of the file is the value of the
option B<output>, if given. If the file already exist,
the method dies.  If B<output> is not given, 
the filename will be
of the format 'tps-XXXX.t', where XXXX is choosen not to
interfere with existing tests.  Exception made of C<output>,
the options accepted by the method are the same than for
C<generate_test>.

Returns the name of the created file.


=head2 runtest( $input_type => I<$input>, %options )

Does the same than C<generate_test>, except that it 
executes the generated code rather than return it. 
The arguments are treated the same as for C<generate_test>.


=head1 AUTHOR

Yanick Champoux, C<< <yanick at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-pod-snippets at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pod-Snippets>.

=head1 REPOSITORY

The code of this module is tracked via a Git repository.

Git url:  git://babyl.dyndns.org/test-pod-snippets.git

Web interface:  http://babyl.dyndns.org/git/test-pod-snippets.git

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

L<podsnippets>

=head2 Test::Inline

Whereas L<Test::Pod::Snippets> extracts
tests out of the modules' documentation, Adam Kennedy's I<Test::Inline> 
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

Copyright 2006, 2007, 2008 Yanick Champoux, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

