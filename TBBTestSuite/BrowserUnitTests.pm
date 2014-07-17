package TBBTestSuite::BrowserUnitTests;

use strict;
use IO::CaptureOutput qw(capture_exec);
use File::Spec;
use File::Find;
use TBBTestSuite::Common qw(exit_error);

my $test_types = {
    xpcshell => \&xpcshell_test,
};

sub get_tbbinfos {
    my ($infos) = @_;
    my %tbbinfos = (
        %$infos,
        pre_tests => \&pre_tests,
        post_tests => \&post_tests,
        type => 'browser',
        filename => "browser-$infos->{commit}",
        test_types => $test_types,
        tests => [],
    );
    push @{$tbbinfos{tests}}, find_xpcshell_tests(\%tbbinfos);
    return \%tbbinfos;
}

sub pre_tests {
    my ($tbbinfos) = @_;
    chdir $tbbinfos->{browserdir};
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

1;
