#!/usr/bin/perl

use strict;

if ( $ARGV[0] eq undef ) {
	print "Please type your name\n";
	my $name = <>;
	chop( $name );
	my @full_name = split( /\s+/, $name );
	print "Hello, @full_name[0], I see your last name is @full_name[1]\n";
} else {
	print "Hello, @ARGV[0], I see your last name is @ARGV[1]\n";
}
