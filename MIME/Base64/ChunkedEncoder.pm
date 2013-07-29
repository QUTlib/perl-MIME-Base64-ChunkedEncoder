package MIME::Base64::ChunkedEncoder;

####################################################################
#
# MIME::Base64::ChunkedEncoder
#
# A Base64 en-/decoder that writes output to a filehandle as chunks of
# input data are provided.
#
# Only decoding is implemented.
#
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

use MIME::Base64;

sub new
{
    my ( $class ) = @_;
    my $self =
    {
        output_fh => undef,
        buffer => '',
    };

    bless $self, $class;

    return $self;
}

#
# Get/Set the output filehandle, returns the filehandle.
#
# $destination can be a filehandle or a reference to a string.
#
# Assumes $destination is a string if it's a scalar, or a filehandle
# otherwise.
sub output
{
    my ( $self, $destination ) = @_;

    if ( defined $destination )
    {
        my $fh;
        if ( ref( $destination ) eq 'SCALAR' )
        {
            # Open the string as a filehandle
            open( $fh, '>', $destination );
        }
        else
        {
            $fh = $destination;
        }
        $self->{output_fh} = $fh;
    }
    return $self->{output_fh};
}

#
# Adds $base64 data to internal buffer, then decodes as many bytes of
# the buffer as possible and writes them to output_fh.
#
sub add_base64
{
    my ( $self, $base64 ) = @_;

    $base64 =~ s/\s+//g; # remove all whitespace
    $self->{buffer} .= $base64;

    my $num_bytes_to_decode = length( $self->{buffer} ) - ( length( $self->{buffer} ) % 4 );
    my $to_decode = substr( $self->{buffer}, 0, $num_bytes_to_decode, '' );
    my $fh = $self->{output_fh};
    print $fh MIME::Base64::decode_base64( $to_decode );
    return;
}


#
# Flushes the internal buffer by decoding the whole buffer and writing
# to output_fh.  It appends padding as necessary.
#
sub flush
{
    my ( $self ) = @_;

    if ( length $self->{buffer} > 0 )
    {
        # Don't worry about adding missing padding as MIME::Base64
        # tolerates missing padding.
        my $fh = $self->{output_fh};
        print $fh MIME::Base64::decode_base64( $self->{buffer} );
        $self->{buffer} = '';
    }
    $self->{output_fh} = undef;
    return;
}

1;
