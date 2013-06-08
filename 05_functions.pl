#!/usr/bin/perl

# enforce good programming practices
use strict;
use warnings;

my $my_string = "blah blah blah";
my $string_length = length( $my_string );

print( $my_string . "\n" );		# classic function form
print $my_string . "\n";		# look ma, no parenthesis!

print "\"$my_string\" is " . length( $my_string ) . " characters long\n";
print "\"$my_string\" is $string_length characters long\n";

my_function( $my_string );

my $result = how_long( $my_string );
print "\"$my_string\" is $result characters long\n";
print "\"$my_string\" is " . how_long( $my_string ) . " characters long\n";

$result = my_function();
print "my_function returned $result\n";

sub my_function {
	my $param = @_[0];
	print "You said \"$param\"\n";
}

sub how_long {
	my $param = $_[0];
	return length( $param );
}
