package TBBTestSuite::Common;

use warnings;
use strict;
use English;
use FindBin;
use IO::CaptureOutput qw(capture_exec);
use File::Slurp;
use IPC::Run qw(run);

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(exit_error system_infos run_alone rm_pidfile winpath
                    has_bin get_var run_to_file get_nbcpu as_array);
}

sub exit_error {
    print STDERR "Error: ", $_[0], "\n";
    chdir '/';
    exit (exists $_[1] ? $_[1] : 1);
}

sub run_alone {
    my $pidfile = "$FindBin::Bin/lock";
    if (-f $pidfile) {
        my $pid = read_file($pidfile);
        exit_error "tbbtestsuite is already running" if (kill(0, $pid));
    }
    write_file($pidfile, $$);
}

sub rm_pidfile {
    unlink "$FindBin::Bin/lock";
}

sub system_infos {
    my %res;
    my $lsbr = '/usr/bin/lsb_release';
    ($res{arch}) = capture_exec('uname', '-m');
    chomp $res{arch};
    if (-f $lsbr) {
        my ($id) = capture_exec($lsbr, '-i');
        $id =~ s/^Distributor ID:\s+//;
        chomp $id;
        my ($release) = capture_exec($lsbr, '-r');
        $release =~ s/^Release:\s+//;
        chomp $release;
        $res{osname} = $id . $release;
    } else {
        ($res{osname}) = capture_exec('uname', '-s');
        chomp $res{osname};
    }
    return \%res;
}

sub winpath {
    my ($path) = @_;
    return $path unless $OSNAME eq 'cygwin';
    my ($res) = capture_exec('cygpath', '-aw', $path);
    chomp $res;
    return $res;
}

sub has_bin {
    my ($bin) = @_;
    my (undef, undef, $success) = capture_exec('which', $bin);
    return $success;
}

sub get_var {
    my ($var, @arg) = @_;
    return ref $var eq 'CODE' ? $var->(@arg) : $var;
}

sub run_to_file {
    my ($file, @cmd) = @_;
    open(my $out, '>', $file) or exit_error "Error opening $file";
    my $res = run \@cmd, '>&', $out;
    close $out;
    return $res;
}

sub get_nbcpu {
    open(my $cpuinfo, '<', '/proc/cpuinfo')
        or exit_error 'Error opening /proc/cpuinfo';
    my $res = grep { m/^processor\s+:\s/ } <$cpuinfo>;
    close $cpuinfo;
    return $res;
}

sub as_array {
    ref $_[0] eq 'ARRAY' ? $_[0] : [ $_[0] ];
}

1;
