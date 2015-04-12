package TBBTestSuite::TestSuite::TestTestSuite;

use strict;
use parent 'TBBTestSuite::TestSuite';

my $test_types = {
    test_test => \&test_test,
};

sub description { 'Test Test suite' }

sub type { 'testtestsuite' };

sub test_types {
    $test_types;
}

sub new {
    my ($ts, $infos) = @_;
    my $testsuite = {
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
    };
    return bless $testsuite, $ts;
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

sub name {
    my ($tbbinfos) = @_;
    return $tbbinfos->{name};
}

1;
