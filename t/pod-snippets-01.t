        use Test::More qw/ no_plan /;

        no warnings;
        no strict;    # things are likely to be sloppy

        # tests extracted from 'lib/Test/Pod/Snippets.pm'

        ok 1 => 'the tests compile';   

            use Test::Pod::Snippets;

    my $tps = Test::Pod::Snippets->new();
    $tps->generate_snippets( @pm_and_pod_files );

  ok 1 => 'begin works!';

    $tps = Test::Pod::Snippets->new

;     $tps->generate_snippets( @source_files )

; $file = 'lib/Test/Pod/Snippets.pm';

    $test_script = $tps->extract_snippets( $file )

; open my $tc_fh, '<', 't/pod-snippets-01.t';
    {
        local $/ = undef;
        is $test_script => <$tc_fh>, 'extract_snippets()';
    }



        ok 1 => 'we reached the end!';
