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
# rrdtool_mem.pl

# define location of rrdtool binary
my $rrdtool = '/usr/bin/rrdtool';
# define location of rrdtool databases
my $rrd = '/var/lib/rrd';
# define location of images
my $img = '/httpd/html/rrdtool';


# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my %pgraphsset;
$pgraphsset{"mem_collect"} = 'Y';
$pgraphsset{"load_collect"} = 'Y';
$pgraphsset{"cpu_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

if ( $pgraphsset{"mem_collect"} eq "Y" ) {

# get memory usage
my $mem = `free -b -o |grep Mem |cut -c19-29 |sed 's/ //g'`;
my $swap = `free -b -o |grep Swap |cut -c19-29 |sed 's/ //g'`;

# remove eol chars
chomp($mem);
chomp($swap);

printf "memory: %.2f Mbytes, swap: %.2f Mbytes\n", $mem/1024/1024, $swap/1024/1024;

# if memory usage rrdtool database doesn't exist, create it
if (! -e "$rrd/mem.rrd")
{
	print "creating rrd database for memory usage...\n";
	system("$rrdtool create $rrd/mem.rrd -s 300"
		." DS:mem:GAUGE:600:0:U"
		." DS:swap:GAUGE:600:0:U"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
}

# insert values into memory usage rrd
`$rrdtool update $rrd/mem.rrd -t mem:swap N:$mem:$swap`;

# create memory graphs
&CreateGraphMem("day");
&CreateGraphMem("week");
&CreateGraphMem("month");
&CreateGraphMem("year");

} else {
        print "mem is not collecting at present\n";
}

if ( $pgraphsset{"load_collect"} eq "Y" ) {

my $lavg1 = `cat /proc/loadavg | cut -d ' ' -f 0-1`;
my $lavg5 = `cat /proc/loadavg | cut -d ' ' -f 2-2`;
my $lavg15 = `cat /proc/loadavg | cut -d ' ' -f 3-3`;
chomp($lavg1);
chomp($lavg5);
chomp($lavg15);
printf "load average: %.2f\, %.2f\, %.2f\n", $lavg1, $lavg5, $lavg15;

# if load average rrdtool database doesn't exist, create it
if (! -e "$rrd/load.rrd")
{
        print "creating rrd database for load averages...\n";
        system("$rrdtool create $rrd/load.rrd -s 300"
                ." DS:lavg1:GAUGE:600:0:U"
                ." DS:lavg5:GAUGE:600:0:U"
                ." DS:lavg15:GAUGE:600:0:U"
                ." RRA:AVERAGE:0.5:1:576"
                ." RRA:AVERAGE:0.5:6:672"
                ." RRA:AVERAGE:0.5:24:732"
                ." RRA:AVERAGE:0.5:144:1460");
}

# insert values into load average rrd
`$rrdtool update $rrd/load.rrd -t lavg1:lavg5:lavg15 N:$lavg1:$lavg5:$lavg15`;

# create load avrage graphs
&CreateGraphLoad("day");
&CreateGraphLoad("week");
&CreateGraphLoad("month"); 
&CreateGraphLoad("year");

} else {
        print "load is not collecting at present\n";
}

if ( $pgraphsset{"cpu_collect"} eq "Y" ) {

#my $cpu = `ps -auxw|awk '!/%/ {proz += \$3;} END { printf("%d", proz)}'`;
#my $cpu = `grep '^cpu ' /proc/stat  | sed -e 's/^cpu */N:/' -e 's/ /:/g'`;
my $cpu = `grep '^cpu ' /proc/stat  | awk '{print "N:"\$2":"\$3":"\$4+\$6+\$7":"\$5;}'`;
chomp($cpu);
printf "cpu usage: %s\n", $cpu;

# if cpu usage rrdtool database doesn't exist, create it
if (! -e "$rrd/cpu.rrd")
{
        print "creating rrd database for CPU usage...\n";
        system("$rrdtool create $rrd/cpu.rrd -s 300"
                ." DS:cpuuser:DERIVE:600:0:480000"
                ." DS:cpunice:DERIVE:600:0:480000"
                ." DS:cpusyst:DERIVE:600:0:480000"
                ." DS:cpuidle:DERIVE:600:0:480000"
                ." RRA:AVERAGE:0.5:1:576"
                ." RRA:AVERAGE:0.5:6:672"
                ." RRA:AVERAGE:0.5:24:732"
                ." RRA:AVERAGE:0.5:144:1460");
}

# insert values into cpu usage rrd
`$rrdtool update $rrd/cpu.rrd -t cpuuser:cpunice:cpusyst:cpuidle $cpu`;

# create cpu usage graphs
&CreateGraphCPU("day");
&CreateGraphCPU("week");
&CreateGraphCPU("month");
&CreateGraphCPU("year");

} else {
        print "cpu is not collecting at present\n";
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

sub CreateGraphMem
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/mem-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"memory usage over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"bytes\""
                ." -b 1024"
                ." DEF:mem=$rrd/mem.rrd:mem:AVERAGE"
                ." DEF:swap=$rrd/mem.rrd:swap:AVERAGE"
                ." CDEF:total=mem,swap,+"
                ." AREA:mem#FFCC66:\"Physical Memory Usage\""
                ." GPRINT:mem:MAX:\"  Max\\: %5.1lf %s\""
                ." GPRINT:mem:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:mem:LAST:\" Current\\: %5.1lf %Sbytes\\n\""
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

sub CreateGraphLoad
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

	system("$rrdtool graph $img/load-$_[0].png"
		." -s \"-1$_[0]\""
		." -t \"load average over the last $_[0]\""
		." --lazy"
		." -h 100 -w 500"
		." -l 0 -r --units-exponent 0"
		." -a PNG"
                ." -v \"load avg\""
		." DEF:lavg1=$rrd/load.rrd:lavg1:AVERAGE"
		." DEF:lavg5=$rrd/load.rrd:lavg5:AVERAGE"
		." DEF:lavg15=$rrd/load.rrd:lavg15:AVERAGE"
		." LINE1:lavg1#FFCC66:\"1 minute load average\""
		." GPRINT:lavg1:MAX:\"    Max\\: %2.2lf\""
		." GPRINT:lavg1:LAST:\" Current\\: %2.2lf\\n\""
		." LINE1:lavg5#FF9900:\"5 minute load average\""
		." GPRINT:lavg5:MAX:\"    Max\\: %2.2lf\""
		." GPRINT:lavg5:LAST:\" Current\\: %2.2lf\\n\""
		." LINE1:lavg15#FF7000:\"15 minute load average\""
		." GPRINT:lavg15:MAX:\"   Max\\: %2.2lf\""
		." GPRINT:lavg15:LAST:\" Current\\: %2.2lf\"");

}

sub CreateGraphCPU
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/cpu-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"CPU load over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -u 100 -r"
                ." -a PNG"
                ." -v \"CPU load (\%)\""
                ." DEF:cpuuser=$rrd/cpu.rrd:cpuuser:AVERAGE"
                ." DEF:cpunice=$rrd/cpu.rrd:cpunice:AVERAGE"
                ." DEF:cpusyst=$rrd/cpu.rrd:cpusyst:AVERAGE"
                ." DEF:cpuidle=$rrd/cpu.rrd:cpuidle:AVERAGE"
                ." CDEF:cpusys=cpunice,cpusyst,+"
                ." CDEF:cputot=cpuuser,cpunice,+,cpusyst,+"
                ." AREA:cpusys#FF9900:\"CPU load system\""
                ." GPRINT:cpusys:MAX:\"   Max\\: %4.1lf\""
                ." GPRINT:cpusys:AVERAGE:\" Avg\\: %4.1lf\""
                ." GPRINT:cpusys:LAST:\" Current\\: %4.1lf\\n\""
                ." STACK:cpuuser#FFCC66:\"CPU load user  \""
                ." GPRINT:cpuuser:MAX:\"   Max\\: %4.1lf\""
                ." GPRINT:cpuuser:AVERAGE:\" Avg\\: %4.1lf\""
                ." GPRINT:cpuuser:LAST:\" Current\\: %4.1lf\\n\""
                ." GPRINT:cputot:MAX:\"  CPU load total   "
                ."   Max\\: %4.1lf\""
                ." GPRINT:cputot:AVERAGE:\" Avg\\: %4.1lf\""
                ." GPRINT:cputot:LAST:\" Current\\: %4.1lf\""
#                ." STACK:cpuidle#FFEE99:\"CPU idle       \""
#                ." GPRINT:cpuidle:MAX:\"   Max\\: %3.1lf\""
#                ." GPRINT:cpuidle:AVERAGE:\" Avg\\: %3.1lf\""
#                ." GPRINT:cpuidle:LAST:\" Current\\: %3.1lf\\n\""
		." LINE1:cpusys#CC6600"
		." LINE1:cputot#CC9966"
		);
}

