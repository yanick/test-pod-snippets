package Test::Pod::Snippets::Parser;

use strict;
use warnings;

use Pod::Parser;
use base qw/ Pod::Parser /;

our $VERSION = '0.03_01';

sub initialize {
    $_[0]->SUPER::initialize;
    $_[0]->{$_} = 0 for qw/ tps_ignore tps_ignore_all tps_within_begin_test /;
    $_[0]->{tps_method_level} = 0;
    $_[0]->{tps_function_level} = 0;
}

sub command {
    my ($parser, $command, $paragraph) = @_;

    if ( $command eq 'for' ) {
        my( $target, $directive, $rest ) = split ' ', $paragraph, 3;

        return unless $target eq 'test';

        return $parser->{tps_ignore} = 1 if $directive eq 'ignore';
        return $parser->{tps_ignore_all} = 1 if $directive eq 'ignore_all';

        $parser->{tps_ignore} = 0;
        no warnings qw/ uninitialized /;
        print {$parser->output_handle} join ' ', $directive, $rest;
    }
    elsif( $command eq 'begin' ) {
        my( $target, $rest ) = split ' ', $paragraph, 2;
        return unless $target eq 'test';
        $parser->{tps_within_begin_test} = 1;
        print {$parser->output_handle} $rest;
    }
    elsif( $command eq 'end' ) {
        my( $target, $rest ) = split ' ', $paragraph, 2;
        return unless $target eq 'test';

        $parser->{tps_within_begin_test} = 0;
    }
    elsif( $command =~ /^head(\d+)/ ) {

$DB::single = 1;
        return unless $parser->{tps}->is_extracting_functions 
                   or $parser->{tps}->is_extracting_methods;

        my $level = $1;

        for my $type ( qw/ tps_method_level tps_function_level / ) {
            if ( $level <= $parser->{$type} ) {
                $parser->{$type} = 0;
            }
        }

        if ( $paragraph =~ /^\s*METHODS\s*$/ ) {
            $parser->{tps_method_level} =
                $parser->{tps}->is_extracting_methods && $level;
            return;
        }

        if ( $paragraph =~ /^\s*FUNCTIONS\s*$/ ) {
            $parser->{tps_function_level} = 
                $parser->{tps}->is_extracting_functions && $level;
            return;
        }

        return if $parser->{tps_ignore} or $parser->{tps_ignore_all};

        my $master_level =  $parser->{tps_method_level} 
                         || $parser->{tps_function_level}
                         || return ;

        # functions and methods are one level deeper than
        # their main header
        return unless $level == 1 + $master_level; 

        $paragraph =~ s/[IBC]<(.*?)>/$1/g;  # remove markups

        $paragraph =~ s/^\s+//;
        $paragraph =~ s/\s+$//;

        if ( $parser->{tps_method_level} ) {
            if ( $paragraph =~ /^new/ ) {
                $paragraph = '$class->'.$paragraph;
                print {$parser->output_handle}
                    $parser->{tps}->get_object_name,
                    ' = $class->', $paragraph, ";\n";
                return;
            }
            else {
                $paragraph = $parser->{tps}->get_object_name.'->'.$paragraph;
            }
        }

        print {$parser->output_handle} '@result = ', $paragraph, ";\n";
    }
}

sub textblock {
    return unless $_[0]->{tps_within_begin_test};

    print_paragraph( @_ ); 
}

sub interior_sequence {}

sub verbatim {
    my $self = shift;

    return unless $self->{tps}->is_extracting_verbatim_bits;

    return if ( $self->{tps_ignore} or $self->{tps_ignore_all} ) 
           and not $self->{tps_within_begin_test};

    print_paragraph( $self, @_ ); 
}

sub print_paragraph {
    my ( $parser, $paragraph, $line_no ) = @_;

    $DB::single = 1;
    my $filename = $parser->input_file || 'unknown';

    # remove the indent
    $paragraph =~ /^(\s*)/;
    my $indent = $1;
    $paragraph =~ s/^$indent//mg;
    $paragraph = "\n#line $line_no $filename\n".$paragraph;

    $paragraph .= ";\n";

    print {$parser->output_handle} $paragraph;
}


'end of Test::Pod::Snippets::Parser';
