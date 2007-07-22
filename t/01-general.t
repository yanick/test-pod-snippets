use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use Test::Pod::Snippets;

snippets_ok( 'blib/lib/Test/Pod/Snippets.pm' );

#my $xps= Test::Pod::Snippets->new;

#my $code = $xps->extract_snippets( 'blib/lib/Test/Pod/Snippets.pm' );
#warn $code;
#eval $code;

