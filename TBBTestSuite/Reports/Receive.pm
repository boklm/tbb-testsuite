package TBBTestSuite::Reports::Receive;

use warnings;
use strict;
use YAML qw(LoadFile);
use File::Path qw(make_path);
use File::Temp;
use File::Copy;
use File::Slurp;
use FindBin;
use TBBTestSuite::Common qw(exit_error);
use TBBTestSuite::Options qw($options);

sub receive_report {
    my $tmpdir = File::Temp->newdir() || exit_error 'Error creating tmp dir';
    chdir $tmpdir || exit_error 'Error entering tmp directory';
    system('tar', '-xf', '-') && exit_error 'Error receiving files';
    exit_error 'Cannot find report.yml' unless -f 'report.yml';
    my $report = LoadFile('report.yml');
    chdir '/';
    my $name = $report->{options}{name};
    if (!$name || $name =~ m/\// || $name =~ m/^\./) {
        exit_error 'Invalid report name';
    }
    exit_error 'Report already exist' if -d "$options->{'reports-dir'}/r/$name";
    $tmpdir->unlink_on_destroy(0);
    system('mv', $tmpdir, "$options->{'reports-dir'}/r/$name");
}

sub update_authkeys {
    my $sshdir = "$ENV{HOME}/.ssh";
    if (!-d $sshdir) {
        make_path($sshdir);
        chmod 0700, $sshdir;
    }
    my $new_authkeys = '';
    my $config = $options->{config} ? " --config=$options->{config}" : '';
    foreach my $uploader (sort keys %{$options->{uploaders}}) {
        my $key = $options->{uploaders}{$uploader}{key};
        $new_authkeys .= "command=\"$FindBin::Bin/tbb-testsuite --action "
                . "receive_report$config\",no-X11-forwarding,"
                . "no-agent-forwarding,no-port-forwarding $key $uploader\n";
    }
    my $authkeys_file = "$sshdir/authorized_keys";
    my $old_authkeys = -f $authkeys_file ? read_file($authkeys_file) : '';
    write_file($authkeys_file, $new_authkeys) if $old_authkeys ne $new_authkeys;
    chmod 0600, $authkeys_file;
}

1;
