#!/usr/bin/perl

use lib '/root/libperl';
use common qw(readFile appendFile digit2);

sub scan {
    chomp(local @output = `nmap -n -sP 192.168.0.1/24`);
    @output = grep(!/^\s*$/,@output);
    @output = grep(!/^Starting Nmap/,@output);
    @output = grep(!/^Nmap done/,@output);
    return @output;
}

sub divmod {
    local $num = shift;
    local $div = shift;
    local $result = int($num/$div);
    local $modulo = $num % $div;
    return ($result,$modulo);
}

sub convertdhms {
    local $time = shift;
    local ($days,$hours,$mins,$secs,$dhms) = ();
    ($days ,$time) = divmod($time,86400);
    ($hours,$time) = divmod($time,3600);
    ($mins ,$time) = divmod($time,60);
    ($secs ,$time) = divmod($time,1);

    $days  = digit2($days);
    $hours = digit2($hours);
    $mins  = digit2($mins);
    $secs  = digit2($secs);

    $dhms = "$days:$hours:$mins:$secs";
    $dhms =~ s/^00://;
    $dhms =~ s/^00://;
    return $dhms;
}




local $logdir          = "/root/netlogs";
local $status_log      = "$logdir/status-log";
local $upStatus        = "$logdir/status-up";
local $downStatus      = "$logdir/status-down";
local $warnThreshold   = 300;
local $timeNow         = time;
local $aliasFile       = "/root/lib/netscanner.cfg";
local %alias           = ();

chomp(local $startdate = `date`);
local $date            = $startdate;
local @output          = scan();
local $ip              = '';
local $mac             = '';
local %uphash          = ();
local %downhash        = ();
local %newhash         = ();
local $thislogfile     = "$logdir/netscanner.log";



foreach $dir (qw(by-ip by-mac by-alias status-log status-up status-down)) {
    if (! -d "$logdir/$dir") { system("mkdir -p $logdir/$dir") }
}


## CREATE ALIAS MAP
local @aliasOutput = readFile($aliasFile);
      @aliasOutput = grep(!/^\s*$/,@aliasOutput);
      @aliasOutput = grep(!/^\s#/, @aliasOutput);
foreach my $line (@aliasOutput) {
    local ($mac,$alias) = ((split('\s+',$line))[0,1]);
    if ( ($mac) and ($alias) ) {
        $alias{$mac} = $alias;
    }
}


## CREATE STATUS MAPS
foreach my $string (`ls $upStatus`)   { chomp($string); $uphash{"$string"}   = "$string" };
foreach my $string (`ls $downStatus`) { chomp($string); $downhash{"$string"} = "$string" };


foreach $line (@output) {
    if ( $line =~ m/^Nmap scan/ ) {
        $ip =  $line;
        $ip =~ s/Nmap scan report for //;
    }
    if ( $line =~ m/^MAC Address/ ) {
        $mac =  $line;
        $mac =  (split('\s+',$mac))[2];
    }
    if ( $line =~ m/^MAC Address/ ) {
        local $alias = $alias{"$mac"};
        if ( $alias eq "" ) { $alias = "unknown" };
        $logstring = "$date  $ip  $mac  $alias";
#        if ($ip)    { system("echo $logstring >> $logdir/by-ip/$ip"      )  }
        if ($ip)    { appendFile("$logdir/by-ip/$ip","$logstring","\n"         )  }
#        if ($mac)   { system("echo $logstring >> $logdir/by-mac/$mac"    )  }
        if ($mac)   { appendFile("$logdir/by-mac/$mac","$logstring","\n"         )  }
#        if ($alias) { system("echo $logstring >> $logdir/by-alias/$alias");
#                      $newhash{"$alias"} = "$alias"                         }
        if ($alias) { appendFile("$logdir/by-alias/$alias","$logstring","\n");
                      $newhash{"$alias"} = "$alias"                         }

        $ip    = "";
        $mac   = "";
        $alias = "";
    }
}





foreach my $key (keys(%uphash)) {
    if (! exists $newhash{$key}) {
        local $timeLast = (stat("$upStatus/$key"))[9];
        local $timeDiff = $timeNow - $timeLast;
        if ( $timeDiff >= $warnThreshold ) {
            local $timeUP   = (split(" ",(readFile("$status_log/$key"))[-1]))[0];
            local $duration = $timeNow - $timeUP;
            local $dhms     = convertdhms($duration);
            local $string   = "$timeNow :: DOWN :: $date ... Status DOWN ... UP duration $dhms";

            system("touch $upStatus/$key");
            system("mv $upStatus/$key $downStatus/$key");
            appendFile("$status_log/$key","$string","\n");
        }
    }
}


foreach my $key (keys(%newhash)) {
    if (exists $downhash{$key}) {
        local $timeDOWN = (split(" ",(readFile("$status_log/$key"))[-1]))[0];
        local $duration = $timeNow - $timeDOWN;
        local $dhms     = convertdhms($duration);
        local $string   = "$timeNow :: UP   :: $date ... Status UP ... DOWN duration $dhms";

        system("touch $downStatus/$key");
        system("mv $downStatus/$key $upStatus/$key");
        appendFile("$status_log/$key","$string","\n");
    }
    if ( (! exists $downhash{$key}) and (! exists $uphash{$key}) ) {
        local $string = "$timeNow :: NEW  :: $date ... Status NEW";
        system("touch $upStatus/$key");
        appendFile("$status_log/$key","$string","\n");
    }
}





local $enddate     = `date`; chomp($enddate);
appendFile("$thislogfile","$startdate  ...  $enddate","\n");
