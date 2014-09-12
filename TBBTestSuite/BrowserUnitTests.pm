package TBBTestSuite::BrowserUnitTests;

use strict;
use FindBin;
use IO::CaptureOutput qw(capture_exec);
use File::Spec;
use File::Find;
use File::Copy;
use File::Slurp;
use XML::LibXML '1.70';
use JSON;
use TBBTestSuite::Common qw(exit_error get_nbcpu run_to_file);
use TBBTestSuite::Reports qw(load_report);
use TBBTestSuite::Options qw($options);

my $test_types = {
    xpcshell => \&xpcshell_test,
    mochitest_plain => sub { mochitest_test('mochitest-plain', @_) },
    mochitest_chrome => sub { mochitest_test('mochitest-chrome', @_) },
    mochitest_browser => sub { mochitest_test('mochitest-browser', @_) },
    mochitest_a11y => sub { mochitest_test('mochitest-a11y', @_) },
    build_firefox => \&build_firefox,
};

our %testsuite = (
    description => 'Tor Browser unit tests',
    test_types  => $test_types,
    pre_tests   => \&pre_tests,
    post_tests  => \&post_tests,
    pre_makereport => \&pre_makereport,
    pre_reports_index => \&pre_reports_index,
);

sub get_tbbinfos {
    my ($infos) = @_;
    my %tbbinfos = (
        %$infos,
        type => 'browserunit',
        filename => "browser-$infos->{commit}",
        tests => [
            {
                name => 'build_firefox',
                type => 'build_firefox',
                fail_type => 'fatal',
                descr => 'Build Firefox',
            },
        ],
    );
    push @{$tbbinfos{tests}}, find_xpcshell_tests(\%tbbinfos);
    push @{$tbbinfos{tests}}, find_mochitest_tests(\%tbbinfos);
    return \%tbbinfos;
}

sub pre_tests {
    my ($tbbinfos) = @_;
    chdir $tbbinfos->{browserdir};
    if ($options->{clean_browserdir}) {
        system('git', 'clean', '-fxd');
        system('git', 'reset', '--hard');
    }
    system('git', 'checkout', $tbbinfos->{commit}) == 0
        or exit_error "Error checking out $tbbinfos->{commit}";
    my ($out, $err, $success) = capture_exec('git', 'show', '-s',
        '--abbrev=20', '--format=%p', $tbbinfos->{commit});
    exit_error "Error checking parents of $tbbinfos->{commit}" unless $success;
    $tbbinfos->{parent_commits} = [ split(' ', $out) ];
    ($out, $err, $success) = capture_exec('git', 'show', '-s',
        '--format=%s', $tbbinfos->{commit});
    exit_error "Error getting commit subject" unless $success;
    $tbbinfos->{commit_subject} = $out;
    ($out, $err, $success) = capture_exec('git', 'show', '-s',
        '--format=%an', $tbbinfos->{commit});
    exit_error "Error getting commit author" unless $success;
    $tbbinfos->{commit_author} = $out;
    my ($config_guess) = capture_exec('./build/autoconf/config.guess');
    chomp $config_guess;
    $tbbinfos->{topobjdir} = "obj-$config_guess";
}

sub post_tests {
}

sub tests_by_name {
    my ($tests) = @_;
    my %res = map { $_->{name} => $_ } @$tests;
    return \%res;
}

sub xpcshell_mochitest_subtests_diff {
    my ($t1, $t2) = @_;
    my (@fail, @fixed);
    my %f1 = ref $t1->{results}{failed} eq 'HASH' ?
                %{$t1->{results}{failed}}
               : map { $_ => 1 } @{$t1->{results}{failed}};
    my %f2 = ref $t2->{results}{failed} eq 'HASH' ?
                %{$t2->{results}{failed}}
               : map { $_ => 1 } @{$t2->{results}{failed}};
    my %f = ( %f1, %f2);
    foreach my $t (keys %f) {
        if ($f2{$t} && !$f1{$t}) {
            push @fail, $t;
        }
        if (!$f2{$t} && $f1{$t}) {
            push @fixed, $t;
        }
    }
    if (@fail or @fixed) {
        return { fail => \@fail, fixed => \@fixed };
    }
    return undef;
}

