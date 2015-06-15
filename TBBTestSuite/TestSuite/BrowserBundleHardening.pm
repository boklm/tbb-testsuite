package TBBTestSuite::TestSuite::BrowserBundleHardening;

use TBBTestSuite::Tests::Command qw(command_run);

use parent 'TBBTestSuite::TestSuite::BrowserBundleTests';

sub description {
    'Tor Browser Bundle Hardening checks';
}

sub type {
    'browserbundle_hardening';
}

sub new {
    my ($ts, $testsuite) = @_;
    return undef unless $testsuite->{os} ne 'MacOSX';
    $testsuite->{type} = $ts->type();
    $testsuite->{tests} = [

        # Windows tests
        {
            name         => 'win_DEP_ASLR',
            type         => 'command',
            retry        => 1,
            descr        => 'Check DEP/ASLR',
            files        => \&TBBTestSuite::TestSuite::BrowserBundleTests::tbb_binfiles,
            command      => [ "$FindBin::Bin/data/check-windows-dep-aslr" ],
            enable       => sub { $_[0]->{os} eq 'Windows' },
        },

        # Linux Tests
        {
            name         => 'readelf_RELRO',
            fail_type    => 'warning',
            type         => 'command',
            retry        => 1,
            descr        => 'Check if binaries are RELocation Read-Only',
            files        => \&TBBTestSuite::TestSuite::BrowserBundleTests::tbb_binfiles,
            command      => [ 'readelf', '-ld' ],
            check_output => sub { ( $_[0] =~ m/GNU_RELRO/ )
                                        && ( $_[0] =~ m/BIND_NOW/ ) },
            enable       => sub { $_[0]->{os} eq 'Linux' },
        },
        {
            name         => 'readelf_stack_canary',
            fail_type    => 'warning',
            type         => 'command',
            retry        => 1,
            descr        => 'Check for stack canary support',
            files        => \&TBBTestSuite::TestSuite::BrowserBundleTests::tbb_binfiles,
            command      => [ 'readelf', '-s' ],
            check_output => sub { $_[0] =~ m/__stack_chk_fail/ },
            enable       => sub { $_[0]->{os} eq 'Linux' },
        },
        {
            name         => 'readelf_NX',
            type         => 'command',
            retry        => 1,
            descr        => 'Check for NX support',
            files        => \&TBBTestSuite::TestSuite::BrowserBundleTests::tbb_binfiles,
            command      => [ 'readelf', '-W', '-l' ],
            check_output => sub { ! ($_[0] =~ m/GNU_STACK.+RWE/) },
            enable       => sub { $_[0]->{os} eq 'Linux' },
        },
        {
            name         => 'readelf_PIE',
            type         => 'command',
            retry        => 1,
            descr        => 'Check for PIE support',
            files        => \&TBBTestSuite::TestSuite::BrowserBundleTests::tbb_binfiles,
            command      => [ 'readelf', '-h' ],
            check_output => sub { $_[0] =~ m/Type:\s+DYN/ },
            enable       => sub { $_[0]->{os} eq 'Linux' },
        },
        {
            name         => 'readelf_no_rpath',
            fail_type    => 'warning',
            type         => 'command',
            retry        => 1,
            descr        => 'Check for no rpath',
            files        => \&TBBTestSuite::TestSuite::BrowserBundleTests::tbb_binfiles,
            command      => [ 'readelf', '-d' ],
            check_output => sub { ! ( $_[0] =~ m/RPATH/ ) },
            enable       => sub { $_[0]->{os} eq 'Linux' },
        },
        {
            name         => 'readelf_no_runpath',
            type         => 'command',
            retry        => 1,
            descr        => 'Check for no runpath',
            files        => \&TBBTestSuite::TestSuite::BrowserBundleTests::tbb_binfiles,
            command      => [ 'readelf', '-d' ],
            check_output => sub { ! ( $_[0] =~ m/runpath/ ) },
            enable       => sub { $_[0]->{os} eq 'Linux' },
        },
    ];
    return bless $testsuite;
}

1;
