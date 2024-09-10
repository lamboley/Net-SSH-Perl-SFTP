use 5.028001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::SSH::Perl::SFTP',
    VERSION_FROM      => 'lib/Net/SSH/Perl/SFTP.pm',
    PREREQ_PM         => { 'Net::SSH::Perl' => 2.142 },
    test              => { TESTS => "t/*.t"},
    ABSTRACT          => 'Add support of SFTP for Net::SSH::Perl',
    AUTHOR            => 'Lucas LAMBOLEY <lucaslamboley@outlook.com>',
    LICENSE           => 'perl',
);
