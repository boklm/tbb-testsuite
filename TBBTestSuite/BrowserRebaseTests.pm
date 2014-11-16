package TBBTestSuite::BrowserRebaseTests;

use strict;
use File::Slurp;
use IO::CaptureOutput qw(capture_exec);
use TBBTestSuite::BrowserGit qw(git_clone_fetch get_commits_by_branch
                                parent_commit git_cmd git_cmd_ch);

my $test_types = {
    cherry_pick => \&cherry_pick,
};

our %testsuite = (
    description => 'Tor Browser rebase tests',
    test_types  => $test_types,
    pre_tests   => \&pre_tests,
    post_tests  => \&post_tests,
    pre_makereport => \&pre_makereport,
    pre_reports_index => \&pre_reports_index,
);

sub test_name {
    my ($commit) = @_;
    my ($res) = git_cmd_ch('git', 'show', '-s', '--abbrev=12',
                           '--format=%h-%f', $commit);
    return $res;
}

sub get_tbbinfos {
    my ($infos) = @_;
    git_clone_fetch;
    my %tbbinfos = (
        %$infos,
        type => 'browserrebase',
        filename => 'browser-rebase',
        tests => [],
    );
    my @commits = reverse get_commits_by_branch($infos->{tb_branch},
                                        $infos->{esr_branch});
    shift @commits;
    foreach my $commit (@commits) {
        my $test = {
            name => test_name($commit),
            type => 'cherry_pick',
            descr => "Cherry pick commit $commit\n",
            commit => $commit,
            retry => 1,
        };
        push @{$tbbinfos{tests}}, $test;
    }
    return \%tbbinfos;
}

sub pre_tests {
    my ($tbbinfos) = @_;
    chdir $TBBTestSuite::BrowserGit::clone_dir;
    git_cmd('git', 'clean', '-fx');
    git_cmd('git', 'checkout', '-f', '--detach');
    if (-f '.git/refs/heads/rebase-test') {
        print "Removing rebase-test branch\n";
        my ($out) = git_cmd('git', 'branch', '-D', 'rebase-test');
        print $out;
    }
    git_cmd('git', 'branch', '-f', 'rebase-test', 'gecko-dev/master');
    git_cmd('git', 'checkout', '-f', 'rebase-test');
}

sub post_tests {
    my ($tbbinfos) = @_;
}

sub pre_makereport {
}

sub pre_reports_index {
}

sub cherry_pick {
    my ($tbbinfos, $test) = @_;
    print "Rebase $test->{commit}\n";
    my ($out, $err, $success) = capture_exec('git', 'cherry-pick', '-Xpatience',
                                '--allow-empty', '--ff', $test->{commit});
    $test->{results}{success} = $success;
    if (!$success) {
        $test->{results}{git_out} = $out;
        $test->{results}{git_err} = $err;
        ($test->{results}{failed_diff}) = git_cmd_ch('git', 'diff');
        $test->{results}{success} = 1 unless $test->{results}{failed_diff};
        git_cmd('git', 'reset', '--hard');
    } else {
        my ($patch) = git_cmd_ch('git', 'format-patch', '--stdout', 'HEAD^');
        write_file("$tbbinfos->{'results-dir'}/$test->{name}.patch", $patch);
        $test->{results}{patch_file} = 1;
    }
}

1;
