package TBBTestSuite::Tests;

use warnings;
use strict;
use English;
use FindBin;
use Cwd qw(getcwd);
use File::Spec;
use File::Temp;
use File::Slurp;
use LWP::UserAgent;
use YAML;
use TBBTestSuite::Common qw(exit_error);
use TBBTestSuite::Options qw($options);
use TBBTestSuite::BrowserBundleTests qw(tbb_filename_infos);
use TBBTestSuite::BrowserUnitTests;

our %testsuite_types = (
    browserunit => \%TBBTestSuite::BrowserUnitTests::testsuite,
    browserbundle => \%TBBTestSuite::BrowserBundleTests::testsuite,
);

sub run_tests {
    my ($tbbinfos) = @_;
    my @enable_tests = $options->{'enable-tests'}
                ? split(',', $options->{'enable-tests'}) : ();
    my $test_types = $testsuite_types{$tbbinfos->{type}}->{test_types};
    foreach my $test (@{$tbbinfos->{tests}}) {
        $test->{fail_type} //= 'error';
    }
    foreach my $test (@{$tbbinfos->{tests}}) {
        print "\n", '*' x (17 + length($test->{name})), "\n";
        print "* Running test $test->{name} *\n";
        print '*' x (17 + length($test->{name})), "\n\n";
        if (@enable_tests && !$test->{always}
            && ! grep { $test->{name} eq $_ } @enable_tests) {
            next;
        }
        if ($test->{enable} && !$test->{enable}->($tbbinfos, $test)) {
            next;
        }
        $test->{start_time} = time;
        $test->{pre}->($tbbinfos, $test) if $test->{pre};
        $test_types->{$test->{type}}->($tbbinfos, $test)
                if $test_types->{$test->{type}};
        $test->{post}->($tbbinfos, $test) if $test->{post};
        $test->{finish_time} = time;
        $test->{run_time} = $test->{finish_time} - $test->{start_time};
        if ($test->{fail_type} eq 'fatal' && is_test_error($test)) {
            last;
        }
    }
}

sub is_test_error {
    my ($test) = @_;
    if ($test->{fail_type} ne 'fatal' && $test->{fail_type} ne 'error') {
        return 0;
    }
    return $test->{results} && !$test->{results}{success};
}

sub is_test_warning {
    my ($test) = @_;
    return $test->{results} && $test->{fail_type} eq 'warning'
           && !$test->{results}{success};
}

sub is_success {
    my ($tests) = @_;
    foreach my $test (@$tests) {
        return 0 if is_test_error($test);
    }
    return 1;
}

sub check_known_issues {
    my ($tbbinfos) = @_;
    return unless $options->{known_issues};
    foreach my $test (@{$tbbinfos->{tests}}) {
        next unless $test->{results};
        next if $test->{results}{success};
        my $issue = $options->{known_issues}{$test->{name}};
        next unless $issue;
        $issue = $issue->($tbbinfos, $test) if ref $issue eq 'CODE';
        @{$test}{keys %$issue} = values %$issue;
    }
}

sub test_by_name {
    my ($tests, $name) = @_;
    foreach my $test (@$tests) {
        return $test if $test->{name} eq $name;
    }
    return undef;
}

sub matching_tbbfile {
    my $o = tbb_filename_infos($_[0]);
    return $o->{type} eq 'browserbundle' && $o->{os} eq $options->{os}
        && $o->{arch} eq $options->{arch};
}

sub check_gpgsig {
    my ($file) = @_;
    my $keyring = $options->{keyring} =~ m/^\// ? $options->{keyring}
        : "$FindBin::Bin/keyring/$options->{keyring}";
    return system('gpg', '--no-default-keyring', '--keyring', $keyring,
        '--verify', '--', $file) == 0;
}

sub test_sha {
    my ($report, $shafile) = @_;
    my $content;
    if ($shafile =~ m/^https?:\/\//) {
        my $ua = LWP::UserAgent->new;
        my $resp = $ua->get($shafile);
        exit_error "Error downloading $shafile:\n" . $resp->status_line
                unless $resp->is_success;
        $content = $resp->decoded_content;
        if ($options->{gpgcheck}) {
            $resp = $ua->get("$shafile.asc");
            exit_error "Error downloading $shafile.asc:\n" . $resp->status_line
                unless $resp->is_success;
            my $tmpdir = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
            write_file("$tmpdir/sha256sum.txt", $content);
            write_file("$tmpdir/sha256sum.txt.asc", $resp->decoded_content);
            exit_error "Error checking gpg signature of $shafile"
                unless check_gpgsig("$tmpdir/sha256sum.txt.asc");
        }
    } else {
        $content = read_file($shafile);
    }
    my (undef, $dir) = File::Spec->splitpath($shafile);
    my @files = map { [ reverse split /  /, $_ ] } split /\n/, $content;
    @files = grep { matching_tbbfile($_->[0]) } @files;
    foreach my $file (@files) {
        my $tbbinfos = tbb_filename_infos("$dir/$file->[0]");
        $tbbinfos->{sha256sum} = $file->[1];
        test_start($report, $tbbinfos);
    }
}

sub test_start {
    my ($report, $tbbinfos) = @_;
    my $oldcwd = getcwd;
    return test_sha($report, $tbbinfos->{tbbfile})
                if $tbbinfos->{type} eq 'sha256sum';
    my $tmpdir = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
    $tbbinfos->{tmpdir} = $tmpdir->dirname;
    $tbbinfos->{tests} //= [ map { { %$_ } } @TBBTestSuite::BrowserBundleTests::tests ];
    $tbbinfos->{'results-dir'} =
        "$options->{'report-dir'}/results-$tbbinfos->{filename}";
    mkdir $tbbinfos->{'results-dir'};
    my $testsuite = $testsuite_types{$tbbinfos->{type}};
    $testsuite->{pre_tests}($tbbinfos);
    $tbbinfos->{start_time} = time;
    run_tests($tbbinfos);
    $tbbinfos->{finish_time} = time;
    $tbbinfos->{run_time} = $tbbinfos->{finish_time} - $tbbinfos->{start_time};
    $testsuite->{post_tests}($tbbinfos);
    chdir $oldcwd;
    check_known_issues($tbbinfos);
    $tbbinfos->{success} = is_success($tbbinfos->{tests});
    $report->{tbbfiles}{$tbbinfos->{filename}} = $tbbinfos;
}

1;
