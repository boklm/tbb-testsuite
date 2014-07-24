package TBBTestSuite::Reports;

use warnings;
use strict;
use FindBin;
use File::Temp;
use File::Path qw(make_path);
use File::Copy;
use Template;
use File::Spec;
use YAML;
use TBBTestSuite::Common qw(exit_error);
use TBBTestSuite::Options qw($options);
use TBBTestSuite::Tests;
use Email::Simple;
use Email::Sender::Simple qw(try_to_sendmail);

my %template_functions = (
    is_test_error => \&TBBTestSuite::Tests::is_test_error,
    is_test_warning => \&TBBTestSuite::Tests::is_test_warning,
);

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
        INCLUDE_PATH => "$FindBin::Bin/tmpl:$report->{options}{'report-dir'}",
        OUTPUT_PATH => $report->{options}{'report-dir'},
    );
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

sub make_reports_index {
    copy_static;
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
        %template_functions,
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

1;
