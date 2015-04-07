package TBBTestSuite::GitRepo;

use strict;
use FindBin;
use TBBTestSuite::Common qw(exit_error);
use Cwd qw(getcwd);
use IO::CaptureOutput qw(capture_exec);

sub new {
    my ($gr, $infos) = @_;
    bless $infos, $gr;
}

sub clone_dir {
    my ($gr) = @_;
    return "$FindBin::Bin/clones/$gr->{name}";
}

sub cmd {
    my ($gr, @cmd) = @_;
    my $oldcwd = getcwd;
    chdir $gr->clone_dir()
        || exit_error "Error entering directory " . $gr->clone_dir();
    my @res = capture_exec(@cmd);
    chdir $oldcwd;
    if (!$res[2]) {
        exit_error 'Error running ' . join(' ', @cmd) . ":\n" . $res[1];
    }
    return @res;
}

sub cmd_ch {
    my (@res) = cmd(@_);
    chomp @res;
    chomp @res;
    return @res;
}

sub clone_fetch {
    my ($gr) = @_;
    mkdir "$FindBin::Bin/clones" unless -d "$FindBin::Bin/clones";
    if (!-d $gr->clone_dir()) {
        system('git', 'clone', $gr->{git_url}, $gr->clone_dir()) == 0
                || exit_error "Error cloning $gr->{git_ur}";
    }
    $gr->cmd('git', 'checkout', '--detach', '-f');
    $gr->cmd('git', 'fetch', 'origin', '+refs/heads/*:refs/heads/*');
}

1;
