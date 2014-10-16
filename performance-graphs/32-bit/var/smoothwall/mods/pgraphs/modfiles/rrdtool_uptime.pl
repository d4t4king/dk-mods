#!/usr/bin/perl
#
# coded by Martin Pot 2003
# http://martybugs.net/smoothwall/rrdtool_mem.cgi
# modified by Erik Hoitinga 2004
#
# modified by Mark Petersen 2007
# modifications made to show uptime graphs.
#
# 
# SmoothWall scripts
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
# rrdtool_uptime.pl

# define location of rrdtool binary
my $rrdtool = '/usr/bin/rrdtool';
# define location of rrdtool databases
my $rrd = '/var/lib/rrd';
# define location of images
my $img = '/httpd/html/rrdtool';

my $path = '/var/log/uptime';

#show when we started
my $StartText;

# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
#my $key = 'uptime';
my %pgraphsset;
$pgraphsset{"uptime_collect"} = 'Y';
$pgraphsset{"uptimemax_collect"} = 'N';
&read_prefs($prefs_file, \%pgraphsset);

if (( $pgraphsset{"uptime_collect"} eq "Y" ) or
    ( $pgraphsset{"uptimemax_collect"} eq "Y" )) {

if (! -d "$path"){
	`mkdir $path`;
	`touch $path/start`;
	`touch $path/hartbeat`;
	`touch $path/total`;
	`touch $path/reboot`;
	print "Createt path for logfiles";}

my $Uptime = int `cut -f1 -d' ' /proc/uptime | cut -f1 -d.`;
print "Uptime         = $Uptime\n";
my $CurentTime = int `date "+%s"`;
print "CurentTime     = $CurentTime\n";


my $StartTime = int `cat $path/start`;
print "StartTime      = $StartTime\n";
if ($StartTime == 0){
	$StartTime = $CurentTime - $Uptime;
	`echo "$StartTime" > $path/start`;
	print "StartTime      = $StartTime\n";}

my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
my ($sec, $min, $hour, $day,$month,$year) = (localtime($StartTime))[0,1,2,3,4,5,6]; 
#
$StartText = sprintf "%02d %3s %02d %02d\\:%02d", $day, $months[$month], $year+1900, $hour, $min;
print "StartText      = $StartText\n";

my $TotalDownTime = int `cat $path/total`;
print "TotalDownTime  = $TotalDownTime\n";
my $Hartbeat = int `cat $path/hartbeat`;
print "Hartbeat       = $Hartbeat\n";
if ($Hartbeat == 0){
	$Hartbeat = $CurentTime - $Uptime;
	`echo "$Hartbeat" > $path/hartbeat`;
	print "Hartbeat       = $Hartbeat\n";}

my $CurentTimeText = `date`;
chomp($CurentTimeText);
print "CurentTimeText = $CurentTimeText\n";
my $DownTime = $CurentTime - $Uptime - $Hartbeat;
print "DownTime       = $DownTime\n";

my $Reboot = int `cat $path/reboot`;
print "Reboot         = $Reboot\n";


if ($DownTime > 0){
	$TotalDownTime = $TotalDownTime + $DownTime;
	$Reboot = $Reboot + 1;
	print "TotalDownTime  = $TotalDownTime\n";
	print "Reboot         = $Reboot\n";
	`echo "$TotalDownTime" > $path/total`;
	`echo "$CurentTime $DownTime" >> $path/log`;
	`echo "$Reboot" > $path/reboot`;}
else{
	$DownTime = 0;
	print "DownTime       = $DownTime\n";}

`echo "$CurentTime" > $path/hartbeat`;

my $RunTime = $CurentTime-$StartTime;
print "RunTime        = $RunTime\n";
my $AvgUpTime = ($RunTime - $TotalDownTime) / $RunTime * 100;
print "AvgUpTime      = $AvgUpTime\n";
if ( $Uptime > 300 ) { $NowUpTime = 100; } else { $NowUpTime = ($Uptime / 3); }

# if uptime usage rrdtool database doesn't exist, create it

#if (! -e "$rrd/uptime.rrd")
#{
#	print "creating rrd database for uptime usage...\n";
#	system("$rrdtool create $rrd/uptime.rrd -s 300"
#		." DS:AvgUpTime:GAUGE:600:0:U"
#		." RRA:AVERAGE:0.5:1:576"
#		." RRA:AVERAGE:0.5:6:672"
#		." RRA:AVERAGE:0.5:24:732"
#		." RRA:AVERAGE:0.5:144:1460");
#}

if ( $pgraphsset{"uptime_collect"} eq "Y" ) {
   if (! -e "$rrd/uptime2.rrd") {
	print "creating rrd database for uptime...\n";
	system("$rrdtool create $rrd/uptime2.rrd -s 300"
		." DS:AvgUpTime:GAUGE:600:0:U"
		." DS:NowUpTime:GAUGE:600:0:U"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
   }
   # insert 0 values into uptime rrd for the missed ones
   if ($DownTime > 300){
      for ($x = $Hartbeat + 300; $x < $CurentTime; $x = $x + 300 ) {
	`$rrdtool update $rrd/uptime2.rrd -t NowUpTime $x:0`;
	printf "$rrdtool update $rrd/uptime2.rrd -t NowUpTime $x:0\n";
      }
   } 

   # insert values into uptime rrd

   #`$rrdtool update $rrd/uptime.rrd -t AvgUpTime N:$AvgUpTime`;
   #printf "$rrdtool update $rrd/uptime.rrd -t AvgUpTime N:$AvgUpTime\n";

   `$rrdtool update $rrd/uptime2.rrd -t AvgUpTime:NowUpTime N:$AvgUpTime:$NowUpTime`;
   printf "$rrdtool update $rrd/uptime2.rrd -t AvgUpTime:NowUpTime N:$AvgUpTime:$NowUpTime\n";

} else {
        print "uptime is not collecting at present\n";
}

if ( $pgraphsset{"uptimemax_collect"} eq "Y" ) {
   if (! -e "$rrd/uptimemax.rrd") {
	print "creating rrd database for max uptime...\n";
	system("$rrdtool create $rrd/uptimemax.rrd -s 300"
		." DS:UpTime:GAUGE:600:0:U"
		." RRA:MAX:0.5:1:576"
		." RRA:MAX:0.5:6:672"
		." RRA:MAX:0.5:24:732"
		." RRA:MAX:0.5:144:1460");
	}

   # insert values into uptimemax rrd
   `$rrdtool update $rrd/uptimemax.rrd -t UpTime N:$Uptime`;
   printf "$rrdtool update $rrd/uptimemax.rrd -t UpTime N:$Uptime\n";

} else {
        print "uptimemax is not collecting at present\n";
}

# create uptime graphs
&CreateGraphUptime("day");
&CreateGraphUptime("week");
&CreateGraphUptime("month");
&CreateGraphUptime("year");

} else {
        print "uptime and uptimemax are not collecting at present\n";
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

sub CreateGraphUptime
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

   if ( $pgraphsset{"uptime_collect"} eq "Y" ) {
	system("$rrdtool graph $img/uptime-$_[0].png"
		." -s \"-1$_[0]\""
		." -t \"System uptime % over the last $_[0]\""
		." --lazy"
		." -h 100 -w 500"
		." -l 0 -u 100 -r --units-exponent 0"
		." -a PNG"
		." -v \"uptime avg %\""
		." DEF:AvgUpTime=$rrd/uptime2.rrd:AvgUpTime:AVERAGE"
		." DEF:NowUpTime=$rrd/uptime2.rrd:NowUpTime:AVERAGE"
		." CDEF:outag=NowUpTime,99.9,GT,0,98,IF"
		." AREA:outag#000090:\"Outages\\n\""
		." LINE2:AvgUpTime#FF9900:\"Historic uptime since\""
		." GPRINT:AvgUpTime:MAX:\"Max\\: %5.1lf\""
		." GPRINT:AvgUpTime:MIN:\"Min\\: %5.1lf\""
		." GPRINT:AvgUpTime:AVERAGE:\"Avg\\: %5.1lf\""
		." GPRINT:AvgUpTime:LAST:\"Current\\: %5.1lf %%\\n\""
		." COMMENT:\"  $StartText\\n\""
		." LINE1:NowUpTime#883333:\"Displayed uptime     \""
		." GPRINT:NowUpTime:MAX:\"Max\\: %5.1lf\""
		." GPRINT:NowUpTime:MIN:\"Min\\: %5.1lf\""
		." GPRINT:NowUpTime:AVERAGE:\"Avg\\: %5.1lf\""
		." GPRINT:NowUpTime:LAST:\"Current\\: %5.1lf %%\""
	);
   }

   if ( $pgraphsset{"uptimemax_collect"} eq "Y" ) {
        system("$rrdtool graph $img/uptimemax-$_[0].png"
		." -s \"-1$_[0]\""
		." -t \"Max System uptime over the last $_[0]\""
		." --lazy"
		." -h 100 -w 500"
		." -l 0 -r --units-exponent 0"
		." -a PNG"
		." -v \"uptime hours\""
		." DEF:UpTimer=$rrd/uptimemax.rrd:UpTime:MAX"
		." CDEF:UpTime=UpTimer,3600,/"
		." LINE2:UpTime#FF9900:\"max uptime\""
		." GPRINT:UpTime:MAX:\"Max\\: %5.1lf\""
		." GPRINT:UpTime:MIN:\"Min\\: %5.1lf\""
		." GPRINT:UpTime:AVERAGE:\"Avg\\: %5.1lf\""
		." GPRINT:UpTime:LAST:\"Current\\: %5.1lf hours\"");
   }
}
