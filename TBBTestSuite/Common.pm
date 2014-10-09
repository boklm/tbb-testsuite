package TBBTestSuite::Common;

use warnings;
use strict;
use English;
use FindBin;
use IO::CaptureOutput qw(capture_exec);
use File::Slurp;
use IPC::Run qw(run);
use Storable qw(dclone);
use DateTime;

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(exit_error system_infos run_alone rm_pidfile winpath
                    has_bin get_var run_to_file get_nbcpu as_array
                    clone_strip_coderef last_days);
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

sub remove_scalarref {
    my ($data) = @_;
    return unless ref $data;
    unless (ref $data eq 'ARRAY' or ref $data eq 'HASH') {
        return;
    }
    foreach my $d (ref $data eq 'ARRAY' ? @$data : values %$data) {
        if (ref $d eq 'ARRAY' or ref $d eq 'HASH') {
            remove_scalarref($d);
        } elsif (ref $d eq 'SCALAR') {
            $d = $$d;
        }
    }
}

# clone a data structure, stripping code references
sub clone_strip_coderef {
    my ($in) = @_;
    local $Storable::Deparse = 0;
    local $Storable::forgive_me = 1;
    local $SIG{__WARN__} = sub {};
    my $res = dclone $in;
    remove_scalarref $res;
    return $res;
}

sub last_days {
    my ($n) = @_;
    my $dt = DateTime->now;
    my @res;
    while ($n > 0) {
        push @res, scalar $dt->ymd;
        $dt -= DateTime::Duration->new(days => 1);
        $n--;
    }
    return @res;
}

1;
