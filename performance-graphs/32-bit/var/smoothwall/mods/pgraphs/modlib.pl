#
# This code is distributed under the terms of the GPL
#
# (c) Tiago Freitas Leal
# (c) Drew S. Dupont - Modifications

$version = '2.3';

#	$storebkp =	where to store backup of the files that are changed by your mod
#	$moddir =	where your mod files are
#	$wkdir =	where you are changing files (backup from and copy to)
#
#	backupinstall ($file, $wkdir, $storebkp, $moddir);
#	backup ($file, $wkdir, $storebkp);
#	install ($file, $wkdir, $moddir);
#	uninstallrestore ($file, $wkdir, $storebkp);
#	uninstall ($file, $wkdir);
#	easymod ($targetfile, $searchfile, $linetodelete, $replacefile);
#	installed ($file, $string);
#
#	search for $string into $file => 1 found / 0 not found

sub backupinstall {
	my $file = $_[0];
	my $wkdir = $_[1];
	my $storebkp = $_[2];
	my $moddir = $_[3];
	print "Backing up $wkdir/$file to $storebkp/$file ...\n";
	system "/bin/cp -fp $wkdir/$file $storebkp/$file";
	print "Installing $moddir/$file to $wkdir/$file ...\n";
	system "/bin/rm -f $wkdir/$file";
	system "/bin/cp -p $moddir/$file $wkdir/$file";
}

sub backup {
	my $file = $_[0];
	my $wkdir = $_[1];
	my $storebkp = $_[2];
	print "Backing up $wkdir/$file to $storebkp/$file ...\n";
	system "/bin/cp -fp $wkdir/$file $storebkp/$file";
}

sub install {
	my $file = $_[0];
	my $wkdir = $_[1];
	my $moddir = $_[2];
	my $targetfile = $_[3];
	my $sedreplace = $_[4];
	if ($targetfile eq '') {
		$targetfile = $file;
	}
	print "Installing $moddir/$file to $wkdir/$targetfile ...\n";
	system "/bin/rm -f $wkdir/$file";
	if ($sedreplace eq '') {
		system "/bin/cp -p $moddir/$file $wkdir/$targetfile";
	} else {
		`sed -n "{$sedreplace p;}" $moddir/$file >> $wkdir/$targetfile`;
		system "/bin/chown nobody:nobody $wkdir/$targetfile";
	}
}

sub uninstallrestore {
	my $file = $_[0];
	my $wkdir = $_[1];
	my $storebkp = $_[2];
	print "Uninstalling $wkdir/$file ...\n";
	system "/bin/rm -f $wkdir/$file";
	print "Restoring $storebkp/$file to $wkdir/$file ...\n";
	system "/bin/cp -p $storebkp/$file $wkdir/$file";
}

sub uninstall {
	my $file = $_[0];
	my $wkdir = $_[1];
	print "Uninstalling $wkdir/$file ...\n";
	system "/bin/rm -f $wkdir/$file";
}

sub easymod {
	my $targetfile = $_[0];
	my $searchfile = $_[1];
	my $linestodelete = $_[2];
	my $linestodeleteorig = $_[2];
	my $replacefile = $_[3];

	open(TARGET, "$targetfile") or die 'Unable to open target file.';
	my @target = <TARGET>;
	close(TARGET);

	open(SEARCH, "$searchfile") or die 'Unable to open search file';
	my @search = <SEARCH>;
	close(SEARCH);

	open(REPLACE, "$replacefile") or die 'Unable to open replace file: '.$replacefile;
	my @replace = <REPLACE>;
	close(REPLACE);

	open(TEMP, ">/tmp/temp") or die 'Unable to open temporary file.';
	flock TEMP, 2;

	print "Modifying $targetfile ...\n";

	my $line;
	my $hold = '';
	my $cnt = 0;
	my $searchsize = @search;
	foreach $line (@target) {
		if ($line eq "$search[$cnt]") {
			$cnt++;
#			print "match : "."$search[$cnt-1]";
			if ($linestodelete > 0) {
				$linestodelete--;
				$hold = $hold . $line;
			} else {
				print TEMP "$line";
			}

			if ($cnt == $searchsize) {
				$hold = '';
				$cnt = 0;
				my $repline;

				foreach $repline (@replace) {
					print TEMP $repline;
#					print "insert:".$repline;
				}

				$linestodelete = $linestodeleteorig;
			}
		} else {
			if ($cnt > 0) {
				print TEMP "$hold";
				$hold = '';
				$linestodelete = $linestodeleteorig;
			}

			print TEMP "$line";
			$cnt = 0;
		}
	}	

	close(TEMP);
	system "/bin/cp /tmp/temp $targetfile";
	system "/bin/rm -f /tmp/temp";
}

sub installed {
	my $targetfile = $_[0];
	my $searchstring = $_[1];

	open(TARGET, "$targetfile") or die 'Unable to open target file.';
	my @target = <TARGET>;
	close(TARGET);

	my $line;
	foreach $line (@target) {
		if ($line eq "$searchstring\n") {
			return 1;
		}
	}	

	return 0;
}
