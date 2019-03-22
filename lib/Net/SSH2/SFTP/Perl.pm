package Net::SSH2::SFTP::Perl;

use strict;
use warnings;

our $VERSION  = '0.01'; 

use parent qw[Net::SSH::Perl::SSH2];

use Net::SSH2::SFTP::Perl::Buffer;
use Net::SSH2::SFTP::Perl::Attributes;
 
use Carp qw[croak];
 
sub new {
    my ($class, $host, $user, $password, %p) = @_;
    
    $p{protocol} = 2;
    
    my $self = $class->SUPER::new($host, %p);
    $self->login($user, $password);
    
    bless $self, $class;
    $self->_initialize(%p);
    $self;
}

sub _initialize {
    my ($self, %p) = @_;
    
    $self->{_msg_id} = 0; 
}
 
sub stat {
    my($self, $remote) = @_;

    my ($channel, $incoming) = $self->_channel_subsystem_sftp;
            
    my ($msg, $id);
    $msg = $self->new_msg(1);
    $msg->put_int32(3);
    
    my $b = Net::SSH2::SFTP::Perl::Buffer->new;
    $b->put_int32($msg->length);
    $b->append($msg->bytes);
    $channel->send_data($b->bytes);
    
    my $len;
    unless ($incoming->length > 4) {
        $self->client_loop;
        croak "Connection closed" unless $incoming->length > 4;
        $len = unpack "N", $incoming->bytes(0, 4, '');
        croak "Received message too long $len" if $len > 256 * 1024;
        while ($incoming->length < $len) {$self->client_loop}
    }
    
    $msg = Net::SSH2::SFTP::Perl::Buffer->new;
    $msg->append($incoming->bytes(0, $len, ''));
    
    my $type = $msg->get_int8;
    croak "Invalid packet back from SSH2_FXP_INIT (type $type)" if $type != 2;

    ($msg, $id) = $self->new_msg_id(17);
    
    $msg->put_str($remote);

    $b = Net::SSH2::SFTP::Perl::Buffer->new;
    $b->put_int32($msg->length);
    $b->append($msg->bytes);
    $channel->send_data($b->bytes);

    unless ($incoming->length > 4) {
        $self->client_loop;
        croak "Connection closed" unless $incoming->length > 4;
        $len = unpack "N", $incoming->bytes(0, 4, '');
        croak "Received message too long $len" if $len > 256 * 1024;
        while ($incoming->length < $len) {$self->client_loop}
    }

    $msg = Net::SSH2::SFTP::Perl::Buffer->new;
    $msg->append($incoming->bytes(0, $len, ''));

    $type = $msg->get_int8;
    my $expected_id = $msg->get_int32;

    croak "ID mismatch ($expected_id != $id)" unless $expected_id == $id;

    if ($type == 101) {return}
    elsif ($type != 105) {croak "Expected SSH2_FXP_ATTRS packet, got $type"}

    $channel->drain_outgoing;
    $channel->{istate} = 0x02;
    $channel->send_eof;
    $channel->{istate} = 0x08;

    $msg->get_attributes;
}

