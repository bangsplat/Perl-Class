#!/usr/bin/perl

use strict;		# enforce good programming practices

my $my_string;	# declare a variable named $my_string
my $another_string = "blah blah blah";	# declare a variable and set it's value
my ( $a, $b );	# declare two variables at once

$my_string = "Hello, World!\n";	# set value of $my_string

$another_string = $my_string;	# set value of $another_string to be same as $my_string

$a = $b = 1;	# set both $a and $b to 1;

print "\$my_string: $my_string\n";
print "\$another_string: $another_string\n";
print "\$a: $a\n";
print "\$b: $b\n";
