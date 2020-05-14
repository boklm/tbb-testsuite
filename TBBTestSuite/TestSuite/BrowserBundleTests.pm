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
use File::Temp;
use JSON;
use Digest::SHA qw(sha256_hex);
use LWP::UserAgent;
use IO::CaptureOutput qw(capture_exec);
use TBBTestSuite::Common qw(exit_error winpath clone_strip_coderef screenshot_thumbnail);
use TBBTestSuite::Options qw($options);
use TBBTestSuite::Tests::VirusTotal qw(virustotal_run);
use TBBTestSuite::Tests::Command qw(command_run);
use TBBTestSuite::Tests::TorBootstrap;
use TBBTestSuite::XServer qw(start_X stop_X set_Xmode);

sub test_types {
    return {
        tor_bootstrap => \&TBBTestSuite::Tests::TorBootstrap::start_tor,
        marionette    => \&marionette_run,
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
        name         => 'win_DEP_ASLR',
        type         => 'command',
        retry        => 1,
        descr        => 'Check DEP/ASLR',
        files        => \&tbb_binfiles,
        command      => [ "$FindBin::Bin/data/check-windows-dep-aslr.sh" ],
        enable       => sub { $_[0]->{os} eq 'Windows' },
        # ticket 16417
        skip_files   => [ qw(
            TorBrowser/Tor/PluggableTransports/_ctypes.pyd
            TorBrowser/Tor/PluggableTransports/_hashlib.pyd
            TorBrowser/Tor/PluggableTransports/_socket.pyd
            TorBrowser/Tor/PluggableTransports/_ssl.pyd
            TorBrowser/Tor/PluggableTransports/bz2.pyd
            TorBrowser/Tor/PluggableTransports/Crypto.Cipher._AES.pyd
            TorBrowser/Tor/PluggableTransports/Crypto.Hash._SHA256.pyd
            TorBrowser/Tor/PluggableTransports/Crypto.Hash._SHA512.pyd
            TorBrowser/Tor/PluggableTransports/Crypto.Random.OSRNG.winrandom.pyd
            TorBrowser/Tor/PluggableTransports/Crypto.Util._counter.pyd
            TorBrowser/Tor/PluggableTransports/Crypto.Util.strxor.pyd
            TorBrowser/Tor/PluggableTransports/flashproxy-client.exe
            TorBrowser/Tor/PluggableTransports/flashproxy-reg-appspot.exe
            TorBrowser/Tor/PluggableTransports/flashproxy-reg-email.exe
            TorBrowser/Tor/PluggableTransports/flashproxy-reg-http.exe
            TorBrowser/Tor/PluggableTransports/flashproxy-reg-url.exe
            TorBrowser/Tor/PluggableTransports/fte.cDFA.pyd
            TorBrowser/Tor/PluggableTransports/fteproxy.exe
            TorBrowser/Tor/PluggableTransports/M2Crypto.__m2crypto.pyd
            TorBrowser/Tor/PluggableTransports/meek-client-torbrowser.exe
            TorBrowser/Tor/PluggableTransports/meek-client.exe
            TorBrowser/Tor/PluggableTransports/obfs4proxy.exe
            TorBrowser/Tor/PluggableTransports/obfsproxy.exe
            TorBrowser/Tor/PluggableTransports/pyexpat.pyd
            TorBrowser/Tor/PluggableTransports/python27.dll
            TorBrowser/Tor/PluggableTransports/select.pyd
            TorBrowser/Tor/PluggableTransports/terminateprocess-buffer.exe
            TorBrowser/Tor/PluggableTransports/unicodedata.pyd
            TorBrowser/Tor/PluggableTransports/w9xpopen.exe
            TorBrowser/Tor/PluggableTransports/zope.interface._zope_interface_coptimizations.pyd
            ) ],
    },
    {
        name            => 'readelf_RELRO',
        type            => 'command',
        descr           => 'Check if binaries are RELocation Read-Only',
        files           => \&tbb_binfiles,
        command         => [ 'readelf', '-ld' ],
        check_output    => sub { ( $_[0] =~ m/GNU_RELRO/ )
                                 && ( $_[0] =~ m/BIND_NOW/ ) },
        enable          => sub { $OSNAME eq 'linux' },
        skip_files   => [ qw(
            TorBrowser/Tor/PluggableTransports/meek-client
            TorBrowser/Tor/PluggableTransports/meek-client-torbrowser
            TorBrowser/Tor/PluggableTransports/meek-client-torbrowser
            TorBrowser/Tor/PluggableTransports/obfs4proxy
            TorBrowser/Tor/PluggableTransports/zope/interface/_zope_interface_coptimizations.so
            ) ],
    },
    {
        name            => 'readelf_stack_canary',
        type            => 'command',
        descr           => 'Check for stack canary support',
        files           => \&tbb_binfiles,
        command         => [ 'readelf', '-s' ],
        check_output    => sub { $_[0] =~ m/__stack_chk_fail/ },
        enable          => sub { $OSNAME eq 'linux' },
        # ticket 13056
        skip_files   => [ qw(
            abicheck
            gtk2/libmozgtk.so
            libmozalloc.so
            libmozgtk.so
            libnssckbi.so
            libplc4.so
            libplds4.so
            TorBrowser/Tor/libstdc++/libstdc++.so.6
            TorBrowser/Tor/PluggableTransports/Crypto/Cipher/_ARC4.so
            TorBrowser/Tor/PluggableTransports/Crypto/Cipher/_XOR.so
            TorBrowser/Tor/PluggableTransports/Crypto/Util/_counter.so
            TorBrowser/Tor/PluggableTransports/fte/cDFA.so
            TorBrowser/Tor/PluggableTransports/meek-client-torbrowser
            TorBrowser/Tor/PluggableTransports/twisted/python/_initgroups.so
            TorBrowser/Tor/PluggableTransports/twisted/runner/portmap.so
            TorBrowser/Tor/PluggableTransports/twisted/test/raiser.so
            TorBrowser/Tor/PluggableTransports/zope/interface/_zope_interface_coptimizations.so
            TorBrowser/Tor/PluggableTransports/meek-client
            TorBrowser/Tor/PluggableTransports/obfs4proxy
            ) ],
    },
    {
        name            => 'readelf_NX',
        type            => 'command',
        descr           => 'Check for NX support',
        files           => \&tbb_binfiles,
        command         => [ 'readelf', '-W', '-l' ],
        check_output    => sub { ! ($_[0] =~ m/GNU_STACK.+RWE/) },
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'readelf_PIE',
        type            => 'command',
        descr           => 'Check for PIE support',
        files           => \&tbb_binfiles,
        command         => [ 'readelf', '-h' ],
        check_output    => sub { $_[0] =~ m/Type:\s+DYN/ },
        enable          => sub { $OSNAME eq 'linux' },
        skip_files   => [ qw(
            TorBrowser/Tor/PluggableTransports/meek-client
            TorBrowser/Tor/PluggableTransports/meek-client-torbrowser
            TorBrowser/Tor/PluggableTransports/obfs4proxy
            TorBrowser/Tor/PluggableTransports/snowflake-client
            ) ],
    },
    {
        name            => 'readelf_no_rpath',
        type            => 'command',
        descr           => 'Check for no rpath',
        files           => \&tbb_binfiles,
        command         => [ 'readelf', '-d' ],
        check_output    => sub { ! ( $_[0] =~ m/RPATH/ ) },
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'readelf_no_runpath',
        type            => 'command',
        descr           => 'Check for no runpath',
        files           => \&tbb_binfiles,
        command         => [ 'readelf', '-d' ],
        check_output    => sub { ! ( $_[0] =~ m/runpath/ ) },
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'otool_PIE',
        type            => 'command',
        descr           => 'Check for PIE support',
        files           => \&tbb_osx_executable_files,
        command         => [ 'otool', '-hv' ],
        check_output    => sub {
            my @lines = split("\n", $_[0]);
            my $last_line = pop @lines;
            my ($flags) = $last_line =~ m/^\s*[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+(.*)/;
            my %flags = map { $_ => 1 } split(/\s+/, $flags);
            return $flags{PIE};
        },
        enable          => sub { $OSNAME eq 'darwin' },
        retry           => 1,
        skip_files   => [ qw(
            Contents/MacOS/Tor/PluggableTransports/meek-client
            Contents/MacOS/Tor/PluggableTransports/meek-client-torbrowser
            Contents/MacOS/Tor/PluggableTransports/obfs4proxy
            ) ],
    },
    {
        name            => 'tor_httpproxy',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using an http proxy',
        httpproxy       => 1,
        enable          => sub { $OSNAME eq 'linux' },
        run_once        => 1,
    },
    {
        name            => 'tor_bridge',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using a bridge',
        enable          => sub { $OSNAME eq 'linux' && $options->{PTtests} },
        run_once        => 1,
    },
    {
        name            => 'tor_bridge_httpproxy',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using a bridge and an http proxy',
        httpproxy       => 1,
        enable          => sub { $OSNAME eq 'linux' && $options->{PTtests} },
        run_once        => 1,
    },
    {
        name            => 'tor_obfs4',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using obfs4',
        enable          => sub { $OSNAME eq 'linux' && $options->{PTtests} },
        run_once        => 1,
    },
    {
        name            => 'tor_obfs4_httpproxy',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using obfs4 and an http proxy',
        httpproxy       => 1,
        enable          => sub { $OSNAME eq 'linux' && $options->{PTtests} },
        run_once        => 1,
    },
    {
        name            => 'tor_meek-azure',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using meek-azure',
        enable          => sub { $OSNAME eq 'linux' && $options->{PTtests} },
        run_once        => 1,
    },
    {
        name            => 'tor_bootstrap',
        type            => 'tor_bootstrap',
        descr           => 'Check that we can bootstrap tor',
        fail_type       => 'fatal',
        no_kill         => 1,
        use_default_config => 1,
    },
    {
        name            => 'screenshots',
        type            => 'marionette',
        descr           => 'Take some screenshots',
    },
    {
        name            => 'check',
        type            => 'marionette',
        use_net         => 1,
        descr           => 'Check that http://check.torproject.org/ think we are using tor',
    },
    {
        name            => 'https-everywhere-disabled',
        marionette_test => 'https-everywhere',
        type            => 'marionette',
        descr           => 'Check that https everywhere is not doing anything when disabled',
        use_net         => 1,
        pre             => sub {
            my ($tbbinfos, $t) = @_;
            my $hdir = "$tbbinfos->{tmpdir}/https-everywhere";
            mkdir "$hdir";
            move($tbbinfos->{ffprofiledir} . '/extensions/https-everywhere-eff@eff.org.xpi',
                $hdir . '/https-everywhere-eff@eff.org.xpi');
        },
        post            => sub {
            my ($tbbinfos, $t) = @_;
            my $hdir = "$tbbinfos->{tmpdir}/https-everywhere";
            move($hdir . '/https-everywhere-eff@eff.org.xpi',
                $tbbinfos->{ffprofiledir} . '/extensions/https-everywhere-eff@eff.org.xpi');
        },
    },
    {
        name            => 'https-everywhere',
        type            => 'marionette',
        use_net         => 1,
        descr           => 'Check that https everywhere is working',
        # Bug 30431: temporarily disable test
        enable          => sub { undef },
    },
    {
        name            => 'settings',
        type            => 'marionette',
        descr           => 'Check that some important settings are correctly set',
    },
    {
        name            => 'acid3',
        type            => 'marionette',
        descr           => 'acid3 tests',
        use_net         => 1,
        retry           => 4,
        # the acid3 test is disabled for now
        enable          => sub { 0; },
    },
    {
        name            => 'slider_settings_1',
        marionette_test => 'slider_settings',
        type            => 'marionette',
        descr           => 'Check that settings are set according to security slider mode',
        slider_mode     => 1,
        pre             => \&set_slider_mode,
        post            => \&reset_slider_mode,
    },
    {
        name            => 'slider_settings_2',
        marionette_test => 'slider_settings',
        type            => 'marionette',
        descr           => 'Check that settings are set according to security slider mode',
        slider_mode     => 2,
        pre             => \&set_slider_mode,
        post            => \&reset_slider_mode,
    },
    {
        name            => 'slider_settings_4',
        marionette_test => 'slider_settings',
        type            => 'marionette',
        descr           => 'Check that settings are set according to security slider mode',
        slider_mode     => 4,
        pre             => \&set_slider_mode,
        post            => \&reset_slider_mode,
    },
    {
        name            => 'dom-objects-enumeration',
        type            => 'marionette',
        descr           => 'Check the list of DOM Objects exposed in the global namespace',
    },
    {
        name            => 'dom-objects-enumeration-worker',
        type            => 'marionette',
        descr           => 'Check the list of DOM Objects exposed in a Worker context',
    },
    {
        name            => 'navigation-timing',
        type            => 'marionette',
        descr           => 'Check that the Navigation Timing API is really disabled',
        use_net         => 1,
    },
    {
        name            => 'resource-timing',
        type            => 'marionette',
        descr           => 'Check that the Resource Timing API is really disabled',
        use_net         => 1,
        # To check that the test fails when resource timing is enabled,
        # uncomment this:
        #prefs           => {
        #    'dom.enable_resource_timing' => 'true',
        #    'privacy.resistFingerprinting' => 'false',
        #},
    },
    {
        name            => 'user-timing',
        type            => 'marionette',
        descr           => 'Check that the User Timing API is really disabled',
        use_net         => 1,
        # To check that the test fails when user timing is enabled,
        # uncomment this:
        #prefs           => {
        #    'dom.enable_user_timing' => 'true',
        #    'privacy.resistFingerprinting' => 'false',
        #},
    },
    {
        name            => 'user-timing-worker',
        type            => 'marionette',
        marionette_test => 'page',
        remote          => 0,
        timeout         => 500,
        descr           => 'Check that the User Timing API in Worker context is really disabled',
        use_net         => 1,
        # To check that the test fails when user timing is enabled,
        # uncomment this:
        #prefs           => {
        #    'dom.enable_user_timing' => 'true',
        #    'privacy.resistFingerprinting' => 'false',
        #},
    },
    {
        name            => 'performance-observer',
        type            => 'marionette',
        descr           => 'Check that the Performance Observer API is really disabled',
        use_net         => 1,
        # To check that the test fails when performance observer is enabled,
        # uncomment this:
        #prefs           => {
        #    'dom.enable_performance_observer' => 'true',
        #},
        # Bug 27137: temporarily disable test
        enable          => sub { undef },
    },
    {
        name            => 'searchengines',
        type            => 'marionette',
        descr           => 'Check that we have the default search engines set',
        # Bug 30340: temporarily disable test
        enable          => sub { undef },
    },
    {
        name            => 'noscript',
        type            => 'marionette',
        descr           => 'Check that noscript options are working',
        use_net         => 1,
        prefs           => {
            'extensions.torbutton.security_slider' => 2,
        },
        # Bug 28876: temporarily disable test
        enable          => sub { undef },
    },
    {
        name            => 'fp_screen_dimensions',
        type            => 'marionette',
        descr           => 'Check that screen dimensions are spoofed correctly',
    },
    {
        name            => 'fp_screen_coords',
        type            => 'marionette',
        descr           => 'Check that screenX, screenY, screenLeft, screenTop, mozInnerScreenX, mozInnerScreenY are 0',
    },
    {
        name            => 'fp_plugins',
        type            => 'marionette',
        descr           => 'Check that plugins are disabled',
    },
    {
        name            => 'fp_useragent',
        type            => 'marionette',
        descr           => 'Check that userAgent is as expected',
    },
    {
        name            => 'fp_navigator',
        type            => 'marionette',
        descr           => 'Check that navigator properties are as expected',
        # Bug 28665: temporarily disable test
        enable          => sub { undef },
    },
    {
        name            => 'play_videos',
        type            => 'marionette',
        descr           => 'Play some videos',
        use_net         => 1,
        marionette_test => 'page',
        remote          => 1,
        timeout         => 50000,
        # Bug 30339: temporarily disable test
        enable          => sub { undef },
    },
    {
        name            => 'svg-disable',
        type            => 'marionette',
        descr           => 'Check if disabling svg is working',
        marionette_test => 'svg',
        use_net         => 1,
        prefs           => {
            'extensions.torbutton.security_custom' => 'true',
            'svg.in-content.enabled' => 'false',
        },
        # Bug 28798: temporarily disable test
        enable          => sub { undef },
        #enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'svg-enable',
        type            => 'marionette',
        descr           => 'Check if enabling svg is working',
        marionette_test => 'svg',
        use_net         => 1,
        prefs           => {
            'extensions.torbutton.security_custom' => 'true',
            'svg.in-content.enabled' => 'true',
        },
        # Bug 28798: temporarily disable test
        enable          => sub { undef },
        #enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'download_pdf',
        type            => 'marionette',
        descr           => 'Check if download of PDF is working (#19402)',
        use_net         => 1,
        # Bug 30333: temporarily disable test
        enable          => sub { undef },
    },
    {
        name            => 'pinning_now',
        type            => 'marionette',
        descr           => 'Check if static public key pinning is working (#20149)',
        marionette_test => 'pinning',
        use_net         => 1,
    },
    {
        name            => 'fpcentral',
        type            => 'marionette',
        descr           => 'Check the browser fingerprint using fpcentral',
        fpcentral_url   => 'https://fpcentral.tbb.torproject.org/fp?automated_test',
        use_net         => 1,
        # Bug 30432: temporarily disable test
        enable          => sub { undef },
    },
);

sub set_test_prefs {
    my ($tbbinfos, $t) = @_;
    return unless $t->{prefs};
    my $prefs = "$tbbinfos->{ffprofiledir}/user.js";
    copy $prefs, "$prefs.backup";
    my $new_prefs = '';
    foreach my $prefname (sort keys %{$t->{prefs}}) {
        $new_prefs .= "user_pref(\"$prefname\", $t->{prefs}{$prefname});\n";
    }
    write_file($prefs, {append => 1}, $new_prefs);
}

sub reset_test_prefs {
    my ($tbbinfos, $t) = @_;
    return unless $t->{prefs};
    my $prefs = "$tbbinfos->{ffprofiledir}/user.js";
    move "$prefs.backup", $prefs;
}

sub set_slider_mode {
    my ($tbbinfos, $t) = @_;
    my $prefs = "$tbbinfos->{ffprofiledir}/user.js";
    copy $prefs, "$prefs.slider_backup";
    write_file($prefs, {append => 1},
      'user_pref("extensions.torbutton.security_custom", false);' . "\n" .
      "user_pref(\"extensions.torbutton.security_slider\", $t->{slider_mode});\n");
}

sub reset_slider_mode {
    my ($tbbinfos, $t) = @_;
    my $prefs = "$tbbinfos->{ffprofiledir}/user.js";
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

sub tbb_osx_executable_files {
    my ($tbbinfos, $test) = @_;
    return $tbbinfos->{osx_executable_files} if $tbbinfos->{osx_executable_files};
    my %exec_files;
    my $wanted = sub {
        return unless -f $File::Find::name;
        $ENV{LC_ALL}= 'C';
        my ($out, $err, $success) = capture_exec('otool', '-hv', $File::Find::name);
        return unless $success;
        my @out_lines = split("\n", $out);
        return if $out_lines[0] =~ m/is not an object file/;
        my $last_line = pop @out_lines;
        my ($type) = $last_line =~ m/^\s*[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+([^\s]+)\s+[^\s]+\s+[^\s]+\s+/;
        my $name = $File::Find::name;
        $name =~ s/^$tbbinfos->{tbbdir}\///;
        $exec_files{$name} = 1 if $type eq 'EXECUTE';
    };
    find($wanted, $tbbinfos->{tbbdir});
    return $tbbinfos->{osx_executable_files} = [ keys %exec_files ];
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
        if ($tbbinfos->{language} eq 'ALL') {
            $tbbinfos->{tbbdir} = "$tmpdir/tor-browser";
        } else {
            $tbbinfos->{tbbdir} = "$tmpdir/tor-browser_$tbbinfos->{language}";
        }
        $tbbinfos->{tbbdir} .= '/Browser';
    } elsif ($tbbinfos->{os} eq 'Windows') {
        my (undef, undef, $f) = File::Spec->splitpath($tbbfile);
        copy($tbbfile, "$tmpdir/$f");
        system('7z', 'x', $f);
        $tbbinfos->{tbbdir} = "$tmpdir/torbrowser/Browser";
        move("$tmpdir/\$_OUTDIR", "$tmpdir/torbrowser") if -d "$tmpdir/\$_OUTDIR";
        if (-d "$tmpdir/Browser") {
            mkdir "$tmpdir/torbrowser";
            move("$tmpdir/Browser", "$tmpdir/torbrowser/Browser");
        }
        move ("$tmpdir/Start Tor Browser.exe", "$tmpdir/torbrowser/");
        system('chmod', '-R', '+rx', $tmpdir) if $OSNAME eq 'cygwin';
    } elsif ($tbbinfos->{os} eq 'MacOSX') {
        my $mountpoint = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
        system('hdiutil', 'mount', '-mountpoint', $mountpoint, $tbbfile);
        system('cp', '-a', "$mountpoint/TorBrowser.app", "$tmpdir/TorBrowser.app");
        system('hdiutil', 'unmount', $mountpoint);
        $tbbinfos->{tbbdir} = "$tmpdir/TorBrowser.app";
    }
}

sub xvfb_run {
    my ($test) = @_;
    return () unless $options->{xvfb};
    my $resolution = $test->{resolution} ? $test->{resolution}
                                         : $options->{resolution};
    return ('xvfb-run', '--auto-servernum', '-s', "-screen 0 ${resolution}x24");
}

sub check_opened_connections {
    my ($tbbinfos, $test) = @_;
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
    if (%bad_connections) {
        $test->{results}{success} = 0;
        $test->{retry} = 0;
    }
    $test->{clean_strace} //= !%bad_connections;
    $test->{results}{bad_connections} = \%bad_connections;
}

sub check_modified_files {
    my ($tbbinfos, $test) = @_;
    my @bad_modified_files = @{$test->{results}{modified_files}};
    if (@bad_modified_files) {
        $test->{results}{success} = 0;
        $test->{retry} = 0;
    }
    $test->{clean_strace} //= !@bad_modified_files;
    $test->{results}{bad_modified_files} = \@bad_modified_files;
}

sub clean_strace {
    my ($tbbinfos, $test) = @_;
    return unless $test->{clean_strace};
    my $logfile = "$tbbinfos->{'results-dir'}/$test->{name}.strace";
    unlink $logfile;
    unlink "$logfile.tmp";
}

sub parse_strace {
    my ($tbbinfos, $test) = @_;
    my %ignore_files = map { $_ => 1 } qw(/dev/null /dev/tty);
    my @ignore_re = ( qr/^\/dev\/(dri)|(shm)/ );
    push @ignore_re, qr/^$test->{workspace}/ if $test->{workspace};
    my %files;
    my $logfile = "$tbbinfos->{'results-dir'}/$test->{name}.strace";
    $test->{results}{connections} = {};
    my %modified_files;
    my %removed_files;
    if (-f "$logfile.tmp") {
        my $txt = read_file("$logfile.tmp");
        write_file($logfile, { append => 1 }, $txt);
        unlink "$logfile.tmp";
    }
    my @lines = read_file($logfile) if -f $logfile;
    LINE: foreach my $line (@lines) {
        if ($line =~ m/^\d+ open\("((?:[^"\\]++|\\.)*+)", ([^\)]+)/ ||
            $line =~ m/^\d+ openat\([^,]+, "((?:[^"\\]++|\\.)*+)", ([^\)]+)/) {
            next if $2 =~ m/O_RDONLY/;
            next if $1 =~ m/^$tbbinfos->{tbbdir}/;
            next if $ignore_files{$1};
            if ($ENV{'MOZMILL_SCREENSHOTS'}) {
                next if $1 =~ m/^$ENV{'MOZMILL_SCREENSHOTS'}/;
            }
            foreach my $re (@ignore_re) {
                next LINE if $1 =~ m/$re/;
            }
            $modified_files{$1}++;
        }
        if ($line =~ m/^\d+ unlink\("((?:[^"\\]++|\\.)*+)"/) {
            next if $1 =~ m/^$tbbinfos->{tbbdir}/;
            next if $ignore_files{$1};
            foreach my $re (@ignore_re) {
                next LINE if $1 =~ m/$re/;
            }
            $removed_files{$1}++;
            delete $modified_files{$1} unless -f $1;
        }
        if ($line =~ m/^\d+ connect\(\d+, \{sa_family=AF_INET, sin_port=htons\((\d+)\), sin_addr=inet_addr\("((?:[^"\\]++|\\.)*+)"\)/) {
            $test->{results}{connections}{"$2:$1"}++;
        }
    }
    $test->{results}{modified_files} = [ keys %modified_files ];
    $test->{results}{removed_files} = [ keys %removed_files ];
}

