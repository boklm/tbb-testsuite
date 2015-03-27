package TBBTestSuite::Reports;

use warnings;
use strict;
use English;
use FindBin;
use File::Temp;
use File::Path qw(make_path);
use File::Copy;
use File::Slurp;
use Template;
use File::Spec;
use JSON;
use YAML::Syck;
use TBBTestSuite::Common qw(exit_error as_array);
use TBBTestSuite::Options qw($options);
use TBBTestSuite::Tests;
use TBBTestSuite::TestSuites;
use Email::Simple;
use Email::Sender::Simple qw(try_to_sendmail);
use DateTime;

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(load_report report_dir report_path save_report);
}

my $screenshot_thumbnail;
BEGIN {
    # For some reason that I did not understand yet, Image::Magick does
    # not work on Windows, so we're not creating thumbnails if we're
    # on Windows. In that case, the thumbnails should be created by the
    # server that receives the results.
    if ($OSNAME ne 'cygwin') {
        require TBBTestSuite::Thumbnail;
        $screenshot_thumbnail = \&TBBTestSuite::Thumbnail::screenshot_thumbnail;
    } else {
        $screenshot_thumbnail = sub { };
    }
}

my %reports;
my %summaries;

my %template_functions = (
    is_test_error => \&TBBTestSuite::Tests::is_test_error,
    is_test_warning => \&TBBTestSuite::Tests::is_test_warning,
    is_test_known => \&TBBTestSuite::Tests::is_test_known,
    test_by_name => \&TBBTestSuite::Tests::test_by_name,
);

sub report_dir {
    my ($report) = @_;
    my $rdir = $options->{'reports-dir'} . '/r';
    make_path($rdir) unless -d $rdir;
    if ($report->{options}{name}) {
        my $reportdir = "$rdir/$report->{options}{name}";
        make_path($reportdir) unless -d $reportdir;
        return $reportdir;
    }
    my $reportdir = File::Temp::newdir(
        'XXXXXX',
        DIR => $rdir,
        CLEANUP => 0)->dirname;
    (undef, undef, $report->{options}{name})
                = File::Spec->splitpath($reportdir);
    return $reportdir;
}

sub report_path {
    report_dir($_[0]) . '/' . $_[1];
}

sub copy_static {
    my $staticdir = "$options->{'reports-dir'}/static";
    mkdir $staticdir unless -d $staticdir;
    foreach my $file_src (glob "$FindBin::Bin/static/*") {
        my (undef, undef, $file) = File::Spec->splitpath($file_src);
        my $file_dst = "$staticdir/$file";
        copy($file_src, $file_dst) unless -f $file_dst;
    }
}

sub make_report {
    my ($report) = @_;
    copy_static;
    my $template = Template->new(
        ENCODING => 'utf8',
        INCLUDE_PATH => "$FindBin::Bin/tmpl:" . report_dir($report),
        OUTPUT_PATH => report_dir($report),
    );
    foreach my $testsuite (values %{$report->{tbbfiles}}) {
        $testsuite->pre_makereport($report);
    }
    my %r = ( %template_functions, %$report );
    $template->process('screenshots.html', \%r, 'screenshots.html',
                       binmode => ':utf8');
    $template->process('testrun_report.html', \%r, 'index.html',
                       binmode => ':utf8');
    foreach my $tbbfile (keys %{$report->{tbbfiles}}) {
        $template->process('report.html', { %r, tbbfile => $tbbfile },
                "$tbbfile.html", binmode => ':utf8')
                || exit_error "Template Error:\n" . $template->error;
    }
}

sub report_type {
    my ($report) = @_;
    foreach my $tbbfile (values %{$report->{tbbfiles}}) {
        return 'browserbundle' if not defined $tbbfile->{type};
        return 'browserbundle' if $tbbfile->{type} eq 'tbbfile';
        return $tbbfile->{type};
    }
    return 'browserbundle';
}

sub date_month {
    my $dt = DateTime->from_epoch(epoch => $_[0]);
    return $dt->year . '-' . sprintf("%02d", $dt->month);
}

