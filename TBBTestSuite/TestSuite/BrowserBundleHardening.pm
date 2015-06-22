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
            # ticket 16417
            skip_files   => [ qw(
                TorBrowser/Tor/PluggableTransports/_ctypes.pyd
                TorBrowser/Tor/PluggableTransports/_hashlib.pyd
                TorBrowser/Tor/PluggableTransports/_socket.pyd
                TorBrowser/Tor/PluggableTransports/_ssl.pyd
                TorBrowser/Tor/PluggableTransports/bz2.pyd
                TorBrowser/Tor/PluggableTransports/Crypto.Cipher._AES.pyd
                TorBrowser/Tor/PluggableTransports/Crypto.Hash._SHA256.pyd
                TorBrowser/Tor/PluggableTransports/Crypto.Hash._SHA512.pyd
                TorBrowser/Tor/PluggableTransports/Crypto.Random.OSRNG.winrandom.pyd
                TorBrowser/Tor/PluggableTransports/Crypto.Util._counter.pyd
                TorBrowser/Tor/PluggableTransports/Crypto.Util.strxor.pyd
                TorBrowser/Tor/PluggableTransports/flashproxy-client.exe
                TorBrowser/Tor/PluggableTransports/flashproxy-reg-appspot.exe
                TorBrowser/Tor/PluggableTransports/flashproxy-reg-email.exe
                TorBrowser/Tor/PluggableTransports/flashproxy-reg-http.exe
                TorBrowser/Tor/PluggableTransports/flashproxy-reg-url.exe
                TorBrowser/Tor/PluggableTransports/fte.cDFA.pyd
                TorBrowser/Tor/PluggableTransports/fteproxy.exe
                TorBrowser/Tor/PluggableTransports/M2Crypto.__m2crypto.pyd
                TorBrowser/Tor/PluggableTransports/meek-client-torbrowser.exe
                TorBrowser/Tor/PluggableTransports/meek-client.exe
                TorBrowser/Tor/PluggableTransports/obfs4proxy.exe
                TorBrowser/Tor/PluggableTransports/obfsproxy.exe
                TorBrowser/Tor/PluggableTransports/pyexpat.pyd
                TorBrowser/Tor/PluggableTransports/python27.dll
                TorBrowser/Tor/PluggableTransports/select.pyd
                TorBrowser/Tor/PluggableTransports/terminateprocess-buffer.exe
                TorBrowser/Tor/PluggableTransports/unicodedata.pyd
                TorBrowser/Tor/PluggableTransports/w9xpopen.exe
                TorBrowser/Tor/PluggableTransports/zope.interface._zope_interface_coptimizations.pyd
                ) ],
        },

        # Linux Tests
        {
            name         => 'readelf_RELRO',
            type         => 'command',
            retry        => 1,
            descr        => 'Check if binaries are RELocation Read-Only',
            files        => \&TBBTestSuite::TestSuite::BrowserBundleTests::tbb_binfiles,
            command      => [ 'readelf', '-ld' ],
            check_output => sub { ( $_[0] =~ m/GNU_RELRO/ )
                                        && ( $_[0] =~ m/BIND_NOW/ ) },
            enable       => sub { $_[0]->{os} eq 'Linux' },
            skip_files   => [ qw(
                TorBrowser/Tor/PluggableTransports/meek-client
                TorBrowser/Tor/PluggableTransports/meek-client-torbrowser
                TorBrowser/Tor/PluggableTransports/meek-client-torbrowser
                TorBrowser/Tor/PluggableTransports/obfs4proxy
                ) ],

        },
        {
            name         => 'readelf_stack_canary',
            type         => 'command',
            retry        => 1,
            descr        => 'Check for stack canary support',
            files        => \&TBBTestSuite::TestSuite::BrowserBundleTests::tbb_binfiles,
            command      => [ 'readelf', '-s' ],
            check_output => sub { $_[0] =~ m/__stack_chk_fail/ },
            enable       => sub { $_[0]->{os} eq 'Linux' },
            # ticket 13056
            skip_files   => [ qw(
                libmozalloc.so
                libnssckbi.so
                libplc4.so
                libplds4.so
                TorBrowser/Tor/libstdc++.so.6
                TorBrowser/Tor/PluggableTransports/Crypto/Cipher/_ARC4.so
                TorBrowser/Tor/PluggableTransports/Crypto/Cipher/_XOR.so
                TorBrowser/Tor/PluggableTransports/Crypto/Util/_counter.so
                TorBrowser/Tor/PluggableTransports/fte/cDFA.so
                TorBrowser/Tor/PluggableTransports/meek-client-torbrowser
                TorBrowser/Tor/PluggableTransports/twisted/python/_initgroups.so
                TorBrowser/Tor/PluggableTransports/twisted/runner/portmap.so
                TorBrowser/Tor/PluggableTransports/twisted/test/raiser.so
                TorBrowser/Tor/PluggableTransports/zope/interface/_zope_interface_coptimizations.so
                ) ],
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
            skip_files   => [ qw(
                TorBrowser/Tor/PluggableTransports/meek-client
                TorBrowser/Tor/PluggableTransports/meek-client-torbrowser
                TorBrowser/Tor/PluggableTransports/obfs4proxy
                ) ],
        },
        {
            name         => 'readelf_no_rpath',
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
