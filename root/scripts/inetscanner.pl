#!/usr/bin/perl

use lib '/root/libperl';
use common qw(appendFile dirname Mkdir);


local ($target,$count,$log) = @ARGV;
local $date = `date`; chomp $date ;
if (! defined $count ) { $count = 10 };
local $cmdString = "ping -c $count $target | tail -1";
local $cmdOutput = `$cmdString`; chomp $cmdOutput;
local ($min,$avg,$max,$mdev) = (split('/',$cmdOutput))[3,4,5,6];
       $min  = (split(' = ',$min))[1];
       $mdev = (split(' ',$mdev))[0];
       if (! $avg) { $avg = "null" };


if ($log) {
    if ( $log =~ /.*\/$/ ) { Mkdir($log); }
    if (-d $log) {
        $logfile = "$log/$target";
    } else {
        $logfile = $log;
    }
    local $logdir = dirname("$logfile");
    appendFile($logfile,"$date    $target    $avg","\n");
} else {
    print "$date    $target    $avg\n";
}

exit ;

