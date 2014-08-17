package TBBTestSuite::Tests::Command;

use strict;
use IO::CaptureOutput qw(capture_exec);
use TBBTestSuite::Common qw(get_var);

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(command_run file_known_issue);
}

sub command_run {
    my ($tbbinfos, $test) = @_;
    $test->{results}{success} = 1;
    my $files = get_var($test->{files}, $tbbinfos, $test);
    for my $file (@$files) {
        my ($out, $err, $success) = capture_exec(@{$test->{command}}, $file);
        if ($success && $test->{check_output}) {
            $success = $test->{check_output}($out);
        }
        if (!$success) {
            $test->{results}{success} = 0;
            $file =~ s/^$tbbinfos->{tbbdir}\///;
            push @{$test->{results}{failed}}, $file;
            next;
        }
    }
}

sub file_known_issue {
    my %files = @_;
    return sub {
        my ($tbbinfos, $test) = @_;
        my $failed;
        my %tickets;
        foreach my $file (@{$test->{results}{failed}}) {
            if ($files{$file}) {
                $tickets{$files{$file}} = 1;
            } else {
                $failed = 1;
            }
        }
        my %res;
        $res{fail_type} = 'known' unless $failed;
        $res{tickets} = [ keys %tickets ] if %tickets;
        return \%res;
    };
}

1;
