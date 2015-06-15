package TBBTestSuite::TestSuite::BrowserBundleVirusTotal;

use parent 'TBBTestSuite::TestSuite::BrowserBundleTests';

sub description {
    'Tor Browser Bundle Virustotal checks';
}

sub type {
    'browserbundle_virustotal';
}

sub new {
    my ($ts, $testsuite) = @_;
    return undef unless $testsuite->{os} eq 'Windows';
    $testsuite->{type} = 'browserbundle_virustotal';
    $testsuite->{tests} = [
        {
            name   => 'virustotal',
            type   => 'virustotal',
            descr  => 'Analyze files on virustotal.com',
        },
    ];
    return bless $testsuite;
}

1;
