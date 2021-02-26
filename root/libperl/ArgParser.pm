package ArgParser;

# FILE          ArgParser.pm
# VERSION       1.01
# PURPOSE       Tool to aid the reading of command-line arguments (and configuration files).
# AUTHOR        Peter Rhodes.
# DATE          29/05/2014 (original circa 2012).
#
# RELEASE HISTORY  #####################################################################################################
########################################################################################################################
# Date          Version     Contributor      Comment
# 10/02/2020    1.02        Peter Rhodes     Updated getarg to stop hash query instantiating itself.
# 05/06/2014    1.01        Peter Rhodes     Added standard info template.
# 29/05/2014    1.1         Peter Rhodes     Tidy up. Implementation of Revert. Inclusion of trim.
#   /  /2013    1.0         Peter Rhodes     First Implementation based on code developed within scopetool.
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
#  There are two distinct purposes for ArgParser, although it could be used for both if desired.
#  The first is that it parses command line arguments into a hash within an object, and then provides methods that assist
#  with the retrieval and manipulation of those stored attributes.
#  The second is that it can parse a file. Fundamentally working in the same way.
#
#
#  ** METHODS
#  local $MyArgs=ArgParser->new();                          # Create Object.
#  (@arglist)      = $MyArgs->listargs;	                    # Return list of Arguments.
#  ($value,$count) = $MyArgs->getarg("argname");            # Return the Value and Count of a given Argument.
#  $MyArgs->printargs;                                      # Print Argument Data Structure - Primarily for DEBUG.
#  $MyArgs->delarg("argname");                              # Remove the argument named "argname".
#  $MyArgs->delargs;                                        # Remove ALL arguments.
#
#  ** METHODS (relating to reading command line arguments).
#  $MyArgs->readargs;                                       # Parse and Store the command line arguments into the Object.
#
#  ** METHODS (relating to reading a configuration file).
#  $MyArgs->argfile("/path/to/file");                       # Set the location of a rulefile.
#  $MyArgs->readfile                                        # Parse and Store the next line of the rulefile.
#  $MyArgs->readfile(17)                                    # Parse and Store the 17th line of the rulefile.
#
#
#  ** NOTES
#
#  1) Arguments defined by "=" can have any length.
#  2) Argument values can contain whitespace. The parser uses a lookahead
#     assertion and understands that "=" and "-" boundaries take precedence.
#  3) Repeating arguments increment the argument count value.
#  4) A "=" is used to define a value, however, a "-" indicates no value,
#     but will not overwrite a value that has already been set (see v above). 
#  5) The readfile method uses an internal counter so that when it is first called, it will read the first line of the file.
#     Each subsequent usage of the readfile method will update that counter so that the next line is read.
#     When counter reaches the end of the file, the method status will be a fail so that the method itself can be placed
#     inside a while loop in order to read each line (see example below).
#  6) readfile method with no argument auto increments internal read counter.
#     IF an argument is specified - IT DOES NOT.
#
#   ** EXAMPLE (reading command line arguments - file parsing works identically).
#
#  ./l v=test -vv k=more testing check=this -p
#  Sets the following arguments, values, and counts :
#	Arg	Value		Count.
#	v	test		3
#	k       more testing	1
#	check	this		1
#	p			1
#
#  ** EXAMPLE (of reading all arguments from a file)
#
#  local $MyArgs = ArgParser->new();
#  $MyArgs->argfile("/path/to/file");
#  while ($MyArgs->readfile) {
#      $MyArgs->printargs;
#      $MyArgs->delargs;
#  }


################################################################################
### %self = new()
### Object Constructor.
################################################################################
sub new {
    local $self              = {};
    $self->{ARGS}            = undef;
    $self->{ARGFILE}         = undef;
    $self->{ARGFILE_TOTAL}   = undef;
    $self->{ARGFILE_COUNTER} = undef;

    bless($self);
    return $self;
} # endsub new
################################################################################


################################################################################
### $lineCount = argfile(%self,$fileName)
### Set the location of the configuration file that will be parsed.
################################################################################
sub argfile {
    local $self       = shift;
    local $argfile    = shift;
    local $line_total = 0;
    local *FILE;

    if ( ! -f $argfile ) { return 0 };
    open (FILE, $argfile) or return 0;

    $line_total++ while (<FILE>);
    close (FILE);

    ${$self->{ARGFILE}}         = $argfile;
    ${$self->{ARGFILE_TOTAL}}   = $line_total;
    ${$self->{ARGFILE_COUNTER}} = 1;

    return $line_total;
}
################################################################################


