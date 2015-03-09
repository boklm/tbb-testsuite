package TBBTestSuite::Options;

use warnings;
use strict;
use English;
use Config;
use FindBin;
use Getopt::Long;
use File::Slurp;
use TBBTestSuite::Common qw(exit_error has_bin);
use Data::Dump qw(pp);

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw($options);
}

sub get_os_name {
    my %os = (
        linux   => 'Linux',
        cygwin  => 'Windows',
        MSWin32 => 'Windows',
        darwin  => 'MacOSX',
    );
    return $os{$OSNAME} ? $os{$OSNAME} : 'Unknown';
}

sub get_arch {
    return 'x86_64' if $Config{archname} =~ m/^x86_64/;
    return 'x86';
}

my %default_options = (
    tmpdir   => "$FindBin::Bin/tmp",
    action   => 'run_tests',
    os       => get_os_name(),
    arch     => get_arch(),
    mozmill  => 1,
    selenium => $OSNAME ne 'cygwin',
    starttor => 1,
    gpgcheck => 1,
    clean_browserdir => 1,
    keyring  => 'erinn.gpg',
    'tor-control-port' => '9551',
    'tor-socks-port'   => '9550',
    'reports-dir'      => "$FindBin::Bin/reports",
    virtualenv => "$FindBin::Bin/virtualenv",
    resolution => '1280x1024',
    xvfb       => 0,
    xdummy     => $OSNAME ne 'cygwin',
    mbox       => has_bin('mbox'),
    virustotal => 0,
    newlayout  => 1,
    'virustotal-api-key-file' => "$ENV{HOME}/.virustotal.api-key",
    'email-to' => [],
    'email-from' => 'TBB Test Report <tbbtest@example.com>',
    'email-subject' => '[test result: [% success ? "ok" : "failed" %]] [% options.name %]',
    'mozmill-dir' => 'c:\tbbtestsuite\mozmill-env',
    'http-proxy-port' => '8888',
    test_data_url => 'http://test-data.tbb.torproject.org',
    test_data_url_https => 'https://test-data.tbb.torproject.org',
    test_data_dir => "$FindBin::Bin/test-data",
);


sub get_options {
    my @options = qw(mozmill! selenium! starttor! tor-control-port=i
                     tor-socks-port=i reports-dir=s gpgcheck! keyring=s
                     virtualenv=s xvfb! name=s download-dir=s config=s
                     action=s enable-tests=s upload-to=s os=s arch=s
                     virustotal! email-to=s@ email-from=s email-subject=s
                     mozmill-dir=s reports-url=s http-proxy-port=i
                     newlayout! mbox! xdummy! disable-tests=s);
    my (%cli, %config);
    Getopt::Long::GetOptionsFromArray(\@_, \%cli, @options) || exit 1;
    $cli{args} = \@_ if @_;
    if ($cli{config}) {
        my $cfile = $cli{config} =~ m/^\// ? $cli{config}
                        : "$FindBin::Bin/config/$cli{config}";
        exit_error "Can't find config file $cfile" unless -f $cfile;
        my $o = { %default_options, %cli };
        %config = eval('my $options = ' . pp($o) . "\n;" . read_file($cfile));
        exit_error "Error reading config file $cfile:\n$@" unless %config;
    }
    return { %default_options, %config, %cli };
}

our $options = get_options(@ARGV);

1;
