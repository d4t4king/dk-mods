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

my ($what,$what1,$what2,$what3,$what4);

# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
#my $key = 'diskx';
my %pgraphsset;
$pgraphsset{"diskx_io_collect"} = 'Y';
$pgraphsset{"diskx_bytes_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

if ( ( $pgraphsset{"diskx_io_collect"} eq "Y" ) ||
     ( $pgraphsset{"diskx_bytes_collect"} eq "Y" ) ) {

# get disk partition traffic usage

my ($hda1rio, $hda1wio, $hda1rse, $hda1wse);
my ($hda2rio, $hda2wio, $hda2rse, $hda2wse);
my ($hda3rio, $hda3wio, $hda3rse, $hda3wse);
my ($hda4rio, $hda4wio, $hda4rse, $hda4wse);

if (open $fh, '<', "/proc/diskstats") {
   while (my $reply = <$fh>) {
#      print $reply;

      if ($reply =~ /^\s+(\d+)\s+(\d+)\s+(.+?)\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+$/) {
  # thanks to Jonny Schulz <jschulz.cpan(at)bloonix.de>.
  #  --    --    --    F1   F2   F3   F4   F5   F6   F7   F8  F9  F10 F11
  #  $1    $2    $3    $4   --   $5   --   $6   --   $7   --  --  --   --
	if ( $3 eq "sda" or $3 eq "hda" ) {
		$what = $3;
		print "what=".$what."\n";
        }
##	} 
##      elsif ($reply =~ /^\s+(\d+)\s+(\d+)\s+(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/) {
  #  --    --    --    F1    F2    F3    F4
  #  $1    $2    $3    $4    $5    $6    $7
	if ( $3 eq "sda1" or $3 eq "hda1" ) {
		$hda1rio = $4;
		$hda1wio = $6;
		$hda1rse = $5;
		$hda1wse = $7;
		$what1 = $3;
	} elsif ( $3 eq "sda2" or $3 eq "hda2" ) {
                $hda2rio = $4;
                $hda2wio = $6;
                $hda2rse = $5;
                $hda2wse = $7;
		$what2 = $3;
        } elsif ( $3 eq "sda3" or $3 eq "hda3" ) {
                $hda3rio = $4;
                $hda3wio = $6;
                $hda3rse = $5;
                $hda3wse = $7;
		$what3 = $3;
        } elsif ( $3 eq "sda4" or $3 eq "hda4" ) {
		$hda4rio = $4;
                $hda4wio = $6;
		$hda4rse = $5;
		$hda4wse = $7;
		$what4 = $3;
	}
      }
   }
   close ($fh);
}

printf "device: %s, reads: %u, writes: %u, read sectors: %u, write sectors: %u\n",
$what1, $hda1rio, $hda1wio, $hda1rse, $hda1wse;
printf "device: %s, reads: %u, writes: %u, read sectors: %u, write sectors: %u\n",
$what2, $hda2rio, $hda2wio, $hda2rse, $hda2wse;
printf "device: %s, reads: %u, writes: %u, read sectors: %u, write sectors: %u\n",
$what3, $hda3rio, $hda3wio, $hda3rse, $hda3wse;
printf "device: %s, reads: %u, writes: %u, read sectors: %u, write sectors: %u\n",
$what4, $hda4rio, $hda4wio, $hda4rse, $hda4wse;

if ( $pgraphsset{"diskx_io_collect"} eq "Y" ) {
# if disk usage rrdtool database doesn't exist, create it
if (! -e "$rrd/diskx_io.rrd")
{
	print "creating rrd database for detailed disk io traffic...\n";
	system("$rrdtool create $rrd/diskx_io.rrd -s 300"
		." DS:hda1rio:DERIVE:600:0:U"
		." DS:hda1wio:DERIVE:600:0:U"
		." DS:hda2rio:DERIVE:600:0:U"
		." DS:hda2wio:DERIVE:600:0:U"
		." DS:hda3rio:DERIVE:600:0:U"
		." DS:hda3wio:DERIVE:600:0:U"
		." DS:hda4rio:DERIVE:600:0:U"
		." DS:hda4wio:DERIVE:600:0:U"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
}

# insert values into disk usage rrd
`$rrdtool update $rrd/diskx_io.rrd -t hda1rio:hda1wio:hda2rio:hda2wio:hda3rio:hda3wio:hda4rio:hda4wio N:$hda1rio:$hda1wio:$hda2rio:$hda2wio:$hda3rio:$hda3wio:$hda4rio:$hda4wio`;

# create disk activity graphs
&CreateGraphDiskx_io("day");
&CreateGraphDiskx_io("week");
&CreateGraphDiskx_io("month");
&CreateGraphDiskx_io("year");
}
if ( $pgraphsset{"diskx_bytes_collect"} eq "Y" ) {
# if disk usage rrdtool database doesn't exist, create it
if (! -e "$rrd/diskx_bytes.rrd")
{
	print "creating rrd database for detailed disk bytes traffic...\n";
	system("$rrdtool create $rrd/diskx_bytes.rrd -s 300"
		." DS:hda1rse:DERIVE:600:0:U"
		." DS:hda1wse:DERIVE:600:0:U"
		." DS:hda2rse:DERIVE:600:0:U"
		." DS:hda2wse:DERIVE:600:0:U"
		." DS:hda3rse:DERIVE:600:0:U"
		." DS:hda3wse:DERIVE:600:0:U"
		." DS:hda4rse:DERIVE:600:0:U"
		." DS:hda4wse:DERIVE:600:0:U"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
}

# insert values into disk usage rrd
`$rrdtool update $rrd/diskx_bytes.rrd -t hda1rse:hda1wse:hda2rse:hda2wse:hda3rse:hda3wse:hda4rse:hda4wse N:$hda1rse:$hda1wse:$hda2rse:$hda2wse:$hda3rse:$hda3wse:$hda4rse:$hda4wse`;

# create disk activity graphs
&CreateGraphDiskx_bytes("day");
&CreateGraphDiskx_bytes("week");
&CreateGraphDiskx_bytes("month");
&CreateGraphDiskx_bytes("year");
}
} else {
        print "diskx_io and diskx_bytes are not collecting at present\n";
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

sub CreateGraphDiskx_io
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/diskx_io-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Disk filesystem ios over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"ios/sec\""
                ." -b 1024"
                ." DEF:hda1rio=$rrd/diskx_io.rrd:hda1rio:AVERAGE"
                ." DEF:hda1wio=$rrd/diskx_io.rrd:hda1wio:AVERAGE"
                ." DEF:hda2rio=$rrd/diskx_io.rrd:hda2rio:AVERAGE"
                ." DEF:hda2wio=$rrd/diskx_io.rrd:hda2wio:AVERAGE"
                ." DEF:hda3rio=$rrd/diskx_io.rrd:hda3rio:AVERAGE"
                ." DEF:hda3wio=$rrd/diskx_io.rrd:hda3wio:AVERAGE"
                ." DEF:hda4rio=$rrd/diskx_io.rrd:hda4rio:AVERAGE"
                ." DEF:hda4wio=$rrd/diskx_io.rrd:hda4wio:AVERAGE"
                ." LINE1:hda1rio#FFCC66:\"$what1 /boot    reads \""
                ." GPRINT:hda1rio:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda1rio:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda1rio:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:hda1wio#FF9900:\"$what1 /boot    writes\""
                ." GPRINT:hda1wio:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda1wio:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda1wio:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:hda2rio#00CC66:\"$what2 swap     reads \""
                ." GPRINT:hda2rio:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda2rio:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda2rio:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:hda2wio#009900:\"$what2 swap     writes\""
                ." GPRINT:hda2wio:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda2wio:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda2wio:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:hda3rio#FF0066:\"$what3 /var/log reads \""
                ." GPRINT:hda3rio:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda3rio:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda3rio:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:hda3wio#FF0000:\"$what3 /var/log writes\""
                ." GPRINT:hda3wio:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda3wio:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda3wio:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:hda4rio#FF99FF:\"$what4 /        reads \""
                ." GPRINT:hda4rio:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda4rio:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda4rio:LAST:\" Current\\: %5.1lf %S /sec\\n\""
                ." LINE1:hda4wio#FF00FF:\"$what4 /        writes\""
                ." GPRINT:hda4wio:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda4wio:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda4wio:LAST:\" Current\\: %5.1lf %S /sec\""
                );
	}

sub CreateGraphDiskx_bytes
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/diskx_bytes-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Disk filesystem bytes over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"bytes/sec\""
                ." -b 1024"
                ." DEF:hda1rse=$rrd/diskx_bytes.rrd:hda1rse:AVERAGE"
                ." DEF:hda1wse=$rrd/diskx_bytes.rrd:hda1wse:AVERAGE"
                ." DEF:hda2rse=$rrd/diskx_bytes.rrd:hda2rse:AVERAGE"
                ." DEF:hda2wse=$rrd/diskx_bytes.rrd:hda2wse:AVERAGE"
                ." DEF:hda3rse=$rrd/diskx_bytes.rrd:hda3rse:AVERAGE"
                ." DEF:hda3wse=$rrd/diskx_bytes.rrd:hda3wse:AVERAGE"
                ." DEF:hda4rse=$rrd/diskx_bytes.rrd:hda4rse:AVERAGE"
                ." DEF:hda4wse=$rrd/diskx_bytes.rrd:hda4wse:AVERAGE"
                ." CDEF:hda1rby=hda1rse,512,*"
                ." CDEF:hda1wby=hda1wse,512,*"
                ." CDEF:hda2rby=hda2rse,512,*"
                ." CDEF:hda2wby=hda2wse,512,*"
                ." CDEF:hda3rby=hda3rse,512,*"
                ." CDEF:hda3wby=hda3wse,512,*"
                ." CDEF:hda4rby=hda4rse,512,*"
                ." CDEF:hda4wby=hda4wse,512,*"
                ." LINE1:hda1rby#FFCC66:\"$what1 /boot    read \""
                ." GPRINT:hda1rby:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda1rby:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda1rby:LAST:\" Current\\: %5.1lf %S bytes/sec\\n\""
                ." LINE1:hda1wby#FF9900:\"$what1 /boot    wrote\""
                ." GPRINT:hda1wby:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda1wby:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda1wby:LAST:\" Current\\: %5.1lf %S bytes/sec\\n\""
                ." LINE1:hda2rby#00CC66:\"$what2 swap     read \""
                ." GPRINT:hda2rby:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda2rby:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda2rby:LAST:\" Current\\: %5.1lf %S bytes/sec\\n\""
                ." LINE1:hda2wby#009900:\"$what2 swap     wrote\""
                ." GPRINT:hda2wby:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda2wby:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda2wby:LAST:\" Current\\: %5.1lf %S bytes/sec\\n\""
                ." LINE1:hda3rby#FF0066:\"$what3 /var/log read \""
                ." GPRINT:hda3rby:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda3rby:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda3rby:LAST:\" Current\\: %5.1lf %S bytes/sec\\n\""
                ." LINE1:hda3wby#FF0000:\"$what3 /var/log wrote\""
                ." GPRINT:hda3wby:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda3wby:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda3wby:LAST:\" Current\\: %5.1lf %S bytes/sec\\n\""
                ." LINE1:hda4rby#FF99FF:\"$what4 /        read \""
                ." GPRINT:hda4rby:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda4rby:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda4rby:LAST:\" Current\\: %5.1lf %S bytes/sec\\n\""
                ." LINE1:hda4wby#FF00FF:\"$what4 /        wrote\""
                ." GPRINT:hda4wby:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:hda4wby:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:hda4wby:LAST:\" Current\\: %5.1lf %S bytes/sec\\n\""
                );
}
