#!/usr/bin/perl

use strict;
use Getopt::Long;

# readID3.pl
#
# read the ID3 tags from a MP3 file
#
# perl readID3.pl --input <filename>
# (more to come)
#
# --version 0|1|2
# 	if empty, default to 0, which means either
#
# --frame |-f <frame_id>
# 	only output specified frames
# 	if empty, output everything
# 	--frame all
#		is the same as leaving it empty
# 	--frame none
#		guarantees not getting any frame data
# 
# --info
# 	output basic tag information in addition to requested tag data
# 
# --image
#	extract APIC image from MP3 and save to image file
#
# created by Theron Trowbridge
# http://therontrowbridge.com
# version 1.1
# Created 2011-12-16
# Modified 2012-03-17
#
# Version History
#
# version 0.9
# 	first working version
#
# version 1.0
#	bug fixes
# 
# version 1.1
# 	fixes handling of text encoding frames
#

my ( $result, $done );
my ( $input_param, $output_param, $version_param, $frame_param, $info_param, $image_param );
my ( $debug_param, $help_param, $test_param );
my ( $filesize, $buffer, $extended_buffer, $buffer_pointer, $output_string );
my ( $id3v1_header, $id3v1_title, $id3v1_artist, $id3v1_album, $id3v1_year );
my ( $id3v1_comment, $id3v1_zerobyte, $id3v1_track, $id3v1_genre, $id3v1_tag_has_track );
my ( $id3v1ext_header, $id3v1ext_title, $id3v1ext_artist, $id3v1ext_album );
my ( $id3v1ext_speed, $id3v1ext_genre, $id3v1ext_starttime, $id3v1ext_endtime );
my ( $id3v1_is_extended_tag, $speed_value );
my ( $byte_value, $comment_string, $track_number, $genre_number, $genre_string );
my ( $id3v2_identifier, $id3v2_version, $id3v2_flags, $id3v2_tag_size, $id3v2_tag_size_value );
my ( $id3v2_major_version, $id3v2_minor_version,$id3v2_version_string );
my ( $id3v2_flag_bit_string, $id3v2_flag_unsynchonization, $id3v2_flag_extended_header );
my ( $id3v2_flag_experimental, $id3v2_flag_footer_present );
my ( $id3v2_extended_header_size );
my ( $frame_is_padding, $frame_id, $frame_size, $frame_size_value, $frame_data );
my ( $frame_flags, $frame_flags_bit_string, $tag_alter_preservation_flag );
my ( $file_alter_preservation_flag, $read_only_flag, $grouping_identity_flag, $compression_flag );
my ( $encryption_flag, $unsynchronization_flag, $data_length_indicator_flag );
my ( $apic_text_encoding, $apic_mime_type, $apic_picture_type, $apic_description, $apic_picture_data, $apic_pointer );
my ( $string_done, $my_character, $image_file, $image_file_extension );

GetOptions( 'input|i=s'		=>	\$input_param,
			'output|o=s'	=>	\$output_param,
			'version|v=i'	=>	\$version_param,
			'frame|f=s'		=>	\$frame_param,
			'image'			=>	\$image_param,
			'info'			=>	\$info_param,
			'debug'			=>	\$debug_param,
			'help|?'		=>	\$help_param );

if ( $help_param ) {
	print "readID3.pl\n";
	print "version 1.1\n\n";
	print "parameters:\n";
	print "--input|-i <input_file>\n";
	print "\tMP3 file to read ID3 tag from\n";
	print "--output|o <output_file>\n";
	print "\tfile to output tag information\n";
	print "--version|v <version>\n";
	print "\tparse ID3v1 or ID3v2 tag\n";
	print "\tdefault is 0, which attempts to read ID3v2, and if not present, switches to ID3v1\n";
	print "--frame|-f <frame>\n";
	print "\tdecode specific frame - default is all\n";
	print "\t--frame all\n";
	print "\t\tdecode all frames\n";
	print "\t--frame none\n";
	print "\t\tdo not display any frame info\n";
	print "--info\n";
	print "\tdisplay general information about the tag (default is false)\n";
	print "--image\n";
	print "\texport any attached image to image file\n";
	print "--help|?\n";
	print "\tdisplay this message\n";
	exit;
}

