package TBBTestSuite::BrowserGit;

use strict;
use FindBin;
use TBBTestSuite::Common qw(exit_error);
use Cwd qw(getcwd);
use IO::CaptureOutput qw(capture_exec);

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(git_clone_fetch get_commits_by_branch parent_commit
                    git_cmd git_cmd_ch);
}

my $torbrowsergit = 'https://git.torproject.org/tor-browser.git';
my $geckodevgit = 'https://github.com/mozilla/gecko-dev';
our $clone_dir = "$FindBin::Bin/clones/tor-browser";

sub git_cmd {
    my $oldcwd = getcwd;
    chdir $clone_dir || exit_error "Error entering directory $clone_dir";
    my @res = capture_exec(@_);
    chdir $oldcwd;
    if (!$res[2]) {
        exit_error 'Error running ' . join(' ', @_) . ":\n" . $res[1];
    }
    return @res;
}

sub git_cmd_ch {
    my (@res) = git_cmd(@_);
    chomp @res;
    chomp @res;
    return @res;
}

sub git_clone_fetch {
    mkdir "$FindBin::Bin/clones" unless -d "$FindBin::Bin/clones";
    if (!-d $clone_dir) {
        system('git', 'clone', $torbrowsergit, $clone_dir) == 0
                || exit_error "Error cloning $torbrowsergit";
    }
    git_cmd('git', 'checkout', '--detach', '-f');
    git_cmd('git', 'fetch', 'origin', '+refs/heads/*:refs/heads/*');
    my ($r) = git_cmd('git', 'remote');
    git_cmd('git', 'remote', 'add', 'gecko-dev', $geckodevgit)
        unless $r =~ m/^gecko-dev$/m;
    git_cmd('git', 'fetch', 'gecko-dev');
}

sub merge_base {
    my ($commit_a, $commit_b) = @_;
    my ($out) = git_cmd_ch('git', 'merge-base', $commit_a, $commit_b);
    return $out;
}

sub parent_commits {
    my ($c) = @_;
    my ($out) = git_cmd_ch('git', 'show', '-s', '--abbrev=20', '--format=%p', $c);
    return split(' ', $out);
}

sub get_commits {
    my ($commit, $commit_stop) = @_;
    my ($out) = git_cmd_ch('git', 'rev-list', '--topo-order',
                           "$commit_stop^..$commit");
    return split "\n", $out;
}

sub get_commits_by_branch {
    my ($tb_branch, $esr_branch) = @_;
    my $base = merge_base($tb_branch, "gecko-dev/$esr_branch");
    my ($commit) = git_cmd_ch('git', 'show', '-s', '--format=%H', $tb_branch);
    return get_commits($commit, $base);
}

1;
