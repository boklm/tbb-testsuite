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
use TBBTestSuite::Reports;
use TBBTestSuite::Common qw(exit_error);
use TBBTestSuite::Options qw($options);
use TBBTestSuite::TestSuites;
use TBBTestSuite::TestSuite::BrowserBundleTests;
use TBBTestSuite::TestSuite::BrowserUnitTests;
use TBBTestSuite::XServer qw(set_Xmode);

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(tbb_filename_infos);
}

sub run_tests {
    my ($tbbinfos) = @_;
    my @enable_tests;
    if ($options->{'enable-tests'}) {
        @enable_tests = ref $options->{'enable-tests'} ?
                            @{$options->{'enable-tests'}}
                            : split(',', $options->{'enable-tests'});
    }
    my @disable_tests;
    if ($options->{'disable-tests'}) {
        @disable_tests = ref $options->{'disable-tests'} ?
                            @{$options->{'disable-tests'}}
                            : split(',', $options->{'disable-tests'});
    }
    my $test_types = $tbbinfos->test_types();
    foreach my $test (@{$tbbinfos->{tests}}) {
        $test->{fail_type} //= 'error';
    }
    foreach my $test (@{$tbbinfos->{tests}}) {
        if (@enable_tests && ! grep { $test->{name} eq $_ } @enable_tests) {
            next;
        }
        if (@disable_tests && grep { $test->{name} eq $_ } @disable_tests) {
            next;
        }
        if ($test->{enable} && !$test->{enable}->($tbbinfos, $test)) {
            next;
        }
        print "\n", '*' x (17 + length($test->{name})), "\n";
        print "* Running test $test->{name} *\n";
        print '*' x (17 + length($test->{name})), "\n\n";
        $test->{start_time} = time;
        if ($options->{xdummy} && $test->{resolution}) {
            set_Xmode($tbbinfos->{Xdisplay}, $test->{resolution});
        }
        $test->{pre}->($tbbinfos, $test) if $test->{pre};
        $test->{tried} = 0;
        while ($test->{tried} < ($test->{retry} // 2)) {
            $test->{tried} += 1;
            $test_types->{$test->{type}}->($tbbinfos, $test)
                if $test_types->{$test->{type}};
            if (!defined $test->{results} || $test->{results}{success}) {
                last;
            }
        }
        $test->{post}->($tbbinfos, $test) if $test->{post};
        if ($options->{xdummy} && $test->{resolution}) {
            set_Xmode($tbbinfos->{Xdisplay}, $options->{resolution});
        }
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

sub is_test_known {
    my ($test) = @_;
    return $test->{results} && $test->{fail_type} eq 'known'
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

sub tbb_filename_infos {
    my ($tbbfile) = @_;
    my (undef, undef, $file) = File::Spec->splitpath($tbbfile);
    my %res = (filename => $file, tbbfile => $tbbfile);
    if ($file =~ m/^tor-browser-linux(..)-([^_]+)_(.+)\.tar\.xz$/) {
        @res{qw(os version language)} = ('Linux', $2, $3);
        $res{arch} = $1 eq '64' ? 'x86_64' : 'x86';
    } elsif ($file =~ m/^torbrowser-install-([^_]+)_(.+)\.exe$/) {
        @res{qw(os arch version language)} = ('Windows', 'x86', $1, $2);
    } elsif ($file =~ m/^TorBrowserBundle-(.+)-osx32_(.+)\.zip$/) {
        @res{qw(os arch version language)} = ('MacOSX', 'x86', $1, $2);
    } else {
        return undef;
    }
    return $options->{virustotal} ?
        TBBTestSuite::TestSuite::BrowserBundleVirusTotal->new(\%res)
        : TBBTestSuite::TestSuite::BrowserBundleTests->new(\%res);
}


sub matching_tbbfile {
    my $o = tbb_filename_infos($_[0]);
    return $o && $o->{os} eq $options->{os} && $o->{arch} eq $options->{arch};
}

sub check_gpgsig {
    my ($file) = @_;
    my @kr_args;
    my @keyrings = ref $options->{keyring} eq 'ARRAY' ?
                        @{$options->{keyring}} : ($options->{keyring});
    print "keyrings\n";
    foreach my $keyring (@keyrings) {
        my $kr = $keyring =~ m/^\// ? $keyring : "$FindBin::Bin/keyring/$keyring";
        push @kr_args, '--keyring', $kr;
    }
    return system('gpg', '--no-default-keyring', @kr_args,
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
    my $tmpdir = File::Temp::newdir('XXXXXX', DIR => $options->{tmpdir});
    $tbbinfos->{tmpdir} = $tmpdir->dirname;
    $tbbinfos->{tests} //= [ map { { %$_ } } @TBBTestSuite::TestSuite::BrowserBundleTests::tests ];
    $tbbinfos->{'results-dir'} =
        TBBTestSuite::Reports::report_path($report,
                                        "results-$tbbinfos->{filename}");
    mkdir $tbbinfos->{'results-dir'};
    my %testsuite_infos = TBBTestSuite::TestSuites::testsuite_infos();
    my $testsuite = $testsuite_infos{$tbbinfos->{type}};
    $tbbinfos->pre_tests();
    $tbbinfos->{start_time} = time;
    run_tests($tbbinfos);
    $tbbinfos->{finish_time} = time;
    $tbbinfos->{run_time} = $tbbinfos->{finish_time} - $tbbinfos->{start_time};
    $tbbinfos->post_tests();
    chdir $oldcwd;
    check_known_issues($tbbinfos);
    $tbbinfos->{success} = is_success($tbbinfos->{tests});
    $report->{tbbfiles}{$tbbinfos->{filename}} = $tbbinfos;
}

1;
