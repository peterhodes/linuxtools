#!/usr/bin/perl

use lib '/root/libperl';
use common qw(appendFile dirname Mkdir runit);
use ArgParser;

local $MyArgs=ArgParser->new();

$MyArgs->readargs;

my ($pingtarget,$null) = $MyArgs->getarg("pingtarget");
my ($pingcount,$null)  = $MyArgs->getarg("pingcount");
my ($log,$null)        = $MyArgs->getarg("logfile");

my @argstring = ("-c $pingcount $pingtarget");
my @output    = runit("ping",\@null,\@argstring);

my $pingstats = @output[-1];
my ($min,$avg,$max,$mdev) = (split('/',$pingstats))[3,4,5,6];
    $min  = (split(' = ',$min))[1];
    $mdev = (split(' ',$mdev))[0];
    if (! $avg) { $avg = "null" };

chomp(my $date = `date`);
my $logtext = "$date   $pingtarget  $avg\n";

if ($log) {
    if ( $log =~ /.*\/$/ ) { Mkdir($log); }
    if (-d $log) {
        $logfile = "$log/netmon-ping:$pingtarget";
    } else {
        $logfile = $log;
    }
    my $logdir = dirname("$logfile");
    appendFile($logfile,$logtext);
} else {
    print "$logtext";
}
