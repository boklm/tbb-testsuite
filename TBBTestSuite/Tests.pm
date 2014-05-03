package TBBTestSuite::Tests;

use warnings;
use strict;
use English;
use FindBin;
use Cwd qw(getcwd);
use File::Spec;
use File::Temp;
use File::Slurp;
use LWP::UserAgent;
use Digest::SHA qw(sha256_hex);
use IO::CaptureOutput qw(capture_exec);
use JSON;
use File::Copy;
use YAML;
use TBBTestSuite::Common qw(exit_error winpath);
use TBBTestSuite::Options qw($options);
use TBBTestSuite::Tests::VirusTotal qw(virustotal_run);
use TBBTestSuite::Tests::TorBootstrap;

my $screenshot_thumbnail;
BEGIN {
    # For some reason that I did not understand yet, Image::Magick does
    # not work on Windows, so we're not creating thumbnails if we're
    # on Windows. In that case, the thumbnails should be created by the
    # server that receives the results.
    if ($OSNAME ne 'cygwin') {
        require TBBTestSuite::Thumbnail;
        $screenshot_thumbnail = \&TBBTestSuite::Thumbnail::screenshot_thumbnail;
    } else {
        $screenshot_thumbnail = sub { };
    }
}

my %test_types = (
    tor_bootstrap => \&TBBTestSuite::Tests::TorBootstrap::start_tor,
    mozmill       => \&mozmill_run,
    selenium      => \&selenium_run,
    virustotal    => \&virustotal_run,
);

our @tests = (
    {
        name   => 'tor_bootstrap',
        type   => 'tor_bootstrap',
        descr  => 'Check that we can bootstrap tor',
        fatal  => 1,
        always => 1,
    },
    {
        name   => 'virustotal',
        type   => 'virustotal',
        descr  => 'Analyze files on virustotal.com',
    },
    {
        name => 'screenshots',
        type  => 'mozmill',
        descr => 'Take some screenshots',
    },
    {
        name => 'check',
        type  => 'selenium',
        descr => 'Check that http://check.torproject.org/ think we are using tor',
    },
    {
        name  => 'https-everywhere',
        type  => 'mozmill',
        descr => 'Check that https everywhere is enabled and working',
    },
    {
        name  => 'https-everywhere-disabled',
        type  => 'mozmill',
        descr => 'Check that https everywhere is not doing anything when disabled',
        pre   => sub { toggle_https_everywhere(0) },
        post  => sub { toggle_https_everywhere(1) },
    },
    {
        name  => 'settings',
        type  => 'mozmill',
        descr => 'Check that some important settings are correctly set',
    },
);

sub toggle_https_everywhere {
    my ($t) = @_;
    my $prefs = 'Data/Browser/profile.default/extensions/' .
        'https-everywhere@eff.org/defaults/preferences/preferences.js';
    my @f = read_file($prefs);
    foreach (@f) {
        if ($t) {
            s/pref\("extensions\.https_everywhere\.globalEnabled",false\);
             /pref("extensions.https_everywhere.globalEnabled",true);/x;
        } else {
            s/pref\("extensions\.https_everywhere\.globalEnabled",true\);
             /pref("extensions.https_everywhere.globalEnabled",false);/x;
        }
    }
    write_file($prefs, @f);
}

sub list_tests {
    foreach my $test (@tests) {
        print "$test->{name} ($test->{type})\n   $test->{descr}\n\n";
    }
}

sub get_tbbfile {
    my ($tbbinfos) = @_;
    $tbbinfos->{tbbfile_orig} = $tbbinfos->{tbbfile};
    if ($tbbinfos->{tbbfile} =~ m/^https?:\/\//) {
        my (undef, undef, $file) = File::Spec->splitpath($tbbinfos->{tbbfile});
        my $output = $options->{'download-dir'} ?
                "$options->{'download-dir'}/$file" : "$tbbinfos->{tmpdir}/$file";
        return $output if -f $output;
        print "Downloading $tbbinfos->{tbbfile}\n";
        my $ua = LWP::UserAgent->new;
        my $resp = $ua->get($tbbinfos->{tbbfile}, ':content_file' => $output);
        exit_error "Error downloading $tbbinfos->{tbbfile}:\n" . $resp->status_line
                unless $resp->is_success;
        $tbbinfos->{tbbfile} = $output;
    }
    exit_error "File $tbbinfos->{tbbfile} does not exist"
                unless -f $tbbinfos->{tbbfile};
}

