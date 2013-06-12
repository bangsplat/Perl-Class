#!/usr/bin/perl

use strict;			# enforce good programming practices

use Getopt::Long;	# module that parses command line options and GetOptions()

# define our variables
my ( $input_param, $output_param, $start_param, $end_param );
my ( $help_param, $version_param, $debug_param, $line_date );

# parse the command line parameters
# the perldoc entry has more information but here are the basics:
# we are defining pairs of values - the value to read, and the variable to put it into
# => is the same as a comma, but it implies association
# '|' indicates an option, so you can type --input or -i
# after the input string, "=s" indicates the input expects a string as a value
# 	so --input myfilename.txt
# there is also a numeric value, indicated by "=i"
# after the input string, '!' indicates the input is a on/off switch
# 	and does not require a value
# and can be negated with "no"
# 	so --debug or --nodebug
GetOptions( 'input|i=s'		=>	\$input_param,
			'output|o=s'	=>	\$output_param,
			'start=s'		=>	\$start_param,
			'end=s'			=>	\$end_param,
			'help|?'		=>	\$help_param,
			'version'		=>	\$version_param,
			'debug!'		=>	\$debug_param );

# display the passed parameters if debug mode is enabled
if ( $debug_param ) {
	print "DEBUG: Passed parameters\n";
	print "\t\$input_param: $input_param\n";
	print "\t\$output_param: $output_param\n";
	print "\t\$start_param: $start_param\n";
	print "\t\$end_param: $end_param\n";
	print "\t\$help_param: $help_param\n";
	print "\t\$version_param: $version_param\n";
	print "\t\$debug_param: $debug_param\n";
}

# display version message if requested, then exit
if ( $version_param ) {
	print "11_files.pl version 0\n";
	exit();
}
# exit() is a function that causes the program to quit
# it may not actually be the best way to exit in these circumstances
# but it's how I do it

# display help message if requested, then quit
if ( $help_param ) {
	print "11_files.pl\n";
	print "Usable parameters:\n";
	print "\t--input | -i <filename> - the log file to parse\n";
	print "\t--output | -o <filename> - the file to output parsed file\n";
	print "\t--start <YYYY-MM-DD> - the start date to extract\n";
	print "\t--end <YYYY-MM-DD> - the end date to extract\n";
	print "\t--help | -? - display his message\n";
	exit();
}

# validate our passed parameters and set some defaults if necessary
if ( $input_param eq undef ) {
	print "Please specify an input file\n";
	exit();
	## we could prompt for one if we wanted to
	## or look at the first passed parameter to see if it looks like a filename
}

if ( $output_param eq undef ) {
	print "Please speify an output file\n";
	exit();
	## we could also make up a file name based on the input file name
}

# default start and stop dates to forever if not specified
if ( $start_param eq undef ) { $start_param = "0000-00-00"; }
if ( $end_param eq undef ) { $end_param = "9999-99-99"; }

# display the adjusted parameters if debug mode is enabled
if ( $debug_param ) {
	print "DEBUG: Passed parameters\n";
	print "\t\$input_param: $input_param\n";
	print "\t\$output_param: $output_param\n";
	print "\t\$start_param: $start_param\n";
	print "\t\$end_param: $end_param\n";
	print "\t\$help_param: $help_param\n";
	print "\t\$version_param: $version_param\n";
	print "\t\$debug_param: $debug_param\n";
}

# get rid of any dashes from the dates so we can compare it
# let's use the substitution regular expression (s///) to do it
# The =~ operator causes the expression to be done on the variable to the left
# the expression between the first two slashes is replaced by the expression
# between the last two slashes
# the g after the last slash is a global flag - it replaces all instances of the expression
$start_param =~ s/-//g;
$end_param =~ s/-//g;

# open input file
if ( $debug_param ) { print "DEBUG: opening input file $input_param\n"; }
open( INPUT_FILE, "<", $input_param )
	or die "Can't open input file $input_param\n";
# INPUT_FILE is a file handle that we will use to refer to the file later
# the "<" indicates the file will be opened read only
# open() returns a result based on the success of the opening
# if there is an error, the or statement displays an error message and quits

# open output file
if ( $debug_param ) { print "DEBUG: opening output file $output_param\n"; }
open( OUTPUT_FILE, ">", $output_param )
	or die "Can't create file $output_param\n";
# ">" opens the file for writing

# read input file
if ( $debug_param ) { print "DEBUG: reading input file\n"; }
while ( <INPUT_FILE> ) {
	# while() loops until the expression returns false
	# <FILE> returns one line from the open file handle FILE
	# Any return value evaluates to true, so while(<FILE>) loops once per line in the file
	# Result of <> is stored in the special variable $_
	chomp();	# get rid of the newline at the end of the line
	# chomp() operates on $_ if no variable is specified
	if ( $debug_param ) {print "DEBUG: reading line: $_\n"; }
	
	# use regular expressions to get the date at the start of the line
	# // is a matching operator - if the regular expression between the slashes matches $_
	# the statement evaluates to true
	# the portion between the parenthesis is a backreference
	# it is placed in a special variable $1 for use later
	if ( /^([0-9]{4}-[0-9]{2}-[0-9]{2})\t/ ) {
		# the date will be in the variable $1
		# now we want to remove the dashes from the date, as above so we can compare it
		if ( $debug_param ) { print "DEBUG: match $1\n"; }
		$line_date = $1;
		$line_date =~ s/-//g;	# get rid of dashes from the data for comparison
	} else {
		# if we don't have a match, the line doesn't start with a properly formatted date
		# we don't want to risk a false match, so empty out $line_date
		if ( $debug_param ) { print "DEBUG: no match\n"; }
		$line_date = "";
	}

	# we want to output dates within our range
	# by this, we mean that our line date is actually a date,
	# and the value is on or after our start date
	# and the value is before or on our end date
	# we can test this by checking $line_date is not ""
	# 	an empty string has a special value called undef (undefined)
	# 	we use the ne ("not equal to") stringwise compare operator to check
	# and also that the numerical value of the date is greater than or equal to the start date
	# 	we will use the >= numerical compare operator
	# and also that the numerical value of the date is less than or equal to the end date
	# 	we will use the <= numerical compare operator
	# all three of these have to be true for the date to be valid
	# 	so we use the && bitwise and operator
	# 	the result is true only if the two statements to the left and right
	# we group the tests with parenthesis to indicate the order of precedence
	# in this case it's not necessary, but I think of the tests in this order
	if ( $line_date ne undef &&
		( ( $line_date >= $start_param  ) && ( $line_date <= $end_param ) ) ) {
		if ( $debug_param ) { print "$line_date is in range\n"; }
		print OUTPUT_FILE "$_\n";
		# to write data to a file, we use print()
		# but we specify an open filehandle
		# if you don't specify a filehandle, Perl defaults to STDOUT
		# so STDOUT is really a special file that output to the screen instead of the disk
	}
}

# close both files
close( INPUT_FILE );
close( OUTPUT_FILE );
