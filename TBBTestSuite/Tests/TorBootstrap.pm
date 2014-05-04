package TBBTestSuite::Tests::TorBootstrap;

use strict;
use File::Slurp;
use Cwd qw(getcwd);
use TBBTestSuite::Common qw(exit_error winpath);
use TBBTestSuite::Options qw($options);
use IO::CaptureOutput qw(capture_exec);
use IO::Socket::INET;

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

# TODO: In the future, we should start tor using tor-launcher
sub start_tor {
    my ($tbbinfos, $test) = @_;
    return unless $options->{starttor};
    my $control_passwd = map { ('a'..'z', 'A'..'Z', 0..9)[rand 62] } 0..8;
    my $cwd = getcwd;
    $ENV{LD_LIBRARY_PATH} = "$cwd/Tor/";
    $ENV{TOR_SOCKS_PORT} = $options->{'tor-socks-port'};
    $ENV{TOR_CONTROL_PORT} = $options->{'tor-control-port'};
    $ENV{TOR_CONTROL_HOST} = '127.0.0.1';
    $ENV{TOR_CONTROL_COOKIE_AUTH_FILE} = winpath("$cwd/Data/Tor/control_auth_cookie");
    my ($hashed_password, undef, $success) =
        capture_exec("$cwd/Tor/tor", '--quiet', '--hash-password', $control_passwd);
    exit_error "Error running tor --hash-password" unless $success;
    chomp $hashed_password;
    my $torrc_file;
    if ($test->{use_default_config}) {
        my @torrc = read_file('Data/Tor/torrc-defaults');
        foreach (@torrc) {
            s/^ControlPort .*/ControlPort $options->{'tor-control-port'}/;
            s/^SocksPort .*/SocksPort $options->{'tor-socks-port'}/;
        }
        push @torrc, "HashedControlPassword $hashed_password\n";
        write_file('Data/Tor/torrc-defaults', @torrc);
        $torrc_file = "$cwd/Data/Tor/torrc-defaults";
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
        $torrc_file = File::Temp->new;
        write_file($torrc_file, $config);
    }
    my @cmd = ("$cwd/Tor/tor", '--defaults-torrc', winpath($torrc_file),
        '-f', winpath("$cwd/Data/Tor/torrc"), 'DataDirectory',
        winpath("$cwd/Data/Tor"), 'GeoIPFile', winpath("$cwd/Data/Tor/geoip"),
        '__OwningControllerProcess', $$);
    $tbbinfos->{torpid} = fork;
    if ($tbbinfos->{torpid} == 0) {
        my $logfile = "$tbbinfos->{'results-dir'}/$test->{name}.log";
        open(STDOUT, '>', $logfile);
        open(STDERR, '>', $logfile);
        exec @cmd;
    }
    my $res = monitor_bootstrap($tbbinfos, $test, $control_passwd);
    fetch($tbbinfos, $test) if $res;
    stop_tor($tbbinfos) unless $test->{no_kill};
    return $res;
}

sub stop_tor {
    my ($tbbinfos) = @_;
    return unless $options->{starttor};
    kill 9, $tbbinfos->{torpid} if $tbbinfos->{torpid};
}

1;
