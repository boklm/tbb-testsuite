package TBBTestSuite::Options;

use warnings;
use strict;
use FindBin;
use Getopt::Long;

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw($options);
}

my %default_options = (
    os       => 'Linux',
    arch     => 'x86_64',
    mozmill  => 1,
    selenium => 1,
    starttor => 1,
    gpgcheck => 1,
    keyring  => 'erinn.gpg',
    'tor-control-port' => '9551',
    'tor-socks-port'   => '9550',
    'reports-dir'      => "$FindBin::Bin/reports",
    virtualenv => "$FindBin::Bin/virtualenv",
    resolution => '1024x768',
    xvfb       => 1,
);


sub get_options {
    my @options = qw(mozmill! selenium! starttor! tor-control-port=i
                     tor-socks-port=i reports-dir=s gpgcheck! keyring=s
                     virtualenv=s xvfb! name=s download-dir=s);
    my %res = %default_options;
    Getopt::Long::GetOptionsFromArray(\@_, \%res, @options) || exit 1;
    $res{files} = \@_;
    return \%res;
}

our $options = get_options(@ARGV);

1;
