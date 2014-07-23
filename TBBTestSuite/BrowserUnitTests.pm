package TBBTestSuite::BrowserUnitTests;

use strict;
use FindBin;
use IO::CaptureOutput qw(capture_exec);
use File::Spec;
use File::Find;
use File::Copy;
use TBBTestSuite::Common qw(exit_error get_nbcpu run_to_file);

my $test_types = {
    xpcshell => \&xpcshell_test,
    build_firefox => \&build_firefox,
};

sub get_tbbinfos {
    my ($infos) = @_;
    my %tbbinfos = (
        %$infos,
        pre_tests => \&pre_tests,
        post_tests => \&post_tests,
        type => 'browserunit',
        filename => "browser-$infos->{commit}",
        test_types => $test_types,
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
                capture_exec('./mach', 'xpcshell-test', $test->{dir});
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
    $test->{results}{success} = 0;
    copy("$FindBin::Bin/data/mozconfig", '.mozconfig');
    run_to_file("$tbbinfos->{'results-dir'}/$test->{name}.configure.txt",
        'make', '-f', 'client.mk', 'configure') or return;
    run_to_file("$tbbinfos->{'results-dir'}/$test->{name}.build.txt",
        'make', '-j' . get_nbcpu, '-f', 'client.mk', 'build') or return;
    $test->{results}{success} = 1;
}

1;
