#!/usr/bin/perl

# enforce good programming practices
use strict;
use warnings;

my $output_string = "";
my $num_cols = 8;		# should be a power of 2 (i.e., 2, 4, or 8)
my $num_length = 3;		# should be at least 3

# create the table contents
for ( my $i = 0; $i < 256; $i++ ) {
	$output_string .= pad_with_leading_zeros( $i, $num_length ) . " ";
	if ( $i > 32 ) { $output_string .= chr( $i ); }
	$output_string .= "\n";
}

print( $output_string = format_into_columns( $output_string, $num_cols ) );

# pad_with_leading_zeros( number, total_length)
# add leading zeros to a number to make it the requested length
sub pad_with_leading_zeros {
	my $number = shift;
	my $length = shift;
	my $return_string = "";
	for ( my $i = 0; $i < ( $length - length( $number ) ); $i++ ) {
		$return_string .= "0";
	}
	$return_string .= "$number";
	return( $return_string );
}

# format_into_columns( table, num_columns)
# Take the 256 table entires and make columns out of it
# Takes two parameters - the table and the number of desired columns
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
