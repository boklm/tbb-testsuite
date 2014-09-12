package TBBTestSuite::BrowserBundleTests;

use warnings;
use strict;
use English;
use FindBin;
use File::Slurp;
use File::Spec;
use File::Find;
use File::Type;
use File::Copy;
use JSON;
use Digest::SHA qw(sha256_hex);
use LWP::UserAgent;
use TBBTestSuite::Common qw(exit_error winpath);
use TBBTestSuite::Options qw($options);
use TBBTestSuite::Tests::VirusTotal qw(virustotal_run);
use TBBTestSuite::Tests::Command qw(command_run);
use TBBTestSuite::Tests::TorBootstrap;
use TBBTestSuite::XServer qw(start_X stop_X set_Xmode);

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(tbb_filename_infos);
}

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

my $test_types = {
    tor_bootstrap => \&TBBTestSuite::Tests::TorBootstrap::start_tor,
    mozmill       => \&mozmill_run,
    selenium      => \&selenium_run,
    virustotal    => \&virustotal_run,
    command       => \&command_run,
};

our %testsuite = (
    description => 'Tor Browser Bundle integration tests',
    test_types  => $test_types,
    pre_tests   => \&pre_tests,
    post_tests  => \&post_tests,
);

our @tests = (
    {
        name         => 'readelf_RELRO',
        fail_type    => 'warning',
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
        fail_type    => 'warning',
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
        fail_type    => 'warning',
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
        fail_type => 'fatal',
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
        pre   => sub { toggle_https_everywhere($_[0], 0) },
        post  => sub { toggle_https_everywhere($_[0], 1) },
    },
    {
        name  => 'settings',
        type  => 'mozmill',
        descr => 'Check that some important settings are correctly set',
    },
    {
        name  => 'dom-objects-enumeration',
        type  => 'mozmill',
        descr => 'Check the list of DOM Objects exposed in the global namespace',
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
    my ($tbbinfos, $t) = @_;
    my $prefs = $tbbinfos->{ffprofiledir} . '/extensions/'
        . 'https-everywhere@eff.org/defaults/preferences/preferences.js';
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
        $tbbinfos->{ffbin} => 1,
        "$tbbinfos->{tordir}/tor" => 1,
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
        @res{qw(type os version language)} = ('browserbundle', 'Linux', $2, $3);
        $res{arch} = $1 eq '64' ? 'x86_64' : 'x86';
    } elsif ($file =~ m/^torbrowser-install-([^_]+)_(.+)\.exe$/) {
        @res{qw(type os arch version language)} =
                ('browserbundle', 'Windows', 'x86', $1, $2);
    } elsif ($file =~ m/^TorBrowserBundle-(.+)-osx32_(.+)\.zip$/) {
        @res{qw(type os arch version language)} =
                ('browserbundle', 'MacOSX', 'x86', $1, $2);
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
        $tbbinfos->{tbbdir} .= '/Browser' if $options->{newlayout};
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
    return unless $options->{mbox};
    my $mbox_log = "$tbbinfos->{'results-dir'}/$test->{name}.mbox.log";
    $test->{results}{connections} = {};
    foreach my $line (read_file($mbox_log)) {
        next unless $line =~ m/ > \[\d+\] -> (.+)/;
        $test->{results}{connections}{$1}++;
    }
}

sub check_modified_files {
    my ($tbbinfos, $test) = @_;
    return unless $options->{mbox};
    my $sandbox_dir = "$tbbinfos->{'results-dir'}/$test->{name}.sandbox";
    return unless -d $sandbox_dir;
    my $add_modified_file = sub {
        return if -d $File::Find::name;
        my $fname = $File::Find::name;
        $fname =~ s{^\Q$sandbox_dir\E}{};
        $fname =~ s{^\Q$tbbinfos->{tbbdir}\E/}{};
        push @{$test->{results}{modified_files}}, $fname;
    };
    find($add_modified_file, $sandbox_dir);
    foreach my $meta (read_file("$sandbox_dir.meta")) {
        if ($meta =~ m/^D:(.*):1$/) {
            my $fname = $1;
            $fname =~ s{^\Q$tbbinfos->{tbbdir}\E/}{};
            push @{$test->{results}{removed_files}}, $fname;
        }
    }
}

sub ff_wrapper {
    my ($tbbinfos, $test) = @_;
    my $wrapper_file = "$tbbinfos->{tbbdir}/ff_wrapper";
    return $wrapper_file if -f $wrapper_file;
    my $wrapper = <<EOF;
#!/bin/sh
set -e
export LD_LIBRARY_PATH="$tbbinfos->{tordir}"
exec \'$tbbinfos->{ffbin}\' "\$@"
EOF
    write_file($wrapper_file, $wrapper);
    chmod 0700, $wrapper_file;
    return $wrapper_file;
}

sub ff_mbox_wrapper {
    my ($tbbinfos, $test) = @_;
    mkdir "$tbbinfos->{'results-dir'}/$test->{name}.sandbox";
    my $ff_wrapper = ff_wrapper($tbbinfos, $test);
    my $wrapper = <<EOF;
#!/bin/sh
set -e
echo log file: $tbbinfos->{'results-dir'}/$test->{name}.mbox.log
exec mbox -i -r \'$tbbinfos->{'results-dir'}/$test->{name}.sandbox\' \\
        -o \'!cat >> $tbbinfos->{'results-dir'}/$test->{name}.mbox.log\' \\
        -s -p $FindBin::Bin/mbox.profile \\
        -- \\
        \'$ff_wrapper\' "\$@"
EOF
    my $wrapper_file = "$tbbinfos->{tbbdir}/ff_$test->{name}";
    write_file($wrapper_file, $wrapper);
    chmod 0700, $wrapper_file;
    return $wrapper_file;
}

sub ffbin_path {
    my ($tbbinfos, $test) = @_;
    if ($OSNAME eq 'cygwin') {
        return winpath("$tbbinfos->{ffbin}.exe");
    }
    return $options->{mbox} ? ff_mbox_wrapper($tbbinfos, $test)
           : ff_wrapper($tbbinfos, $test);
}

sub mozmill_run {
    my ($tbbinfos, $test) = @_;
    return unless $options->{mozmill};
    $test->{screenshots} = [];
    my $screenshots_tmp = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
    $ENV{'MOZMILL_SCREENSHOTS'} = winpath($screenshots_tmp);
    my $results_file = "$tbbinfos->{'results-dir'}/$test->{name}.json";
    system(xvfb_run($test), mozmill_cmd(), '-b', ffbin_path($tbbinfos, $test),
        '-p', winpath($tbbinfos->{ffprofiledir}),
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
    check_modified_files($tbbinfos, $test);
    $test->{results}{success} = !$test->{results}{results}->[0]->{failed};
}

sub selenium_run {
    my ($tbbinfos, $test) = @_;
    return unless $options->{selenium};
    my $result_file = $ENV{SELENIUM_TEST_RESULT_FILE} =
        "$tbbinfos->{'results-dir'}/$test->{name}.json";
    $ENV{TBB_BIN} = ffbin_path($tbbinfos, $test);
    $ENV{TBB_PROFILE} = $tbbinfos->{ffprofiledir};
    system(xvfb_run($test), "$options->{virtualenv}/bin/python",
        "$FindBin::Bin/selenium-tests/run_test", $test->{name});
    $test->{results} = decode_json(read_file($result_file));
    check_opened_connections($tbbinfos, $test);
    check_modified_files($tbbinfos, $test);
}

sub set_tbbpaths {
    my ($tbbinfos) = @_;
    if ($options->{newlayout}) {
        $tbbinfos->{ffbin} = "$tbbinfos->{tbbdir}/firefox";
        $tbbinfos->{tordir} = "$tbbinfos->{tbbdir}/TorBrowser/Tor";
        $tbbinfos->{datadir} = "$tbbinfos->{tbbdir}/TorBrowser/Data";
    } else {
        $tbbinfos->{ffbin} =  "$tbbinfos->{tbbdir}/Browser/firefox";
        $tbbinfos->{tordir} = "$tbbinfos->{tbbdir}/Tor";
        $tbbinfos->{datadir} = "$tbbinfos->{tbbdir}/Data";
    }
    $tbbinfos->{torbin} = "$tbbinfos->{tordir}/tor";
    $tbbinfos->{ptdir} = "$tbbinfos->{tordir}/PluggableTransports";
    $tbbinfos->{ffprofiledir} = "$tbbinfos->{datadir}/Browser/profile.default";
}

sub pre_tests {
    my ($tbbinfos) = @_;
    get_tbbfile($tbbinfos);
    if ($tbbinfos->{sha256sum} &&
        $tbbinfos->{sha256sum} ne sha256_hex(read_file($tbbinfos->{tbbfile}))) {
        exit_error "Wrong sha256sum for $tbbinfos->{tbbfile}";
    }
    $tbbinfos->{sha256sum} //= sha256_hex(read_file($tbbinfos->{tbbfile}));
    extract_tbb($tbbinfos);
    set_tbbpaths($tbbinfos);
    chdir $tbbinfos->{tbbdir} || exit_error "Can't enter directory $tbbinfos->{tbbdir}";
    $ENV{TOR_SKIP_LAUNCH} = 1;
    if ($options->{xdummy}) {
        $tbbinfos->{Xdisplay} = start_X("$tbbinfos->{'results-dir'}/xorg.log");
        set_Xmode($tbbinfos->{Xdisplay}, $options->{resolution});
    }
}

sub post_tests {
    my ($tbbinfos) = @_;
    TBBTestSuite::Tests::TorBootstrap::stop_tor($tbbinfos);
    stop_X($tbbinfos->{Xdisplay}) if $options->{xdummy};
}

1;
