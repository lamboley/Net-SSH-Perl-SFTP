use 5.028001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::SSH2::SFTP::Perl',
    VERSION_FROM      => 'lib/Net/SSH2/SFTP/Perl.pm',
    PREREQ_PM         => { 'Net::SSH::Perl' => 2.14 },
    test              => { TESTS => "t/*.t"},
    ABSTRACT          => 'Add support of SFTP for Net::SSH::Perl',
    AUTHOR            => 'Lucas LAMBOLEY <lucaslamboley@outlook.com>',
    LICENSE           => 'perl',
);
