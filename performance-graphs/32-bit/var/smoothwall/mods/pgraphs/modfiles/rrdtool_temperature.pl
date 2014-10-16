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
# expand to 7 temps
# single call to sensors
# now driven from the choices in the $prefs_file
# sensors_temperature_chip='gl520sm'
# sensors_temp1_find='temp1'
# sensors_temp1_show=' CPU temperature'
# sensors_temp2_find='temp2'
# sensors_temp2_show='Case temperature'

#path to rrdtool database
$rrd = "/var/lib/rrd";

#path to rrdtool binary
$rrdtool = "/usr/bin/rrdtool";

# define location of images
my $img = '/httpd/html/rrdtool';

# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my $key = 'temperature';
my %pgraphsset;
$pgraphsset{"$key"."_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

#----------------------------------------------------------------------
# Variables
#----------------------------------------------------------------------

# WARNING: These are overwritten from the preferences file if found
#
# list the sensor that shows/contains the right temp1: temp2: ONLY
# if you do not this script may have more sensors than really belong  
# null is OK if you only see one temp1: temp2: in the sensors output
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
%temp_name   = ( "temp1"  => "temp1",
 		 "temp2"  => "temp2", 
		 "temp3"  => "temp3", 
		 "temp4"  => "temp4", 
		 "temp5"  => "temp5", 
		 "temp6"  => "temp6", 
		 "temp7"  => "temp7", 
	        );
%temp_value  = ( "temp1"  => "U",
		 "temp2"  => "U",
		 "temp3"  => "U",
		 "temp4"  => "U",
		 "temp5"  => "U",
		 "temp6"  => "U",
		 "temp7"  => "U",
	        ) ;
%temp_graph  = ( "temp1"  => "",
		 "temp2"  => "", 
		 "temp3"  => "", 
		 "temp4"  => "", 
		 "temp5"  => "", 
		 "temp6"  => "", 
		 "temp7"  => "", 
	        );
%temp_colour = ( "temp1"  => "ffcc66",
		 "temp2"  => "ff9900", 
		 "temp3"  => "8da0cb", 
		 "temp4"  => "e78ac3", 
		 "temp5"  => "66c2a5", 
		 "temp6"  => "e5c494",
		 "temp7"  => "a6d854", 
		);

# are we collecting?

if ( $pgraphsset{$key."_collect"} eq "Y" ) {

# is there a named sensor ?

   if ( $pgraphsset{"sensors_".$key."chip"} ) {
        $chipset_name =  $pgraphsset{"sensors_".$key."_chip"};
   }

   for $j (sort(keys %temp_name)) {
# what name do we expect to see in the sensors output for temp1..temp7 ?
#
      if ( $pgraphsset{"sensors_".$j."_find"} ) {
        $temp_name{$j} =  $pgraphsset{"sensors_".$j."_find"};
      } 

# what do we want to show on the graph for temp1..temp7 ?
# <empty> = do not show the line
      if ( $pgraphsset{"sensors_".$j."_show"} ) {
        $temp_graph{$j} =  $pgraphsset{"sensors_".$j."_show"};
      }
   }

#----------------------------------------------------------------------
# grab current temps
# I expect the output from sensors to look like this:
# temp1:        5555 RPM (stuff stuff stuff stuff)
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
	      for $i (sort(keys %temp_name)) {
                 if ( "$outer[0]" eq "$temp_name{$i}" ) {
                    $temp_value{ $i} = $fields[1];
                    print "info = ".$temp_value{$i}." on '".$temp_name{$i}."'\n";
                 }
              }
	   }
        } 
   }
   close(OUT);

   $a = 0;
   for $j (sort(keys %temp_name)) {
      $final_value[$a] = $temp_value{$j};
      $a++;
   }

   &processtempinfo("$final_value[0]","$final_value[1]","$final_value[2]","$final_value[3]","$final_value[4]","$final_value[5]","$final_value[6]");

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
# $_[0] = temp1
# $_[1] = temp2
# $_[2] = temp3
# $_[3] = temp4
# $_[4] = temp5
# $_[5] = temp6
# $_[6] = temp7
#----------------------------------------------------------------------
sub processtempinfo
{

        # make database if one isn't found, just storing averages for now

        if (! -e "$rrd/temperature.rrd")
         {
                print "Building new database...\n";
                system("$rrdtool create $rrd/temperature.rrd -s 300"
		." DS:temp1:GAUGE:600:0:U"
		." DS:temp2:GAUGE:600:0:U"
		." DS:temp3:GAUGE:600:0:U"
		." DS:temp4:GAUGE:600:0:U"
		." DS:temp5:GAUGE:600:0:U"
		." DS:temp6:GAUGE:600:0:U"
		." DS:temp7:GAUGE:600:0:U"
                ." RRA:AVERAGE:0.5:1:576 "
                ." RRA:AVERAGE:0.5:6:672 "
                ." RRA:AVERAGE:0.5:24:732 "
                ." RRA:AVERAGE:0.5:144:1460 ");
         }
        
        #print the current temps to the screen
        for $k (sort(keys %temp_name)) {
   		print "Values for $k test='$temp_name{$k}' value='$temp_value{$k}' graph='$temp_graph{$k}'\n";
 	}


        # insert values into the rrd database
`$rrdtool update $rrd/temperature.rrd -t temp1:temp2:temp3:temp4:temp5:temp6:temp7 N:"$_[0]":"$_[1]":"$_[2]":"$_[3]":"$_[4]":"$_[5]":"$_[6]"`;

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
        my $cstring = "$rrdtool graph $img/temperature-$_[0].png"
        ." -s \"-1$_[0]\""
        ." -t \"Temperature over the last $_[0]\""
	." -r --units-exponent 0"
        ." -a PNG"
	." --lazy"
        ." -h 100 -w 500"
#	." --no-minor"
        ." -v \"degrees C\""
	." DEF:temp1=$rrd/temperature.rrd:temp1:AVERAGE"
        ." DEF:temp2=$rrd/temperature.rrd:temp2:AVERAGE"    
        ." DEF:temp3=$rrd/temperature.rrd:temp3:AVERAGE"    
        ." DEF:temp4=$rrd/temperature.rrd:temp4:AVERAGE"    
        ." DEF:temp5=$rrd/temperature.rrd:temp5:AVERAGE"    
        ." DEF:temp6=$rrd/temperature.rrd:temp6:AVERAGE"    
        ." DEF:temp7=$rrd/temperature.rrd:temp7:AVERAGE"    
        ;
        for $k (sort(keys %temp_name)) {
	   if ( $temp_graph{$k} ) {
	      $cstring = $cstring 
	      ." LINE2:$k#".$temp_colour{$k}.":\"".$temp_graph{$k}."\""
              ." GPRINT:$k:MAX:\" Max\\: %5.1lf\""
              ." GPRINT:$k:MIN:\"Min\\: %5.1lf\""
              ." GPRINT:$k:AVERAGE:\"Avg\\: %5.1lf\""
              ." GPRINT:$k:LAST:\"Current\\: %5.1lf C\\n\""
           }
        }
	
	#print $cstring."\n";
	system ($cstring);
}

