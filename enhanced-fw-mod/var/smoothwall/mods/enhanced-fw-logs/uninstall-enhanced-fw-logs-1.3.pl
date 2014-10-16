#!/usr/bin/perl
#
# This code is distributed under the terms of the GPL
#
# (c) Tiago Freitas Leal
#
# uninstall script for [3.0] Enhanced Firewall Logs MOD V1.3
# MOD Author: KrisTof on smoothwall forums
# Release date: 05/18/2010

# # # # # # # # # # # # # # # # # # #
# check for existing installations  #
# # # # # # # # # # # # # # # # # # #

if (&installed ("/usr/lib/smoothwall/langs/base.pl", "# Enhanced Firewall Logs MOD V1.3")) {
	print "\nUninstalling Enhanced Firewall Logs MOD V1.3\n \n";
}
else
{
	        print " \nCan not find Enhanced Firewall Logs MOD V1.3!\n \n";
	        exit;
			}


# # # # # # # # # # # #
# handle file copying #
# # # # # # # # # # # #

my $bkp = '/var/smoothwall/mods/enhanced-fw-logs/backup';

my $mod = '/var/smoothwall/mods/enhanced-fw-logs/modfiles';

$dir = '/httpd/cgi-bin/logs.cgi';
&uninstallrestore ('firewalllog.dat' ,$dir, $bkp);

$dir = '/httpd/html/help';
&uninstallrestore ('firewalllog.dat.html.en', $dir, $bkp);

# # # # # # # # # # # #
# handle file editing #
# # # # # # # # # # # #

my $param = '/var/smoothwall/mods/enhanced-fw-logs/params';

&easymod ("/usr/lib/smoothwall/langs/base.pl", "$param/base.pl.93.d",'7',"/dev/null");


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