################################################################################
### $status = readfile(%self,$lineNumber)
### Parse a line from a file, into the Argument Object.
### $status     1=success 0=fail
### %self       This Object.
### $lineNumber The line number to be parsed. If none is specified, then
###             the "current" line is read and counter is incremented.
################################################################################
sub readfile {
    local $self         = shift;
    local $user_counter = shift;
    local $argfile      = ${$self->{ARGFILE}};
    local $line_total   = ${$self->{ARGFILE_TOTAL}};
    local $line_counter = ${$self->{ARGFILE_COUNTER}};
    local $line_content = "";
    local $counter;
    local *FILE;

    if ( $user_counter ) {				
        $counter = $user_counter             # If $user_counter is set then use it !
    } else {						
        $counter = $line_counter             # Otherwise use the internal counter.
    }							
							
    ($counter <= $line_total) or return 0;   # If the counter has exceeded the line count
    open (FILE, $argfile) or return 0;       #  then we must quit and return 0 (fail).

    while(<FILE>) {                          # Read the appropriate line from the file.
        if ( $. == $counter) {				
            $line_content=$_; chomp $line_content;	
            last;					
        }						
    }							
							
    if ( ! $user_counter ) {                 # Only in the case that a line number was NOT specified,
        $line_counter++;                     #  should we increment the internal line counter.
        ${$self->{ARGFILE_COUNTER}} = $line_counter;	
    }							

    readargs($self,"$line_content");         # Let's parse the line.
    return 1;
}
################################################################################


################################################################################
### void = readargs(%self)
### void = readargs(%self,$lineContent)
### Parse a given line, into the Argument Object.
### %self        This Object.
### $lineContent Usually this will be NULL, and in that case the method
###               will read its arguments from @ARGV.
###              However, this method was redesigned so that it could be overloaded directly so that
###               it could be called from readargs with a line to be parsed. This completely eliminates
###               the necessity to write the parsing code again.
################################################################################
sub readargs {
    local $self=shift;
    local $arginput=shift;
    local $args=${$self->{ARGS}};
    local $arg,$value,@argsplit,$argsplit,$line;


    if ( ! $arginput ) {                                # If there is no argument then take it from @ARGV.
        $line="@ARGV";
    } else {
        $line=$arginput;
    }

    foreach $part (split('\s+(?=[a-z]+=|-)',$line)) { # Split on "-" or "=" that is preceeded by [a-z]+ that is itself preceeded by whitespace.
        ($arg,$value) =  split("=",$part,2);
        $flag_dash    =  grep(/^-/,$arg);             # flag=1 IF the arg starts with a "-"
        $flag_equal   =  grep(/=/,$part);             # flag=1 IF there is an "=" within the string.

        $arg          =~ s/\s+$//;                    # Remove whitespace from the end of the line.
        $arg          =~ s/\s*,\s*/,/g;               # Trim the spaces from comma seperated lists.
        $arg          =~ s/\s+/ /g;                   # Replace multiple whitespace with a single space.
        $arg          =~ s/^-+//g;                    # Remove leading "-" characters.

        if ( ( $flag_dash ) and ( ! $flag_equal ) ) { # When we get something like -lrt we want to split that into seperate flags, of one character each.
            @argsplit = split(//,$arg);
            @argsplit = grep(/[0-9a-zA-Z]/,@argsplit);
            foreach $argsplit (@argsplit) {
                if ( ! $args{$argsplit}{COUNT} ) {
                    $args{$argsplit}{COUNT} = 1;
                    } else {
                    $args{$argsplit}{COUNT}++;
                };
            } # endforeach
        } else {                                       # Everything else (not individual flags indicated by -lrt).
            $args{$arg}{VALUE} = $value;
            $args{$arg}{COUNT}++;
        } # endif

    } # endforeach

    ${$self->{ARGS}} = $args;
} # endsub readargs
################################################################################


################################################################################
### @argList = listargs(%self)
### List all arguments (but not their value or count).
################################################################################
sub listargs {
    local $self    = shift;
    local $args    = ${$self->{ARGS}};
    local $arg;
    local @arglist = ();

    foreach $arg (sort keys(%args)) {push @arglist,$arg}
    return  @arglist;
} # endsub listargs
################################################################################


################################################################################
### ($argValue,$argCount) = getarg(%self,$argName)
### Return the Value and Count of a given argument.
################################################################################
sub getarg {
    local $self  = shift;
    local $arg   = shift;
    local $args  = ${$self->{ARGS}};

    local $value = "";
    local $count = 0;

    if (exists $args{$arg}) {
        $value = $args{$arg}{VALUE};
        $count = $args{$arg}{COUNT};
    }

    return $value,$count;
} # endsub getarg
################################################################################


################################################################################
### void = delarg(%self,$argName)
### Delete a given argument.
################################################################################
sub delarg {
    local $self = shift;
    local $arg  = shift;
    local $args = ${$self->{ARGS}};

    ($arg) or return 0;
    delete $args{$arg};
    ${$self->{ARGS}}=$args;
} # endsub delarg
################################################################################


################################################################################
### void = delargs(%self)
### Delete all arguments. Useful when looping through a config file and
###  each line is to be read indepently of other lines.
################################################################################
sub delargs {
    local $self = shift;
    local $args = ${$self->{ARGS}};

    %args=();
    ${$self->{ARGS}} = $args;
}
################################################################################


################################################################################
### void = printargs(%self)
### Print each argument - it's name, it's value, and it's count.
### Useful for debugging.
################################################################################
sub printargs {
    local $self = shift;
    local $args = ${$self->{ARGS}};
    local $arg,$value,@arglist,$count;

    foreach $arg (sort keys(%args)) {
        $value  = $args{$arg}{VALUE};
        $count  = $args{$arg}{COUNT};
     
        print "Argument >$arg< Value >$value< Count >$count<\n";
    }
}
################################################################################


1;  # MODULE SUCCESS.
