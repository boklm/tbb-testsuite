package TBBTestSuite::BrowserUnitTests;

use strict;
use IO::CaptureOutput qw(capture_exec);
use File::Spec;
use File::Find;

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
        filename => 'browser',
        test_types => $test_types,
        tests => [],
    );
    push @{$tbbinfos{tests}}, find_xpcshell_tests(\%tbbinfos);
    return \%tbbinfos;
}

sub pre_tests {
    my ($tbbinfos) = @_;
    chdir $tbbinfos->{browserdir};
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
        return if $dir =~ m/^obj-/;
        push @res, {
            name  => "xpcshell:$dir",
            type  => 'xpcshell',
            descr => "xpcshell test in directory $dir",
        };
    };
    find($wanted, $tbbinfos->{browserdir});
    return @res;
}

sub xpcshell_test {
    my ($tbbinfos, $test) = @_;
    my ($out, $err, $success) =
                capture_exec('./mach', 'xpcshell-test', $test->{name});
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