if ( $input_param eq undef ) {
	print "Please specify a filename\n";
	exit;
	### in the future, do a glob of *.mp3???
}
if ( $version_param eq undef ) { $version_param = 0; }
if ( $frame_param eq "all" ) { $frame_param = ""; }

$output_string = "";

if ( $version_param == 1 ) { $output_string = read_v1_tag(); }	# ID3v1 tag
elsif ( $version_param == 2 ) { $output_string = read_v2_tag();	}	# Id3v2 tag
else {
	# try ID3v2 tag if it exists, otherwise return the ID3v1 tag if it exists
	$output_string = read_v2_tag();
	if ( $output_string eq undef ) { $output_string = read_v1_tag(); }
}

## interesting side effect of this approach...
## if there is a v2 tag, and an unused frame is specified, there will be no return value
## if no version was specified, it will appear there is no v2 tag and the v1 tag will be returned

if ( $debug_param ) { print"\n"; }

if ( $output_param ) {
	open( OUTPUT_FILE, '>', $output_param ) or die $!;
	print( OUTPUT_FILE $output_string );
	close( OUTPUT_FILE );
} else { print $output_string; }

###
### subroutines
###

sub read_v1_tag {
	# handle ID3 v1 and ID3v1.1
	
	my $id3v1_output_string;
		
	# open the input file
	open( MYFILE, "<", $input_param )
		or die "Could not open file $input_param\n";
	binmode( MYFILE );				# treat as binary file
	$filesize = -s MYFILE;			# get the size of the file
	if ( $debug_param ) { print "$input_param file size: $filesize\n"; }
	
	# ID3v1 tags are usually at the end of the file in the last 128 bytes
	# there is an extended version of the ID3v1 tag which comes before the regular tag
	# it's 227 bytes long and starts with "TAG+"
	# it's not an official extension, and only a few players support it
	# Back up 355 bytes (128 + 227) from the end of the file, and read the rest in
	# parse through last 128 as a regular tag
	# see if previous 227 is an extended tag and parse if it is
	# see http://en.wikipedia.org/wiki/ID3
	
	seek( MYFILE, -355, 2 );
	read( MYFILE, $extended_buffer, 227 );
	read( MYFILE, $buffer, 128 );
	close( MYFILE );
	
	# check that this is a ID3 tag
	$id3v1_header = substr( $buffer, 0, 3 );
	
	if ( $id3v1_header eq "TAG" ){
		# parse the ID3 tag
		$id3v1_title = substr( $buffer, 3, 30 );
		$id3v1_artist = substr( $buffer, 33, 30 );
		$id3v1_album = substr( $buffer, 63, 30 );
		$id3v1_year = substr( $buffer, 93, 4 );
		$id3v1_comment = substr ( $buffer, 97, 28 );
		$id3v1_zerobyte = substr( $buffer, 125, 1 );
		$id3v1_track = substr( $buffer, 126, 1 );
		$id3v1_genre = substr( $buffer, 127, 1 );
		
		if ( $debug_param ) {
			print "DEBUG: ID3v1 tag elements\n";
			print "Title: $id3v1_title\n";
			print "Artist: $id3v1_artist\n";
			print "Album: $id3v1_album\n";
			print "Year: $id3v1_year\n";
			print "Comment: $id3v1_comment\n";
			print "Zero Byte: $id3v1_zerobyte\n";
			print "Track: $id3v1_track\n";
			print "Genre: $id3v1_genre\n";
			print "\n";
		}
		
		# unpack( "W", <byte> ) is same as ord( <byte> )
		$id3v1_tag_has_track = unpack( "W", $id3v1_zerobyte );
		if ( $debug_param ) { print "id3v1_tag_has_track: $id3v1_tag_has_track\n"; }
		
		if ( !$id3v1_tag_has_track ) {
			if ( $debug_param ) { print "ID3v1 tas has a track number\n"; }
			$comment_string = $id3v1_comment;
			$track_number = unpack( "W", $id3v1_track );
		} else {
			if ( $debug_param ) { print "ID3v1 tas has no track number\n"; }
			$comment_string = $id3v1_comment . $id3v1_track . $id3v1_genre;
			$track_number = "";
		}
		
		if ( $debug_param ) {
			print "comment_string: $comment_string\n";
			print "track_number: $track_number\n";
		}
		
		$genre_number = unpack( "W", $id3v1_genre );
		if ( $debug_param ) { print "genre_number: $genre_number\n"; }
		
		$genre_string = decodeID3v1Genre( $genre_number );
		if ( $debug_param ) { print "genre_string: $genre_string\n"; }
		
		$id3v1_is_extended_tag = 0;
		$id3v1ext_header = substr( $extended_buffer, 0, 4 );
		$id3v1ext_title = substr( $extended_buffer, 4, 60 );
		$id3v1ext_artist = substr( $extended_buffer, 64, 60 );
		$id3v1ext_album = substr( $extended_buffer, 124, 60 );
		$id3v1ext_speed = substr( $extended_buffer, 184, 1 );
		$id3v1ext_genre = substr( $extended_buffer, 185, 30 );
		$id3v1ext_starttime = substr( $extended_buffer, 215, 6 );
		$id3v1ext_endtime = substr( $extended_buffer, 221, 6 );

		if ( $debug_param ) {
			print "DEBUG: ID3v1 extended tag elements\n";
			print "Extended header: $id3v1ext_header\n";
			print "Extended title: $id3v1ext_title\n";
			print "Extended artist: $id3v1ext_artist\n";
			print "Extended album: $id3v1ext_album\n";
			print "Extended speed: $id3v1ext_speed\n";
			print "Extended genre: $id3v1ext_genre\n";
			print "Extended start time: $id3v1ext_starttime\n";
			print "Extended end time: $id3v1ext_endtime\n";
		}
		
		if ( $id3v1ext_header eq "TAG+" ) {
			$id3v1_is_extended_tag = 1;
			if ( $debug_param ) { print "DEBUG: Appears to be an extended tag\n"; }
			$id3v1_title .= $id3v1ext_title;
			$id3v1_artist .= $id3v1ext_artist;
			$id3v1_album .= $id3v1ext_album;
			$speed_value = unpack( "W", $id3v1ext_speed );
		}
		
		if ( $info_param ) {
			$id3v1_output_string .= "File\t$input_param\n" . "Version\tID3v1\n";
		}
		
		$id3v1_output_string .= "Title\t$id3v1_title\n" . "Artist\t$id3v1_artist\n"
		. "Album\t$id3v1_album\n" . "Year\t$id3v1_year\n"
		. "Comment\t$comment_string\n";
		if ( $track_number ne undef ) { $id3v1_output_string .= "Track\t$track_number\n"; }
		$id3v1_output_string .= "Genre\t$genre_string ($genre_number)\n";
		
		if ( $id3v1_is_extended_tag ) {
			$id3v1_output_string .= "Speed\t$id3v1ext_speed\n" . "Extended Genre\t$id3v1ext_genre\n" .
			"Start Time\t$id3v1ext_starttime\n" . "End Time\t$id3v1ext_endtime\n";
		}
		
	} else {
		# this is not a ID3v1 tag
		if ( $debug_param ) { print "$input_param does not contain a ID3v1 tag\n"; }
		$id3v1_output_string = "";
	}
	
	return( $id3v1_output_string );
}

