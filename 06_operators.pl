#!/usr/bin/perl

use strict;		# enforce good programming practices

my ( $a, $b, $c );
my $my_string = "foo";

$a = 2;
$b = 5;
$c = 2 + 2;
print "result is $c\n";
$c = $a + $b;
print "result is $c\n";
$c = $a * $b;
print "result is $c\n";
$c += $a;
print "result is $c\n";
$c *= $b;
print "result is $c\n";
$c++;

if ( $c >= 60 ) {
	print "\$c is greater than or equal to 60\n";
} else {
	print "\$c is less than 60\n";
}

print "\$c is $c\n";
if ( $c-- == 60 ) { print "\$c is exactly 60\n"; }
else { print "\$c is NOT 60\n"; }

print "\$c is $c\n";
if ( --$c == 60 ) { print "\$c is exactly 60\n"; }
else { print "\$c is NOT 60\n"; }

if ( $c != 0 ) { print "\$c is not zero\n"; }
print "\$c is $c\n";

print "$c" . " " x 5 . "\n";
print "$c " x 5 . "\n";

if ( $my_string = "foo" ) { print "\$my_string = \"foo\"\n"; }
if ( $my_string = "bar" ) { print "\$my_string = \"bar\"\n"; }
if ( $my_string == "foo" ) { print "\$my_string == \"foo\"\n"; }
if ( $my_string == "bar" ) { print "\$my_string == \"bar\"\n"; }
if ( $my_string eq "foo" ) { print "\$my_string eq \"foo\"\n"; }
if ( $my_string eq "bar" ) { print "\$my_string eq \"bar\"\n"; }
if ( $my_string ne "foo" ) { print "\$my_string ne \"foo\"\n"; }
if ( $my_string ne "bar" ) { print "\$my_string ne \"bar\"\n"; }
print "$my_string\n";



