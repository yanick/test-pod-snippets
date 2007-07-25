use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Pod::Snippets',
    license             => 'perl',
    dist_author         => 'Yanick Champoux <cpan@babyl.dyndns.org>',
    dist_version_from   => 'lib/Test/Pod/Snippets.pm',
    build_requires => {
        'Test::More'  => 0,
        'Pod::Parser' => 0,
    },
    sign                => 1,
    add_to_cleanup      => [ 'Test-Pod-Snippets-*', 't/pod-snippets-*.t' ],
    create_makefile_pl  => 'passthrough',
    script_files        => [ qw/ pod2snippets  / ],
#    PL_files            => { 'script/test-pod-snippets.PL' => q{}  },
);

$builder->create_build_script();
