package TBBTestSuite::TestSuite::BrowserBundleTests;

use warnings;
use strict;

use parent 'TBBTestSuite::TestSuite';

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
use TBBTestSuite::Common qw(exit_error winpath clone_strip_coderef);
use TBBTestSuite::Options qw($options);
use TBBTestSuite::Tests::VirusTotal qw(virustotal_run);
use TBBTestSuite::Tests::Command qw(command_run);
use TBBTestSuite::Tests::TorBootstrap;
use TBBTestSuite::XServer qw(start_X stop_X set_Xmode);

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

sub test_types {
    return {
        tor_bootstrap => \&TBBTestSuite::Tests::TorBootstrap::start_tor,
        mozmill       => \&mozmill_run,
        marionette    => \&marionette_run,
        selenium      => \&selenium_run,
        virustotal    => \&virustotal_run,
        command       => \&command_run,
    };
}

sub type {
    'browserbundle';
}

sub description {
    'Tor Browser Bundle integration tests';
}

our @tests = (
    {
        name         => 'readelf_RELRO',
        fail_type    => 'warning',
        type         => 'command',
        descr        => 'Check if binaries are RELocation Read-Only',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-ld' ],
        check_output => sub { ( $_[0] =~ m/GNU_RELRO/ )
                                && ( $_[0] =~ m/BIND_NOW/ ) },
        enable       => sub { $OSNAME eq 'linux' },
    },
    {
        name         => 'readelf_stack_canary',
        fail_type    => 'warning',
        type         => 'command',
        descr        => 'Check for stack canary support',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-s' ],
        check_output => sub { $_[0] =~ m/__stack_chk_fail/ },
        enable       => sub { $OSNAME eq 'linux' },
    },
    {
        name         => 'readelf_NX',
        type         => 'command',
        descr        => 'Check for NX support',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-W', '-l' ],
        check_output => sub { ! ($_[0] =~ m/GNU_STACK.+RWE/) },
        enable       => sub { $OSNAME eq 'linux' },
    },
    {
        name         => 'readelf_PIE',
        type         => 'command',
        descr        => 'Check for PIE support',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-h' ],
        check_output => sub { $_[0] =~ m/Type:\s+DYN/ },
        enable       => sub { $OSNAME eq 'linux' },
    },
    {
        name         => 'readelf_no_rpath',
        fail_type    => 'warning',
        type         => 'command',
        descr        => 'Check for no rpath',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-d' ],
        check_output => sub { ! ( $_[0] =~ m/RPATH/ ) },
        enable       => sub { $OSNAME eq 'linux' },
    },
    {
        name         => 'readelf_no_runpath',
        type         => 'command',
        descr        => 'Check for no runpath',
        files        => \&tbb_binfiles,
        command      => [ 'readelf', '-d' ],
        check_output => sub { ! ( $_[0] =~ m/runpath/ ) },
        enable       => sub { $OSNAME eq 'linux' },
    },
    {
        name      => 'tor_httpproxy',
        type      => 'tor_bootstrap',
        descr     => 'Access tor using an http proxy',
        httpproxy => 1,
        enable    => sub { $OSNAME eq 'linux' },
    },
    {
        name   => 'tor_bridge',
        type   => 'tor_bootstrap',
        descr  => 'Access tor using a bridge',
        enable => sub { $OSNAME eq 'linux' },
    },
    {
        name      => 'tor_bridge_httpproxy',
        type      => 'tor_bootstrap',
        descr     => 'Access tor using a bridge and an http proxy',
        httpproxy => 1,
        enable    => sub { $OSNAME eq 'linux' },
    },
    {
        name   => 'tor_obfs3',
        type   => 'tor_bootstrap',
        descr  => 'Access tor using obfs3',
        enable => sub { $OSNAME eq 'linux' },
    },
    {
        name      => 'tor_obfs3_httpproxy',
        type      => 'tor_bootstrap',
        descr     => 'Access tor using obfs3 and an http proxy',
        httpproxy => 1,
        enable    => sub { $OSNAME eq 'linux' },
    },
    {
        name   => 'tor_obfs4',
        type   => 'tor_bootstrap',
        descr  => 'Access tor using obfs4',
        enable => sub { $OSNAME eq 'linux' && $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name      => 'tor_obfs4_httpproxy',
        type      => 'tor_bootstrap',
        descr     => 'Access tor using obfs4 and an http proxy',
        httpproxy => 1,
        enable    => sub { $OSNAME eq 'linux' && $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name   => 'tor_fte',
        type   => 'tor_bootstrap',
        descr  => 'Access tor using fteproxy',
        enable => sub { $OSNAME eq 'linux' },
    },
    {
        name      => 'tor_fte_httpproxy',
        type      => 'tor_bootstrap',
        descr     => 'Access tor using fteproxy and an http proxy',
        httpproxy => 1,
        enable    => sub { $OSNAME eq 'linux' },
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
        name  => 'acid3',
        type  => 'mozmill',
        descr => 'acid3 tests',
    },
    {
        name         => 'slider_settings_1',
        mozmill_test => 'slider_settings',
        type         => 'mozmill',
        descr        => 'Check that settings are set according to security slider mode',
        slider_mode  => 1,
        pre          => \&set_slider_mode,
        post         => \&reset_slider_mode,
        enable       => sub { $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name         => 'slider_settings_2',
        mozmill_test => 'slider_settings',
        type         => 'mozmill',
        descr        => 'Check that settings are set according to security slider mode',
        slider_mode  => 2,
        pre          => \&set_slider_mode,
        post         => \&reset_slider_mode,
        enable       => sub { $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name         => 'slider_settings_3',
        mozmill_test => 'slider_settings',
        type         => 'mozmill',
        descr        => 'Check that settings are set according to security slider mode',
        slider_mode  => 3,
        pre          => \&set_slider_mode,
        post         => \&reset_slider_mode,
        enable       => sub { $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name         => 'slider_settings_4',
        mozmill_test => 'slider_settings',
        type         => 'mozmill',
        descr        => 'Check that settings are set according to security slider mode',
        slider_mode  => 4,
        pre          => \&set_slider_mode,
        post         => \&reset_slider_mode,
        enable       => sub { $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name  => 'dom-objects-enumeration',
        type  => 'mozmill',
        descr => 'Check the list of DOM Objects exposed in the global namespace',
    },
    {
        name  => 'navigation-timing',
        type  => 'mozmill',
        descr => 'Check that the Navigation Timing API is really disabled',
    },
    {
        name  => 'resource-timing',
        type  => 'mozmill',
        descr => 'Check that the Resource Timing API is really disabled',
    },
    {
        name  => 'searchengines',
        type  => 'mozmill',
        descr => 'Check that we have the default search engines set',
    },
    {
        name  => 'noscript',
        type  => 'mozmill',
        descr => 'Check that noscript options are working',
        retry => 1,
        prefs => {
            'extensions.torbutton.security_slider' => 2,
        },
        enable       => sub { $_[0]->{version} !~ m/^4.0/ },
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
    {
        name => 'play_videos',
        type => 'mozmill',
        descr => 'Play some videos',
        mozmill_test => 'test_page',
        remote => 1,
        timeout => 50000,
        interval => 100,
    },
    {
        name => 'svg-disable',
        type => 'mozmill',
        descr => 'Check if disabling svg is working',
        mozmill_test => 'svg',
        svg_enabled => 0,
        prefs => {
            'extensions.torbutton.security_custom' => 'true',
            'svg.in-content.enabled' => 'false',
        },
        enable => sub { $OSNAME eq 'linux' },
    },
    {
        name => 'svg-enable',
        type => 'mozmill',
        descr => 'Check if enabling svg is working',
        mozmill_test => 'svg',
        svg_enabled => 1,
        prefs => {
            'extensions.torbutton.security_custom' => 'true',
            'svg.in-content.enabled' => 'true',
        },
        enable => sub { $OSNAME eq 'linux' },
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

sub set_test_prefs {
    my ($tbbinfos, $t) = @_;
    return unless $t->{prefs};
    my $prefs = "$tbbinfos->{ffprofiledir}/preferences/extension-overrides.js";
    copy $prefs, "$prefs.backup";
    my $new_prefs = '';
    foreach my $prefname (sort keys %{$t->{prefs}}) {
        $new_prefs .= "pref(\"$prefname\", $t->{prefs}{$prefname});\n";
    }
    write_file($prefs, {append => 1}, $new_prefs);
    print "prefs file: $prefs\n";
}

sub reset_test_prefs {
    my ($tbbinfos, $t) = @_;
    return unless $t->{prefs};
    my $prefs = "$tbbinfos->{ffprofiledir}/preferences/extension-overrides.js";
    move "$prefs.backup", $prefs;
}

sub set_slider_mode {
    my ($tbbinfos, $t) = @_;
    my $prefs = "$tbbinfos->{ffprofiledir}/preferences/extension-overrides.js";
    copy $prefs, "$prefs.slider_backup";
    write_file($prefs, {append => 1},
      'pref("extensions.torbutton.security_custom", false);' . "\n" .
      "pref(\"extensions.torbutton.security_slider\", $t->{slider_mode});\n");
}

sub reset_slider_mode {
    my ($tbbinfos, $t) = @_;
    my $prefs = "$tbbinfos->{ffprofiledir}/preferences/extension-overrides.js";
    move "$prefs.slider_backup", $prefs;
}

sub tbb_binfiles {
    my ($tbbinfos, $test) = @_;
    return $tbbinfos->{binfiles} if $tbbinfos->{binfiles};
    my %binfiles;
    my %wanted_types = (
        'application/x-executable-file' => 1,
        'application/x-ms-dos-executable' => 1,
    );
    my $wanted = sub {
        return unless -f $File::Find::name;
        my $type = File::Type->new->checktype_filename($File::Find::name);
        return unless $wanted_types{$type};
        my $name = $File::Find::name;
        $name =~ s/^$tbbinfos->{tbbdir}\///;
        $binfiles{$name} = 1;
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
        $tbbinfos->{tbbdir} = "$tmpdir/torbrowser/Browser";
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
    my %bad_connections =  %{$test->{results}{connections}};
    delete $bad_connections{"127.0.0.1:$options->{'tor-control-port'}"};
    delete $bad_connections{"127.0.0.1:$options->{'tor-socks-port'}"};
    # For some reasons, tor-browser creates two connections to the default
    # socks port even when when TOR_SOCKS_PORT is set
    # https://lists.torproject.org/pipermail/tbb-dev/2014-May/000050.html
    if (defined $bad_connections{'127.0.0.1:9150'}
        && $bad_connections{'127.0.0.1:9150'} <= 2) {
        delete $bad_connections{'127.0.0.1:9150'}
    }
    $test->{results}{success} = 0 if %bad_connections;
    $test->{results}{bad_connections} = \%bad_connections;
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
    return unless -f "$sandbox_dir.meta";
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
export LD_LIBRARY_PATH="$tbbinfos->{tbbdir}:$tbbinfos->{tordir}"
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

sub mozmill_export_options {
    my ($tbbinfos, $test) = @_;
    my $options_file = winpath("$FindBin::Bin/mozmill-tests/lib/testsuite.js");
    my $json_opts = encode_json clone_strip_coderef $options;
    my $json_test = encode_json clone_strip_coderef $test;
    my $json_tbbinfos = encode_json clone_strip_coderef
                                { %$tbbinfos, tests => undef };
    my $content = <<EOF;
var options = $json_opts;
var test = $json_test;
var tbbinfos = $json_tbbinfos;
exports.options = options;
exports.test = test;
exports.tbbinfos = tbbinfos;
EOF
    write_file($options_file, $content);
}

sub marionette_run {
    my ($tbbinfos, $test) = @_;
    set_test_prefs($tbbinfos, $test);

    my $result_file_html = "$tbbinfos->{'results-dir'}/$test->{name}.html";
    my $result_file_txt = "$tbbinfos->{'results-dir'}/$test->{name}.txt";
    #--log-unittest  ./res.txt --log-html ./res.html
    system(xvfb_run($test), "$FindBin::Bin/virtualenv_marionette/bin/tor-browser-tests",
        '--log-unittest', $result_file_txt, '--log-html', $result_file_html,
        '--binary', ffbin_path($tbbinfos, $test),
        '--profile', winpath($tbbinfos->{ffprofiledir}),
        "$FindBin::Bin/marionette/tor_browser_tests/test_$test->{name}.py");
    my @txt_log = read_file($result_file_txt);
    $test->{results}{success} = shift @txt_log eq ".\n";
    $test->{results}{log} = join '', @txt_log;
    reset_test_prefs($tbbinfos, $test);
    check_opened_connections($tbbinfos, $test);
    check_modified_files($tbbinfos, $test);
}

sub mozmill_run {
    my ($tbbinfos, $test) = @_;
    return unless $options->{mozmill};
    mozmill_export_options($tbbinfos, $test);
    set_test_prefs($tbbinfos, $test);
    $test->{screenshots} = [];
    my $screenshots_tmp = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
    $ENV{'MOZMILL_SCREENSHOTS'} = winpath($screenshots_tmp);
    my $results_file = "$tbbinfos->{'results-dir'}/$test->{name}.json";
    my $mozmill_test = $test->{mozmill_test} // $test->{name};
    system(xvfb_run($test), mozmill_cmd(), '-b', ffbin_path($tbbinfos, $test),
        '-p', winpath($tbbinfos->{ffprofiledir}),
        '-t', winpath("$FindBin::Bin/mozmill-tests/tbb-tests/$mozmill_test.js"),
        '--report', 'file://' . winpath($results_file));
    my $i = 0;
    for my $screenshot_file (reverse sort glob "$screenshots_tmp/*.png") {
        move($screenshot_file, "$tbbinfos->{'results-dir'}/$test->{name}-$i.png");
        $screenshot_thumbnail->($tbbinfos->{'results-dir'}, "$test->{name}-$i.png");
        push @{$test->{screenshots}}, "$test->{name}-$i.png";
        $i++;
    }
    $test->{results} = decode_json(read_file($results_file));
    $test->{results}{success} = $test->{results}{results}->[0]->{passed} ?
                        !$test->{results}{results}->[0]->{failed} : 0;
    reset_test_prefs($tbbinfos, $test);
    check_opened_connections($tbbinfos, $test);
    check_modified_files($tbbinfos, $test);
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
    $tbbinfos->{ptdir} = winpath("$tbbinfos->{tordir}/PluggableTransports");
    $tbbinfos->{ffprofiledir} = "$tbbinfos->{datadir}/Browser/profile.default";
}

sub new {
    my ($ts, $testsuite) = @_;
    $testsuite->{type} = 'browserbundle';
    $testsuite->{tests} = [ map { { %$_ } } @tests ];
    return undef unless $testsuite->{os} eq $options->{os};
    return undef unless $testsuite->{arch} eq $options->{arch};
    return bless $testsuite, $ts;
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
    copy "$FindBin::Bin/data/cert_override.txt",
          "TorBrowser/Data/Browser/profile.default/cert_override.txt";
    $ENV{TOR_SKIP_LAUNCH} = 1;
    $ENV{TOR_SOCKS_PORT} = $options->{'tor-socks-port'};
    $ENV{TOR_CONTROL_PORT} = $options->{'tor-control-port'};
    if ($options->{xdummy}) {
        $tbbinfos->{Xdisplay} = start_X("$tbbinfos->{'results-dir'}/xorg.log");
    }
}

sub post_tests {
    my ($tbbinfos) = @_;
    TBBTestSuite::Tests::TorBootstrap::stop_tor($tbbinfos);
    stop_X($tbbinfos->{Xdisplay}) if $options->{xdummy};
}

1;