sub ff_wrapper {
    my ($tbbinfos, $test) = @_;
    my $wrapper_file = "$tbbinfos->{tbbdir}/ff_wrapper";
    return $wrapper_file if -f $wrapper_file;
    my $wrapper = <<EOF;
#!/bin/sh
set -e
export HOME="$tbbinfos->{tbbdir}"
export LD_LIBRARY_PATH="$tbbinfos->{tbbdir}:$tbbinfos->{tordir}"
export FONTCONFIG_PATH="\${HOME}/TorBrowser/Data/fontconfig"
export FONTCONFIG_FILE="fonts.conf"
exec \'$tbbinfos->{ffbin}\' "\$@"
EOF
    write_file($wrapper_file, $wrapper);
    chmod 0700, $wrapper_file;
    return $wrapper_file;
}

sub ff_strace_wrapper {
    my ($tbbinfos, $test) = @_;
    my $ff_wrapper = ff_wrapper($tbbinfos, $test);
    my $logfile = "$tbbinfos->{'results-dir'}/$test->{name}.strace";
    my $wrapper = <<EOF;
#!/bin/sh
if [ -f $logfile.tmp ]
then
   cat $logfile.tmp >> $logfile
   rm $logfile.tmp
fi
echo \$@ >> /tmp/ff_run.log
strace -e trace=file,network -f -o $logfile.tmp -- \'$ff_wrapper\' "\$@"
exit_code=\$?
cat $logfile.tmp >> $logfile
rm $logfile.tmp
exit \$?
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
    my %t = map { $_ => 1 } qw(marionette);
    if ($options->{use_strace} && $t{$test->{type}}) {
        return ff_strace_wrapper($tbbinfos, $test);
    }
    return $tbbinfos->{ffbin} if $OSNAME eq 'darwin';
    return ff_wrapper($tbbinfos, $test);
}