sub read_v2_tag {
	# handle ID3 v2.3 and v2.4

	my $id3v2_output_string;

	# open the input file
	open( MYFILE, "<", $input_param )
		or die "Could not open file $input_param\n";
	binmode( MYFILE );				# treat as binary file
	$filesize = -s MYFILE;			# get the size of the file
	if ( $debug_param ) { print "$input_param file size: $filesize\n"; }
	
	$result = read( MYFILE, $buffer, 10 );
	if ( $debug_param ) { print "DEBUG: Header read result: $result\n"; }
	
	$id3v2_identifier = substr( $buffer, 0, 3 );
	$id3v2_version = substr( $buffer, 3, 2 );
	$id3v2_flags = substr( $buffer, 5, 1 );
	$id3v2_tag_size = substr( $buffer, 6, 4 );
	
	if ( $info_param ) {
		$id3v2_output_string .= "File\t$input_param\n";
		$id3v2_output_string .= "Identifier\t$id3v2_identifier\n";
	}
	if ( $id3v2_identifier ne "ID3" ) {
		close( MYFILE );
		return "";
	}
	$id3v2_major_version = unpack( "W", substr( $id3v2_version, 0, 1 ) );
	$id3v2_minor_version = unpack( "W", substr( $id3v2_version, 1, 1 ) );
	$id3v2_version_string = "ID3v2.$id3v2_major_version.$id3v2_minor_version";
	if ( $info_param ) { $id3v2_output_string .= "ID3 version\t$id3v2_version_string\n"; }
	
	$id3v2_flag_bit_string = unpack( "B8", $id3v2_flags );
	$id3v2_flag_unsynchonization = substr( $id3v2_flag_bit_string, 1, 1 );
	$id3v2_flag_extended_header = substr( $id3v2_flag_bit_string, 2, 1 );
	$id3v2_flag_experimental = substr( $id3v2_flag_bit_string, 3, 1 );
	$id3v2_flag_footer_present = substr( $id3v2_flag_bit_string, 4, 1 );
	
	if ( $info_param ) {
		if ( $id3v2_flag_unsynchonization ) { $id3v2_output_string .= "Unsychronization\ttrue\n"; }
		else { $id3v2_output_string .= "Unsychronization\tfalse\n"; }
			
		if ( $id3v2_flag_extended_header ) { $id3v2_output_string .= "Extended header\ttrue\n"; }
		else { $id3v2_output_string .= "Extended header\tfalse\n"; }
		
		if ( $id3v2_flag_experimental ) { $id3v2_output_string .= "Experimental indicator\ttrue\n"; }
		else { $id3v2_output_string .= "Experimental indicator\tfalse\n"; }
		
		if ( $id3v2_flag_footer_present ) { $id3v2_output_string .= "Footer present\ttrue\n"; }
		else { $id3v2_output_string .= "Footer present\tfalse\n"; }
	}		
	
	$id3v2_tag_size_value = synchsafe_value( $id3v2_tag_size, 4 );
		
	if ( $info_param ) { $id3v2_output_string .= "Tag size\t$id3v2_tag_size_value\n"; }
	
	# read the rest of the tag
	$result = read( MYFILE, $buffer, $id3v2_tag_size_value );
	if ( $debug_param ) { print "DEBUG: Read rest of tag result: $result\n"; }
	
	$buffer_pointer = 0;
	
	# parse extended header
	if ( $id3v2_flag_extended_header ) {
		# extended header format:
		# 	Extended Header Size	4 * %0xxxxxxx
		# 	Number of flag bytes	$01
		# 	Extended Flags			$xx
		# the extended header size is a synchsafe value

		$id3v2_extended_header_size = substr( $buffer, $buffer_pointer, 4 );
		$buffer_pointer += 4;
		
		my $id3v2_extended_header_size_value = synchsafe_value( $id3v2_extended_header_size, 4 );
		if ( $info_param ) {
			$id3v2_output_string .= "Extended header size\t$id3v2_extended_header_size_value\n";
		}
		$buffer_pointer += $id3v2_extended_header_size_value
		
		## for now, skipping the extended header
		## need to figure out how to parse the flags
		## the documentation is a bit unclear
	}
	
	## frame format:
	#	Frame ID      $xx xx xx xx  (four characters)
	#	Size      4 * %0xxxxxxx
	#	Flags         $xx xx
	
	$done = 0;
	while ( !$done ) {
		if ( $debug_param ) { print "\n"; }
		
		$frame_id = substr( $buffer, $buffer_pointer, 4 );
		$frame_is_padding = ( ord( $frame_id ) == 0 );
		if ( $debug_param && $frame_is_padding ) { print "DEBUG: Frame is padding\n"; }
		# if the frame_id starts with 0x00, the frame is padding
		# padding must come after the last frame, so we can safely skip the rest of the tag
		## per the ID3 spec:
		## 	Furthermore it MUST NOT have any padding when a tag footer is added to the tag
		## so we should check if the footer present flag is set and warn if there is padding
		
		if ( !$frame_is_padding ) {
			$buffer_pointer += 4;
			if ( $debug_param ) { print "frame_id: $frame_id\n"; }
			
			$frame_size = substr( $buffer, $buffer_pointer, 4 );
			$buffer_pointer += 4;
			$frame_size_value = synchsafe_value( $frame_size, 4 );
			if ( $debug_param ) { print "frame_size_value: $frame_size_value\n"; }
			
			$frame_flags = substr( $buffer, $buffer_pointer, 2 );
			$buffer_pointer += 2;
			if ( $debug_param ) { print "frame_flags: $frame_flags\n"; }
			
			$frame_flags_bit_string = unpack( "B16", $frame_flags );
			if ( $debug_param ) { print "DEBUG: frame_flags_bit_string: $frame_flags_bit_string\n"; }
			
			$tag_alter_preservation_flag = substr( $frame_flags_bit_string, 1, 1 );
			$file_alter_preservation_flag = substr( $frame_flags_bit_string, 2, 1 );
			$read_only_flag = substr( $frame_flags_bit_string, 3, 1 );
			$grouping_identity_flag = substr( $frame_flags_bit_string, 9, 1 );
			$compression_flag = substr( $frame_flags_bit_string, 12, 1 );
			$encryption_flag = substr( $frame_flags_bit_string, 13, 1 );
			$unsynchronization_flag = substr( $frame_flags_bit_string, 14, 1 );
			$data_length_indicator_flag = substr( $frame_flags_bit_string, 15, 1 );
			
			if ( $debug_param ) {
				if ( $tag_alter_preservation_flag ) { print "Frame should be discarded if altered\n"; }
				else { print "Frame should be preserved if altered\n"; }
				
				if ( $file_alter_preservation_flag ) { print "Frame should be discarded if file altered\n"; }
				else { print "Frame should be preserved if file altered\n"; }
				
				if ( $read_only_flag ) { print "Frame is read-only\n"; }
				else { print "Frame is not read-only\n"; }
				
				if ( $grouping_identity_flag ) { print "Frame contains group information\n"; }
				else { print "Frame does not contain group information\n"; }
				
				if ( $compression_flag ) { print "Frame is compressed using zlib [zlib] deflate method\n"; }
				else { print "Frame is not compressed\n"; }
				
				if ( $encryption_flag ) { print "Frame is encrypted\n"; }
				else { print "Frame is not encrypted\n"; }
				
				if ( $unsynchronization_flag ) { print "Frame has been unsyrchronised\n"; }
				else { print "Frame has not been unsynchronised\n"; }
				
				if ( $data_length_indicator_flag ) { print "A data length Indicator has been added to the frame\n"; }
				else { print "There is no Data Length Indicator\n"; }
			}
			
			$frame_data = substr( $buffer, $buffer_pointer, $frame_size_value );
			$buffer_pointer += $frame_size_value;
			if ( $debug_param ) {
				if ( $frame_id eq "APIC" ) { print "frame_data: <picture>\n"; }
				else { print "frame_data: $frame_data\n"; }
			}
			
			# if frame is a text frame, get rid of the encoding byte
			if ( substr( $frame_id, 0, 1 ) eq "T" ) {
				if ( $debug_param ) { print( "DEBUG: $frame_id is a text frame\n" ); }
				$frame_data = decode_text( $frame_data );
			} else {
				if ( $debug_param ) { print( "DEBUG: $frame_id is NOT a text frame\n" ); }
			}
			
			# if frame is a 'COMM' comment frame, get rid of the encoding byte
			if ( $frame_id eq "COMM" ) {
				if ( $debug_param ) { print( "DEBUG: $frame_id is a comment frame\n" ); }
				$frame_data = decode_comment( $frame_data );
			}
						
			## add to output
			## create sub that takes frame_id and returns a text description

			# if no frame is specified, output everything, including frame IDs
			# if a frame is specified, output only it
			# substitute "[image]" for APIC frame data
			if ( $frame_param eq undef ) {
				if ( $frame_id eq "APIC" ) { $id3v2_output_string .= "$frame_id\t[picture]\n"; }
				else { $id3v2_output_string .= "$frame_id\t$frame_data\n"; }
			} else {
				if ( $frame_param eq $frame_id ) {
					if ( $frame_id eq "APIC" ) { $id3v2_output_string .= "[picture]\n"; }
					else { $id3v2_output_string .= "$frame_data\n"; }
				}
			}
			
			# if frame contains a picture, process it.
			if ( $image_param && ( $frame_id eq "APIC" ) ) {

				###
				$apic_pointer = 0;
				$apic_text_encoding = unpack( "W", substr( $frame_data, $apic_pointer++, 1 ) );

				$apic_mime_type = "";
				$string_done = 0;
				while ( !$string_done ) {
					$my_character = substr( $frame_data, $apic_pointer++, 1 );
					if ( unpack( "W", $my_character ) == 0 ) { $string_done = 1; }
					$apic_mime_type .= $my_character;
				}
				
				$apic_picture_type = unpack( "W", substr( $frame_data, $apic_pointer++, 1 ) );
				
				$apic_description = "";
				$string_done = 0;
				while ( !$string_done ) {
					$my_character = substr( $frame_data, $apic_pointer++, 1 );
					if ( unpack( "W", $my_character ) == 0 ) { $string_done = 1; }
					$apic_description .= $my_character;
				}
				
				$apic_picture_data = substr( $frame_data, $apic_pointer, $frame_size_value - $apic_pointer );
				
				if ( $debug_param ) {
					print "DEBUG: APIC text encoding: $apic_text_encoding\n";
					print "DEBUG: APIC MIME type: $apic_mime_type\n";
					print "DEBUG: APIC picture type: $apic_picture_type\n";
					print "DEBUG: APIC description: $apic_description\n";
				}
				
				# write the picture data out to a file
				$image_file = $input_param;
				$image_file =~ s/\..+//g;					#	strip off the extension
				$image_file_extension = $apic_mime_type;
				$image_file_extension =~ s/^.+\///;			#	get the picture type from the MIME type
				$image_file .= "_$apic_picture_type" . 	"." . $image_file_extension;
				open( IMAGE_FILE, '>', $image_file ) or die $!;
				binmode( IMAGE_FILE );
				print IMAGE_FILE $apic_picture_data;
				close( IMAGE_FILE );
			}
			
		} else {
			# if the frame is padding, skip the rest of the tag
			$done = 1;
		}
		
		if ( $debug_param ) { print "DEBUG: buffer_pointer: $buffer_pointer\ttag_size: $id3v2_tag_size_value\n"; }
		
		# if we've come to the end of the tag, end
		if ( $buffer_pointer >= $id3v2_tag_size_value ) { $done = 1; }
	}
	
	# clean up
	close( MYFILE );
	
	return( $id3v2_output_string );
}