sub get {
    my($self, $remote, $local, $a) = @_;

    $a = $self->stat($remote) unless defined $a;

    local *FH;
    if ($local) {
        open FH, ">$local" or croak "Can't open $local: $!";
        binmode FH or croak "Can't binmode FH: $!"; 
    }

    my ($channel, $incoming) = $self->_channel_subsystem_sftp;

    my ($msg, $id);
    $msg = $self->new_msg(1);
    $msg->put_int32(3);

    my $b = Net::SSH2::SFTP::Perl::Buffer->new;
    $b->put_int32($msg->length);
    $b->append($msg->bytes);
    $channel->send_data($b->bytes);

    my $len;
    unless ($incoming->length > 4) {
        $self->client_loop;
        croak "Connection closed" unless $incoming->length > 4;
        $len = unpack "N", $incoming->bytes(0, 4, '');
        croak "Received message too long $len" if $len > 256 * 1024;
        while ($incoming->length < $len) { $self->client_loop }
    }

    $msg = Net::SSH2::SFTP::Perl::Buffer->new;
    $msg->append($incoming->bytes(0, $len, ''));

    my $type = $msg->get_int8;
    croak "Invalid packet back from SSH2_FXP_INIT (type $type)" if $type != 2;

    ($msg, $id) = $self->new_msg_id(3);

    $msg->put_str($remote);
    $msg->put_int32(0x01);
    $msg->put_attributes(Net::SSH2::SFTP::Perl::Attributes->new);

    $b = Net::SSH2::SFTP::Perl::Buffer->new;
    $b->put_int32($msg->length);
    $b->append($msg->bytes);
    $channel->send_data($b->bytes);

    unless ($incoming->length > 4) {
        $self->client_loop;
        croak "Connection closed" unless $incoming->length > 4;
        $len = unpack "N", $incoming->bytes(0, 4, '');
        croak "Received message too long $len" if $len > 256 * 1024;
        while ($incoming->length < $len) { $self->client_loop }
    }

    $msg = Net::SSH2::SFTP::Perl::Buffer->new;
    $msg->append($incoming->bytes(0, $len, ''));

    $type = $msg->get_int8;
    my $expected_id = $msg->get_int32;

    croak "ID mismatch ($expected_id != $id)" unless $expected_id == $id;

    if ($type == 101) {
        $self->warn("Couldn't get handle", $msg->get_int32);
        return;
    }
    elsif ($type != 102) { croak "Expected SSH2_FXP_HANDLE packet, got $type" }

    my $handle = $msg->get_str;
    return unless defined $handle;

    my $offset = 0;
    while (1) {
        ($msg, $id) = $self->new_msg_id(5);

        $msg->put_str($handle);
        $msg->put_int64($offset);
        $msg->put_int32(65536);

        $b = Net::SSH2::SFTP::Perl::Buffer->new;
        $b->put_int32($msg->length);
        $b->append($msg->bytes);
        $channel->send_data($b->bytes);

        unless ($incoming->length > 4) {
            $self->client_loop;
            croak "Connection closed" unless $incoming->length > 4;
            $len = unpack "N", $incoming->bytes(0, 4, '');
            croak "Received message too long $len" if $len > 256 * 1024;
            while ($incoming->length < $len) { $self->client_loop }
        }

        $msg = Net::SSH2::SFTP::Perl::Buffer->new;
        $msg->append($incoming->bytes(0, $len, ''));

        $type = $msg->get_int8;
        $expected_id = $msg->get_int32;

        croak "ID mismatch ($expected_id != $id)" unless $expected_id == $id;

        my $status;
        if ($type == 101) {
            $status = $msg->get_int32;
            if ($status != 1) {
                $self->warn("Couldn't read from remote file", $status);
            }
        }
        elsif ($type != 103) { croak "Expected SSH2_FXP_DATA packet, got $type" }

        my $data = $msg->get_str;
        
        last if defined $status && $status == 1;
        return unless $data;

        my $len = length($data);
        croak "Received more data than asked for $len > " . 65536 if $len > 65536;
        print FH $data if $local;
        $offset += $len;
    }

    ($msg, $id) = $self->new_msg_id(4);
    $msg->put_str($handle);

    $b = Net::SSH2::SFTP::Perl::Buffer->new;
    $b->put_int32($msg->length);
    $b->append($msg->bytes);
    $channel->send_data($b->bytes);

    unless ($incoming->length > 4) {
        $self->client_loop;
        croak "Connection closed" unless $incoming->length > 4;
        $len = unpack "N", $incoming->bytes(0, 4, '');
        croak "Received message too long $len" if $len > 256 * 1024;
        while ($incoming->length < $len) { $self->client_loop }
    }

    $msg = Net::SSH2::SFTP::Perl::Buffer->new;
    $msg->append($incoming->bytes(0, $len, ''));

    $type = $msg->get_int8;
    $expected_id = $msg->get_int32;

    croak "ID mismatch ($expected_id != $id)" unless $expected_id == $id;
    croak "Expected SSH2_FXP_STATUS packet, got $type" if $type != 101;

    my $status = $msg->get_int32;

    $self->warn("Couldn't close file", $status) unless $status == 0;

    $channel->drain_outgoing;
    $channel->{istate} = 0x02;
    $channel->send_eof;
    $channel->{istate} = 0x08;

    if ($local) {
        close FH;
        my $flags = $a->flags;
        my $mode = $flags & 0x04 ? $a->perm & 0777 : 0666;
        chmod $mode, $local or croak "Can't chmod $local: $!";

        if ($flags & 0x08) {
            utime $a->atime, $a->mtime, $local or croak "Can't utime $local: $!";
        }
    }
}