sub tbb_filename_infos {
    my ($tbbfile) = @_;
    my (undef, undef, $file) = File::Spec->splitpath($tbbfile);
    my %res = (filename => $file, tbbfile => $tbbfile);
    if ($file =~ m/^tor-browser-linux(..)-([^_]+)_(.+)\.tar\.xz$/) {
        @res{qw(type os version language)} = ('tbbfile', 'Linux', $2, $3);
        $res{arch} = $1 eq '64' ? 'x86_64' : 'x86';
    } elsif ($file =~ m/^torbrowser-install-([^_]+)_(.+)\.exe$/) {
        @res{qw(type os arch version language)} =
                ('tbbfile', 'Windows', 'x86', $1, $2);
    } elsif ($file =~ m/^TorBrowserBundle-(.+)-osx32_(.+)\.zip$/) {
        @res{qw(type os arch version language)} =
                ('tbbfile', 'MacOSX', 'x86', $1, $2);
    } elsif ($file eq 'sha256sums.txt') {
        $res{type} = 'sha256sum';
    } else {
        $res{type} = 'Unknown';
    }
    return \%res;
}

sub extract_tbb {
    my ($tbbinfos) = @_;
    exit_error "Can't open file $tbbinfos->{tbbfile}" unless -f $tbbinfos->{tbbfile};
    my $tbbfile = File::Spec->rel2abs($tbbinfos->{tbbfile});
    my $tmpdir = $tbbinfos->{tmpdir};
    chdir $tmpdir;
    if ($tbbinfos->{os} eq 'Linux') {
        system('tar', 'xf', $tbbfile);
        $tbbinfos->{tbbdir} = "$tmpdir/tor-browser_$tbbinfos->{language}";
    } elsif ($tbbinfos->{os} eq 'Windows') {
        my (undef, undef, $f) = File::Spec->splitpath($tbbfile);
        copy($tbbfile, "$tmpdir/$f");
        system('7z', 'x', $f);
        $tbbinfos->{tbbdir} = "$tmpdir/torbrowser";
        move("$tmpdir/\$_OUTDIR", "$tmpdir/torbrowser");
        move ("$tmpdir/Start Tor Browser.exe", "$tmpdir/torbrowser/");
    }
}

sub xvfb_run {
    my ($test) = @_;
    return () unless $options->{xvfb};
    my $resolution = $test->{resolution} ? $test->{resolution}
                                         : $options->{resolution};
    return ('xvfb-run', '--auto-servernum', '-s', "-screen 0 ${resolution}x24");
}

sub mozmill_cmd {
    if ($OSNAME eq 'cygwin') {
        return ( "$options->{'mozmill-dir'}\\run.cmd", 'mozmill' );
    }
    return ("$options->{virtualenv}/bin/mozmill");
}

sub ffbin_path {
    my ($tbbinfos) = @_;
    if ($OSNAME eq 'cygwin') {
        return winpath("$tbbinfos->{tbbdir}/Browser/firefox.exe");
    }
    return "$tbbinfos->{tbbdir}/Browser/firefox";
}

sub mozmill_run {
    my ($tbbinfos, $test) = @_;
    return unless $options->{mozmill};
    $test->{screenshots} = [];
    my $screenshots_tmp = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
    $ENV{'MOZMILL_SCREENSHOTS'} = winpath($screenshots_tmp);
    my $results_file = "$tbbinfos->{'results-dir'}/$test->{name}.json";
    system(xvfb_run($test), mozmill_cmd(), '-b', ffbin_path($tbbinfos),
        '-p', winpath("$tbbinfos->{tbbdir}/Data/Browser/profile.default"),
        '-t', winpath("$FindBin::Bin/mozmill-tests/tbb-tests/$test->{name}.js"),
        '--report', 'file://' . winpath($results_file));
    my $i = 0;
    for my $screenshot_file (reverse sort glob "$screenshots_tmp/*.png") {
        move($screenshot_file, "$tbbinfos->{'results-dir'}/$test->{name}-$i.png");
        $screenshot_thumbnail->($tbbinfos->{'results-dir'}, "$test->{name}-$i.png");
        push @{$test->{screenshots}}, "$test->{name}-$i.png";
        $i++;
    }
    $test->{results} = decode_json(read_file($results_file));
    $test->{results}{success} = !$test->{results}{results}->[0]->{failed};
}

sub selenium_run {
    my ($tbbinfos, $test) = @_;
    return unless $options->{selenium};
    my $result_file = $ENV{SELENIUM_TEST_RESULT_FILE} =
        "$tbbinfos->{'results-dir'}/$test->{name}.json";
    system(xvfb_run($test), "$options->{virtualenv}/bin/python",
        "$FindBin::Bin/selenium-tests/run_test", $test->{name});
    $test->{results} = decode_json(read_file($result_file));
}

