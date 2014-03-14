package TBBTestSuite::Reports;

use warnings;
use strict;
use FindBin;
use File::Temp;
use File::Path qw(make_path);
use Template;
use File::Spec;
use YAML;
use TBBTestSuite::Common qw(exit_error);
use TBBTestSuite::Options qw($options);
use TBBTestSuite::Tests;

sub set_report_dir {
    my ($report) = @_;
    if ($report->{options}{name}) {
        $report->{options}{'report-dir'} = "$report->{options}{'reports-dir'}/$report->{options}{name}";
        make_path($options->{'report-dir'});
        return;
    }
    make_path($report->{options}{'reports-dir'});
    $report->{options}{'report-dir'} = File::Temp::newdir(
        'XXXXXX',
        DIR => $report->{options}{'reports-dir'},
        CLEANUP => 0)->dirname;
    (undef, undef, $report->{options}{name})
                = File::Spec->splitpath($report->{options}{'report-dir'});
}

sub make_report {
    my ($report) = @_;
    my $template = Template->new(
        ENCODING => 'utf8',
        INCLUDE_PATH => "$FindBin::Bin/tmpl",
        OUTPUT_PATH => $report->{options}{'report-dir'},
    );
    for my $page (qw(index.html screenshots.html)) {
        $template->process($page, $report, $page, binmode => ':utf8');
    }
    foreach my $tbbfile (keys %{$report->{tbbfiles}}) {
        $template->process('report.html', { %$report, tbbfile => $tbbfile },
                "$tbbfile.html", binmode => ':utf8')
                || exit_error "Template Error:\n" . $template->error;
    }
}

sub make_reports_index {
    my $template = Template->new(
        ENCODING => 'utf8',
        INCLUDE_PATH => "$FindBin::Bin/tmpl",
        OUTPUT_PATH => $options->{'reports-dir'},
    );
    my %reports;
    foreach my $dir (glob "$options->{'reports-dir'}/*") {
        my $resfile = "$dir/report.yml";
        next unless -f $resfile;
        my (undef, undef, $name) = File::Spec->splitpath($dir);
        $reports{$name} = YAML::LoadFile($resfile);
        $reports{$name}->{time} = 1 unless $reports{$name}->{time};
    }
    my @reports_by_time =
        sort { $reports{$b}->{time} <=> $reports{$a}->{time} } keys %reports;
    my $vars = {
        reports => \%reports,
        reports_by_time => \@reports_by_time,
    };
    $template->process('reports_index.html', $vars, 'index.html');
    $template->process('tests_index.html', { %$vars, tests =>
            \@TBBTestSuite::Tests::tests }, 'tests.html');
}

1;
