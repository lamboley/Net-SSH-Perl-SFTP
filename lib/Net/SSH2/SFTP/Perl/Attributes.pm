package Net::SSH2::SFTP::Perl::Attributes;

use strict;
use warnings;

use Net::SSH2::SFTP::Perl::Buffer;

our @FIELDS = qw[flags size uid gid perm atime mtime];

for my $f (@FIELDS) {
    no strict 'refs';
    *$f = sub { shift->{$f} };
}

sub new {
    my $class = shift;
    my $a = bless { }, $class;
    $a->init(@_);
}

sub init {
    my ($a, %param) = @_;
    $a->{$_} = 0 for (@FIELDS);
    
    if (my $buf = $param{Buffer}) {
        $a->{flags} = $buf->get_int32;
        
        if ($a->{flags} & 0x01) {
            $a->{size} = $buf->get_int64;
        }
        if ($a->{flags} & 0x02) {
            $a->{uid} = $buf->get_int32;
            $a->{gid} = $buf->get_int32;
        }
        if ($a->{flags} & 0x04) {
            $a->{perm} = $buf->get_int32;
        }
        if ($a->{flags} & 0x08) {
            $a->{atime} = $buf->get_int32;
            $a->{mtime} = $buf->get_int32;
        }
        if ($a->{flags} & 0x80000000) {
            my $extended_count = $buf->get_int32;
            for (1..$extended_count) {
                my $name = $buf->get_str;
                my $value = $buf->get_str;
                $a->{$name} = $value;
            }
        }
    }
    $a;
}

sub as_buffer {
    my $a = shift;
    my $buf = Net::SSH2::SFTP::Perl::Buffer->new;
    $buf->put_int32($a->{flags});
    if ($a->{flags} & 0x01) {
        $buf->put_int64(int $a->{size});
    }
    if ($a->{flags} & 0x02) {
        $buf->put_int32($a->{uid});
        $buf->put_int32($a->{gid});
    }
    if ($a->{flags} & 0x04) {
        $buf->put_int32($a->{perm});
    }
    if ($a->{flags} & 0x08) {
        $buf->put_int32($a->{atime});
        $buf->put_int32($a->{mtime});
    }
    $buf;
}

1;
