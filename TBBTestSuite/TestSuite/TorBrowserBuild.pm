package TBBTestSuite::TestSuite::TorBrowserBuild;

use strict;
use parent 'TBBTestSuite::TestSuite::RBMBuild';

use TBBTestSuite::GitRepo;

sub description {
    'Tor Browser Build';
}

sub type {
    'tor-browser_build';
};

sub set_tests {
    my ($testsuite) = @_;
    $testsuite->{tests} = [
        # Nightly
        {
            name  => 'nightly-linux-x86_64',
            descr => 'build tor-browser nightly linux-x86_64',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'nightly',
                'torbrowser-linux-x86_64',
                'noversiondir',
            ],
            publish_dir => 'nightly-linux-x86_64',
        },
        {
            name  => 'nightly-linux-i686',
            descr => 'build tor-browser nightly linux-i686',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'nightly',
                'torbrowser-linux-i686',
                'noversiondir',
            ],
            publish_dir => 'nightly-linux-i686',
        },
        {
            name  => 'nightly-windows-i686',
            descr => 'build tor-browser nightly windows-i686',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'nightly',
                'torbrowser-windows-i686',
                'noversiondir',
            ],
            publish_dir => 'nightly-windows-i686',
        },
        {
            name  => 'nightly-osx-x86_64',
            descr => 'build tor-browser nightly osx-x86_64',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'nightly',
                'torbrowser-osx-x86_64',
                'noversiondir',
            ],
            publish_dir => 'nightly-osx-x86_64',
        },

        # Alpha
        {
            name  => 'alpha-linux-x86_64',
            descr => 'build tor-browser alpha linux-x86_64',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'alpha',
                'torbrowser-linux-x86_64',
                'noversiondir',
            ],
            publish_dir => 'alpha-linux-x86_64',
        },
        {
            name  => 'alpha-linux-i686',
            descr => 'build tor-browser alpha linux-i686',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'alpha',
                'torbrowser-linux-i686',
                'noversiondir',
            ],
            publish_dir => 'alpha-linux-i686',
        },
        {
            name  => 'alpha-windows-i686',
            descr => 'build tor-browser alpha windows-i686',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'alpha',
                'torbrowser-windows-i686',
                'noversiondir',
            ],
            publish_dir => 'alpha-windows-i686',
        },
        {
            name  => 'alpha-osx-x86_64',
            descr => 'build tor-browser alpha osx-x86_64',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'alpha',
                'torbrowser-osx-x86_64',
                'noversiondir',
            ],
            publish_dir => 'alpha-osx-x86_64',
        },

        # Hardened
        {
            name  => 'hardened-linux-x86_64',
            descr => 'build tor-browser hardened linux-x86_64',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'hardened',
                'torbrowser-linux-x86_64',
                'noversiondir',
            ],
            publish_dir => 'hardened-linux-x86_64',
        },
    ];
}

sub pre_tests {
    my ($tbbinfos) = @_;
    my $gr = TBBTestSuite::GitRepo->new({
            name => 'tor-browser-build',
            git_url => 'https://git.torproject.org/user/boklm/tor-browser-build.git',
        });
    $gr->clone_fetch;
    $gr->cmd('git', 'checkout', 'dev');
    chdir $gr->clone_dir();
    system('make', 'submodule-update');
    system('make', 'fetch');
}

1;
