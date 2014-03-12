package TBBTestSuite::Common;

use warnings;
use strict;
use IO::CaptureOutput qw(capture_exec);

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(exit_error system_infos);
}

sub exit_error {
    print STDERR "Error: ", $_[0], "\n";
    chdir '/';
    exit (exists $_[1] ? $_[1] : 1);
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
        $res{osname} = 'Linux';
    }
    return \%res;
}

1;
