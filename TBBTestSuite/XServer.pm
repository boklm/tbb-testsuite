package TBBTestSuite::XServer;
use FindBin;
use TBBTestSuite::Common qw(exit_error);
use IO::CaptureOutput qw(capture_exec);
use POSIX ":sys_wait_h";

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(start_X stop_X set_Xmode);
}

my %Xpid;
my %WMpid;

sub free_display {
    my $i = 0;
    while ($i < 1000) {
        return ":$i" unless -S "/tmp/.X11-unix/X$i";
        $i++;
    }
    exit_error "Could not find free X display";
}

sub start_X {
    my ($logfile, $display) = @_;
    $display //= free_display;
    my $datadir = "$FindBin::Bin/data";
    $Xpid{$display} = fork;
    if (!$Xpid{$display}) {
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>', '/dev/null');
        exec("$datadir/Xdummy", '-noreset', '+extension', 'GLX',
            '+extension', 'RANDR', '+extension', 'RENDER', '-config',
            "$datadir/xorg.conf", '-logfile', $logfile, $display)
                || exit_error "Could not start Xorg";
    }
    sleep 3;
    $ENV{DISPLAY} = $display;
    $WMpid{$display} = fork;
    if (!$WMpid{$display}) {
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>', '/dev/null');
        exec('fluxbox')
                || exit_error "Could not start WM";
    }
    return $display;
}

sub kill_process {
    my ($pid) = @_;
    return unless $pid;
    kill 15, $pid;
    my ($kid, $i) = (0, 5);
    while ($kid == 0 && $i) {
        $i--;
        $kid = waitpid($pid, WNOHANG);
        sleep 1 if $kid == 0;
    }
    kill 9, $pid if $kid == 0;
}

sub stop_X {
    my ($display) = @_;
    kill_process $WMpid{$display};
    kill_process $Xpid{$display};
}

sub set_Xmode {
    my ($display, $mode) = @_;
    $ENV{DISPLAY} = $display;
    my ($out, $err, $success)
        = capture_exec('xrandr', '--output', 'default', '--mode', $mode);
    exit_error "Error changing mode: $err" unless $success;
    return $success;
}

1;