sub diff_results {
    my ($r1, $r2) = @_;
    my %res;
    $res{run_time} = $r2->{run_time} - $r1->{run_time};
    $res{fail_tests} = [];
    $res{fixed_tests} = [];
    $res{tests_time} = {};
    $res{subtests} = {};
    my $r1t = tests_by_name($r1->{tests});
    my $r2t = tests_by_name($r2->{tests});
    foreach my $test (keys %$r2t) {
        my ($t1, $t2) = ($r1t->{$test}, $r2t->{$test});
        if (defined $t2->{run_time} && defined $t1->{run_time}) {
            $res{tests_time}->{$test} = $t2->{run_time} - $t1->{run_time};
        }
        next unless defined $t1->{results};
        next unless defined $t2->{results};
        if (!$t2->{results}{success} && $t1->{results}{success}) {
            push @{$res{fail_tests}}, $test;
        }
        if ($t2->{results}{success} && !$t1->{results}{success}) {
            push @{$res{fixed_tests}}, $test;
        }
        if ($t1->{type} eq 'xpcshell' || $t1->{type} =~ m/^mochitest_/) {
            my $s = xpcshell_mochitest_subtests_diff($t1, $t2);
            $res{subtests}{$test} = $s if $s;
        }
    }
    return \%res;
}

sub pre_makereport {
    my ($report, $tbbfile, $r) = @_;
    my $tbbinfos = $report->{tbbfiles}{$tbbfile};
    foreach my $test (@{$tbbinfos->{tests}}) {
        mochitest_error_logs($test);
    }
    return unless $tbbinfos->{parent_results};
    $r //= TBBTestSuite::Reports::load_report($tbbinfos->{parent_results}[0]);
    return unless $r;
    my $parent = $r->{tbbfiles}{$tbbinfos->{parent_results}[1]};
    return unless $parent;
    $tbbinfos->{parent_diff} = diff_results($parent, $tbbinfos);
}

sub pre_reports_index {
    my ($reports, $report) = @_;
    foreach my $tbbfile (keys %{$report->{tbbfiles}}) {
        my $tbbinfos = $report->{tbbfiles}{$tbbfile};
        pre_makereport($report, $tbbfile,
                       $reports->{$tbbinfos->{parent_results}[0]})
                   if $tbbinfos->{parent_results};
        foreach my $test (@{$report->{tbbfiles}{$tbbfile}{tests}}) {
            mochitest_error_logs($test);
        }
    }
}

sub find_xpcshell_tests {
    my ($tbbinfos) = @_;
    my @res;
    my $wanted = sub {
        return unless -f $File::Find::name;
        my (undef, $dir, $file) = File::Spec->splitpath($File::Find::name);
        return unless $file eq 'xpcshell.ini';
        $dir =~ s{^$tbbinfos->{browserdir}/}{};
        $dir =~ s{/$}{};
        return if $dir =~ m/^obj-/;
        push @res, {
            name  => "xpcshell:$dir",
            type  => 'xpcshell',
            descr => "xpcshell test in directory $dir",
            dir   => $dir,
        };
    };
    find($wanted, $tbbinfos->{browserdir});
    return @res;
}

sub find_mochitest_tests {
    my ($tbbinfos) = @_;
    my @res;
    my $wanted = sub {
        return unless -f $File::Find::name;
        my (undef, $dir, $file) = File::Spec->splitpath($File::Find::name);
        return unless $file eq 'Makefile.in';
        $dir =~ s{^$tbbinfos->{browserdir}/}{};
        $dir =~ s{/$}{};
        return if $dir =~ m/^obj-/;
        my @makefile = read_file $File::Find::name;
        my @types;
        push @types, 'plain' if grep { m/MOCHITEST_FILES/ } @makefile;
        push @types, 'chrome' if grep { m/MOCHITEST_CHROME_FILES/ } @makefile;
        push @types, 'browser' if grep { m/MOCHITEST_BROWSER_FILES/ } @makefile;
        push @types, 'a11y' if grep { m/MOCHITEST_A11Y_FILES/ } @makefile;
        foreach my $type (@types) {
            push @res, {
                name => "mochitest-$type:$dir",
                type => "mochitest_$type",
                descr => "$type mochitest in directory $dir",
                dir => $dir,
            };
        }
    };
    find($wanted, $tbbinfos->{browserdir});
    return @res;
}

