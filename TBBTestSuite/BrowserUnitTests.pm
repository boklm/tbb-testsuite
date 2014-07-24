package TBBTestSuite::BrowserUnitTests;

use strict;
use FindBin;
use IO::CaptureOutput qw(capture_exec);
use File::Spec;
use File::Find;
use File::Copy;
use File::Slurp;
use TBBTestSuite::Common qw(exit_error get_nbcpu run_to_file);
use TBBTestSuite::Reports qw(load_report);

my $test_types = {
    xpcshell => \&xpcshell_test,
    build_firefox => \&build_firefox,
};

our %testsuite = (
    test_types => $test_types,
    pre_tests  => \&pre_tests,
    post_tests => \&post_tests,
    pre_makereport => \&pre_makereport,
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
    return \%tbbinfos;
}

sub pre_tests {
    my ($tbbinfos) = @_;
    chdir $tbbinfos->{browserdir};
    system('git', 'clean', '-fxd');
    system('git', 'reset', '--hard');
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
}

sub post_tests {
}

sub tests_by_name {
    my ($tests) = @_;
    my %res = map { $_->{name} => $_ } @$tests;
    return \%res;
}

sub xpcshell_subtests_diff {
    my ($t1, $t2) = @_;
    my (@fail, @fixed);
    my %f1 = map { $_ => 1 } @{$t1->{results}{failed}};
    my %f2 = map { $_ => 1 } @{$t2->{results}{failed}};
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
        $res{tests_time}->{$test} = $t2->{run_time} - $t1->{run_time};
        next unless defined $t1->{results};
        next unless defined $t2->{results};
        if (!$t2->{results}{success} && $t1->{results}{success}) {
            push @{$res{fail_tests}}, $test;
        }
        if ($t2->{results}{success} && !$t1->{results}{success}) {
            push @{$res{fixed_tests}}, $test;
        }
        if ($t1->{type} eq 'xpcshell') {
            my $s = xpcshell_subtests_diff($t1, $t2);
            $res{subtests}{$test} = $s if $s;
        }
    }
    return \%res;
}

sub pre_makereport {
    my ($report, $tbbfile) = @_;
    my $tbbinfos = $report->{tbbfiles}{$tbbfile};
    return unless $tbbinfos->{parent_results};
    my $r = TBBTestSuite::Reports::load_report($tbbinfos->{parent_results}[0]);
    return unless $r;
    my $parent = $r->{tbbfiles}{$tbbinfos->{parent_results}[1]};
    return unless $parent;
    $tbbinfos->{parent_diff} = diff_results($parent, $tbbinfos);
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

sub xpcshell_test {
    my ($tbbinfos, $test) = @_;
    my ($out, $err, $success) =
                capture_exec('xvfb-run', '--server-args=-screen 0 1024x768x24',
                    './mach', 'xpcshell-test', $test->{dir});
    $test->{results}{success} = $success;
    $test->{results}{out} = $out;
    $test->{results}{failed} = [];
    foreach my $line (split "\n", $out) {
        if ($line =~ m{TEST-UNEXPECTED-FAIL \| /([^\|]+) \|}) {
            my (undef, undef, $file) = File::Spec->splitpath($1);
            push @{$test->{results}{failed}}, $file;
        }
    }
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
