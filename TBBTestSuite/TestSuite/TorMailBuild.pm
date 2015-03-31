package TBBTestSuite::TestSuite::TorMailBuild;

use strict;
use parent 'TBBTestSuite::TestSuite::RBMBuild';

use TBBTestSuite::GitRepo;

sub description {
    'Tor Mail Build';
}

sub type {
    'tor-mail_build';
};

sub set_tests {
    my ($testsuite) = @_;
    $testsuite->{tests} = [
        {
            name  => 'linux-x86_64',
            descr => 'build tor-mail linux-x86_64',
            type  => 'rbm_build',
            project => 'tor-mail',
            targets => [
                'linux-x86_64',
                'tor-mail',
            ],
            publish_dir => 'linux-x86_64',
        },
        {
            name  => 'linux-i686',
            descr => 'build tor-mail linux-i686',
            type  => 'rbm_build',
            project => 'tor-mail',
            targets => [
                'linux-i686',
                'tor-mail',
            ],
            publish_dir => 'linux-i686',
        },
    ];
}

sub pre_tests {
    my ($tbbinfos) = @_;
    my $gr = TBBTestSuite::GitRepo->new({
            name => 'tor-mail',
            git_url => 'https://git.torproject.org/tor-messenger-build.git',
        });
    $gr->clone_fetch;
    $gr->cmd('git', 'checkout', 'master');
    chdir $gr->clone_dir();
    system('make', 'submodule-update');
    system('make', 'fetch');
}

1;
