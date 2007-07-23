package Test::Pod::Snippets::Parser;

use strict;
use warnings;

use Pod::Parser;
use base qw/ Pod::Parser /;

sub initialize {
    $_[0]->SUPER::initialize;
    $_[0]->{$_} = 0 for qw/ tps_ignore tps_ignore_all tps_within_begin_test /;
    $_[0]->{tps_object_name}       = '$thingy';
    $_[0]->{tps_extract_methods}   = 0;
    $_[0]->{tps_extract_functions} = 0;
    $_[0]->{tps_classname}         = 'Unknown::Class::Name';

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

        return unless $parser->{tps_method_header};

        my $level = $1;
        if ( $paragraph =~ /^\s*METHODS\s*$/ ) {
            $parser->{tps_method_level} = $level;
            return;
        }

        if ( $level <= $parser->{tps_method_level} ) {
            $parser->{tps_method_level} = 0;
            return;
        }

        return if $parser->{tps_ignore} or $parser->{tps_ignore_all};

        return if $level != 1 + $parser->{tps_method_level};

        $paragraph =~ s/^\s+//;
        $paragraph =~ s/\s+$//;

        print {$parser->output_handle} 
              '@result = $', $parser->{tps_object_name}, "->$paragraph;\n";
    }
}

sub textblock {
    return unless $_[0]->{tps_within_begin_test};

    print_paragraph( @_ ); 
}

sub interior_sequence {}

sub verbatim {
    return if  ( $_[0]->{tps_ignore} or $_[0]->{tps_ignore_all} ) 
           and not $_[0]->{tps_within_begin_test};

    print_paragraph( @_ ); 
}

sub print_paragraph {
    my ( $parser, $paragraph, $line_no ) = @_;

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
