package TBBTestSuite::TestSuite::RBMBuild;

use strict;
use parent 'TBBTestSuite::TestSuite';

use TBBTestSuite::Common qw(exit_error run_to_file);
use IO::CaptureOutput qw(capture_exec);
use File::Path qw(make_path);

sub description {
    'rbm build';
}

sub type {
    'rbmbuild';
};

sub test_types {
    return {
        rbm_build => \&rbm_build,
    };
}

sub set_tests {
    die 'Need to be implemented';
}

sub new {
    my ($ts, $infos) = @_;
    my $testsuite = {
        %$infos,
        type => $ts->type(),
        filename => $ts->type(),
    };
    bless $testsuite, $ts;
    $testsuite->set_tests();
    return $testsuite;
}

sub rbm_build {
    my ($testsuite, $test) = @_;
    $test->{results}{success} = 0;
    my @cmd = ('./rbm/rbm', 'build', $test->{project});
    foreach my $target ($test->{targets} ? @{$test->{targets}} : ()) {
        push @cmd, '--target', $target;
    }
    if ($testsuite->{publish_dir}) {
        push @cmd, '--output-dir', "$testsuite->{publish_dir}/$test->{publish_dir}";
        $ENV{RBM_LOGS_DIR} = "$testsuite->{publish_dir}/$test->{publish_dir}/logs";
    }
    run_to_file("$testsuite->{'results-dir'}/$test->{name}.build.txt", @cmd)
        or return;
    $test->{results}{success} = 1;
}

sub reports_index_tmpl {
    return 'reports_index_rbmbuild.html';
}

1;
