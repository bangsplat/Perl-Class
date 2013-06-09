#!/usr/bin/perl

# enforce good programming practices
use strict;

my ( $name, @full_name );

if ( $ARGV[0] eq undef ) {
	print "Please type your first and last name\n";
	chomp( $name = <STDIN> );
	@full_name = split( /\s+/, $name );
	print( respond( $full_name[0], $full_name[1] ) );
} else {
	print( respond( $ARGV[0], $ARGV[1] ) );
}

sub respond {
	my $first = shift;
	my $last = shift;
	return( "Hello, $first, I see your last name is $last\n" );
}
