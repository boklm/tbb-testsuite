package TBBTestSuite::TestSuites;

use strict;

use TBBTestSuite::TestSuite::TestTestSuite;
use TBBTestSuite::TestSuite::BrowserBundleTests;
use TBBTestSuite::TestSuite::BrowserBundleVirusTotal;
use TBBTestSuite::TestSuite::BrowserUnitTests;
use TBBTestSuite::TestSuite::BrowserRebaseTests;
use TBBTestSuite::TestSuite::RBMBuild;
use TBBTestSuite::TestSuite::TorMailBuild;
use TBBTestSuite::TestSuite::TorMessengerBuild;

my @testsuite_list = qw(TestTestSuite BrowserBundleTests BrowserBundleVirusTotal
                        BrowserUnitTests BrowserRebaseTests RBMBuild TorMailBuild
                        TorMessengerBuild);
my %testsuite_types;
sub testsuite_types {
    return %testsuite_types if %testsuite_types;
    foreach my $ts (@testsuite_list) {
        $testsuite_types{"TBBTestSuite::TestSuite::${ts}"->type()} = $ts;
    }
    return %testsuite_types;
}

sub testsuite_infos {
    my %testsuite_infos;
    foreach my $ts (@testsuite_list) {
        my $n = "TBBTestSuite::TestSuite::${ts}";
        $testsuite_infos{$n->type()} = {
            name => $n,
            type => $n->type(),
            description => $n->description(),
        };
    }
    return %testsuite_infos;
}

sub new_by_type {
    my ($type, $testsuite) = @_;
    my %ts = testsuite_types();
    return $ts{$type} ? "TBBTestSuite::TestSuite::$ts{$type}"->new($testsuite)
        : undef;
}

1;
