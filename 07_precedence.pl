#!/usr/bin/perl

# enforce good programming practices
use strict;
use warnings;


my $result;

#	* and / take precedence over + and -
# 	so they will be performed first

$result = 2 + 4 * 5;	#	== 22
print "$result\n";

#	expressions in parenthesis will be performed first
# 	regardless of precendence

$result = (2 + 4) * 5;	#	== 30
print "$result\n";

#	operator associvity
#	most math operators of the same precedence are performed left to right
#	some are right to left, see http://perldoc.perl.org/perlop.html

$result = 8 - 4 - 2;	#	== 2
print "$result\n";

#	expressions in parenthesis will be performed first
# 	regardless of associtivty

$result = 8 - (4 - 2);	#	== 6
print "$result\n";
