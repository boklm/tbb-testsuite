package TBBTestSuite::Tests;

use warnings;
use strict;
use English;
use FindBin;
use Cwd qw(getcwd);
use File::Type;
use File::Find;
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
    command       => \&command_run,
);

our @tests = (
    {
        name         => 'readelf_RELRO',
        type         => 'command',
        descr        => 'Check if binaries are RELocation Read-Only',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-ld' ],
        check_output => sub { ( $_[0] =~ m/GNU_RELRO/ )
                                && ( $_[0] =~ m/\(BIND_NOW\)/ ) },
        enable       => sub { $options->{os} eq 'Linux' },
    },
    {
        name         => 'readelf_stack_canary',
        type         => 'command',
        descr        => 'Check for stack canary support',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-s' ],
        check_output => sub { $_[0] =~ m/__stack_chk_fail/ },
        enable       => sub { $options->{os} eq 'Linux' },
    },
    {
        name         => 'readelf_NX',
        type         => 'command',
        descr        => 'Check for NX support',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-W', '-l' ],
        check_output => sub { ! ($_[0] =~ m/GNU_STACK.+RWE/) },
        enable       => sub { $options->{os} eq 'Linux' },
    },
    {
        name         => 'readelf_PIE',
        type         => 'command',
        descr        => 'Check for PIE support',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-h' ],
        check_output => sub { $_[0] =~ m/Type:\s+DYN/ },
        enable       => sub { $options->{os} eq 'Linux' },
    },
    {
        name         => 'readelf_no_rpath',
        type         => 'command',
        descr        => 'Check for no rpath',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-d' ],
        check_output => sub { ! ( $_[0] =~ m/RPATH/ ) },
        enable       => sub { $options->{os} eq 'Linux' },
    },
    {
        name         => 'readelf_no_runpath',
        type         => 'command',
        descr        => 'Check for no runpath',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-d' ],
        check_output => sub { ! ( $_[0] =~ m/runpath/ ) },
        enable       => sub { $options->{os} eq 'Linux' },
    },
    {
        name      => 'tor_httpproxy',
        type      => 'tor_bootstrap',
        descr     => 'Access tor using an http proxy',
        httpproxy => 1,
    },
    {
        name   => 'tor_bridge',
        type   => 'tor_bootstrap',
        descr  => 'Access tor using a bridge',
    },
    {
        name      => 'tor_bridge_httpproxy',
        type      => 'tor_bootstrap',
        descr     => 'Access tor using a bridge and an http proxy',
        httpproxy => 1,
    },
    {
        name   => 'tor_obfs3',
        type   => 'tor_bootstrap',
        descr  => 'Access tor using obfs3',
    },
    {
        name      => 'tor_obfs3_httpproxy',
        type      => 'tor_bootstrap',
        descr     => 'Access tor using obfs3 and an http proxy',
        httpproxy => 1,
    },
    {
        name   => 'tor_fte',
        type   => 'tor_bootstrap',
        descr  => 'Access tor using fteproxy',
    },
    {
        name      => 'tor_fte_httpproxy',
        type      => 'tor_bootstrap',
        descr     => 'Access tor using fteproxy and an http proxy',
        httpproxy => 1,
    },
    {
        name   => 'tor_bootstrap',
        type   => 'tor_bootstrap',
        descr  => 'Check that we can bootstrap tor',
        fatal  => 1,
        always => 1,
        use_default_config => 1,
        no_kill => 1,
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
        {
        name => 'fp_screen_dimensions',
        type  => 'selenium',
        descr => 'Check that screen dimensions are spoofed correctly',
    },
    {
        name => 'fp_screen_coords',
        type  => 'selenium',
        descr => 'Check that screenX, screenY, screenLeft, screenTop, mozInnerScreenX, mozInnerScreenY are 0',
    },
    {
        name => 'fp_plugins',
        type  => 'selenium',
        descr => 'Check that plugins are disabled',
    },
    {
        name => 'fp_useragent',
        type  => 'selenium',
        descr => 'Check that userAgent is as expected',
    },        {
        name => 'fp_navigator',
        type  => 'selenium',
        descr => 'Check that navigator properties are as expected',
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

sub tbb_binfiles {
    my ($tbbinfos, $test) = @_;
    return $tbbinfos->{binfiles} if $tbbinfos->{binfiles};
    my %binfiles = (
        "$tbbinfos->{tbbdir}/Browser/firefox" => 1,
        "$tbbinfos->{tbbdir}/Tor/tor" => 1,
    );
    my $wanted = sub {
        return unless -f $File::Find::name;
        return unless -x $File::Find::name;
        my $type = File::Type->new->checktype_filename($File::Find::name);
        return unless $type eq 'application/x-executable-file';
        $binfiles{$File::Find::name} = 1;
    };
    find($wanted, $tbbinfos->{tbbdir});
    return $tbbinfos->{binfiles} = [ keys %binfiles ];
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

sub check_opened_connections {
    my ($tbbinfos, $test) = @_;
    my $mbox_log = "$tbbinfos->{'results-dir'}/$test->{name}.mbox.log";
    $test->{results}{connections} = {};
    foreach my $line (read_file($mbox_log)) {
        next unless $line =~ m/ > \[\d+\] -> (.+)/;
        $test->{results}{connections}{$1}++;
    }
}

sub ff_mbox_wrapper {
    my ($tbbinfos, $test) = @_;
    mkdir "$tbbinfos->{'results-dir'}/$test->{name}.sandbox";
    my $wrapper = <<EOF;
#!/bin/sh
set -e
echo log file: $tbbinfos->{'results-dir'}/$test->{name}.mbox.log
exec mbox -i -r \'$tbbinfos->{'results-dir'}/$test->{name}.sandbox\' \\
        -o \'$tbbinfos->{'results-dir'}/$test->{name}.mbox.log\' \\
        -s -p $FindBin::Bin/mbox.profile \\
        -- \\
        \'$tbbinfos->{tbbdir}/Browser/firefox\' "\$@"
EOF
    my $wrapper_file = "$tbbinfos->{tbbdir}/ff_$test->{name}";
    write_file($wrapper_file, $wrapper);
    chmod 0700, $wrapper_file;
    return $wrapper_file;
}

sub ffbin_path {
    my ($tbbinfos, $test) = @_;
    if ($OSNAME eq 'cygwin') {
        return winpath("$tbbinfos->{tbbdir}/Browser/firefox.exe");
    }
    return $options->{mbox} ? ff_mbox_wrapper($tbbinfos, $test)
           : "$tbbinfos->{tbbdir}/Browser/firefox";
}

sub mozmill_run {
    my ($tbbinfos, $test) = @_;
    return unless $options->{mozmill};
    $test->{screenshots} = [];
    my $screenshots_tmp = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
    $ENV{'MOZMILL_SCREENSHOTS'} = winpath($screenshots_tmp);
    my $results_file = "$tbbinfos->{'results-dir'}/$test->{name}.json";
    system(xvfb_run($test), mozmill_cmd(), '-b', ffbin_path($tbbinfos, $test),
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
    check_opened_connections($tbbinfos, $test);
    $test->{results}{success} = !$test->{results}{results}->[0]->{failed};
}

sub selenium_run {
    my ($tbbinfos, $test) = @_;
    return unless $options->{selenium};
    my $result_file = $ENV{SELENIUM_TEST_RESULT_FILE} =
        "$tbbinfos->{'results-dir'}/$test->{name}.json";
    $ENV{TBB_BIN} = "$tbbinfos->{tbbdir}/Browser/firefox";
    $ENV{TBB_PROFILE} = "$tbbinfos->{tbbdir}/Data/Browser/profile.default";
    system(xvfb_run($test), "$options->{virtualenv}/bin/python",
        "$FindBin::Bin/selenium-tests/run_test", $test->{name});
    $test->{results} = decode_json(read_file($result_file));
}

sub command_run {
    my ($tbbinfos, $test) = @_;
    $test->{results}{success} = 1;
    my $files = $test->{files};
    $files = $files->($tbbinfos, $test) if ref $files eq 'CODE';
    for my $file (@$files) {
        my ($out, $err, $success) = capture_exec(@{$test->{command}}, $file);
        if ($success && $test->{check_output}) {
            $success = $test->{check_output}($out);
        }
        if (!$success) {
            $test->{results}{success} = 0;
            $file =~ s/^$tbbinfos->{tbbdir}\///;
            push @{$test->{results}{failed}}, $file;
            next;
        }
    }
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
        if ($test->{enable} && !$test->{enable}->($tbbinfos, $test)) {
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
    $ENV{TOR_SKIP_LAUNCH} = 1;
    run_tests($tbbinfos);
    TBBTestSuite::Tests::TorBootstrap::stop_tor($tbbinfos);
    chdir $oldcwd;
    $tbbinfos->{success} = is_success($tbbinfos->{tests});
    $report->{tbbfiles}{$tbbinfos->{filename}} = $tbbinfos;
}

1;
