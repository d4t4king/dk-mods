#!/usr/bin/perl
#
# original coded by Martin Pot 2003
# http://martybugs.net/smoothwall/rrdtool_mem.cgi
#
# SmoothWall scripts
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
# rrdtool_squid.pl

# define location of rrdtool binary
my $rrdtool = '/usr/bin/rrdtool';

# define location of rrdtool databases
my $rrd = '/var/lib/rrd';

# define location of images
my $img = '/httpd/html/rrdtool';

# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my $key = 'squid';
my %pgraphsset;
$pgraphsset{"$key"."_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

if ( $pgraphsset{$key."_collect"} eq "Y" ) {

# get usage 
my $du_reply = `du -sk /var/spool/squid/cache | awk '{print \$1/1024}'`;
chomp($du_reply);

print "Squid cache used = " . $du_reply . " Mbytes\n";

my $cache_val = `grep 'CACHE_SIZE' /var/smoothwall/proxy/settings | awk -F= '{print \$2}'`;
chomp($cache_val);

print "Squid cache limit = " . $cache_val . " Mbytes\n";

# if squid rrdtool database doesn't exist, create it
if (! -e "$rrd/squid.rrd")
{
        print "creating rrd database for squid...\n";
        system("$rrdtool create $rrd/squid.rrd -s 300"
                ." DS:squid_du:GAUGE:600:0:U"
                ." DS:squid_max:GAUGE:600:0:U"
                ." RRA:AVERAGE:0.5:1:576"
                ." RRA:AVERAGE:0.5:6:672"
                ." RRA:AVERAGE:0.5:24:732"
                ." RRA:AVERAGE:0.5:144:1460");
}

# insert values into squid rrd
`$rrdtool update $rrd/squid.rrd -t squid_du:squid_max N:$du_reply:$cache_val`;

# create connections graphs
&CreateGraphSquid("day");
&CreateGraphSquid("week");
&CreateGraphSquid("month");
&CreateGraphSquid("year");

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

sub CreateGraphSquid
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/squid-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Squid Web Proxy cache usage over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -a PNG"
                ." -l 0"
		." -v \"Mbytes\""
		." DEF:squid_du=$rrd/squid.rrd:squid_du:AVERAGE"
		." DEF:squid_max=$rrd/squid.rrd:squid_max:AVERAGE"
                ." AREA:squid_du#FFCC66:\"Cache used \""
                ." GPRINT:squid_du:MAX:\"        Max\\: %7.1lf M\""
                ." GPRINT:squid_du:AVERAGE:\"Avg\\: %7.1lf M\""
                ." GPRINT:squid_du:LAST:\"Current\\: %7.1lf Mbytes\\n\""
                ." LINE1:squid_max#CC6600:\"Cache limit\""
                ." GPRINT:squid_max:MAX:\"        Max\\: %7.1lf M\""
                ." GPRINT:squid_max:AVERAGE:\"Avg\\: %7.1lf M\""
                ." GPRINT:squid_max:LAST:\"Current\\: %7.1lf Mbytes\\n\""
                );
}
