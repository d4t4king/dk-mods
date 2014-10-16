#!/usr/bin/perl
#
# coded by Martin Pot 2003
# http://martybugs.net/smoothwall/rrdtool_mem.cgi
#
# modified by Erik Hoitinga 2004
# modifications made to show load-average, cpu-usage and connections graphs.
#
# SmoothWall scripts
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
# rrdtool_memoryx.pl


# define location of rrdtool binary
my $rrdtool = '/usr/bin/rrdtool';
# define location of rrdtool databases
my $rrd = '/var/lib/rrd';
# define location of images
my $img = '/httpd/html/rrdtool';


# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my $key = 'memoryx';
my %pgraphsset;
$pgraphsset{"$key"."_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

if ( $pgraphsset{$key."_collect"} eq "Y" ) {

# get memory usage
my $mem = `free -b -o |grep Mem |cut -c19-29 |sed 's/ //g'`;
my $swap = `free -b -o |grep Swap |cut -c19-29 |sed 's/ //g'`;
my $buff = `free -b -o |grep Mem |cut -c52-62 |sed 's/ //g'`;
my $cache = `free -b -o |grep Mem |cut -c63-73 |sed 's/ //g'`;

# remove eol chars
chomp($mem);
chomp($swap);
chomp($buff);
chomp($cache);

printf "memory: %.2f Mbytes, swap: %.2f Mbytes, buffers: %.2f Mbytes, caches: %.2f Mbytes\n",
$mem/1024/1024, $swap/1024/1024, $buff/1024/1024, $cache/1024/1024;

# if memory usage rrdtool database doesn't exist, create it
if (! -e "$rrd/memoryx.rrd")
{
	print "creating rrd database for memory usage...\n";
	system("$rrdtool create $rrd/memoryx.rrd -s 300"
		." DS:mem:GAUGE:600:0:U"
		." DS:swap:GAUGE:600:0:U"
		." DS:buff:GAUGE:600:0:U"
		." DS:cache:GAUGE:600:0:U"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
}

# insert values into memory usage rrd
`$rrdtool update $rrd/memoryx.rrd -t mem:swap:buff:cache N:$mem:$swap:$buff:$cache`;

# create memory graphs
&CreateGraphMemoryx("day");
&CreateGraphMemoryx("week");
&CreateGraphMemoryx("month");
&CreateGraphMemoryx("year");

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

sub CreateGraphMemoryx
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/memoryx-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"detailed memory usage over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"bytes\""
                ." -b 1024"
                ." DEF:mem=$rrd/memoryx.rrd:mem:AVERAGE"
                ." DEF:swap=$rrd/memoryx.rrd:swap:AVERAGE"
                ." DEF:buff=$rrd/memoryx.rrd:buff:AVERAGE"
                ." DEF:cache=$rrd/memoryx.rrd:cache:AVERAGE"
                ." CDEF:total=mem,swap,+"
                ." CDEF:process=mem,buff,cache,+,-"
                ." AREA:process#FFCC66:\"Processes Memory Usage\""
                ." GPRINT:process:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:process:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:process:LAST:\" Current\\: %5.1lf %Sbytes\\n\""
                ." STACK:cache#CC9966:\"Cache Memory Usage\""
                ." GPRINT:cache:MAX:\"     Max\\: %5.1lf %s\""
                ." GPRINT:cache:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:cache:LAST:\" Current\\: %5.1lf %Sbytes\\n\""
                ." STACK:buff#FFEE99:\"Buffers Memory Usage\""
                ." GPRINT:buff:MAX:\"   Max\\: %5.1lf %s\""
                ." GPRINT:buff:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:buff:LAST:\" Current\\: %5.1lf %Sbytes\\n\""
                ." STACK:swap#FF9900:\"Swap Memory Usage\""
                ." GPRINT:swap:MAX:\"      Max\\: %5.1lf %S\""
                ." GPRINT:swap:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:swap:LAST:\" Current\\: %5.1lf %Sbytes\\n\""
                ." GPRINT:total:MAX:\"  Total Memory Usage       Max\\: %5.1lf %S\""
                ." GPRINT:total:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:total:LAST:\" Current\\: %5.1lf %Sbytes\""
                ." LINE1:mem#CC9966"
                ." LINE1:total#CC6600");
}