sub _channel_subsystem_sftp {
    my $self = shift;

    my $channel = $self->_session_channel;
    $channel->open;

    $channel->register_handler(91, sub {
        my($c, $packet) = @_;
        my $r_packet = $c->request_start('subsystem', 1);
        $r_packet->put_str('sftp');
        $r_packet->send;
    });

    my $subsystem_reply = sub {
        my($c, $packet) = @_;
        $c->{ssh}->fatal_disconnect("Request for subsystem 'sftp' failed on channel '" . $packet->get_int32 . "'") if $packet->type == 100;
        $c->{ssh}->break_client_loop;
    };

    my $cmgr = $self->channel_mgr;
    $cmgr->register_handler(100, $subsystem_reply);
    $cmgr->register_handler(99, $subsystem_reply);

    my $incoming = Net::SSH2::SFTP::Perl::Buffer->new;
    $channel->register_handler("_output_buffer", sub {
        my($c, $incomingfer) = @_;
        $incoming->append($incomingfer->bytes);
        $c->{ssh}->break_client_loop;
    });

    $self->client_loop;

    ($channel, $incoming);
}

sub new_msg {
    my($ssh, $code) = @_;
    my $msg = Net::SSH2::SFTP::Perl::Buffer->new;
    $msg->put_int8($code);
    $msg;
}

sub new_msg_id {
    my ($ssh, $code, $sid) = @_;
    my $msg = $ssh->new_msg($code);
    my $id = defined $sid ? $sid : $ssh->msg_id;
    $msg->put_int32($id);
    ($msg, $id);
}

sub msg_id { $_[0]->{_msg_id}++ }

1;
__END__

=head1 NAME

Net::SSH2::SFTP::Perl - Add support of SFTP for Net::SSH::Perl

=head1 SYNOPSIS

    my $ssh = Net::SSH2::SFTP::Perl->new($host, $user, $password);

    my ($out, $err, $ex) = $ssh->cmd('id');

    $ssh->get('/home/lamboley/toto', 'C:\toto');

    ($out, $err, $ex) = $ssh->cmd('ls');

    if (my $a = $ssh->stat('/home/lamboley/toto2')) {
        $ssh->get('/home/lamboley/toto2', 'C:\toto2', $a);
    }

=head1 DESCRIPTION

Net::SH2::SFTP::Perl inherit from Net::SSH::Perl and implement SFTP command.
Net::SFTP already implement SFTP through Net::SSH::Perl but doesn't allow us
to do SSH command, because it is only a SFTP client.

Actually, just the stat and get command are written.

Net::SH2::SFTP::Perl is inspired/based on Net::SFTP.

=head1 TODO

* Rewrite for more flexibility

* Implement the other SFTP fonction

* Write test suite

=head1 AUTHOR

Lucas LAMBOLEY E<lt>lucaslamboley@outlook.comE<gt>

=head1 COPYRIGHT

Copyright 2019 Lucas LAMBOLEY

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::SSH::Perl> L<Net::SFTP>

=cut
