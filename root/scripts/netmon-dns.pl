#!/usr/bin/perl

use lib '/root/libperl';
use common qw(appendFile dirname Mkdir runit);
use ArgParser;


local $MyArgs=ArgParser->new();
$MyArgs->readargs;

my ($queryserver,$null) = $MyArgs->getarg("queryserver");
my ($queryhost,$null)   = $MyArgs->getarg("queryhost");
my ($log,$null)         = $MyArgs->getarg("logfile");

my @argstring = ("\@${queryserver}","${queryhost}");
my @output    = runit("dig",\@null,\@argstring);

my @result = grep(/^${queryhost}.*IN.*A.*\d+\.\d+\.\d+\.\d+$/,@output);
my $ip     = (split(/\s+/,@result[0]))[-1];

chomp(my $date = `date`);

my $logtext = "$date   $queryserver  $queryhost  $ip\n";

if ($log) {
    if ( $log =~ /.*\/$/ ) { Mkdir($log); }
    if (-d $log) {
        $logfile = "$log/netmon-dns:$queryserver:$queryhost";
    } else {
        $logfile = $log;
    }
    my $logdir = dirname("$logfile");
    appendFile($logfile,$logtext);
} else {
    print "$logtext";
}








