#!/usr/bin/perl
#
# from an original ocoded by Martin Pot 2003
# http://martybugs.net/smoothwall/rrdtool_mem.cgi
#
# SmoothWall scripts
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
# rrdtool_ping.pl
#
use Scalar::Util 'looks_like_number';

# define location of rrdtool binary
my $rrdtool = '/usr/bin/rrdtool';
# define location of rrdtool databases
my $rrd = '/var/lib/rrd';
# define location of images
my $img = '/httpd/html/rrdtool';

my $fping_bin = '/usr/bin/fping';

my @targets;
my @pings;
my $pct;

my %dnssettings;
my %ethersettings;
my %hop;

# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my %pgraphsset;
$pgraphsset{"ping_collect"} = 'N';
$pgraphsset{"red_avail_collect"} = 'N';
&read_prefs($prefs_file, \%pgraphsset);

if (( $pgraphsset{"ping_collect"} eq "Y" ) or 
    ( $pgraphsset{"red_avail_collect"} eq "Y" )){

my $reply = '';
# by default red is down
$pct = 0;

if (defined($pgraphsset{"target_1"})){ $targets[1]=$pgraphsset{"target_1"} }
if (defined($pgraphsset{"target_2"})){ $targets[2]=$pgraphsset{"target_2"} }
if (defined($pgraphsset{"target_3"})){ $targets[3]=$pgraphsset{"target_3"} }
if (defined($pgraphsset{"target_4"})){ $targets[4]=$pgraphsset{"target_4"} }

$pings[1] = 'U';
$pings[2] = 'U';
$pings[3] = 'U';
$pings[4] = 'U';

open(OUT, "$fping_bin -C3 -p5000 -t5000 -q -e $targets[1] $targets[2] $targets[3] $targets[4] 2>&1 1>/dev/null |")
      or die("ERROR! Could not run the ping tests!\n$!\n");
while(<OUT>) {
	$reply = $_;
	chomp($reply);
	print "$reply\n";
	my @fields = split(/ +/,$reply);
#	print "found: $fields[0] $fields[3]\n";
	my $avg = 0;
	my $cnt = 0;
	if (looks_like_number($fields[2])) {$avg = $avg+$fields[2]; $cnt++; }
	if (looks_like_number($fields[3])) {$avg = $avg+$fields[3]; $cnt++; }
	if (looks_like_number($fields[4])) {$avg = $avg+$fields[4]; $cnt++; }
	if ($cnt > 0 ) {
		if ( "$fields[0]" eq "$targets[1]" ) { $pings[1] = $avg/$cnt };
		if ( "$fields[0]" eq "$targets[2]" ) { $pings[2] = $avg/$cnt };
		if ( "$fields[0]" eq "$targets[3]" ) { $pings[3] = $avg/$cnt };
		if ( "$fields[0]" eq "$targets[4]" ) { $pings[4] = $avg/$cnt };
	        $pct = 100;
	}
}

if ( $pgraphsset{"ping_collect"} eq "Y" ) {
	printf "ping times: %.2f\, %.2f\, %.2f\, %.2f\n", $pings[1], $pings[2], $pings[3], $pings[4];
	# if ping rrdtool database doesn't exist, create it
	if (! -e "$rrd/ping.rrd")
	{
        	print "creating rrd database for ping time...\n";
        	system("$rrdtool create $rrd/ping.rrd -s 300"
                	." DS:ping1:GAUGE:600:0:U"
                	." DS:ping2:GAUGE:600:0:U"
                	." DS:ping3:GAUGE:600:0:U"
                	." DS:ping4:GAUGE:600:0:U"
                	." RRA:AVERAGE:0.5:1:576"
                	." RRA:AVERAGE:0.5:6:672"
                	." RRA:AVERAGE:0.5:24:732"
                	." RRA:AVERAGE:0.5:144:1460");
	}

	# insert values into ping time rrd
	      `$rrdtool update $rrd/ping.rrd -t ping1:ping2:ping3:ping4 N:$pings[1]:$pings[2]:$pings[3]:$pings[4]`;

	print "$rrdtool update $rrd/ping.rrd -t ping1:ping2:ping3:ping4 N:$pings[1]:$pings[2]:$pings[3]:$pings[4]\n";

	# create ping time graphs
	&CreateGraphPing("day");
	&CreateGraphPing("week");
	&CreateGraphPing("month"); 
	&CreateGraphPing("year");
}

if ( $pgraphsset{"red_avail_collect"} eq "Y" ) {
	if ($pct == 100) {print "Red is up\n";}
	# if red_avail rrdtool database doesn't exist, create it
	if (! -e "$rrd/red_avail.rrd")
	{
        	print "creating rrd database for red_availability...\n";
        	system("$rrdtool create $rrd/red_avail.rrd -s 300"
                	." DS:up:GAUGE:600:0:100"
                	." RRA:AVERAGE:0.5:1:576"
                	." RRA:AVERAGE:0.5:6:672"
                	." RRA:AVERAGE:0.5:24:732"
                	." RRA:AVERAGE:0.5:144:1460");
	}	

	# insert values into red availability rrd
	      `$rrdtool update $rrd/red_avail.rrd -t up N:$pct`;
	print "$rrdtool update $rrd/red_avail.rrd -t up N:$pct\n";

	# create red availability graphs
	&CreateGraphRed_Up("day");
	&CreateGraphRed_Up("week");
	&CreateGraphRed_Up("month");
	&CreateGraphRed_Up("year");

}
} else {
        print "ping and red_avail are not collecting at present\n";
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

sub CreateGraphPing
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

	system("$rrdtool graph $img/ping-$_[0].png"
		." -s \"-1$_[0]\""
		." -t \"Ping times over the last $_[0]\""
		." --lazy"
		." -h 100 -w 500"
#linear version ." -l 0 -r --units-exponent 0"
		." --logarithmic"
		." -r -Y --units=si"
		." -a PNG"
                ." -v \"ping time (ms)\""
		." DEF:site1=$rrd/ping.rrd:ping1:AVERAGE"
		." DEF:site2=$rrd/ping.rrd:ping2:AVERAGE"
		." DEF:site3=$rrd/ping.rrd:ping3:AVERAGE"
		." DEF:site4=$rrd/ping.rrd:ping4:AVERAGE"
		." LINE1:site1#CC9966:\"$targets[1]\\t\""
		." GPRINT:site1:MAX:\"    Max\\: %4.1lf\""
		." GPRINT:site1:AVERAGE:\" Avg\\: %4.1lf\""
		." GPRINT:site1:LAST:\" Current\\: %4.1lf ms\\n\""
		." LINE1:site2#FF9900:\"$targets[2]\\t\""
		." GPRINT:site2:MAX:\"    Max\\: %4.1lf\""
		." GPRINT:site2:AVERAGE:\" Avg\\: %4.1lf\""
		." GPRINT:site2:LAST:\" Current\\: %4.1lf ms\\n\""
		." LINE1:site3#883333:\"$targets[3]\\t\""
		." GPRINT:site3:MAX:\"    Max\\: %4.1lf\""
		." GPRINT:site3:AVERAGE:\" Avg\\: %4.1lf\""
		." GPRINT:site3:LAST:\" Current\\: %4.1lf ms\\n\""
		." LINE1:site4#779922:\"$targets[4]\\t\""
		." GPRINT:site4:MAX:\"    Max\\: %4.1lf\""
		." GPRINT:site4:AVERAGE:\" Avg\\: %4.1lf\""
		." GPRINT:site4:LAST:\" Current\\: %4.1lf ms\"");
}

sub CreateGraphRed_Up
{
	# creates graph
	# inputs: $_[0]: interval (ie, day, week, month, year)

         system("$rrdtool graph $img/red_avail-$_[0].png"
		." -s \"-1$_[0]\""
		." -t \"Red side availability over the last $_[0]\""
		." --lazy"
		." -h 100 -w 500"
		." -l 0 -u 100 -r --units-exponent 0"
		." -a PNG"
		." -v \"Availability %\""
		." DEF:avail=$rrd/red_avail.rrd:up:AVERAGE"
		." CDEF:outag=avail,99.9,GT,0,98,IF"
		." AREA:outag#000090:\"Red side outages\\n\""
		." LINE2:avail#FF9900:\"Red side availability  \""
                ." GPRINT:avail:AVERAGE:\" Avg\\: %2.1lf\""
		." GPRINT:avail:LAST:\" Current\\: %2.1lf %%\"");
}
