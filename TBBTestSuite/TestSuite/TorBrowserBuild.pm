package TBBTestSuite::TestSuite::TorBrowserBuild;

use strict;
use parent 'TBBTestSuite::TestSuite::RBMBuild';

use TBBTestSuite::GitRepo;
use File::Copy;
use IO::CaptureOutput qw(capture_exec);

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
                'noversiondir',
                'nightly',
                'torbrowser-linux-x86_64',
            ],
            publish_dir => 'nightly-linux-x86_64',
        },
        {
            name  => 'nightly-linux-i686',
            descr => 'build tor-browser nightly linux-i686',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'noversiondir',
                'nightly',
                'torbrowser-linux-i686',
            ],
            publish_dir => 'nightly-linux-i686',
        },
        {
            name  => 'nightly-windows-i686',
            descr => 'build tor-browser nightly windows-i686',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'noversiondir',
                'nightly',
                'torbrowser-windows-i686',
            ],
            publish_dir => 'nightly-windows-i686',
        },
        {
            name  => 'nightly-windows-x86_64',
            descr => 'build tor-browser nightly windows-x86_64',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'noversiondir',
                'nightly',
                'torbrowser-windows-x86_64',
            ],
            publish_dir => 'nightly-windows-x86_64',
        },
        {
            name  => 'nightly-osx-x86_64',
            descr => 'build tor-browser nightly osx-x86_64',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'noversiondir',
                'nightly',
                'torbrowser-osx-x86_64',
            ],
            publish_dir => 'nightly-osx-x86_64',
        },
        {
            name  => 'nightly-android-armv7',
            descr => 'build tor-browser nightly android-armv7',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'noversiondir',
                'nightly',
                'torbrowser-android-armv7',
            ],
            publish_dir => 'nightly-android-armv7',
        },
        {
            name  => 'nightly-android-x86',
            descr => 'build tor-browser nightly android-x86',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'noversiondir',
                'nightly',
                'torbrowser-android-x86',
            ],
            publish_dir => 'nightly-android-x86',
        },
        {
            name  => 'nightly-android-x86_64',
            descr => 'build tor-browser nightly android-x86_64',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'noversiondir',
                'nightly',
                'torbrowser-android-x86_64',
            ],
            publish_dir => 'nightly-android-x86_64',
        },
        {
            name  => 'nightly-android-aarch64',
            descr => 'build tor-browser nightly android-aarch64',
            type  => 'rbm_build',
            project => 'release',
            targets => [
                'noversiondir',
                'nightly',
                'torbrowser-android-aarch64',
            ],
            publish_dir => 'nightly-android-aarch64',
        },
    ];
}

sub pre_tests {
    my ($tbbinfos) = @_;
    my $gr = TBBTestSuite::GitRepo->new({
            name => 'tor-browser-build',
            git_url => 'https://git.torproject.org/builders/tor-browser-build.git',
        });
    $gr->clone_fetch;
    $gr->cmd('git', 'checkout', 'master');
    chdir $gr->clone_dir();
    copy($tbbinfos->{rbm_local_conf}, $gr->clone_dir() . '/rbm.local.conf')
            if $tbbinfos->{rbm_local_conf};
    my @clean = ('clean') if $tbbinfos->{make_clean};
    foreach my $cmd (('submodule-update', 'fetch', @clean)) {
        my ($out, $err, $success) = capture_exec('make', $cmd);
        if (!$success) {
            $tbbinfos->{pre_tests_error} = "Error running make $cmd:\n$out\n$err";
            return;
        }
    }
}

1;
