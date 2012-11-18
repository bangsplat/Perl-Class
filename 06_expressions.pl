#!/usr/bin/perl

use strict;

my $helloworld = "Hello, World!";	# assigning string at time of delcaration
my ( $i, $j );
my $result;
my ( $foo, $bar );

$i = 0;								# assigning a number to a scalar
$bar = $i + 42;						# assigning the result of an arithmetic expression
$foo = $bar;						# assigning the value of a variable
$result = print "$helloworld\n";	# assigning the output of a function
$j = ( $i == 0 );					# assigning the result of a conditional operator

print "The result of the print function is: \"$result\"\n";
print "\$i: \"$i\"\n";
print "\$j: \"$j\"\n";
print "\$foo: \"$foo\"\n";
print "\$bar: \"$bar\"\n";
