## NAME

Net::SSH::Perl::SFTP - Add support of SFTP for Net::SSH::Perl

## SYNOPSIS

    my $ssh = Net::SSH::Perl::SFTP->new($host, $user, $password);

    my ($out, $err, $ex) = $ssh->cmd('id');

    $ssh->get('/home/lamboley/toto', 'C:\toto');

    ($out, $err, $ex) = $ssh->cmd('ls');

    if (my $a = $ssh->stat('/home/lamboley/toto2')) {
        $ssh->get('/home/lamboley/toto2', 'C:\toto2', $a);
    }

## DESCRIPTION

Net::SSH::Perl::SFTP inherit from Net::SSH::Perl and implement SFTP command. Net::SFTP already implement SFTP through Net::SSH::Perl but doesn't allow us to do SSH command, because it is only a SFTP client.

Actually, just the stat and get command are written.

Net::SSH::Perl::SFTP is inspired/based on Net::SFTP.


## AUTHOR

Lucas LAMBOLEY <lucaslamboley@outlook.com>

## COPYRIGHT

Copyright 2019 Lucas LAMBOLEY

## LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## SEE ALSO

[Net::SSH::Perl](https://metacpan.org/pod/Net::SSH::Perl) [Net::SFTP](https://metacpan.org/pod/Net::SFTP)
