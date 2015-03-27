package TBBTestSuite::TestSuite;

use TBBTestSuite::TestTestSuite;
use TBBTestSuite::BrowserBundleTests;
use TBBTestSuite::BrowserBundleVirusTotal;
use TBBTestSuite::BrowserUnitTests;
use TBBTestSuite::BrowserRebaseTests;

use Scalar::Util 'blessed';

my @testsuite_list = qw(TestTestSuite BrowserBundleTests BrowserBundleVirusTotal
                        BrowserUnitTests BrowserRebaseTests);
my %testsuite_types;
sub testsuite_types {
    return %testsuite_types if %testsuite_types;
    foreach my $ts (@testsuite_list) {
        $testsuite_types{"TBBTestSuite::${ts}"->type()} = $ts;
    }
    return %testsuite_types;
}

sub testsuite_infos {
    my %testsuite_infos;
    foreach my $ts (@testsuite_list) {
        my $n = "TBBTestSuite::${ts}";
        $testsuite_infos{$n->type()} = {
            name => $n,
            type => $n->type(),
            description => $n->description(),
        };
    }
    return %testsuite_infos;
}

sub new {
    my ($testsuite) = @_;
    return bless $testsuite;
}

sub load {
    my ($testsuite) = @_;
    my %ts = testsuite_types;
    return bless $testsuite, "TBBTestSuite::$ts{$testsuite->{type}}";
}

sub type {
    die "No type";
}

sub description {
    die "No description";
}

sub pre_tests {
}

sub post_tests {
}

sub pre_makereport {
}

sub pre_reports_index {
}

sub reports_index_tmpl {
    my ($testsuite) = @_;
    my $type = $testsuite->type();
    return "reports_index_$type.html";
}

1;