sub xpcshell_test {
    my ($tbbinfos, $test) = @_;
    my $xunit_file = "$tbbinfos->{topobjdir}/.mozbuild/xpchsell.xunit.xml";
    unlink $xunit_file if -f $xunit_file;
    my @xvfb = $options->{xvfb} ?
        ('xvfb-run', '--server-args=-screen 0 1024x768x24') : ();
    my ($out, $err, $success) =
                capture_exec(@xvfb, './mach', 'xpcshell-test', $test->{dir});
    return unless -f $xunit_file;
    $test->{results}{out} = $out;
    $test->{results}{failed} = {};
    my $root = eval {
        -f $xunit_file
                && XML::LibXML->load_xml(location => $xunit_file)
                              ->documentElement();
    };
    if (!$root) {
        $test->{results}{success} = 0;
        return;
    }
    $test->{results}{success} = ($root->getAttribute('failures') // 0)== 0;
    foreach my $testcase (@{$root->getChildrenByLocalName('testcase')}) {
        if ($testcase->getChildrenByLocalName('failure')) {
            $test->{results}{failed}{$testcase->getAttribute('name')} =
                            ($testcase->getChildrenByLocalName('failure'))[0]
                                                    ->textContent;
        }
    }
}

sub mochitest_test {
    my ($mach_command, $tbbinfos, $test) = @_;
    my $failures_file = "$tbbinfos->{topobjdir}/.mozbuild/mochitest_failures.json";
    unlink $failures_file if -f $failures_file;
    my @xvfb = $options->{xvfb} ?
        ('xvfb-run', '--server-args=-screen 0 1024x768x24') : ();
    my ($out, $err, $success) =
                capture_exec(@xvfb, './mach', $mach_command, $test->{dir});
    return unless -f $failures_file;
    $test->{results}{out} = $out;
    my $failed = eval { -f $failures_file
                && decode_json(scalar read_file($failures_file)) };
    $test->{results}{failed} = $failed ? [ keys %$failed ] : [];
    $test->{results}{success} = $failed && ! @{$test->{results}{failed}};
}

sub mochitest_error_logs {
    my ($test) = @_;
    return unless $test->{type} =~ m/^mochitest_/;
    return unless exists $test->{results};
    return unless $test->{results}{out};
    return if exists $test->{results}{error_logs};
    my @logs = split /^/, $test->{results}{out};
    @logs = grep { m/^\s*[^\s]+\s[^\s]+\sERROR/ } @logs;
    $test->{results}{error_logs} = join '', @logs;
}

sub build_firefox {
    my ($tbbinfos, $test) = @_;
    my $nbcpu = get_nbcpu;
    $test->{results}{success} = 0;
    copy("$FindBin::Bin/data/mozconfig", '.mozconfig');
    my @l = read_file('.mozconfig');
    foreach (@l) {
        s/MOZ_MAKE_FLAGS="-j4"/MOZ_MAKE_FLAGS="-j$nbcpu"/;
    }
    write_file('.mozconfig', @l);
    run_to_file("$tbbinfos->{'results-dir'}/$test->{name}.configure.txt",
        'make', '-f', 'client.mk', 'configure') or return;
    run_to_file("$tbbinfos->{'results-dir'}/$test->{name}.build.txt",
        'make', "-j$nbcpu", '-f', 'client.mk', 'build') or return;
    $test->{results}{success} = 1;
}

1;