sub marionette_export_options {
    my ($tbbinfos, $test) = @_;
    my $options_file = File::Temp->new();
    my $json = {
        options  => clone_strip_coderef($options),
        test     => clone_strip_coderef($test),
        tbbinfos => clone_strip_coderef({ %$tbbinfos, tests => undef }),
    };
    write_file($options_file, encode_json($json));
    return $options_file;
}

sub marionette_run {
    my ($tbbinfos, $test) = @_;
    if ($test->{tried} && $test->{use_net}) {
        TBBTestSuite::Tests::TorBootstrap::send_newnym($tbbinfos);
    }
    set_test_prefs($tbbinfos, $test);

    my $options_file = marionette_export_options($tbbinfos, $test);
    $ENV{TESTSUITE_DATA_FILE} = winpath($options_file);
    my $result_file_html = "$tbbinfos->{'results-dir'}/$test->{name}.html";
    my $result_file_txt = "$tbbinfos->{'results-dir'}/$test->{name}.txt";
    $test->{workspace} = "$tbbinfos->{'results-dir'}/$test->{name}_ws";
    mkdir $test->{workspace};
    #--log-unittest  ./res.txt --log-html ./res.html
    my $bin = $OSNAME eq 'cygwin' ? 'Scripts' : 'bin';
    my $marionette_test = $test->{marionette_test} // $test->{name};
    my $pypath = $ENV{PYTHONPATH};
    my $old_pypath = $ENV{PYTHONPATH};
    $ENV{PYTHONPATH} = winpath("$FindBin::Bin/marionette/tor_browser_tests/lib");
    my $sep = $OSNAME eq 'cygwin' ? ';' : ':';
    $ENV{PYTHONPATH} .= $sep . $old_pypath if $old_pypath;
    $test->{screenshots} = [];
    my $screenshots_tmp = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
    $ENV{'MARIONETTE_SCREENSHOTS'} = winpath($screenshots_tmp);
    system(xvfb_run($test), "$FindBin::Bin/virtualenv-marionette-5.0.0/$bin/tor-browser-tests",
        '--log-unittest', winpath($result_file_txt),
        '--log-html', winpath($result_file_html),
        '--server-root', winpath("$FindBin::Bin/test-data"),
        '--binary', ffbin_path($tbbinfos, $test),
        '--profile', winpath($tbbinfos->{ffprofiledir}),
        $OSNAME eq 'cygwin' ? () : ('--workspace', $test->{workspace}),
        winpath("$FindBin::Bin/marionette/tor_browser_tests/test_${marionette_test}.py"));
    $ENV{PYTHONPATH} = $pypath;
    my @txt_log = -f $result_file_txt ? read_file($result_file_txt) : ('NoFile');
    my $res_line = shift @txt_log;
    $test->{results}{success} = $res_line eq ".\n" || $res_line eq ".\r\n";
    $test->{results}{log} = join '', @txt_log;
    my $i = 0;
    for my $screenshot_file (sort glob "$screenshots_tmp/*.png") {
        move($screenshot_file, "$tbbinfos->{'results-dir'}/$test->{name}-$i.png");
        screenshot_thumbnail($tbbinfos->{'results-dir'}, "$test->{name}-$i.png");
        push @{$test->{screenshots}}, "$test->{name}-$i.png";
        $i++;
    }
    reset_test_prefs($tbbinfos, $test);
    parse_strace($tbbinfos, $test);
    check_opened_connections($tbbinfos, $test);
    check_modified_files($tbbinfos, $test);
    clean_strace($tbbinfos, $test);
}

