package Logger;
use common qw(getDate getTime truncate_string) ;

# BEGIN {
#     use Data::Dumper qw( Dumper ) ;
#     print Dumper(\%INC) ;
# }


# FILE		Logger.pm
# VERSION       1.2
# PURPOSE	Tool to aid logging.
# AUTHOR	Peter Rhodes.
# DATE          17/09/2014 (original circa 2012).
#
# RELEASE HISTORY  #####################################################################################################
########################################################################################################################
# Date          Version     Contributor      Comment
# 17/09/2014    1.2         Peter Rhodes     Zero-value colsize. 0 now indicates that the colsize has no fixed length.
# 29/05/2014    1.1         Peter Rhodes     Tidy up. Implementation of Revert. Inclusion of trim.
#   /  /2012    1.0         Peter Rhodes     First Implementation.
########################################################################################################################
########################################################################################################################
#
#        1         2         3         4         5         6         7         8         9         0         1         2
#23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
#
########################################################################################################################
#
#  DESCRIPTION
#
#  ** METHODS
#
#  local $mylog=Logger->new();
#  $mylog->logfile("/path/to/file");
#  $mylog->source("Source Name");				# If no argument is provided, the calling program is used.
#  $mylog->user("User Name");					# If no argument is provided, the unix user is used.
#  $mylog->setcols("DATE|PID|USER|SOURCE|MESSAGE",col_size);    # Default values are set in newcols()
#  $mylog->log("My message");					# Create log message in log file.
#
#  ** NOTES
#  1. The first argument of each method/function is the object itself. This is achieved using
#     a reference to a hash that stores the entire object. We use the variable name $self.
#  2. Each method instantiates local variables and then sets them back into the object.
#     This might seem unnecessary (why not work directly on the object itself), however
#     the purpose of this is to make the package more maintainable to those who are not
#     overly familiar with Perl OO and Package maintenance.


################################################################################
### new()
### Object Constructor.
################################################################################
sub new {
    local $self                         = {};
    $self->{LOGFILE}                    = undef;
    $self->{USER}                       = undef;
    $self->{COLS}			= undef;
    @{$self->{SOURCE}}			= ();
    $self->{CONFIG}			= undef;

    newcols($self);                       # Set the default col values.
    user($self);                          # Set the default user.
    source($self);                        # Set the default source.

    bless($self);
    return $self;
}
################################################################################


################################################################################
### newcols()
### Initialise the COLOUMN sizes for each field.
### Default values can be found here.
################################################################################
sub newcols {
    local $self      = shift;
    local $cols      = ${$self->{COLS}};
    local $config    = ${$self->{CONFIG}};

    $cols{DATE}      = 20;
    $cols{PID}       = 10;
    $cols{USER}      = 20;
    $cols{SOURCE}    = 40;
    $cols{MESSAGE}   = 40;

    $config{FIELD1}{COLS} = 20;
    $config{FIELD1}{JUSTIFY} = "left";


    ${$self->{COLS}} = $cols;
}
################################################################################


################################################################################
### logfile(str)
### Set the logfile property which indicates the path of the logfile.
################################################################################
sub logfile {
    local $self      = shift;
    local $logfile   = shift;
    $self->{LOGFILE} = $logfile;
}
################################################################################


################################################################################
### source(str)
### Set the source property.
### If no argument is given, the source defaults to the calling program name.
################################################################################
sub source {
    local $self   = shift;
    local $source = shift;

    ($source) or $source = (caller(0))[1]; # If no arg then set to calling program.
    local @sourceStack = @{$self->{SOURCE}};
    unshift(@sourceStack,$source);

    @{$self->{SOURCE}} = @sourceStack;
}


################################################################################
### sourceRevert()
### Revert to previous source property before the current one was set.
### When entering a function and changing the source value that change is permanent
###  and continues despite leaving the given function.
### The purpose of sourceRevert is that if placed at the end of such a function,
###  the previous value is set so that the calling function will continue to
###  accurately report the correct value prior to entering the new function.
### EXAMPLE : sub myFunction {
###               $myLog->source("New Source Name");
###               # FUNCTION BODY
###               $myLog->sourceRevert;
###            }
################################################################################
sub sourceRevert {
    local $self        = shift;
    local @sourceStack = @{$self->{SOURCE}};
    shift @sourceStack;
    @{$self->{SOURCE}} = @sourceStack;
}
################################################################################


################################################################################
### user(str)
### Set the user property.
### If no argument is given, the source defaults to the UNIX user running the program.
################################################################################
sub user {
    local $self      = shift;
    local $user      = shift;

    ($user) or $user = $ENV{LOGNAME} or $user = $ENV{USER} or $user = getpwuid($<);
                     # If user not set, then set to calling user.

    $self->{USER}    = $user;
}
################################################################################


################################################################################
### setcols(str,int)
### Change the coloumn size of a given coloumn type.
### Valid types are DATE,PID,USER,SOURCE,MESSAGE.
################################################################################
sub setcols {
    local $self      = shift;
    local $colname   = shift;                  # Arg1 : Coloumn Name
    local $colsize   = shift;                  # Arg2 : Coloumn Size
    local $cols      = ${$self->{COLS}};

    ($colname) or return 0;                     # Ensure colname is set.

    $cols{$colname}  = $colsize;
    ${$self->{COLS}} = $cols;
}
################################################################################


################################################################################
### log(str)
### Send a message to the Logfile (declared previously).
################################################################################
sub log {
    local $self        = shift;
    local $Message     = shift;
    local $Logfile     = $self->{LOGFILE};
    local $User        = $self->{USER};
    local $cols        = ${$self->{COLS}};
    local @sourceStack = @{$self->{SOURCE}};
    local $PID         = $$;

    local $date        = getDate();
    local $time        = getTime();
    local $tstamp      = "$date $time";
    local $Source      = $sourceStack[0];

    local $cDate       = $cols{DATE};
    local $cPid        = $cols{PID};
    local $cUser       = $cols{USER};
    local $cSrc        = $cols{SOURCE};
    local $cMsg        = $cols{MESSAGE};

    $Date              = truncate_string($Date,$cDate)   if ($cDate != 0);
    $PID               = truncate_string($PID,$cPid)     if ($cPID  != 0);
    $User              = truncate_string($User,$cUser)   if ($cUser != 0);
    $Source            = truncate_string($Source,$cSrc)  if ($cSrc  != 0);
    $Message           = truncate_string($Message,$cMsg) if ($cMsg  != 0);

    open   (LOG,">>$Logfile");
    #printf  LOG "%-${cDate}s %-${cPid}s %-${cUser}s %-${cSrc}s %-${cMsg}s\n",$tstamp,$PID,$User,$Source,$Message;
    printf  LOG "%-${cDate}s %-${cPid}s %-${cUser}s %-${cSrc}s %-s\n",$tstamp,$PID,$User,$Source,$Message;
    close  (LOG);
}
################################################################################

1;  # MODULE SUCCESS.
