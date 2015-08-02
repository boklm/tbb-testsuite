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

sub git_cmd_noerr {
    my $oldcwd = getcwd;
    chdir $clone_dir || exit_error "Error entering directory $clone_dir";
    my @res = capture_exec(@_);
    chdir $oldcwd;
    return @res;
}

sub git_cmd {
    my @res = git_cmd_noerr(@_);
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

sub get_taggerdate {
    my ($tagname) = @_;
    my ($out) = git_cmd('git', 'for-each-ref', '--format=%(taggerdate:raw)',
                        "refs/tags/$tagname");
    my @r = split ' ', $out;
    return $r[0];
}

sub latest_tagged_version {
    my ($branch, $min_date) = @_;
    my ($d) = git_cmd('git', 'describe', '--long', '--match=tbb-*', $branch);
    my @t = split /-/, $d;
    pop @t;
    pop @t;
    my $tag = join('-', @t);
    my (undef, undef, $sig_ok) = git_cmd_noerr('git', 'tag', '-v', $tag);
    return () unless $sig_ok;
    if ($t[0] ne 'tbb' || @t != 3) {
        exit_error "Unknown tag format $tag";
    }
    if ($min_date && get_taggerdate($tag) < $min_date) {
        return ();
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
    my $two_weeks_ago = time - 1209600;
    foreach my $branch (branch_list) {
        my ($version, $build) = latest_tagged_version($branch, $two_weeks_ago);
        next unless $version;
        foreach my $user (@tbb_builders) {
            my $buildname;
            my $url = "https://people.torproject.org/~$user/builds/$version-$build/sha256sums-unsigned-build.txt";
            my $sha = get($url);
            if ($sha && head("$url.asc")) {
                $buildname = "$version-$build";
            } else {
                $url = "https://people.torproject.org/~$user/builds/$version/sha256sums-unsigned-build.txt";
                $sha = get($url);
                next unless $sha;
                next unless head("$url.asc");
                my $shasha = substr(sha256_hex($sha), 0, 5);
                $buildname = "$version-$shasha";
            }
            push @res, {
                buildname => $buildname,
                version => $version,
                build => $build,
                url => $url,
                user => $user,
            };
        }
    }
    return @res;
}

1;
