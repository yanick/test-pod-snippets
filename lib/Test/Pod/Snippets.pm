package Test::Pod::Snippets;

use warnings;
use strict;

use Pod::Parser;

use base qw/ Pod::Parser /;

our $ignore = 0;
our $ignore_all = 0;

sub initialize {
    $ignore = 0;
    $ignore_all = 0;
    $_[0]->SUPER::initialize;
}

sub command {
    my ($parser, $command, $paragraph) = @_;

    if ( $command eq 'for' ) {
        my( $target, $directive, $rest ) = split ' ', $paragraph, 3;

        return unless $target eq 'test';

        return $ignore = 1 if $directive eq 'ignore';
        return $ignore_all = 1 if $directive eq 'ignore_all';

        $ignore = 0;
        no warnings qw/ uninitialized /;
        print {$parser->output_handle} join ' ', $directive, $rest;
    }
}

sub textblock {}
sub interior_sequence {}

sub verbatim {
    return if $ignore or $ignore_all;

    my ($parser, $paragraph) = @_;

    print {$parser->output_handle} $paragraph;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub extract_snippets {
    my( $self, $file ) = @_;

    my $output;
    open my $fh, '>', \$output;
    $self->parse_from_file( $file, $fh );

    return <<"END_TESTS";
        use Test::More qw/ no_plan /;

        no warnings;
        no strict;    # things are likely to be sloppy

        ok 1 => 'the tests compile';   

        $output

        ok 1 => 'we reached the end!';
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

Test::Pod::Snippets - Extracts tests from POD 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Test::Pod::Snippets;

    my $foo = Test::Pod::Snippets->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

=head2 function2

=cut

=head1 AUTHOR

Yanick Champoux, C<< <cpan at babyl.dyndns.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-pod-snippets at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pod-Snippets>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

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

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Yanick Champoux, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

