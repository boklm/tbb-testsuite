package TBBTestSuite::Reports::Send;

use warnings;
use strict;
use TBBTestSuite::Common qw(exit_error);
use TBBTestSuite::Options qw($options);

sub send_report {
    exit_error 'No report name specified' unless $options->{name};
    exit_error 'No destination specified' unless $options->{'upload-to'};
    my $report_dir = "$options->{'reports-dir'}/r/$options->{name}";
    chdir $report_dir || exit_error 'Error accessing report dir';
    system("tar cf - . | ssh -T $options->{'upload-to'}");
}

1;