sub run_tests {
    my ($tbbinfos) = @_;
    my @enable_tests = $options->{'enable-tests'}
                ? split(',', $options->{'enable-tests'}) : ();
    foreach my $test (@{$tbbinfos->{tests}}) {
        if (@enable_tests && !$test->{always}
            && ! grep { $test->{name} eq $_ } @enable_tests) {
            next;
        }
        $test->{pre}->($test) if $test->{pre};
        $test_types{$test->{type}}->($tbbinfos, $test)
                if $test_types{$test->{type}};
        $test->{post}->($test) if $test->{post};
        if ($test->{fatal} && $test->{results} &&
            !$test->{results}{success}) {
            last;
        }
    }
}

sub is_success {
    my ($tests) = @_;
    foreach my $test (@$tests) {
        if ($test->{results} && !$test->{results}{success}) {
            return 0;
        }
    }
    return 1;
}

sub matching_tbbfile {
    my $o = tbb_filename_infos($_[0]);
    return $o->{type} eq 'tbbfile' && $o->{os} eq $options->{os}
        && $o->{arch} eq $options->{arch};
}

sub check_gpgsig {
    my ($file) = @_;
    my $keyring = $options->{keyring} =~ m/^\// ? $options->{keyring}
        : "$FindBin::Bin/keyring/$options->{keyring}";
    return system('gpg', '--no-default-keyring', '--keyring', $keyring,
        '--verify', '--', $file) == 0;
}

sub test_sha {
    my ($report, $shafile) = @_;
    my $content;
    if ($shafile =~ m/^https?:\/\//) {
        my $ua = LWP::UserAgent->new;
        my $resp = $ua->get($shafile);
        exit_error "Error downloading $shafile:\n" . $resp->status_line
                unless $resp->is_success;
        $content = $resp->decoded_content;
        if ($options->{gpgcheck}) {
            $resp = $ua->get("$shafile.asc");
            exit_error "Error downloading $shafile.asc:\n" . $resp->status_line
                unless $resp->is_success;
            my $tmpdir = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
            write_file("$tmpdir/sha256sum.txt", $content);
            write_file("$tmpdir/sha256sum.txt.asc", $resp->decoded_content);
            exit_error "Error checking gpg signature of $shafile"
                unless check_gpgsig("$tmpdir/sha256sum.txt.asc");
        }
    } else {
        $content = read_file($shafile);
    }
    my (undef, $dir) = File::Spec->splitpath($shafile);
    my @files = map { [ reverse split /  /, $_ ] } split /\n/, $content;
    @files = grep { matching_tbbfile($_->[0]) } @files;
    foreach my $file (@files) {
        test_tbb($report, "$dir/$file->[0]", $file->[1]);
    }
}

sub test_tbb {
    my ($report, $tbbfile, $sha256sum) = @_;
    my $oldcwd = getcwd;
    my $tbbinfos = tbb_filename_infos($tbbfile);
    return test_sha($report, $tbbfile) if $tbbinfos->{type} eq 'sha256sum';
    my $tmpdir = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
    $tbbinfos->{tmpdir} = $tmpdir->dirname;
    get_tbbfile($tbbinfos);
    if ($sha256sum && $sha256sum ne sha256_hex(read_file($tbbinfos->{tbbfile}))) {
        exit_error "Wrong sha256sum for $tbbinfos->{tbbfile}";
    }
    $tbbinfos->{sha256sum} = $sha256sum ? $sha256sum
                                : sha256_hex(read_file($tbbinfos->{tbbfile}));
    $tbbinfos->{tests} = [ map { { %$_ } } @tests ];
    $tbbinfos->{'results-dir'} =
        "$options->{'report-dir'}/results-$tbbinfos->{filename}";
    mkdir $tbbinfos->{'results-dir'};
    extract_tbb($tbbinfos);
    chdir $tbbinfos->{tbbdir} || exit_error "Can't enter directory $tbbinfos->{tbbdir}";
    $ENV{TBB_BIN} = "$tbbinfos->{tbbdir}/Browser/firefox";
    $ENV{TBB_PROFILE} = "$tbbinfos->{tbbdir}/Data/Browser/profile.default";
    $ENV{TOR_SKIP_LAUNCH} = 1;
    run_tests($tbbinfos);
    TBBTestSuite::Tests::TorBootstrap::stop_tor($tbbinfos);
    chdir $oldcwd;
    $tbbinfos->{success} = is_success($tbbinfos->{tests});
    $report->{tbbfiles}{$tbbinfos->{filename}} = $tbbinfos;
}

1;