sub set_tbbpaths {
    my ($tbbinfos) = @_;
    $tbbinfos->{ffbin} = "$tbbinfos->{tbbdir}/firefox";
    $tbbinfos->{tordir} = "$tbbinfos->{tbbdir}/TorBrowser/Tor";
    $tbbinfos->{datadir} = "$tbbinfos->{tbbdir}/TorBrowser/Data";
    if ($tbbinfos->{os} eq 'MacOSX') {
        $tbbinfos->{ffbin} = "$tbbinfos->{tbbdir}/Contents/MacOS/firefox";
        unless ($tbbinfos->{version} =~ m/^5./) {
            $tbbinfos->{ffprofiledir} = "$tbbinfos->{tbbdir}/Contents/Resources/distribution";
            $tbbinfos->{tordir} = "$tbbinfos->{tbbdir}/Contents/Resources/TorBrowser/Tor";
            $tbbinfos->{datadir} = "$tbbinfos->{tbbdir}/../TorBrowser-data";
            $tbbinfos->{torrcdefaults} = "$tbbinfos->{tordir}/torrc-defaults";
            $tbbinfos->{torgeoip} = "$tbbinfos->{tordir}/geoip";
            mkdir $tbbinfos->{datadir} unless -d $tbbinfos->{datadir};
            mkdir "$tbbinfos->{datadir}/Tor" unless -d "$tbbinfos->{datadir}/Tor";
        }
    }
    $tbbinfos->{torrcdefaults} //= "$tbbinfos->{datadir}/Tor/torrc-defaults";
    $tbbinfos->{torgeoip} //= "$tbbinfos->{datadir}/Tor/geoip";
    $tbbinfos->{torbin} = "$tbbinfos->{tordir}/tor";
    $tbbinfos->{ptdir} = winpath("$tbbinfos->{tordir}/PluggableTransports");
    $tbbinfos->{ffprofiledir} //= "$tbbinfos->{datadir}/Browser/profile.default";
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
    my $prefs_file = "$tbbinfos->{ffprofiledir}/user.js";
    open(my $prefs_fh, '>>', $prefs_file);
    print $prefs_fh 'user_pref("privacy.spoof_english", 1);', "\n";
    close $prefs_fh;
    chdir $tbbinfos->{tbbdir} || exit_error "Can't enter directory $tbbinfos->{tbbdir}";
    copy "$FindBin::Bin/data/cert_override.txt",
          "$tbbinfos->{ffprofiledir}/cert_override.txt";
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
