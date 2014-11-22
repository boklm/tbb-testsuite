package TBBTestSuite::TestTestSuite;

use strict;

my $test_types = {
    test_test => \&test_test,
};

our %testsuite = (
    description => 'Tor Browser test testsuite',
    test_types  => $test_types,
    pre_tests   => \&pre_tests,
    post_tests  => \&post_tests,
    pre_makereport => \&pre_makereport,
    pre_reports_index => \&pre_reports_index,
);

sub get_tbbinfos {
    my ($infos) = @_;
    my %tbbinfos = (
        %$infos,
        type => 'testtestsuite',
        filename => 'testtestsuite',
        tests => [
            {
                name => 'first_test',
                type => 'test_test',
                r => 1,
            },
            {
                name => 'second_test',
                type => 'test_test',
                r => 0,
            },
            {
                name => 'warn_test',
                type => 'test_test',
                r => 0,
                fail_type => 'warning',
            },
        ],
    );
    return \%tbbinfos;
}

sub pre_tests {
    my ($tbbinfos) = @_;
    print "Test TestSuite pre tests\n";
}

sub post_tests {
    my ($tbbinfos) = @_;
    print "Test TestSuite post tests\n";
}

sub pre_makereport {
    print "Test TestSuite pre makereport\n";
}

sub pre_reports_index {
    print "Test TestSuite pre reports index\n";
}

sub test_test {
    my ($tbbinfos, $test) = @_;
    print "running test $test->{name}\n";
    $test->{results}{success} = $test->{r};
}

1;