sub make_reports_index {
    my ($changed_report) = @_;
    my %pre_reports_index;
    my @changed_tags;
    my @changed_type;
    my @changed_month;
    if ($changed_report) {
        @changed_tags = $changed_report->{options}{tags} ?
                        @{$changed_report->{options}{tags}} : ();
        push @changed_type, report_type($changed_report);
        push @changed_month, date_month($changed_report->{time});
    }
    copy_static;
    my $template = Template->new(
        ENCODING => 'utf8',
        INCLUDE_PATH => "$FindBin::Bin/tmpl",
        OUTPUT_PATH => $options->{'reports-dir'},
    );
    foreach my $dir (glob "$options->{'reports-dir'}/r/*") {
        my $resfile = "$dir/report.yml";
        next unless -f $resfile;
        my (undef, undef, $name) = File::Spec->splitpath($dir);
        load_report_summary($name);
    }
    my @reports_by_time =
        sort { $reports{$b}->{time} <=> $reports{$a}->{time} } keys %reports;
    my %reports_by_tag;
    my %reports_by_type;
    my %reports_by_month;
    foreach my $report (keys %summaries) {
        my $type = $summaries{$report}->{type};
        push @{$reports_by_type{$type}}, $report;
        my $tags = as_array($summaries{$report}->{options}{tags} // []);
        foreach my $tag (@$tags) {
            push @{$reports_by_tag{$type}->{$tag}}, $report;
        }
        my $month = date_month($summaries{$report}->{time});
        push @{$reports_by_month{$type}->{$month}}, $report;
    }
    my %testsuite_infos = TBBTestSuite::TestSuites::testsuite_infos();
    my $vars = {
        %template_functions,
        reports => \%reports,
        reports_list => \@reports_by_time,
        reports_by_type => \%reports_by_type,
        reports_by_tag => \%reports_by_tag,
        reports_by_month => \%reports_by_month,
        testsuite_types => \%testsuite_infos,
    };
    $template->process('reports_index.html', $vars, 'index.html')
                || exit_error "Template Error:\n" . $template->error;
    foreach my $type ($changed_report ? @changed_type : keys %reports_by_type) {
        my @s = sort { $summaries{$b}->{time} <=> $summaries{$a}->{time} }
                @{$reports_by_type{$type}};
        @s = @s[0..19] if @s > 20;
        load_reports_for_index(\%pre_reports_index, @s);
        my $title = "Last 20 reports";
        my ($t) = values %{$reports{$s[0]}->{tbbfiles}};
        my $tmpl_file = $t->reports_index_tmpl();
        $template->process($tmpl_file,
          { %$vars, reports_list => \@s, title => $title }, "index-$type.html")
                || exit_error "Template Error:\n" . $template->error;
        $template->process('tests_index.html', { %$vars, testsuite_type => $type,
                tests => $t->{tests} }, "tests-$type.html")
                || exit_error "Template Error:\n" . $template->error;
    }
    foreach my $type ($changed_report ? @changed_type : keys %reports_by_tag) {
        foreach my $tag ($changed_report ? @changed_tags
                                : keys %{$reports_by_tag{$type}}) {
            my @s = sort { $summaries{$b}->{time} <=> $summaries{$a}->{time} }
                @{$reports_by_tag{$type}->{$tag}};
            load_reports_for_index(\%pre_reports_index, @s);
            my $title = "Reports for $tag";
            my ($t) = values %{$reports{$s[0]}->{tbbfiles}};
            my $tmpl_file = $t->reports_index_tmpl();
            $template->process($tmpl_file,
                    { %$vars, reports_list => \@s, title => $title, },
                    "index-$type-$tag.html")
                        || exit_error "Template Error:\n" . $template->error;
        }
    }
    foreach my $type ($changed_report ? @changed_type : keys %reports_by_month) {
        foreach my $month ($changed_report ? @changed_month
                                : keys %{$reports_by_month{$type}}) {
            my @s = sort { $summaries{$b}->{time} <=> $summaries{$a}->{time} }
                @{$reports_by_month{$type}->{$month}};
            load_reports_for_index(\%pre_reports_index, @s);
            my $title = "$month reports";
            my ($t) = values %{$reports{$s[0]}->{tbbfiles}};
            my $tmpl_file = $t->reports_index_tmpl();
            $template->process($tmpl_file,
                    { %$vars, reports_list => \@s, title => $title, },
                    "index-$type-$month.html")
                        || exit_error "Template Error:\n" . $template->error;
            }
    }
}

sub text_report {
    my ($report) = @_;
    my $res;
    my $template = Template->new(
        ENCODING => 'utf8',
        INCLUDE_PATH => "$FindBin::Bin/tmpl",
    );
    $template->process('testrun_report.txt', { %template_functions, %$report },
                        \$res, binmode => ':utf8')
                || exit_error "Template Error:\n" . $template->error;
    return $res;
}

sub email_report {
    my ($report) = @_;
    exit_error 'email-to is not defined' unless @{$report->{options}{'email-to'}};
    my ($subject, $body);
    my $template = Template->new(
        ENCODING => 'utf8',
        INCLUDE_PATH => "$FindBin::Bin/tmpl",
    );
    my %r = ( %template_functions, %$report );
    $template->process(\$report->{options}{'email-subject'}, \%r, \$subject,
                       binmode => ':utf8')
                || exit_error "Template Error:\n" . $template->error;
    $template->process('testrun_report.txt', \%r, \$body,
                       binmode => ':utf8')
                || exit_error "Template Error:\n" . $template->error;
    foreach my $email_to (@{$report->{options}{'email-to'}}) {
        my $email = Email::Simple->create(
            header => [
                From    => $report->{options}{'email-from'},
                To      => $email_to,
                Subject => $subject,
            ],
            body => $body,
        );
        if (!try_to_sendmail($email)) {
            print STDERR "Warning: Error sending email to $email_to\n";
        }
    }
}

sub load_report {
    my ($report_name) = @_;
    return $reports{$report_name} if exists $reports{$report_name};
    my $reportfile = "$options->{'reports-dir'}/r/$report_name/report.yml";
    return undef unless -f $reportfile;
    my $r = YAML::Syck::LoadFile($reportfile);
    foreach my $testsuite (values %{$r->{tbbfiles}}) {
        TBBTestSuite::TestSuite::load($testsuite);
    }
    return $reports{$report_name} = $r;
}

sub load_reports_for_index {
    my ($pre_reports_index, @reports) = @_;
    foreach my $rname (@reports) {
        my $r = load_report($rname);
        next if $pre_reports_index->{$rname};
        $pre_reports_index->{$rname} = 1;
        foreach my $testsuite (values %{$r->{tbbfiles}}) {
            $testsuite->pre_reports_index(\%reports, $reports{$rname});
        }
    }
}

sub load_report_summary {
    my ($report_name) = @_;
    return $summaries{$report_name} if exists $summaries{$report_name};
    my $summaryfile = "$options->{'reports-dir'}/r/$report_name/summary.json";
    if (!-f $summaryfile) {
        $summaries{$report_name} = report_summary(load_report($report_name));
        save_report_summary($reports{$report_name});
        return $summaries{$report_name};
    }
    return $summaries{$report_name} = decode_json read_file $summaryfile;
}

sub report_summary {
    my ($report) = @_;
    my %res = (
        type => report_type($report),
        time => 1,
    );
    foreach my $o (qw(report_format time success)) {
        $res{$o} = $report->{$o} if $report->{$o};
    }
    $res{options}->{tags} = $report->{options}{tags} // [];
    my $tbbver = $report->{options}{tbbversion};
    push @{$res{options}->{tags}}, $tbbver if $tbbver;
    return \%res;
}

sub save_report_summary {
    my ($report) = @_;
    write_file(report_path($report, 'summary.json'),
               encode_json(report_summary($report)));
}

sub save_report {
    my ($report) = @_;
    save_report_summary($report);
    YAML::Syck::DumpFile(report_path($report, 'report.yml'), $report);
}

sub generate_missing_thumbnails {
    my ($report) = @_;
    foreach my $tbbinfos (values %{$report->{tbbfiles}}) {
        $tbbinfos->{'results-dir'} =
                TBBTestSuite::Reports::report_path($report,
                                        "results-$tbbinfos->{filename}");
        foreach my $test (@{$tbbinfos->{tests}}) {
            next unless $test->{screenshots};
            foreach my $screenshot (@{$test->{screenshots}}) {
                $screenshot_thumbnail->($tbbinfos->{'results-dir'}, $screenshot);
            }
        }
    }
}

1;
