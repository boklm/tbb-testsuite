package TBBTestSuite::TBBVersion;

use warnings;
use strict;
use FindBin;
use TBBTestSuite::Common qw(exit_error);
use Cwd qw(getcwd);
use File::Slurp;
use IO::CaptureOutput qw(capture_exec);
use LWP::Simple;
use Digest::SHA qw(sha256_hex);

my $options;
my $tbbgit_url = 'https://git.torproject.org/builders/tor-browser-bundle.git';
my @sign_users = ( 'mikeperry', 'gk', );
my @tbb_builders = ( 'mikeperry', 'gk', 'linus', 'erinn', 'boklm', );
my $clone_dir = "$FindBin::Bin/clones/tbb";

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

sub git_clone_pull {
    mkdir "$FindBin::Bin/clones" unless -d "$FindBin::Bin/clones";
    if (!-d $clone_dir) {
        system('git', 'clone', $tbbgit_url, $clone_dir) == 0
                || exit_error "Error cloning $tbbgit_url";
    }
    git_cmd('git', 'checkout', '--detach');
    git_cmd('git', 'fetch', '-p', 'origin', '+refs/heads/*:refs/heads/*');
}

sub set_gpgwrapper {
    my $keyring = '';
    foreach my $user (@sign_users) {
        $keyring .= " --keyring $FindBin::Bin/keyring/$user.gpg";
    }
    my $wrapper = <<EOF;
#!/bin/sh
set -e
exec gpg --no-default-keyring $keyring --trust-model always "\$@"
EOF
    my $wrapper_file = "$options->{tmpdir}/gpgtbbgit";
    write_file($wrapper_file, $wrapper);
    chmod 0700, $wrapper_file;
    git_cmd('git', 'config', '--replace-all', '--local',
                'gpg.program', $wrapper_file);
}

sub latest_tagged_version {
    my ($branch) = @_;
    my ($d) = git_cmd('git', 'describe', '--long', '--match=tbb-*', $branch);
    my @t = split /-/, $d;
    pop @t;
    pop @t;
    my $tag = join('-', @t);
    git_cmd('git', 'tag', '-v', $tag);
    if ($t[0] ne 'tbb' || @t != 3) {
        exit_error "Unknown tag format $tag";
    }
    return ($t[1], $t[2]);
}

sub branch_list {
    my $oldcwd = getcwd;
    chdir "$clone_dir/.git/refs/heads";
    my @res = glob '*';
    chdir $oldcwd;
    return @res;
}

sub latest_builds {
    $options = shift;
    my @res;
    git_clone_pull;
    set_gpgwrapper;
    foreach my $branch (branch_list) {
        my ($version, $build) = latest_tagged_version($branch);
        foreach my $user (@tbb_builders) {
            my $url = "https://people.torproject.org/~$user/builds/$version/sha256sums.txt";
            my $sha = get($url);
            next unless $sha;
            next unless head("$url.asc");
            my $shasha = sha256_hex($sha);
            push @res, {
                version => $version,
                build => $build,
                url => $url,
                user => $user,
                shasha => $shasha,
            };
        }
    }
    return @res;
}

1;
