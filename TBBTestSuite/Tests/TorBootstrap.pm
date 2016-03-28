package TBBTestSuite::Tests::TorBootstrap;

use strict;
use English;
use File::Slurp;
use Cwd qw(getcwd);
use TBBTestSuite::Common qw(exit_error winpath has_bin);
use TBBTestSuite::Options qw($options);
use IO::CaptureOutput qw(capture_exec);
use IO::Socket::INET;
use POSIX ":sys_wait_h";

my $httpproxy_pid;

sub start_httpproxy {
    my ($tbbinfos, $test) = @_;
    return if $httpproxy_pid = fork;
    exec 'ncat', '-l', '--proxy-type', 'http', 'localhost',
         $options->{'http-proxy-port'};
}

sub stop_httpproxy {
    kill 15, $httpproxy_pid if $httpproxy_pid;
    $httpproxy_pid = undef;
}

END {
    stop_httpproxy;
}

sub winpid {
    $OSNAME eq 'cygwin' ? Cygwin::pid_to_winpid($_[0]) : $_[0];
}

sub send_newnym {
    my ($tbbinfos) = @_;
    return unless ($options->{starttor} && $tbbinfos->{torpid});
    my $sock = new IO::Socket::INET(
        PeerAddr => 'localhost',
        PeerPort => $options->{'tor-control-port'},
        Proto => 'tcp',
    );
    print $sock 'AUTHENTICATE "', $tbbinfos->{tor_control_passwd}, "\"\n";
    my $r = <$sock>;
    return undef unless $r =~ m/^250 OK/;
    print $sock "SIGNAL NEWNYM\n";
    return <$sock> =~ m/^250 OK/;
}

sub monitor_bootstrap {
    my ($tbbinfos, $test, $control_passwd) = @_;
    sleep 10;
    my $sock = new IO::Socket::INET(
        PeerAddr => 'localhost',
        PeerPort => $options->{'tor-control-port'},
        Proto => 'tcp',
    );
    if (!$sock) {
        $test->{results}{success} = 0;
        return 0;
    }
    print $sock 'AUTHENTICATE "', $control_passwd, "\"\n";
    my $r = <$sock>;
    exit_error "Authentication error: $r" unless $r =~ m/^250 OK/;
    my $i = 0;
    while (1) {
        print $sock "GETINFO status/bootstrap-phase\n";
        $r = <$sock>;
        print $r;
        last if $r =~ m/^250-status\/bootstrap-phase.* TAG=done/;
        sleep 1;
        $i++;
        if ($i > 300) {
            $test->{results}{success} = 0;
            return 0;
        }
    }
    print "Bootstraping done\n";
    $test->{results}{success} = 1;
    return 3;
}

sub fetch {
    my ($tbbinfos, $test) = @_;
    my (undef, $err, $success) = capture_exec('curl', '-sS', '--socks5',
        "localhost:$options->{'tor-socks-port'}", 'http://www.yahoo.com/');
    if (!$success) {
        $test->{results}{success} = 0;
        $test->{results}{fetch_error} = $err;
    }
}

sub tor_capture_exec {
    my ($tbbinfos) = shift;
    my $ld_lib = $ENV{LD_LIBRARY_PATH};
    $ENV{LD_LIBRARY_PATH} = "$tbbinfos->{tbbdir}:$tbbinfos->{tordir}";
    my @res = capture_exec(@_);
    $ENV{LD_LIBRARY_PATH} = $ld_lib;
    return @res;
}

# TODO: In the future, we should start tor using tor-launcher
sub start_tor {
    my ($tbbinfos, $test) = @_;
    return unless $options->{starttor};
    if ($test->{httpproxy} && !has_bin('ncat')) {
        return;
    }
    my $control_passwd = map { ('a'..'z', 'A'..'Z', 0..9)[rand 62] } 0..8;
    $tbbinfos->{tor_control_passwd} = $control_passwd
                        if $test->{name} eq 'tor_bootstrap';
    my $cwd = getcwd;
    start_httpproxy($tbbinfos, $test) if $test->{httpproxy};
    $ENV{TOR_SOCKS_PORT} = $options->{'tor-socks-port'};
    $ENV{TOR_CONTROL_PORT} = $options->{'tor-control-port'};
    $ENV{TOR_CONTROL_HOST} = '127.0.0.1';
    $ENV{TOR_CONTROL_COOKIE_AUTH_FILE} = winpath("$tbbinfos->{datadir}/Tor/control_auth_cookie");
    my ($hashed_password, $err, $success) = tor_capture_exec($tbbinfos,
        winpath($tbbinfos->{torbin}), '--quiet', '--hash-password',
        $control_passwd);
    exit_error "Error running tor --hash-password: $err" unless $success;
    chomp $hashed_password;
    my $torrc_file;
    if ($test->{use_default_config}) {
        $torrc_file = "$tbbinfos->{datadir}/Tor/torrc-defaults";
        my @torrc = read_file($torrc_file);
        foreach (@torrc) {
            s/^ControlPort .*/ControlPort $options->{'tor-control-port'}/;
            s/^SocksPort .*/SocksPort $options->{'tor-socks-port'}/;
        }
        push @torrc, "HashedControlPassword $hashed_password\n";
        write_file($torrc_file, @torrc);
    } else {
        my $template = Template->new(
            ENCODING => 'utf8',
            INCLUDE_PATH => "$FindBin::Bin/tor-config",
        );
        my $vars = {
            test => $test,
            options => $options,
            tbbinfos => $tbbinfos,
            hashed_control_password => $hashed_password,
        };
        my $config;
        $template->process("$test->{name}.conf", $vars, \$config,
            binmode => ':utf8')
                || exit_error "Template Error:\n" . $template->error;
        $test->{torrc} = $config;
        $torrc_file = File::Temp->new;
        write_file($torrc_file, $config);
    }
    my @cmd = (winpath($tbbinfos->{torbin}), '--defaults-torrc',
        winpath($torrc_file),
        '-f', winpath("$tbbinfos->{datadir}/Tor/torrc"),
        'DataDirectory', winpath("$tbbinfos->{datadir}/Tor"),
        'GeoIPFile', winpath("$tbbinfos->{datadir}/Tor/geoip"),
        '__OwningControllerProcess', winpid($$));
    $tbbinfos->{torpid} = fork;
    if ($tbbinfos->{torpid} == 0) {
        $ENV{LD_LIBRARY_PATH} = "$tbbinfos->{tbbdir}:$tbbinfos->{tordir}";
        my $logfile = "$tbbinfos->{'results-dir'}/$test->{name}.log";
        open(STDOUT, '>', $logfile);
        open(STDERR, '>', $logfile);
        exec @cmd;
    }
    my $res = monitor_bootstrap($tbbinfos, $test, $control_passwd);
    fetch($tbbinfos, $test) if $res;
    stop_tor($tbbinfos, $test) unless $test->{no_kill};
    return $res;
}

sub stop_tor {
    my ($tbbinfos, $test) = @_;
    return unless ($options->{starttor} && $tbbinfos->{torpid});
    kill 15, $tbbinfos->{torpid};
    my ($kid, $i) = (0, 5);
    while ($kid == 0 && $i) {
        $i--;
        $kid = waitpid($tbbinfos->{torpid}, WNOHANG);
        sleep 1 if $kid == 0;
    }
    kill 9, $tbbinfos->{torpid} if $kid == 0;
    stop_httpproxy($tbbinfos, $test) if $test->{httpproxy};
}

1;
