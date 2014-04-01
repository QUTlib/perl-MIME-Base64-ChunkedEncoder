####################################################################
#
# Copyright 2013 Queensland University of Technology. All Rights
# Reserved.
#
# This file is part of perl-MIME-Base64-ChunkedEncoder.
#
# perl-MIME-Base64-ChunkedEncoder is free software: you can
# redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
####################################################################

use strict;
use warnings;


use File::Temp;
use Test::More;
use Scalar::Util qw(openhandle);

BEGIN
{
    use File::Basename qw(dirname);
    use lib dirname( __FILE__ ) . '/../lib';
}

BEGIN { use_ok('MIME::Base64::ChunkedEncoder'); }

my $decoder = MIME::Base64::ChunkedEncoder->new();

my $string = '';
ok( openhandle( $decoder->output( \$string ) ), 'Returns a filehandle when given a string ref' );

my $tmp_file = File::Temp->new();
ok( openhandle( $decoder->output( $tmp_file ) ), 'Returns a filehandle when given a temp file'  );

# Test some very simple decoding
decodes_to( $decoder, ['dGVzdCBzdHJpbmc='], 'test string', 'Decoded in single 4-char multiple chunk' );

# Chunked decoding
decodes_to( $decoder, ['dGVzdCBzdHJpb', 'mc='], 'test string', 'Decoded in multiple chunks' );
decodes_to( $decoder, ['dGVzdC', 'BzdHJpb', 'mc='], 'test string', 'Decoded in more chunks' );
decodes_to( $decoder, ['', '', 'dGVzdC', 'BzdHJpb', 'mc='], 'test string', 'Decoded in more chunks' );
decodes_to( $decoder, ['dGVz', 'dCBz', 'dHJpb', 'mc='], 'test string', 'Decoded in 4-char chunks' );
decodes_to( $decoder, ['d', 'G', 'V', 'z', 'd', 'C', 'B', 'z', 'dHJpb', 'mc='], 'test string', 'Decoded in 1-char chunks' );

decodes_to( $decoder, ["dGVzdC\n", "Bzd\nHJpb", 'mc='], 'test string', 'Decoded Base64 data with line-breaks' );

# Missing padding
decodes_to( $decoder, ['dGVzdCBzdHJpbmc'], 'test string', 'Decodes correctly when padding is missing' );

# Encoded empty strings
decodes_to( $decoder, ['=='], '', 'Decodes empty string' );
decodes_to( $decoder, ['='], '', 'Decodes empty string' );
decodes_to( $decoder, [''], '', 'Decodes empty string' );

# Writing to a file
$decoder->output( $tmp_file );
$decoder->add_base64( 'dGVzdCBzdHJpbmc=' );
$decoder->flush();
seek( $tmp_file, 0, 0 );
my @lines = $tmp_file->getlines();
is( join( '', @lines), 'test string', 'Writing to File::Temp' );
undef( $tmp_file );

# test .pdf file input
my $dirname = dirname( __FILE__ );
file_data_survives_decoding( $dirname . '/test.pdf', $decoder, 1 );
file_data_survives_decoding( $dirname . '/test.pdf', $decoder, 4 );
file_data_survives_decoding( $dirname . '/test.pdf', $decoder, 42 );
file_data_survives_decoding( $dirname . '/test.pdf', $decoder, 400 );
file_data_survives_decoding( $dirname . '/test.pdf', $decoder, 1200 );
file_data_survives_decoding( $dirname . '/test.docx', $decoder, 400 );

done_testing();

#
# Decodes $encoded using $decoder and returns true if it equals
# $expected
#
sub decodes_to
{
    my ( $decoder, $chunks, $expected, $description ) = @_;

    #diag($expected);

    my $string = '';
    $decoder->output( \$string );

    foreach my $chunk ( @{$chunks} )
    {
        $decoder->add_base64( $chunk );
    }
    $decoder->flush();

    return is( $string, $expected, $description );
}

use File::Slurp qw(read_file);
use MIME::Base64 qw(encode_base64);
use Digest::MD5 qw(md5_hex);

#
# Encodes contents of file with $filename using MIME::Base64, then
# decodes it in chunks of $chunk_size using $decoder and returns true
# if the result equals the original contents.
#
sub file_data_survives_decoding
{
    my ( $filename, $decoder, $chunk_size ) = @_;
    #diag($filename);

    my $input_data = read_file( $filename, { binmode => ':raw' } );
    my $input_md5 = md5_hex( $input_data );
    my $base64_data = encode_base64( $input_data );
    #diag( "Base64 length = " . length( $base64_data ) );
    undef( $input_data );
    my $output_data = '';
    $decoder->output( \$output_data );
    # Take a $chunk_size'd substring from the start of the Base64 data
    # and decode it, then repeat
    my $remaining = length( $base64_data );
    while ( $remaining > 0 )
    {
        my $chunk = substr( $base64_data, 0, $chunk_size, '' );
        $decoder->add_base64( $chunk );
        $remaining -= $chunk_size;
    }
    $decoder->flush();
    my $output_md5 = md5_hex( $output_data );
    return is( $input_md5, $output_md5, "Encode and decode $filename in $chunk_size character chunks");
}

1;