sub decode_text {
	my $frame_text_data = $_[0];
	my $data_length = length( $frame_text_data );
	my $text_encoding = substr( $frame_text_data, 0, 1 );
	my $frame_text = substr( $frame_text_data, 1, $data_length-1 );
	
	if ( $debug_param ) {
		print "DEBUG: frame text data: $frame_text_data\n";
		print "DEBUG: frame text encoding: " . ord( $text_encoding ) . "\n";
	}
	
	# in theory, we should look at $text_encoding and deciding what to do based on it
	# for now, assume it is there and assume it is 0x00 - ASCII text
	
	return( $frame_text );
}

sub decode_comment {
	my $frame_comm_data = $_[0];
	my $data_length = length( $frame_comm_data );
	my $frame_commment = substr( $frame_comm_data, 5, $data_length-5 );

	if ( $debug_param ) { print "DEBUG: frame comment data: $frame_comm_data\n"; }
	
	# in theory, we should look at $text_encoding and deciding what to do based on it
	# for now, assume it is there and assume it is 0x00 - ASCII text
	
	return( $frame_commment );
}


sub synchsafe_value {
	my $synchsafe_string = $_[0];
	my $synchsafe_length = $_[1];
	my $synchsafe_bit_string = "";
	
	for ( my $i = 0; $i < $synchsafe_length; $i++ ) {
		$synchsafe_bit_string .= substr( unpack( "B8", substr( $synchsafe_string, $i, 1 ) ), 1, 7 );
	}
	
	return( oct( "0b" . $synchsafe_bit_string ) );
}

