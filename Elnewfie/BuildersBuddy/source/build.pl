#!/usr/bin/perl -w
use File::Basename;

my $outname = $ARGV[1] . '/' . basename($ARGV[0]);
my $outfile;
open $outfile, '>' . $outname or die "Unable to open outfile: " . $outname;

merge($ARGV[0], $outfile);
close $outfile;
exit;

####################################
sub merge {
	my $file;
	my $outfile = $_[1];
	my $opened = 1;
	open $file, $_[0] or $opened = 0;
	if(!$opened) {
		printf STDERR "Could not open module " . $_[0] . "\n";
		return(0);
	}
	
	while(<$file>) {
		if(/^\W?\$import (\S*?)\s/) {
			#Get the module filename
			my $module = $1;
			$module =~ s/\./\//g;
			$module =~ s/;//;
			$module =~ s/\/lslm/\.lslm/;
			
			#Did we do this one already?
			if(!hasModule($module)) {
				if($module ne 'common/log.lslm') {
					#Import the module
					addModule($module);
					merge($module, $outfile);
				}
			}
			
		} else {
			#Strip out module statements
			next if(/^\$module/);
	
			#Strip out debug statements
			next if(/debug\(/);
			next if(/debugl\(/);
			
			print $outfile $_;
		}
	}
	
	close $file;
}

{
	my @modules = ();

	####################################
	sub hasModule {
		my $module = $_[0];
		my $count = 0 + @modules;
		
		for(my $i = 0; $i < $count; $i++) {
			if($modules[$i] eq $module) { return 1; }
		}
		
		return 0;
	}
	
	####################################
	sub addModule {
		my $module = $_[0];
		push(@modules, $module);
	}
}