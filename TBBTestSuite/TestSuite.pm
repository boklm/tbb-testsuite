package TBBTestSuite::TestSuite;

use TBBTestSuite::TestSuites;
use Scalar::Util 'blessed';


sub new {
    my ($testsuite) = @_;
    return bless $testsuite;
}

sub load {
    my ($testsuite) = @_;
    my %ts = TBBTestSuite::TestSuites::testsuite_types();
    return bless $testsuite, "TBBTestSuite::TestSuite::$ts{$testsuite->{type}}";
}

sub type {
    die "No type";
}

sub description {
    die "No description";
}

sub name {
    undef;
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
