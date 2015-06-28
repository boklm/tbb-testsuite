package TBBTestSuite::TestSuite::TorMessengerBuild;

use strict;
use parent 'TBBTestSuite::TestSuite::RBMBuild';

use TBBTestSuite::GitRepo;

sub description {
    'Tor Messenger Build';
}

sub type {
    'tor-messenger_build';
};

sub set_tests {
    my ($testsuite) = @_;
    $testsuite->{tests} = [
        {
            name  => 'linux-x86_64',
            descr => 'build tor-messenger linux-x86_64',
            type  => 'rbm_build',
            project => 'tor-messenger',
            targets => [
                'noint',
                'linux-x86_64',
                'tor-messenger',
            ],
            publish_dir => 'linux-x86_64',
        },
        {
            name  => 'linux-i686',
            descr => 'build tor-messenger linux-i686',
            type  => 'rbm_build',
            project => 'tor-messenger',
            targets => [
                'noint',
                'linux-i686',
                'tor-messenger',
            ],
            publish_dir => 'linux-i686',
        },
        {
            name  => 'windows-i686',
            descr => 'build tor-messenger windows-i686',
            type  => 'rbm_build',
            project => 'tor-messenger',
            targets => [
                'noint',
                'windows-i686',
                'tor-messenger',
            ],
            publish_dir => 'windows-i686',
        },
        {
            name  => 'osx-x86_64',
            descr => 'build tor-messenger osx-x86_64',
            type  => 'rbm_build',
            project => 'tor-messenger',
            targets => [
                'noint',
                'osx-x86_64',
                'tor-messenger',
            ],
            publish_dir => 'osx-x86_64',
        },
    ];
}

sub pre_tests {
    my ($tbbinfos) = @_;
    my $gr = TBBTestSuite::GitRepo->new({
            name => 'tor-messenger',
            git_url => 'https://git.torproject.org/tor-messenger-build.git',
        });
    $gr->clone_fetch;
    $gr->cmd('git', 'checkout', 'master');
    chdir $gr->clone_dir();
    system('make', 'submodule-update');
    system('make', 'fetch');
}

1;
