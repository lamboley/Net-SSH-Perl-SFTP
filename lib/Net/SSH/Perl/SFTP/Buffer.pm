package Net::SSH::Perl::SFTP::Buffer;

use strict;
use warnings;

use parent qw[Net::SSH::Perl::Buffer];

use Math::Int64 qw[net_to_int64 int64_to_net];

sub new { shift->SUPER::new(@_) }

sub get_int64 {
    my $buf = shift;
    my $off = defined $_[0] ? shift : $buf->{offset};
    $buf->{offset} += 8;
    net_to_int64($buf->bytes($off, 8));
}

sub put_int64 { shift->{buf} .= int64_to_net($_[0]) }

sub get_attributes { Net::SSH::Perl::SFTP::Attributes->new(Buffer => shift) }

sub put_attributes { shift->{buf} .= $_[0]->as_buffer->bytes }

1;
