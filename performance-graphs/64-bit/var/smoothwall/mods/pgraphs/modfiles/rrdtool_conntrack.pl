#!/usr/bin/perl
#
# originally coded by Martin Pot 2003
# http://martybugs.net/smoothwall/rrdtool_mem.cgi
#
# modified by Erik Hoitinga 2004
# modifications made to show load-avarage, cpu-usage and connections graphs.
#
# SmoothWall scripts
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
# rrdtool_conntrack.pl

# define location of rrdtool binary
my $rrdtool = '/usr/bin/rrdtool';
# define location of rrdtool databases
my $rrd = '/var/lib/rrd';
# define location of images
my $img = '/httpd/html/rrdtool';

use Socket;

# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my $key = 'connections';
my %pgraphsset;
$pgraphsset{"$key"."_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

if ( $pgraphsset{$key."_collect"} eq "Y" ) {

# Default value 
$connectionsd=0; 
$connectionsm=0; 
$connections=0; 

open (PROCNETBUFF,"< /proc/net/ip_conntrack"); 
@ip_conntrack_brut = <PROCNETBUFF>; 
close (PROCNETBUFF); 

foreach (@ip_conntrack_brut){ 
   $_=~ s/\[\S+\]\s//; 
   $proto=$_; 

   if (/tcp/){ 
	$proto =~ s/(\w+)\s+(\d+)\s(\S+)\s(\w+)\ssrc=(\S+)\sdst=(\S+)\ssport=(\S+)\sdport=(\S+)\spackets=(\S+)\sbytes=(\S+)\s+src=(\S+)\sdst=(\S+)\ssport=(\S+)\sdport=(\S+)\spackets=(\S+)\sbytes=(\S+)\s+mark=(\S+)\suse=(\S+)\s*\n/$1/; 
	$srcaddr   = $5; 
	$plpl      = $12; 
   } elsif (/icmp/){ 
	$proto =~ s/(\w+)\s+(\d+)\s(\S+)\ssrc=(\S+)\sdst=(\S+)\stype=(\S+)\scode=(\S+)\sid=(\S+)\spackets=(\S+)\sbytes=(\S+)\s+src=(\S+)\sdst=(\S+)\stype=(\S+)\scode=(\S+)\sid=(\S+)\spackets=(\S+)\sbytes=(\S+)\s+mark=(\S+)\suse=(\S+)\s*\n/$1/; 
	$srcaddr   = $4; 
	$plpl      = $12; 
   } elsif (/udp/){ 
	$proto =~ s/(\w+)\s+(\d+)\s(\S+)\ssrc=(\S+)\sdst=(\S+)\ssport=(\S+)\sdport=(\S+)\spackets=(\S+)\sbytes=(\S+)\s+src=(\S+)\sdst=(\S+)\ssport=(\S+)\sdport=(\S+)\spackets=(\S+)\sbytes=(\S+)\s+mark=(\S+)\suse=(\S+)\s*\n/$1/; 
	$srcaddr   = $4; 
	$plpl      = $11; 
   }  

   $connections=$connections+1; 
   if ($srcaddr ne $plpl){ 
	$connectionsm=$connectionsm+1; 
   }elsif ($srcaddr eq $plpl) { 
	$connectionsd=$connectionsd+1; 
   } 
}

printf "DIRECT connections: %.0f, MASQUERADED connections: %.0f\n", $connectionsd, $connectionsm;

# if connections rrdtool database doesn't exist, create it
if (! -e "$rrd/connections.rrd")
{
        print "creating rrd database for connections...\n";
        system("$rrdtool create $rrd/connections.rrd -s 300"
                ." DS:connectionsd:GAUGE:600:0:U"
		." DS:connectionsm:GAUGE:600:0:U"
                ." RRA:AVERAGE:0.5:1:576"
                ." RRA:AVERAGE:0.5:6:672"
                ." RRA:AVERAGE:0.5:24:732"
                ." RRA:AVERAGE:0.5:144:1460");
}

# insert values into connections rrd
`$rrdtool update $rrd/connections.rrd -t connectionsd:connectionsm N:$connectionsd:$connectionsm`;

# create connections graphs
&CreateGraphConnections("day");
&CreateGraphConnections("week");
&CreateGraphConnections("month");
&CreateGraphConnections("year");


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

sub CreateGraphConnections
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/connections-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"MASQUERADED and DIRECT connections over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"connections\""
                ." DEF:connectionsd=$rrd/connections.rrd:connectionsd:AVERAGE"
		." DEF:connectionsm=$rrd/connections.rrd:connectionsm:AVERAGE"
                ." CDEF:total=connectionsd,connectionsm,+"
                ." AREA:connectionsd#FFCC66:\"DIRECT connections\""
                ." GPRINT:connectionsd:MAX:\"        Max\\: %6.0lf\""
                ." GPRINT:connectionsd:AVERAGE:\"Avg\\: %6.0lf\""
                ." GPRINT:connectionsd:LAST:\"Current\\: %6.0lf\\n\""
                ." STACK:connectionsm#FF9900:\"MASQUERADED connections\""
                ." GPRINT:connectionsm:MAX:\"   Max\\: %6.0lf\""
                ." GPRINT:connectionsm:AVERAGE:\"Avg\\: %6.0lf\""
                ." GPRINT:connectionsm:LAST:\"Current\\: %6.0lf\\n\""
                ." GPRINT:total:MAX:\"Total number of connections   Max\\: %6.0lf\""
                ." GPRINT:total:AVERAGE:\"Avg\\: %6.0lf\""
                ." GPRINT:total:LAST:\"Current\\: %6.0lf\""
                ." LINE1:connectionsd#CC9966"
                ." LINE1:total#CC6600");
}
