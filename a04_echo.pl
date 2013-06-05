#!/usr/bin/perl

use strict;

if ( $ARGV[0] eq undef ) {
	print "Please type your name\n";
} else {
	print "Hello, @ARGV[0], I see your last name is @ARGV[1]\n";
}
