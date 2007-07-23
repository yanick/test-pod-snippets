
use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use Test::Pod::Snippets;

my $tps = Test::Pod::Snippets->new( );

ok  $tps->is_getting_verbatim_bits, 'default: getting verbatim bits';
ok !$tps->is_getting_methods,       'default: not getting methods';
ok !$tps->is_getting_methods,       'default: not getting functions';

my $pod = <<'END_POD';
=head1 NAME

Foo - Make your programs footastic

=head1 SYNOPSIS

    print "Hello world!";

=head1 METHODS

=head2 new

=head2 meh

Do stuff, for example:

    my $x = $foo->meh;

=head1 FUNCTIONS

=head2 bar( $blah )

yada yada

END_POD



