#!/usr/bin/perl

use strict;

my ( $name, @full_name );

if ( $ARGV[0] eq undef ) {
	print "Please type your name\n";
	chomp( $name = <STDIN> );
	@full_name = split( /\s+/, $name );
	print "Hello, @full_name[0], I see your last name is @full_name[1]\n";
} else {
	print "Hello, @ARGV[0], I see your last name is @ARGV[1]\n";
}
