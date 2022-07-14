package TBBTestSuite::TestSuite::TorBrowserBuild;

use strict;
use parent 'TBBTestSuite::TestSuite::RBMBuild';

use TBBTestSuite::Common qw(run_to_file);
use TBBTestSuite::GitRepo;
use File::Copy;
use IO::CaptureOutput qw(capture_exec);
use Path::Tiny;

sub description {
    'Tor Browser Build';
}

sub type {
    'tor-browser_build';
};

sub test_types {
    my $self = shift;
    my $res = $self->SUPER::test_types();
    $res->{make_incrementals} = \&make_incrementals;
    return $res;
}

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
                'browser-linux-x86_64',
                'torbrowser',
            ],
            publish_dir => 'nightly-linux-x86_64',
        },
        {
            name  => 'incrementals-nightly-linux-x86_64',
            descr => 'create incrementals for tor-browser nightly linux-x86_64',
            type  => 'make_incrementals',
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
                'browser-linux-i686',
                'torbrowser',
            ],
            publish_dir => 'nightly-linux-i686',
        },
        {
            name  => 'incrementals-nightly-linux-i686',
            descr => 'create incrementals for tor-browser nightly linux-i686',
            type  => 'make_incrementals',
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
                'browser-windows-i686',
                'torbrowser',
            ],
            publish_dir => 'nightly-windows-i686',
        },
        {
            name  => 'incrementals-nightly-windows-i686',
            descr => 'create incrementals for tor-browser nightly windows-i686',
            type  => 'make_incrementals',
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
                'browser-windows-x86_64',
                'torbrowser',
            ],
            publish_dir => 'nightly-windows-x86_64',
        },
        {
            name  => 'incrementals-nightly-windows-x86_64',
            descr => 'create incrementals for tor-browser nightly windows-x86_64',
            type  => 'make_incrementals',
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
                'browser-osx-x86_64',
                'torbrowser',
            ],
            publish_dir => 'nightly-osx-x86_64',
        },
        {
            name  => 'incrementals-nightly-osx-x86_64',
            descr => 'create incrementals for tor-browser nightly osx-x86_64',
            type  => 'make_incrementals',
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
                'browser-android-armv7',
                'torbrowser',
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
                'browser-android-x86',
                'torbrowser',
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
                'browser-android-x86_64',
                'torbrowser',
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
                'browser-android-aarch64',
                'torbrowser',
            ],
            publish_dir => 'nightly-android-aarch64',
        },
    ];
}

sub make_incrementals {
    my ($testsuite, $test) = @_;
    $test->{results}{success} = 0;
    mkdir 'nightly' unless -d 'nightly';
    # Clean the nightly directory
    foreach my $subdir (path('nightly')->children) {
        unlink $subdir if -l $subdir;
    }
    foreach my $builddir (path($testsuite->{publish_dir} . '/..')->children) {
        if (-f "$builddir/$test->{publish_dir}/sha256sums-unsigned-build.txt") {
            symlink("$builddir/$test->{publish_dir}", 'nightly/' . $builddir->basename);
        }
    }
    my @cmd = ('make', 'incrementals-nightly');
    run_to_file("$testsuite->{'results-dir'}/$test->{name}.build.txt", @cmd)
        or return;
    $test->{results}{success} = 1;
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
    if ($tbbinfos->{tbb_version}) {
        $ENV{TORBROWSER_NIGHTLY_VERSION} = $tbbinfos->{tbb_version};
    }
}

1;
