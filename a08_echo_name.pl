#!/usr/bin/perl

use strict;

my ( $name, @full_name );

if ( $ARGV[0] eq undef ) {
	print "Please type your name\n";
	chomp( $name = <STDIN> );
	@full_name = split( /\s+/, $name );
	print( respond( $full_name[0], $full_name[1] ) );
} else {
	print( respond( $ARGV[0], $ARGV[1] ) );
}

sub respond {
	my $first = @_[0];
	my $last = @_[1];
	return( "Hello, $first, I see your last name is $last\n" );
}