sub decodeID3v1Genre {
	my $genre_value = $_[0];
	if ( $genre_value == 0 ) { return "Blues "; }
	elsif ( $genre_value == 1 ) { return "Classic Rock"; }
	elsif ( $genre_value == 2 ) { return "Country"; }
	elsif ( $genre_value == 3 ) { return "Dance"; }
	elsif ( $genre_value == 4 ) { return "Disco"; }
	elsif ( $genre_value == 5 ) { return "Funk"; }
	elsif ( $genre_value == 6 ) { return "Grunge"; }
	elsif ( $genre_value == 7 ) { return "Hip-Hop"; }
	elsif ( $genre_value == 8 ) { return "Jazz"; }
	elsif ( $genre_value == 9 ) { return "Metal"; }
	elsif ( $genre_value == 10 ) { return "New Age"; }
	elsif ( $genre_value == 11 ) { return "Oldies"; }
	elsif ( $genre_value == 12 ) { return "Other"; }
	elsif ( $genre_value == 13 ) { return "Pop"; }
	elsif ( $genre_value == 14 ) { return "R&B"; }
	elsif ( $genre_value == 15 ) { return "Rap"; }
	elsif ( $genre_value == 16 ) { return "Reggae"; }
	elsif ( $genre_value == 17 ) { return "Rock"; }
	elsif ( $genre_value == 18 ) { return "Techno"; }
	elsif ( $genre_value == 19 ) { return "Industrial"; }
	elsif ( $genre_value == 20 ) { return "Alternative"; }
	elsif ( $genre_value == 21 ) { return "Ska"; }
	elsif ( $genre_value == 22 ) { return "Death Metal"; }
	elsif ( $genre_value == 23 ) { return "Pranks"; }
	elsif ( $genre_value == 24 ) { return "Soundtrack"; }
	elsif ( $genre_value == 25 ) { return "Euro-Techno"; }
	elsif ( $genre_value == 26 ) { return "Ambient"; }
	elsif ( $genre_value == 27 ) { return "Trip-Hop"; }
	elsif ( $genre_value == 28 ) { return "Vocal"; }
	elsif ( $genre_value == 29 ) { return "Jazz+Funk"; }
	elsif ( $genre_value == 30 ) { return "Fusion"; }
	elsif ( $genre_value == 31 ) { return "Trance"; }
	elsif ( $genre_value == 32 ) { return "Classical"; }
	elsif ( $genre_value == 33 ) { return "Instrumental"; }
	elsif ( $genre_value == 34 ) { return "Acid"; }
	elsif ( $genre_value == 35 ) { return "House"; }
	elsif ( $genre_value == 36 ) { return "Game"; }
	elsif ( $genre_value == 37 ) { return "Sound Clip"; }
	elsif ( $genre_value == 38 ) { return "Gospel"; }
	elsif ( $genre_value == 39 ) { return "Noise"; }
	elsif ( $genre_value == 40 ) { return "AlternRock"; }
	elsif ( $genre_value == 41 ) { return "Bass"; }
	elsif ( $genre_value == 42 ) { return "Soul"; }
	elsif ( $genre_value == 43 ) { return "Punk"; }
	elsif ( $genre_value == 44 ) { return "Space"; }
	elsif ( $genre_value == 45 ) { return "Meditative"; }
	elsif ( $genre_value == 46 ) { return "Instrumental Pop"; }
	elsif ( $genre_value == 47 ) { return "Instrumental Rock"; }
	elsif ( $genre_value == 48 ) { return "Ethnic"; }
	elsif ( $genre_value == 49 ) { return "Gothic"; }
	elsif ( $genre_value == 50 ) { return "Darkwave"; }
	elsif ( $genre_value == 51 ) { return "Techno-Industrial"; }
	elsif ( $genre_value == 52 ) { return "Electronic"; }
	elsif ( $genre_value == 53 ) { return "Pop-Folk"; }
	elsif ( $genre_value == 54 ) { return "Eurodance"; }
	elsif ( $genre_value == 55 ) { return "Dream"; }
	elsif ( $genre_value == 56 ) { return "Southern Rock"; }
	elsif ( $genre_value == 57 ) { return "Comedy"; }
	elsif ( $genre_value == 58 ) { return "Cult"; }
	elsif ( $genre_value == 59 ) { return "Gangsta"; }
	elsif ( $genre_value == 60 ) { return "Top 40"; }
	elsif ( $genre_value == 61 ) { return "Christian Rap"; }
	elsif ( $genre_value == 62 ) { return "Pop/Funk"; }
	elsif ( $genre_value == 63 ) { return "Jungle"; }
	elsif ( $genre_value == 64 ) { return "Native American"; }
	elsif ( $genre_value == 65 ) { return "Cabaret"; }
	elsif ( $genre_value == 66 ) { return "New Wave"; }
	elsif ( $genre_value == 67 ) { return "Psychadelic"; }
	elsif ( $genre_value == 68 ) { return "Rave"; }
	elsif ( $genre_value == 69 ) { return "Showtunes"; }
	elsif ( $genre_value == 70 ) { return "Trailer"; }
	elsif ( $genre_value == 71 ) { return "Lo-Fi"; }
	elsif ( $genre_value == 72 ) { return "Tribal"; }
	elsif ( $genre_value == 73 ) { return "Acid Punk"; }
	elsif ( $genre_value == 74 ) { return "Acid Jazz"; }
	elsif ( $genre_value == 75 ) { return "Polka"; }
	elsif ( $genre_value == 76 ) { return "Retro"; }
	elsif ( $genre_value == 77 ) { return "Musical"; }
	elsif ( $genre_value == 78 ) { return "Rock & Roll"; }
	elsif ( $genre_value == 79 ) { return "Hard Rock"; }
	elsif ( $genre_value == 80 ) { return "Folk"; }
	elsif ( $genre_value == 81 ) { return "Folk-Rock"; }
	elsif ( $genre_value == 82 ) { return "National Folk"; }
	elsif ( $genre_value == 83 ) { return "Swing"; }
	elsif ( $genre_value == 84 ) { return "Fast Fusion"; }
	elsif ( $genre_value == 85 ) { return "Bebob"; }
	elsif ( $genre_value == 86 ) { return "Latin"; }
	elsif ( $genre_value == 87 ) { return "Revival"; }
	elsif ( $genre_value == 88 ) { return "Celtic"; }
	elsif ( $genre_value == 89 ) { return "Bluegrass"; }
	elsif ( $genre_value == 90 ) { return "Avantgarde"; }
	elsif ( $genre_value == 91 ) { return "Gothic Rock"; }
	elsif ( $genre_value == 92 ) { return "Progressive Rock"; }
	elsif ( $genre_value == 93 ) { return "Psychedelic Rock"; }
	elsif ( $genre_value == 94 ) { return "Symphonic Rock"; }
	elsif ( $genre_value == 95 ) { return "Slow Rock"; }
	elsif ( $genre_value == 96 ) { return "Big Band"; }
	elsif ( $genre_value == 97 ) { return "Chorus"; }
	elsif ( $genre_value == 98 ) { return "Easy Listening"; }
	elsif ( $genre_value == 99 ) { return "Acoustic"; }
	elsif ( $genre_value == 100 ) { return "Humour"; }
	elsif ( $genre_value == 101 ) { return "Speech"; }
	elsif ( $genre_value == 102 ) { return "Chanson"; }
	elsif ( $genre_value == 103 ) { return "Opera"; }
	elsif ( $genre_value == 104 ) { return "Chamber Music"; }
	elsif ( $genre_value == 105 ) { return "Sonata"; }
	elsif ( $genre_value == 106 ) { return "Symphony"; }
	elsif ( $genre_value == 107 ) { return "Booty Bass"; }
	elsif ( $genre_value == 108 ) { return "Primus"; }
	elsif ( $genre_value == 109 ) { return "Porn Groove"; }
	elsif ( $genre_value == 110 ) { return "Satire"; }
	elsif ( $genre_value == 111 ) { return "Slow Jam"; }
	elsif ( $genre_value == 112 ) { return "Club"; }
	elsif ( $genre_value == 113 ) { return "Tango"; }
	elsif ( $genre_value == 114 ) { return "Samba"; }
	elsif ( $genre_value == 115 ) { return "Folklore"; }
	elsif ( $genre_value == 116 ) { return "Ballad"; }
	elsif ( $genre_value == 117 ) { return "Power Ballad"; }
	elsif ( $genre_value == 118 ) { return "Rhythmic Soul"; }
	elsif ( $genre_value == 119 ) { return "Freestyle"; }
	elsif ( $genre_value == 120 ) { return "Duet"; }
	elsif ( $genre_value == 121 ) { return "Punk Rock"; }
	elsif ( $genre_value == 122 ) { return "Drum Solo"; }
	elsif ( $genre_value == 123 ) { return "A capella"; }
	elsif ( $genre_value == 124 ) { return "Euro-House"; }
	elsif ( $genre_value == 125 ) { return "Dance Hall"; }
	else { return "undefined"; }
}
