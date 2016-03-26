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
        name            => 'readelf_RELRO',
        fail_type       => 'warning',
        type            => 'command',
        descr           => 'Check if binaries are RELocation Read-Only',
        files           => \&tbb_binfiles,
        command         => [ 'readelf', '-ld' ],
        check_output    => sub { ( $_[0] =~ m/GNU_RELRO/ )
                                 && ( $_[0] =~ m/BIND_NOW/ ) },
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'readelf_stack_canary',
        fail_type       => 'warning',
        type            => 'command',
        descr           => 'Check for stack canary support',
        files           => \&tbb_binfiles,
        command         => [ 'readelf', '-s' ],
        check_output    => sub { $_[0] =~ m/__stack_chk_fail/ },
        enable          => sub { $OSNAME eq 'linux' },
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
    },
    {
        name            => 'readelf_no_rpath',
        fail_type       => 'warning',
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
        name            => 'tor_httpproxy',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using an http proxy',
        httpproxy       => 1,
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_bridge',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using a bridge',
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_bridge_httpproxy',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using a bridge and an http proxy',
        httpproxy       => 1,
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_obfs3',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using obfs3',
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_obfs3_httpproxy',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using obfs3 and an http proxy',
        httpproxy       => 1,
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_obfs4',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using obfs4',
        enable          => sub { $OSNAME eq 'linux' && $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name            => 'tor_obfs4_httpproxy',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using obfs4 and an http proxy',
        httpproxy       => 1,
        enable          => sub { $OSNAME eq 'linux' && $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name            => 'tor_fte',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using fteproxy',
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_fte_httpproxy',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using fteproxy and an http proxy',
        httpproxy       => 1,
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_scramblesuit',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using scramblesuit',
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_scramblesuit_httpproxy',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using scramblesuit and an http proxy',
        httpproxy       => 1,
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_meek-google',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using meek-google',
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_meek-amazon',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using meek-amazon',
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'tor_meek-azure',
        type            => 'tor_bootstrap',
        descr           => 'Access tor using meek-azure',
        enable          => sub { $OSNAME eq 'linux' },
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
        type            => 'mozmill',
        descr           => 'Take some screenshots',
    },
    {
        name            => 'check',
        type            => 'selenium',
        use_net         => 1,
        descr           => 'Check that http://check.torproject.org/ think we are using tor',
    },
    {
        name            => 'https-everywhere',
        type            => 'mozmill',
        use_net         => 1,
        descr           => 'Check that https everywhere is enabled and working',
    },
    {
        name            => 'https-everywhere-disabled',
        type            => 'mozmill',
        descr           => 'Check that https everywhere is not doing anything when disabled',
        use_net         => 1,
        pre             => sub { toggle_https_everywhere($_[0], 0) },
        post            => sub { toggle_https_everywhere($_[0], 1) },
    },
    {
        name            => 'settings',
        type            => 'mozmill',
        descr           => 'Check that some important settings are correctly set',
    },
    {
        name            => 'acid3',
        type            => 'mozmill',
        descr           => 'acid3 tests',
        use_net         => 1,
        retry           => 4,
    },
    {
        name            => 'slider_settings_1',
        mozmill_test    => 'slider_settings',
        type            => 'mozmill',
        descr           => 'Check that settings are set according to security slider mode',
        slider_mode     => 1,
        pre             => \&set_slider_mode,
        post            => \&reset_slider_mode,
        enable          => sub { $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name            => 'slider_settings_2',
        mozmill_test    => 'slider_settings',
        type            => 'mozmill',
        descr           => 'Check that settings are set according to security slider mode',
        slider_mode     => 2,
        pre             => \&set_slider_mode,
        post            => \&reset_slider_mode,
        enable          => sub { $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name            => 'slider_settings_3',
        mozmill_test    => 'slider_settings',
        type            => 'mozmill',
        descr           => 'Check that settings are set according to security slider mode',
        slider_mode     => 3,
        pre             => \&set_slider_mode,
        post            => \&reset_slider_mode,
        enable          => sub { $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name            => 'slider_settings_4',
        mozmill_test    => 'slider_settings',
        type            => 'mozmill',
        descr           => 'Check that settings are set according to security slider mode',
        slider_mode     => 4,
        pre             => \&set_slider_mode,
        post            => \&reset_slider_mode,
        enable          => sub { $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name            => 'dom-objects-enumeration',
        type            => 'mozmill',
        descr           => 'Check the list of DOM Objects exposed in the global namespace',
    },
    {
        name            => 'navigation-timing',
        type            => 'mozmill',
        descr           => 'Check that the Navigation Timing API is really disabled',
        use_net         => 1,
    },
    {
        name            => 'resource-timing',
        type            => 'mozmill',
        descr           => 'Check that the Resource Timing API is really disabled',
        use_net         => 1,
    },
    {
        name            => 'searchengines',
        type            => 'mozmill',
        descr           => 'Check that we have the default search engines set',
    },
    {
        name            => 'noscript',
        type            => 'mozmill',
        descr           => 'Check that noscript options are working',
        use_net         => 1,
        prefs           => {
            'extensions.torbutton.security_slider' => 2,
        },
        enable          => sub { $_[0]->{version} !~ m/^4.0/ },
    },
    {
        name            => 'fp_screen_dimensions',
        type            => 'selenium',
        descr           => 'Check that screen dimensions are spoofed correctly',
    },
    {
        name            => 'fp_screen_coords',
        type            => 'selenium',
        descr           => 'Check that screenX, screenY, screenLeft, screenTop, mozInnerScreenX, mozInnerScreenY are 0',
    },
    {
        name            => 'fp_plugins',
        type            => 'selenium',
        descr           => 'Check that plugins are disabled',
    },
    {
        name            => 'fp_useragent',
        type            => 'selenium',
        descr           => 'Check that userAgent is as expected',
    },        {
        name            => 'fp_navigator',
        type            => 'selenium',
        descr           => 'Check that navigator properties are as expected',
    },
    {
        name            => 'play_videos',
        type            => 'mozmill',
        descr           => 'Play some videos',
        use_net         => 1,
        mozmill_test    => 'test_page',
        remote          => 1,
        timeout         => 50000,
        interval        => 100,
    },
    {
        name            => 'svg-disable',
        type            => 'mozmill',
        descr           => 'Check if disabling svg is working',
        mozmill_test    => 'svg',
        svg_enabled     => 0,
        use_net         => 1,
        prefs           => {
            'extensions.torbutton.security_custom' => 'true',
            'svg.in-content.enabled' => 'false',
        },
        enable          => sub { $OSNAME eq 'linux' },
    },
    {
        name            => 'svg-enable',
        type            => 'mozmill',
        descr           => 'Check if enabling svg is working',
        mozmill_test    => 'svg',
        use_net         => 1,
        svg_enabled     => 1,
        prefs           => {
            'extensions.torbutton.security_custom' => 'true',
            'svg.in-content.enabled' => 'true',
        },
        enable          => sub { $OSNAME eq 'linux' },
    },
);

sub toggle_https_everywhere {
    my ($tbbinfos, $t) = @_;
    my $prefs = $tbbinfos->{ffprofiledir} . '/extensions/'
        . 'https-everywhere@eff.org/defaults/preferences/preferences.js';
    my $prefs_eff = $tbbinfos->{ffprofiledir} . '/extensions/'
        . 'https-everywhere-eff@eff.org/defaults/preferences/preferences.js';
    $prefs = $prefs_eff unless -f $prefs;
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
        if ($tbbinfos->{language} eq 'ALL') {
            $tbbinfos->{tbbdir} = "$tmpdir/tor-browser";
        } else {
            $tbbinfos->{tbbdir} = "$tmpdir/tor-browser_$tbbinfos->{language}";
        }
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
    $test->{results}{bad_connections} = \%bad_connections;
}

sub check_modified_files {
    my ($tbbinfos, $test) = @_;
    my @bad_modified_files = @{$test->{results}{modified_files}};
    if (@bad_modified_files) {
        $test->{results}{success} = 0;
        $test->{retry} = 0;
    }
    $test->{results}{bad_modified_files} = \@bad_modified_files;
}

sub clean_strace {
    my ($tbbinfos, $test) = @_;
    my $logfile = "$tbbinfos->{'results-dir'}/$test->{name}.strace";
    unlink $logfile;
    unlink "$logfile.tmp";
}

sub parse_strace {
    my ($tbbinfos, $test) = @_;
    my %ignore_files = map { $_ => 1 } qw(/dev/null /dev/tty);
    my %files;
    my $logfile = "$tbbinfos->{'results-dir'}/$test->{name}.strace";
    my $logfile_tmp = "$tbbinfos->{'results-dir'}/$test->{name}.strace.tmp";
    $test->{results}{connections} = {};
    my %modified_files;
    my %removed_files;
    my @lines = read_file($logfile) if -f $logfile;
    push @lines, read_file($logfile_tmp) if -f $logfile_tmp;
    foreach my $line (@lines) {
        if ($line =~ m/^\d+ open\("((?:[^"\\]++|\\.)*+)", ([^\)]+)/ ||
            $line =~ m/^\d+ openat\([^,]+, "((?:[^"\\]++|\\.)*+)", ([^\)]+)/) {
            next if $2 =~ m/O_RDONLY/;
            next if $1 =~ m/^$tbbinfos->{tbbdir}/;
            next if $ignore_files{$1};
            next if $1 =~ m/^$ENV{'MOZMILL_SCREENSHOTS'}/;
            $modified_files{$1}++;
        }
        if ($line =~ m/^\d+ unlink\("((?:[^"\\]++|\\.)*+)"/) {
            next if $1 =~ m/^$tbbinfos->{tbbdir}/;
            $removed_files{$1}++;
            delete $modified_files{$1} unless -f $1;
        }
        if ($line =~ m/^\d+ connect\(\d+, {sa_family=AF_INET, sin_port=htons\((\d+)\), sin_addr=inet_addr\("((?:[^"\\]++|\\.)*+)"\)/) {
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
strace -f -o $logfile.tmp -- \'$ff_wrapper\' "\$@"
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
    if ($options->{use_strace} && $test->{type} eq 'mozmill') {
        return ff_strace_wrapper($tbbinfos, $test);
    }
    return ff_wrapper($tbbinfos, $test);
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

sub mozmill_run {
    my ($tbbinfos, $test) = @_;
    return unless $options->{mozmill};
    if ($test->{tried} && $test->{use_net}) {
        TBBTestSuite::Tests::TorBootstrap::send_newnym($tbbinfos);
    }
    clean_strace($tbbinfos, $test) if $options->{use_strace};
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
    if (-f $results_file) {
        $test->{results} = decode_json(read_file($results_file));
        $test->{results}{success} = $test->{results}{results}->[0]->{passed} ?
                                !$test->{results}{results}->[0]->{failed} : 0;
    } else {
        $test->{results}{success} = 0;
    }
    reset_test_prefs($tbbinfos, $test);
    if ($options->{use_strace}) {
        parse_strace($tbbinfos, $test);
        check_opened_connections($tbbinfos, $test);
        check_modified_files($tbbinfos, $test);
        clean_strace($tbbinfos, $test) if $test->{results}{success};
    }
}

sub selenium_run {
    my ($tbbinfos, $test) = @_;
    return unless $options->{selenium};
    if ($test->{tried} && $test->{use_net}) {
        TBBTestSuite::Tests::TorBootstrap::send_newnym($tbbinfos);
    }
    my $result_file = $ENV{SELENIUM_TEST_RESULT_FILE} =
        "$tbbinfos->{'results-dir'}/$test->{name}.json";
    $ENV{TBB_BIN} = ffbin_path($tbbinfos, $test);
    $ENV{TBB_PROFILE} = $tbbinfos->{ffprofiledir};
    system(xvfb_run($test), "$options->{virtualenv}/bin/python",
        "$FindBin::Bin/selenium-tests/run_test", $test->{name});
    $test->{results} = decode_json(read_file($result_file));
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
    my $prefs_file = "$tbbinfos->{ffprofiledir}/preferences/extension-overrides.js";
    open(my $prefs_fh, '>>', $prefs_file);
    print $prefs_fh 'pref("extensions.torbutton.prompted_language", true);', "\n";
    close $prefs_fh;
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
