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
    my $rdir = $report->{options}{'reports-dir'} . '/r';
    if ($report->{options}{name}) {
        $report->{options}{'report-dir'} = "$rdir/$report->{options}{name}";
        make_path($options->{'report-dir'});
        return;
    }
    make_path($rdir);
    $report->{options}{'report-dir'} = File::Temp::newdir(
        'XXXXXX',
        DIR => $rdir,
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
    $template->process('screenshots.html', $report, 'screenshots.html',
                       binmode => ':utf8');
    $template->process('testrun_report.html', $report, 'index.html',
                       binmode => ':utf8');
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
    foreach my $dir (glob "$options->{'reports-dir'}/r/*") {
        my $resfile = "$dir/report.yml";
        next unless -f $resfile;
        my (undef, undef, $name) = File::Spec->splitpath($dir);
        $reports{$name} = YAML::LoadFile($resfile);
        $reports{$name}->{time} = 1 unless $reports{$name}->{time};
    }
    my @reports_by_time =
        sort { $reports{$b}->{time} <=> $reports{$a}->{time} } keys %reports;
    my %reports_by_tbbversion;
    foreach my $report (keys %reports) {
        my $tbbver = $reports{$report}->{options}{tbbversion};
        push @{$reports_by_tbbversion{$tbbver}}, $report if $tbbver;
    }
    my $vars = {
        reports => \%reports,
        reports_list => \@reports_by_time,
    };
    $template->process('reports_index.html', $vars, 'index.html');
    $template->process('tests_index.html', { %$vars, tests =>
            \@TBBTestSuite::Tests::tests }, 'tests.html');
    foreach my $tbbver (keys %reports_by_tbbversion) {
        my @s = sort { $reports{$b}->{time} <=> $reports{$a}->{time} }
                @{$reports_by_tbbversion{$tbbver}};
        $template->process('reports_index.html',
            { %$vars, reports_list => \@s }, "tbbversion_$tbbver.html");
    }
}

1;
