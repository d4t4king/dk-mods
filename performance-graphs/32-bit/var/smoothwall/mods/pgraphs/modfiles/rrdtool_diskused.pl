#!/usr/bin/perl
#
# coded by Martin Pot 2003
# http://martybugs.net/smoothwall/rrdtool_mem.cgi
#
# SmoothWall scripts
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
# rrdtool_diskusage.pl

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
$pgraphsset{"disk_used_collect"} = 'Y';
$pgraphsset{"inodes_used_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

my ($rootfs, $rootin, $rootdev, $rootsize);
my ($bootfs, $bootin, $bootdev, $bootsize);
my ($vlogfs, $vlogin, $vlogdev, $vlogsize);

if ( ( $pgraphsset{"disk_used_collect"} eq "Y" ) ||
     ( $pgraphsset{"inodes_used_collect"} eq "Y" ) ) {

# get disk partition traffic usage

  if ( $pgraphsset{"disk_used_collect"} eq "Y" ) {
  # if disk usage rrdtool database doesn't exist, create it
    if (! -e "$rrd/disk_used.rrd")
    {
	print "creating rrd database for disk filesystem usage...\n";
	system("$rrdtool create $rrd/disk_used.rrd -s 300"
		." DS:rootfs:GAUGE:600:0:110"
		." DS:bootfs:GAUGE:600:0:110"
		." DS:vlogfs:GAUGE:600:0:110"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
    } 

    @echo = `df -k`;
    shift(@echo);
    foreach $mount (@echo) {
      chomp($mount);
      ($dev, $size, $size_used, $size_avail, $size_percentage, $mount_point) = split(/\s+/,$mount);
      $dev =~ s!/dev/!!;
      #specs say the used percentage = used/(used+avail) rather than used/size
      if ($mount_point eq '/')        { 
	$rootfs = 100*($size_used/($size_used+$size_avail));
    	$rootdev = $dev;
      }
      if ($mount_point eq '/boot')    { 
	$bootfs = 100*($size_used/($size_used+$size_avail));
    	$bootdev = $dev;
      }
      if ($mount_point eq '/var/log') { 
	$vlogfs = 100*($size_used/($size_used+$size_avail));
    	$vlogdev = $dev;
      }
    }
    # insert values into disk usage rrd
    `$rrdtool update $rrd/disk_used.rrd -t rootfs:bootfs:vlogfs N:$rootfs:$bootfs:$vlogfs`;
print "$rrdtool update $rrd/disk_used.rrd -t rootfs:bootfs:vlogfs N:$rootfs:$bootfs:$vlogfs\n";

    @echo = `df -h`;
    shift(@echo);
    foreach $mount (@echo) {
      chomp($mount);
      ($dev, $size, $size_used, $size_avail, $size_percentage, $mount_point) = split(/\s+/,$mount);
      if ($mount_point eq '/')        { $rootsize = $size.'B'; } 
      if ($mount_point eq '/boot')    { $bootsize = $size.'B'; }
      if ($mount_point eq '/var/log') { $vlogsize = $size.'B'; }
    }
    
    # create disk usage graphs
    &CreateGraphDisk_used("day");
    &CreateGraphDisk_used("week");
    &CreateGraphDisk_used("month");
    &CreateGraphDisk_used("year");
  }
  
  if ( $pgraphsset{"inodes_used_collect"} eq "Y" ) {
  # if disk usage rrdtool database doesn't exist, create it
    if (! -e "$rrd/inodes_used.rrd")
    {
	print "creating rrd database for disk filesystem inodes usage...\n";
	system("$rrdtool create $rrd/inodes_used.rrd -s 300"
		." DS:rootin:GAUGE:600:0:110"
		." DS:bootin:GAUGE:600:0:110"
		." DS:vlogin:GAUGE:600:0:110"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
    }  

    @echo = `df -i`;
    shift(@echo);
    foreach $mount (@echo) {
      chomp($mount);
      ($dev, $size, $size_used, $size_avail, $size_percentage, $mount_point) = split(/\s+/,$mount);
      $dev =~ s!/dev/!!;
      if ($mount_point eq '/') { 
	$rootin = 100*($size_used/$size);
    	$rootdev = $dev;
      }
      if ($mount_point eq '/boot') { 
	$bootin = 100*($size_used/$size);
    	$bootdev = $dev;
      }
      if ($mount_point eq '/var/log') { 
	$vlogin = 100*($size_used/$size);
    	$vlogdev = $dev;
      }
    }
    # insert values into inodes used rrd
    `$rrdtool update $rrd/inodes_used.rrd -t rootin:bootin:vlogin N:$rootin:$bootin:$vlogin`;
print "$rrdtool update $rrd/inodes_used.rrd -t rootin:bootin:vlogin N:$rootin:$bootin:$vlogin\n";
   
    # create disk inode graphs
    &CreateGraphInodes_used("day");
    &CreateGraphInodes_used("week");
    &CreateGraphInodes_used("month");
    &CreateGraphInodes_used("year");
  }
} else {
  print "disk_used and inodes_used are not collecting at present\n";
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

sub CreateGraphDisk_used
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/disk_used-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Filesystem space usage over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
		." -u 100"
                ." -X 0"
                ." -a PNG"
                ." -v \"% used\""
                ." -b 1024"
                ." DEF:rootfs=$rrd/disk_used.rrd:rootfs:AVERAGE"
                ." DEF:bootfs=$rrd/disk_used.rrd:bootfs:AVERAGE"
                ." DEF:vlogfs=$rrd/disk_used.rrd:vlogfs:AVERAGE"
                ." LINE1:bootfs#FF9900:\"$bootdev /boot   \""
                ." GPRINT:bootfs:MAX:\" Max\\: %5.2lf\""
                ." GPRINT:bootfs:AVERAGE:\" Avg\\: %5.2lf\""
                ." GPRINT:bootfs:LAST:\" Current\\: %5.2lf %% of $bootsize\\n\""
                ." LINE1:vlogfs#FF0000:\"$vlogdev /var/log\""
                ." GPRINT:vlogfs:MAX:\" Max\\: %5.2lf\""
                ." GPRINT:vlogfs:AVERAGE:\" Avg\\: %5.2lf\""
                ." GPRINT:vlogfs:LAST:\" Current\\: %5.2lf %% of $vlogsize\\n\""
                ." LINE1:rootfs#FF00FF:\"$rootdev /       \""
                ." GPRINT:rootfs:MAX:\" Max\\: %5.2lf\""
                ." GPRINT:rootfs:AVERAGE:\" Avg\\: %5.2lf\""
                ." GPRINT:rootfs:LAST:\" Current\\: %5.2lf %% of $rootsize\\n\""
                );
	}

sub CreateGraphInodes_used
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

        system("$rrdtool graph $img/inodes_used-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Filesystem inodes usage over the last $_[0]\""
		." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
		." -u 100"
		." -X 0"
                ." -a PNG"
		." -v \"% used\""
                ." -b 1024"
                ." DEF:rootin=$rrd/inodes_used.rrd:rootin:AVERAGE"
                ." DEF:bootin=$rrd/inodes_used.rrd:bootin:AVERAGE"
                ." DEF:vlogin=$rrd/inodes_used.rrd:vlogin:AVERAGE"
                ." LINE1:bootin#FF9900:\"$bootdev /boot   \""
                ." GPRINT:bootin:MAX:\" Max\\: %5.2lf\""
                ." GPRINT:bootin:AVERAGE:\" Avg\\: %5.2lf\""
                ." GPRINT:bootin:LAST:\" Current\\: %5.2lf %%\\n\""
                ." LINE1:vlogin#FF0000:\"$vlogdev /var/log\""
                ." GPRINT:vlogin:MAX:\" Max\\: %5.2lf\""
                ." GPRINT:vlogin:AVERAGE:\" Avg\\: %5.2lf\""
                ." GPRINT:vlogin:LAST:\" Current\\: %5.2lf %%\\n\""
                ." LINE1:rootin#FF00FF:\"$rootdev /       \""
                ." GPRINT:rootin:MAX:\" Max\\: %5.2lf\""
                ." GPRINT:rootin:AVERAGE:\" Avg\\: %5.2lf\""
                ." GPRINT:rootin:LAST:\" Current\\: %5.2lf %%\\n\""
                );
}
