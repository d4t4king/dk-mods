#!/usr/bin/perl
#
# Revision: 0.1
# Author: Peter Scordamaglia
# Email: pscordam@tampabay.rr.com
#
# Created: 6/19/05
# Last Modified: 6/19/05
#
#--------------------------REVISION 0.1-------------------------------
# first release :)
#---------------------------------------------------------------------
#
# Revision 0.2 # John Hysted
#
# Add code to handle turning collection on and off from the GUI
#
# Revision 0.3 # John Hysted # June 2011
#
# /usr/bin/sensors has moved and output format has changed
# Convert from temperature to fan monitoring
# expand to 7 fans
# single call to sensors
# now driven from the choices in the $prefs_file
#
# sensors_fan_chip='gl520sm'
# sensors_fan1_find='fan1'
# sensors_fan1_show=' CPU fan'
# sensors_fan2_find='fan2'
# sensors_fan2_show='Case fan'
#

#path to rrdtool database
$rrd = "/var/lib/rrd";

#path to rrdtool binary
$rrdtool = "/usr/bin/rrdtool";

# define location of images
my $img = '/httpd/html/rrdtool';

# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my $key = 'fan';
my %pgraphsset;
$pgraphsset{"$key"."_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

#----------------------------------------------------------------------
# Variables
#----------------------------------------------------------------------

# WARNING: These are overwritten from the preferences file if found
#
# list the sensor that shows/contains the right fan1: fan2: ONLY
# if you do not this script may have more sensors than really belong  
# null is OK if you only see one fan1: fan2: in the sensors output
#Change Sensor Names

# Each sensor pack on a particular MB have different names for each
# value
# Some boards do not have all these sensors and different boards
# may not call these sensors by the same name, so you will have to map the
# 'names' you see for your sensors to the ones used in this script.
# The left column is the name used by this script and is indicative of
# the data it is expecting to be stored in it.
# On the right side is name of your sensor. 
# Upper/Lower Case matters !!

$chipset_name = '';
%fan_name   = ( "fan1"  => "fan1",
 		"fan2"  => "fan2", 
		"fan3"  => "fan3", 
		"fan4"  => "fan4", 
		"fan5"  => "fan5", 
		"fan6"  => "fan6", 
		"fan7"  => "fan7", 
	        );
%fan_value  = ( "fan1"  => "U",
		"fan2"  => "U",
		"fan3"  => "U",
		"fan4"  => "U",
		"fan5"  => "U",
		"fan6"  => "U",
		"fan7"  => "U",
	        ) ;
%fan_graph  = ( "fan1"  => "",
		"fan2"  => "", 
		"fan3"  => "", 
		"fan4"  => "", 
		"fan5"  => "", 
		"fan6"  => "", 
		"fan7"  => "", 
	        );
%fan_colour = ( "fan1"  => "ffcc66",
		"fan2"  => "ff9900", 
		"fan3"  => "8da0cb", 
		"fan4"  => "e78ac3", 
		"fan5"  => "66c2a5", 
		"fan6"  => "e5c494",
		"fan7"  => "a6d854", 
		);

# are we collecting?

if ( $pgraphsset{$key."_collect"} eq "Y" ) {

# is there a named sensor ?

   if ( $pgraphsset{"sensors_".$key."chip"} ) {
        $chipset_name =  $pgraphsset{"sensors_".$key."_chip"};
   }
	
   for $j (sort(keys %fan_name)) {
# what name do we expect to see in the sensors output for temp1..temp7 ?
#
       if ( $pgraphsset{"sensors_".$j."_find"} ) {
          $fan_name{$j} =  $pgraphsset{"sensors_".$j."_find"};
       }

# what do we want to show on the graph for temp1..temp7 ?
# <empty> = do not show the line

       if ( $pgraphsset{"sensors_".$j."_show"} ) {
          $fan_graph{$j} =  $pgraphsset{"sensors_".$j."_show"};
      }
   }

#----------------------------------------------------------------------
# grab current fans
# I expect the output from sensors to look like this:
# fan1:        5555 RPM (stuff stuff stuff stuff)
# and look for the colon and the spaces
#----------------------------------------------------------------------
   open(OUT, "/usr/bin/sensors $chipset_name|")  or die "Could not run 'sensor'. did you install LM_SENSOR mod?\n";
   while(<OUT>) {
        $reply = $_;
        chomp($reply);
        print "$reply\n";
        if ($reply) { # is not null then
	   my @outer  = split(/:/,$reply);
           if ($outer[1]) { # is not null
	      my @fields = split(/ +/,$outer[1]);
	      for $i (sort(keys %fan_name)) {
                 if ( "$outer[0]" eq "$fan_name{$i}" ) {
                    $fan_value{ $i} = $fields[1];
                    print "info = $fan_value{$i} on '$fan_name{$i}'\n";
                 }
              }
	   }
        } 
   }
   close(OUT);

   $a = 0;
   for $j (sort(keys %fan_name)) {
      $final_value[$a] = $fan_value{$j};
      $a++;
   }

   &processfaninfo("$final_value[0]","$final_value[1]","$final_value[2]","$final_value[3]","$final_value[4]","$final_value[5]","$final_value[6]");

} else {
        print "$key is not collecting at present\n";
}

sub read_prefs
{
        my $filename = $_[0];
        my $hash = $_[1];
        my ($var, $val);
        if ( -r $filename ) {
                open(FILE, $filename);
                while (<FILE>) {
                        chomp;
                        ($var, $val) = split /=/, $_, 2;
                        if ($var) {
                                $val =~ s/^\'//g;
                                $val =~ s/\'$//g;
                                $hash->{$var} = $val;
                        }
                }
                close FILE;
        }
}

#----------------------------------------------------------------------
# Add information from each disk to rrdtool database
# inputs
# $_[0] = fan1
# $_[1] = fan2
# $_[2] = fan3
# $_[3] = fan4
# $_[4] = fan5
# $_[5] = fan6
# $_[6] = fan7
#----------------------------------------------------------------------
sub processfaninfo
{

        # make database if one isn't found, just storing averages for now

        if (! -e "$rrd/fan.rrd")
         {
                print "Building new database...\n";
                system("$rrdtool create $rrd/fan.rrd -s 300"
		." DS:fan1:GAUGE:600:0:U"
		." DS:fan2:GAUGE:600:0:U"
		." DS:fan3:GAUGE:600:0:U"
		." DS:fan4:GAUGE:600:0:U"
		." DS:fan5:GAUGE:600:0:U"
		." DS:fan6:GAUGE:600:0:U"
		." DS:fan7:GAUGE:600:0:U"
                ." RRA:AVERAGE:0.5:1:576 "
                ." RRA:AVERAGE:0.5:6:672 "
                ." RRA:AVERAGE:0.5:24:732 "
                ." RRA:AVERAGE:0.5:144:1460 ");
         }
        
        #print the current fans to the screen
        for $k (sort(keys %fan_name)) {
	   print "Values for $k test='$fan_name{$k}' value='$fan_value{$k}' graph='$fan_graph{$k}'\n";
 	}


        # insert values into the rrd database
`$rrdtool update $rrd/fan.rrd -t fan1:fan2:fan3:fan4:fan5:fan6:fan7 N:"$_[0]":"$_[1]":"$_[2]":"$_[3]":"$_[4]":"$_[5]":"$_[6]"`;

        # create graphs
##        &MakeGraph("hour");
        &MakeGraph("day");
        &MakeGraph("week");
        &MakeGraph("month");
        &MakeGraph("year");

}

#----------------------------------------------------------------------
# Build some nice graphs
# input
# $_[0] = hour,day,week,month, or year
#----------------------------------------------------------------------
sub MakeGraph
{
        my $cstring = "$rrdtool graph $img/fan-$_[0].png"
        ." -s \"-1$_[0]\""
        ." -t \"Fan Speeds over the last $_[0]\""
	." -r --units-exponent 0"
        ." -a PNG"
	." --lazy"
        ." -h 100 -w 500"
#	." --no-minor"
        ." -v \"RPM\""
	." DEF:fan1=$rrd/fan.rrd:fan1:AVERAGE"
        ." DEF:fan2=$rrd/fan.rrd:fan2:AVERAGE"    
        ." DEF:fan3=$rrd/fan.rrd:fan3:AVERAGE"    
        ." DEF:fan4=$rrd/fan.rrd:fan4:AVERAGE"    
        ." DEF:fan5=$rrd/fan.rrd:fan5:AVERAGE"    
        ." DEF:fan6=$rrd/fan.rrd:fan6:AVERAGE"    
        ." DEF:fan7=$rrd/fan.rrd:fan7:AVERAGE"    
        ;
        for $k (sort(keys %fan_name)) {
	   if ( $fan_graph{$k} ) {
	      $cstring = $cstring 
	      ." LINE2:$k#".$fan_colour{$k}.":\"".$fan_graph{$k}."\""
              ." GPRINT:$k:MAX:\" Max\\: %5.0lf\""
              ." GPRINT:$k:MIN:\"Min\\: %5.0lf\""
              ." GPRINT:$k:AVERAGE:\"Avg\\: %5.0lf\""
              ." GPRINT:$k:LAST:\"Current\\: %5.0lf RPM\\n\""
           }
        }
	
	#print $cstring."\n";
	system ($cstring);
}

