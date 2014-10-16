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
# expand to 9 voltages
# single call to sensors
# now driven from the choices in the $prefs_file
# sensors_voltage_chip=''
# sensors_volt1_find='in0'
# sensors_volt1_show=' +3.3V'
# sensors_volt2_find='in1'
# sensors_volt2_show='+5V'

#path to rrdtool database
$rrd = "/var/lib/rrd";

#path to rrdtool binary
$rrdtool = "/usr/bin/rrdtool";

# define location of images
my $img = '/httpd/html/rrdtool';

# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my $key = 'voltage';
my %pgraphsset;
$pgraphsset{"$key"."_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

#----------------------------------------------------------------------
# Variables
#----------------------------------------------------------------------

# WARNING: These are overwritten from the preferences file if found
#
# list the sensor that shows/contains the right volt1: volt2: ONLY
# if you do not this script may have more sensors than really belong  
# null is OK if you only see one volt1: volt2: in the sensors output
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
%volt_name   = ( "volt1"  => "in0",
 		 "volt2"  => "in1", 
		 "volt3"  => "in2", 
		 "volt4"  => "in3", 
		 "volt5"  => "in4", 
		 "volt6"  => "in5", 
		 "volt7"  => "in6", 
		 "volt8"  => "in7", 
		 "volt9"  => "in8", 
	        );
%volt_value  = ( "volt1"  => "U",
		 "volt2"  => "U",
		 "volt3"  => "U",
		 "volt4"  => "U",
		 "volt5"  => "U",
		 "volt6"  => "U",
		 "volt7"  => "U",
		 "volt8"  => "U",
		 "volt9"  => "U",
	        ) ;
%volt_graph  = ( "volt1"  => "",
		 "volt2"  => "", 
		 "volt3"  => "", 
		 "volt4"  => "", 
		 "volt5"  => "", 
		 "volt6"  => "", 
		 "volt7"  => "", 
		 "volt8"  => "", 
		 "volt9"  => "", 
	        );
%volt_colour = ( "volt1"  => "ffcc66",
		 "volt2"  => "ff9900", 
		 "volt3"  => "8da0cb", 
		 "volt4"  => "e78ac3", 
		 "volt5"  => "66c2a5", 
		 "volt6"  => "e5c494",
		 "volt7"  => "a6d854", 
		 "volt8"  => "ff0000", 
		 "volt9"  => "0000ff", 
		);

# are we collecting?

if ( $pgraphsset{$key."_collect"} eq "Y" ) {

# is there a named sensor ?

   if ( $pgraphsset{"sensors_".$key."chip"} ) {
        $chipset_name =  $pgraphsset{"sensors_".$key."_chip"};
   }

   for $j (sort(keys %volt_name)) {
# what name do we expect to see in the sensors output for volt1..volt7 ?
#
      if ( $pgraphsset{"sensors_".$j."_find"} ) {
        $volt_name{$j} =  $pgraphsset{"sensors_".$j."_find"};
      } 

# what do we want to show on the graph for volt1..volt7 ?
# <empty> = do not show the line
      if ( $pgraphsset{"sensors_".$j."_show"} ) {
        $volt_graph{$j} =  $pgraphsset{"sensors_".$j."_show"};
      }
   }

#----------------------------------------------------------------------
# grab current volts
# I expect the output from sensors to look like this:
# volt1:        5555 RPM (stuff stuff stuff stuff)
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
	      for $i (sort(keys %volt_name)) {
                 if ( "$outer[0]" eq "$volt_name{$i}" ) {
                    $volt_value{ $i} = $fields[1];
                    print "info = ".$volt_value{$i}." on '".$volt_name{$i}."'\n";
                 }
              }
	   }
        } 
   }
   close(OUT);

   $a = 0;
   for $j (sort(keys %volt_name)) {
      $final_value[$a] = $volt_value{$j};
      $a++;
   }

   &processvoltinfo("$final_value[0]","$final_value[1]","$final_value[2]","$final_value[3]","$final_value[4]","$final_value[5]","$final_value[6]","$final_value[7]","$final_value[8]");

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
# $_[0] = volt1
# $_[1] = volt2
# $_[2] = volt3
# $_[3] = volt4
# $_[4] = volt5
# $_[5] = volt6
# $_[6] = volt7
# $_[7] = volt8
# $_[8] = volt9
#----------------------------------------------------------------------
sub processvoltinfo
{

        # make database if one isn't found, just storing averages for now

        if (! -e "$rrd/voltage.rrd")
         {
                print "Building new database...\n";
                system("$rrdtool create $rrd/voltage.rrd -s 300"
		." DS:volt1:GAUGE:600:0:U"
		." DS:volt2:GAUGE:600:0:U"
		." DS:volt3:GAUGE:600:0:U"
		." DS:volt4:GAUGE:600:0:U"
		." DS:volt5:GAUGE:600:0:U"
		." DS:volt6:GAUGE:600:0:U"
		." DS:volt7:GAUGE:600:0:U"
		." DS:volt8:GAUGE:600:0:U"
		." DS:volt9:GAUGE:600:0:U"
                ." RRA:AVERAGE:0.5:1:576 "
                ." RRA:AVERAGE:0.5:6:672 "
                ." RRA:AVERAGE:0.5:24:732 "
                ." RRA:AVERAGE:0.5:144:1460 ");
         }
        
        #print the current volts to the screen
        for $k (sort(keys %volt_name)) {
   		print "Values for $k test='$volt_name{$k}' value='$volt_value{$k}' graph='$volt_graph{$k}'\n";
 	}


        # insert values into the rrd database
`$rrdtool update $rrd/voltage.rrd -t volt1:volt2:volt3:volt4:volt5:volt6:volt7:volt8:volt9 N:"$_[0]":"$_[1]":"$_[2]":"$_[3]":"$_[4]":"$_[5]":"$_[6]":"$_[7]":"$_[8]"`;

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
        my $cstring = "$rrdtool graph $img/voltage-$_[0].png"
        ." -s \"-1$_[0]\""
        ." -t \"Voltage over the last $_[0]\""
	." -r --units-exponent 0"
        ." -a PNG"
	." --lazy"
        ." -h 100 -w 500"
#	." --no-minor"
        ." -v \"Volts\""
	." DEF:volt1=$rrd/voltage.rrd:volt1:AVERAGE"
        ." DEF:volt2=$rrd/voltage.rrd:volt2:AVERAGE"    
        ." DEF:volt3=$rrd/voltage.rrd:volt3:AVERAGE"    
        ." DEF:volt4=$rrd/voltage.rrd:volt4:AVERAGE"    
        ." DEF:volt5=$rrd/voltage.rrd:volt5:AVERAGE"    
        ." DEF:volt6=$rrd/voltage.rrd:volt6:AVERAGE"    
        ." DEF:volt7=$rrd/voltage.rrd:volt7:AVERAGE"    
        ." DEF:volt8=$rrd/voltage.rrd:volt8:AVERAGE"    
        ." DEF:volt9=$rrd/voltage.rrd:volt9:AVERAGE"    
        ;
        for $k (sort(keys %volt_name)) {
	   if ( $volt_graph{$k} ) {
	      $cstring = $cstring 
	      ." LINE2:$k#".$volt_colour{$k}.":\"".$volt_graph{$k}."\""
              ." GPRINT:$k:MAX:\" Max\\: %5.2lf\""
              ." GPRINT:$k:MIN:\"Min\\: %5.2lf\""
              ." GPRINT:$k:AVERAGE:\"Avg\\: %5.2lf\""
              ." GPRINT:$k:LAST:\"Current\\: %5.2lf V\\n\""
           }
        }
	
	#print $cstring."\n";
	system ($cstring);
}

