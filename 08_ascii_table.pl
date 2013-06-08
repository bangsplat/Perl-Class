#!/usr/bin/perl

# enforce good programming practices
use strict;
use warnings;

my $output_string = "";
my $num_cols = 8;		# should be a power of 2 (i.e., 2, 4, or 8)
my $num_length = 3;
my $col_width = 8;

# create the table contents
for ( my $i = 0; $i < 256; $i++ ) {
#	for ( my $j = 0; $j < ( $num_length - length( $i ) ); $j++ ) {
#		$output_string .= "0";
#	}
#	$output_string .= "$i ";
	$output_string .= pad_with_leading_zeros( $i, $num_length ) . " ";
	if ( $i > 32 && $i < 128 ) {	# skip non-printing stuff
		$output_string .= chr( $i );
	}
	$output_string .= "\n";
}

$output_string = format_into_columns( $output_string, $num_cols );


print( "$output_string" );

sub pad_with_leading_zeros {
	my $number = shift( @_ );
	my $length = shift( @_ );
	my $return_string = "";
	for ( my $i = 0; $i < ( $length - length( $number ) ); $i++ ) {
		$return_string .= "0";
	}
	$return_string .= "$number";
	return( $return_string );
}

sub pad_with_spaces {
	my $input_string = shift;
	my $length = shift;
	for ( my $i = 0; $i < ( $length - length( $input_string ) ); $i++ ) {
		$input_string .= " ";
	}
	return( $input_string );
}

sub format_into_columns {
	my @input_list = split( '\n', $_[0] );
	my $num_columns = $_[1];
	my $return_string = "";
	
	for ( my $row = 0; $row < ( 256 / $num_columns ); $row++ ) {
		for ( my $col = 0; $col < $num_columns; $col++ ) {
			$return_string .= "$input_list[(($row)+($col*(256/$num_columns)))]\t";
		}
		$return_string .= "\n";
	}
	
	return( $return_string );
}
