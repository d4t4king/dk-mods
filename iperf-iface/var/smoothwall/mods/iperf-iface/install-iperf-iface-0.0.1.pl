#!/usr/bin/perl
#
# This code is distributed under the terms of the GPL
#
# (c) The Smoothwall Team
#
# THIS MOD IS FOR SMOOTHWALL 3.1 (NOT 3.0 or 2.0)
#
# install script for [3.1] Iperf Interface v0.0.1
# Mod Author: dataking
# Release Date: 12/30/2013
#
# # # # # # # # # # # # # # # # # # #
# check for existing installations  #
# # # # # # # # # # # # # # # # # # #


print "Installing Iperf Interface v0.0.1...\n";

# # # # # # # # # # # #
# handle file copying #
# # # # # # # # # # # #

#	backupinstall ($file ,$wkdir ,$storebkp ,$moddir);
#	install ($file ,$wkdir ,$moddir);

my $bkp = '/var/smoothwall/mods/iperf-iface/backup';

my $mod = '/var/smoothwall/mods/iperf-iface/modfiles';

# Backup and install stuff in /httpd/cgi-bin
$dir = '/httpd/cgi-bin/';
&backup ('iptools.cgi' ,$dir ,$bkp ,$mod);
&install ('iptools.cgi' ,$dir ,$mod);

# Backup and install stuff in /httpd/html/help
$dir = '/httpd/html/help';
&backup ('iptools.cgi.html.en' ,$dir ,$bkp ,$mod);
&install ('iptools.cgi.html.en' ,$dir ,$mod);

# Backup base (in case)
$dir = '/usr/lib/smoothwall/langs';
&backup ('en.pl', $dir, $bkp, $mod);

# # # # # # # # # # # #
# handle permissions  #
# # # # # # # # # # # #

system ("chmod 755 /httpd/cgi-bin/iptools.cgi");
system ("chmod 1777 /tmp");

# # # # # # # # # # # #
# handle file editing #
# # # # # # # # # # # #

my $param = '/var/smoothwall/mods/iperf-iface/params';

&easymod ("/usr/lib/smoothwall/langs/en.pl", "$param/en.pl.1.s",'0',"$param/en.pl.1.r");

print "Done.\n";

# # # # # # # # # # # #
# handle file linking #
# # # # # # # # # # # #

# # # #
# end #
# # # #

#
# This code is distributed under the terms of the GPL
#
# (c) Tiago Freitas Leal

$version = '2.1';

#	$storebkp =	where to store backup of the files that are changed by your mod
#	$moddir =	where your mod files are
#	$wkdir =	where you are changing files (backup from and copy to)
#
#	backupinstall ($file ,$wkdir ,$storebkp ,$moddir);
#	backup ($file ,$wkdir ,$storebkp);
#	install ($file ,$wkdir ,$moddir);
#	uninstallrestore ($file ,$wkdir ,$storebkp);
#	uninstall ($file  ,$wkdir);
#
#	installed ($file, $string);
#
#	search for $string into $file => 1 found / 0 not found

sub backupinstall
{
	my $file = $_[0];
	my $wkdir = $_[1];
	my $storebkp = $_[2];
	my $moddir = $_[3];
#	system "/bin/cp -p $wkdir/$file $storebkp/$file";
	system "/bin/cp $moddir/$file $wkdir/$file";
}

sub backup
{
	my $file = $_[0];
	my $wkdir = $_[1];
	my $storebkp = $_[2];
	system "/bin/cp -p $wkdir/$file $storebkp/$file";
}

sub install
{
	my $file = $_[0];
	my $wkdir = $_[1];
	my $moddir = $_[2];
	system "/bin/cp -p $moddir/$file $wkdir/$file";
}

sub uninstallrestore
{
	my $file = $_[0];
	my $wkdir = $_[1];
	my $storebkp = $_[2];
	system "/bin/cp -p $storebkp/$file $wkdir/$file";
#	system "/bin/rm -f $storebkp/$file";
}

sub uninstall
{
	my $file = $_[0];
	my $wkdir = $_[1];
	system "/bin/rm -f $wkdir/$file";
}

sub easymod
{
	my $targetfile = $_[0];
	my $searchfile = $_[1];
	my $linestodelete = $_[2];
	my $replacefile = $_[3];

	open(TARGET, "$targetfile") or die 'Unable to open target file.';
	my @target = <TARGET>;
	close(TARGET);

	open(SEARCH, "$searchfile") or die 'Unable to open search file';
	my @search = <SEARCH>;
	close(SEARCH);

	open(REPLACE, "$replacefile") or die 'Unable to open replace file.';
	my @replace = <REPLACE>;
	close(REPLACE);

	open(TEMP, ">/tmp/temp") or die 'Unable to open temporary file.';
	flock TEMP, 2;

	my $found = 0;
	my $line;
	foreach $line (@target)
	{
		if ($found == 0)
		{
			if ($line eq "@search")
			{
				$found = 1;
				if ($linestodelete > 0)
				{
					$linestodelete--;
				}
				else {print TEMP "$line"; }
				my $repline;
				foreach $repline (@replace) {print TEMP $repline; }
			}
			else {print TEMP "$line"; }
		}
		else
		{
			if ($linestodelete > 0)
			{
				$linestodelete--;
			}
			else {print TEMP "$line"; }
		}
	}	
	close(TEMP);
	system "/bin/cp /tmp/temp $targetfile";
	system "/bin/rm -f /tmp/temp";
}

sub installed
{
	my $targetfile = $_[0];
	my $searchstring = $_[1];

	open(TARGET, "$targetfile") or die 'Unable to open target file.';
	my @target = <TARGET>;
	close(TARGET);

	my $line;
	foreach $line (@target)
	{
		if ($line eq "$searchstring\n")
		{
			return 1;
		}
	}	
	return 0;
}
