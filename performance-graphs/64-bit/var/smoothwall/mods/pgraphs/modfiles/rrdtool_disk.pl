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


my $what;
# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
#my $key = 'disk';
my %pgraphsset;
$pgraphsset{"disk_io_collect"} = 'Y';
$pgraphsset{"disk_bytes_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

if ( ( $pgraphsset{"disk_io_collect"} eq "Y" ) ||
     ( $pgraphsset{"disk_bytes_collect"} eq "Y" ) ) {

# get disk traffic usage

   my $xtd_reply = `cat /proc/diskstats | grep -e 'sda ' -e 'hda ' `;
   my $hdario;
   my $hdawio;
   my $hdariol;
   my $hdawiol;
   my $hdarse;
   my $hdawse;

# thaks to Jonny Schulz <jschulz.cpan(at)bloonix.de>.
# -----------------------------------------------------------------------------
# Field  1 -- # of reads issued
#     This is the total number of reads completed successfully.
# Field  2 -- # of reads merged, field 6 -- # of writes merged
#     Reads and writes which are adjacent to each other may be merged for
#     efficiency.  Thus two 4K reads may become one 8K read before it is
#     ultimately handed to the disk, and so it will be counted (and queued)
#     as only one I/O.  This field lets you know how often this was done.
# Field  3 -- # of sectors read
#     This is the total number of sectors read successfully.
# Field  4 -- # of milliseconds spent reading
#     This is the total number of milliseconds spent by all reads (as
#     measured from __make_request() to end_that_request_last()).
# Field  5 -- # of writes completed
#     This is the total number of writes completed successfully.
# Field  6 -- # of writes merged (see 2)
# Field  7 -- # of sectors written
#     This is the total number of sectors written successfully.
# Field  8 -- # of milliseconds spent writing
#     This is the total number of milliseconds spent by all writes (as
#     measured from __make_request() to end_that_request_last()).
# Field  9 -- # of I/Os currently in progress
#     The only field that should go to zero. Incremented as requests are
#     given to appropriate request_queue_t and decremented as they finish.
# Field 10 -- # of milliseconds spent doing I/Os
#     This field is increases so long as field 9 is nonzero.
# Field 11 -- weighted # of milliseconds spent doing I/Os
#     This field is incremented at each I/O start, I/O completion, I/O
#     merge, or read of these stats by the number of I/Os in progress
#     (field 9) times the number of milliseconds spent doing I/O since the
#     last update of this field.  This can provide an easy measure of both
#     I/O completion time and the backlog that may be accumulating.
# -----------------------------------------------------------------------------
#  --    --    --    F1   F2   F3   F4   F5   F6   F7   F8  F9  F10 F11
#  $1    $2    $3    $4   --   $5   --   $6   --   $7   --  --  --   --

   
   while($xtd_reply =~ /([^\n]+)\n?/g) {
     $reply = $1;
     print "$reply\n";

     if ($reply =~ /^\s+(\d+)\s+(\d+)\s+(.+?)\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+$/) {
	if ($4 != 0 ) {
	   $hdario = $4;
	   $hdawio = $6;
	   $hdarse = $5;
	   $hdawse = $7;
	   $what = $3;
           printf "device: %s, reads: %u, writes: %u, read sectors: %u, write sectors: %u\n",
               $what, $hdario, $hdawio, $hdarse, $hdawse;
        }
     }   
     if ($reply =~ /^\s+(\d+)\s+(\d+)\s+(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+$/) {
	if ( $5 != 0 ) {
	   $hdariol = $hdario + $5;
	   $hdawiol = $hdawio + $8;
           printf "device: %s, logical reads: %u, logical writes: %u\n",
               $what, $hdariol, $hdawiol;
        }
     }
  }
  if ( $pgraphsset{"disk_io_collect"} eq "Y" ) {
 
# if disk usage rrdtool database doesn't exist, create it
	if (! -e "$rrd/disk_io.rrd") {
	   print "creating rrd database for disk io traffic...\n";
	   system("$rrdtool create $rrd/disk_io.rrd -s 300"
		." DS:hdario:DERIVE:600:0:U"
		." DS:hdawio:DERIVE:600:0:U"
		." DS:hdariol:DERIVE:600:0:U"
		." DS:hdawiol:DERIVE:600:0:U"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
	}	

# insert values into memory usage rrd
	`$rrdtool update $rrd/disk_io.rrd -t  hdario:hdawio:hdariol:hdawiol N:$hdario:$hdawio:$hdariol:$hdawiol`;

# create disk activity graphs
	&CreateGraphDisk_io("day");
	&CreateGraphDisk_io("week");
	&CreateGraphDisk_io("month");
	&CreateGraphDisk_io("year");
   }

   if ( $pgraphsset{"disk_bytes_collect"} eq "Y" ) {
# if disk usage rrdtool database doesn't exist, create it
	if (! -e "$rrd/disk_bytes.rrd") {
	   print "creating rrd database for disk bytes traffic...\n";
	   system("$rrdtool create $rrd/disk_bytes.rrd -s 300"
		." DS:hdarse:DERIVE:600:0:U"
		." DS:hdawse:DERIVE:600:0:U"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
	}	

# insert values into memory usage rrd
	`$rrdtool update $rrd/disk_bytes.rrd -t  hdarse:hdawse N:$hdarse:$hdawse`;

# create disk activity graphs
	&CreateGraphDisk_bytes("day");
	&CreateGraphDisk_bytes("week");
	&CreateGraphDisk_bytes("month");
	&CreateGraphDisk_bytes("year");
   }
} else {
   print "disk_io and disk_bytes are not collecting at present\n";
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

sub CreateGraphDisk_io
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/disk_io-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Disk activity ios for $what over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"ios/sec\""
                ." -b 1024"
                ." DEF:hdario=$rrd/disk_io.rrd:hdario:AVERAGE"
                ." DEF:hdawio=$rrd/disk_io.rrd:hdawio:AVERAGE"
                ." DEF:hdariol=$rrd/disk_io.rrd:hdariol:AVERAGE"
                ." DEF:hdawiol=$rrd/disk_io.rrd:hdawiol:AVERAGE"
                ." CDEF:total=hdario,hdawio,+"
                ." CDEF:totall=hdariol,hdawiol,+"
                ." LINE1:hdario#00CC66:\"io physical reads \""
                ." GPRINT:hdario:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hdario:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hdario:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:hdawio#009900:\"io physical writes\""
                ." GPRINT:hdawio:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hdawio:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hdawio:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:total#007700:\"io physical total \""
                ." GPRINT:total:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:total:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:total:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:hdariol#FFCC66:\"io logical reads  \""
                ." GPRINT:hdariol:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hdariol:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hdariol:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:hdawiol#FF9900:\"io logical writes \""
                ." GPRINT:hdawiol:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hdawiol:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hdawiol:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:totall#FF7700:\"io logical total  \""
                ." GPRINT:totall:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:totall:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:totall:LAST:\" Current\\: %5.1lf %S /sec\""
                );
}

sub CreateGraphDisk_bytes
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/disk_bytes-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Disk activity bytes for $what over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"bytes/sec\""
                ." -b 1024"
                ." DEF:hdarse=$rrd/disk_bytes.rrd:hdarse:AVERAGE"
                ." DEF:hdawse=$rrd/disk_bytes.rrd:hdawse:AVERAGE"
                ." CDEF:hdarby=hdarse,512,*"
                ." CDEF:hdawby=hdawse,512,*"
                ." CDEF:total=hdarby,hdawby,+"
                ." LINE1:hdarby#FFCC66:\"Read \""
                ." GPRINT:hdarby:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hdarby:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hdarby:LAST:\" Current\\: %5.1lf %S bytes/sec\\n\""
                ." LINE1:hdawby#FF9900:\"Wrote\""
                ." GPRINT:hdawby:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hdawby:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hdawby:LAST:\" Current\\: %5.1lf %S bytes/sec\\n\""
                ." LINE1:total#FF7700:\"Total\""
                ." GPRINT:total:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:total:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:total:LAST:\" Current\\: %5.1lf %S bytes/sec\""
                );
}
