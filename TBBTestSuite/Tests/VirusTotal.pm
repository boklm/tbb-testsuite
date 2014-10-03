package TBBTestSuite::Tests::VirusTotal;

use strict;
use Cwd;
use JSON;
use LWP::UserAgent;
use File::Slurp;
use File::Spec;
use File::Find;
use Digest::SHA qw(sha256_hex);
use Data::Dump qw(dd);
use TBBTestSuite::Options qw($options);

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(virustotal_run);
}

my %urls = (
    report => 'https://www.virustotal.com/vtapi/v2/file/report',
    scan   => 'https://www.virustotal.com/vtapi/v2/file/scan',
);

my $min_time = 15; # minimal time between requests (in seconds)
my $last_req = 0;
sub req {
    my ($ua, @args) = @_;
    if ($last_req && time - $last_req < $min_time) {
        sleep($min_time - (time - $last_req));
    }
    $last_req = time;
    my $r = $ua->post(@args);
    return "$r->code - $r->message" unless $r->is_success;
    my $res;
    eval {
        $res = JSON::decode_json $r->content;
    };
    return $res;
}

sub scan_file {
    my ($file) = @_;
    my $apikey = read_file($options->{'virustotal-api-key-file'});
    my (undef, undef, $filename) = File::Spec->splitpath($file);
    print "Checking $filename on virustotal\n";
    my $sha = sha256_hex(read_file($file));
    my $params_report = {
        resource => $sha,
        apikey => $apikey,
    };
    my $ua = LWP::UserAgent->new;
    my $r = req($ua, $urls{report}, $params_report);
    return $r if $r->{response_code};
    my $params_scan = {
        apikey => $apikey,
        file => [ $file, $filename ],
    };
    $r = req($ua, $urls{scan}, Content_Type => 'multipart/form-data',
                               Content => $params_scan);
    return $r unless $r->{response_code};
    my $retry = 20;
    while ($retry) {
        $retry--;
        sleep(30);
        $r = req($ua, $urls{report}, $params_report);
        return $r if $r->{response_code};
    }
    return $r;
}

sub virustotal_run {
    my ($tbbinfos, $test) = @_;
    return unless $options->{virustotal};
    my $files = {};
    $files->{$tbbinfos->{filename}} = scan_file($tbbinfos->{tbbfile});
    my $cwd = getcwd;
    my $scanfile = sub {
        my $file = $File::Find::name;
        return unless -f $file;
        return unless $file =~ m/\.exe$/;
        my $relative = $file;
        $relative =~ s/^$cwd\///;
        $files->{$relative} = scan_file($File::Find::name);
    };
    find($scanfile, $cwd);
    $test->{results}{files} = $files;
    $test->{results}{success} = 1;
    foreach my $file (keys %$files) {
        if (!$files->{$file}{response_code} || $files->{$file}{positives}) {
            $test->{results}{success} = 0;
        }
    }
}

1;
