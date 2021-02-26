package asicommon;

use lib '/root/libperl';
use Logger;


sub run {
    $mode    = shift;
    $command = shift;
    local $cmdlog=Logger->new();
    $cmdlog->logfile("/root/ASI/cmdlog");
    $cmdlog->setcols("USER",10);
    $cmdlog->setcols("SOURCE",25);
    $cmdlog->setcols("MESSAGE",60);
    if ( $mode eq "TEST" ) { $cmdlog->log("TEST ONLY $command") }
    if ( $mode eq "MEND" ) { $cmdlog->log("RUNNING   $command");
                             print("$command")                  }
}


sub archiveFile {
    local $file = shift;
    local ($second,$minute,$hour,$day,$month,
           $yearOffset,$dayOfWeek,$dayOfYear,$daylightSavings) = localtime();
           $yearOffset  += 1900;
    local  $processPID   = $$;

    local @file = split("/",$file);
    if ( $file[-1] !~ /^\./ ) { $file[-1] = ".$file[-1]" }
    local $newfile = join("/",@file);

    if ( $month  =~ /^\d$/ ) {$month  = "0$month"}
    if ( $day    =~ /^\d$/ ) {$day    = "0$day"}
    if ( $hour   =~ /^\d$/ ) {$hour   = "0$hour"}
    if ( $minute =~ /^\d$/ ) {$minute = "0$minute"}
    if ( $second =~ /^\d$/ ) {$second = "0$second"}

    local $archiveStamp = "${yearOffset}${month}${day}-${hour}${minute}${second}-${processPID}.asititan";
    local $newfile      = "$newfile-$archiveStamp";

    local $cmdlog=Logger->new();
    $cmdlog->logfile("/root/ASI/cmdlog");
    if ( $mode eq "MEND" ) {
        $cmdlog->log("ARCHIVING $file"); 
        system("/usr/bin/cp -p $file $newfile");
    }
}


1;
