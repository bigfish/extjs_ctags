#!/usr/bin/perl
use File::Basename;
my $file = shift;

#read file into string
open(HANDLE, $file) || die ("could not open file $file");
my @lines = <HANDLE>;
close(HANDLE);

my %subclasses;

#collect the pairs of class and constructor tags into pairs 
foreach(@lines){
	chomp;
	my $line = $_;
	my $sig; 
	my $class;
	my $type;
	my $superclass;

	if ($line =~ /^([A-Z]+[^\t]*)\t[^\t]*\t.*;"\t([a-z])/){
		$class = $1;
		$type = $2;
		if ($type eq "c"){
			if ($line =~ /\tinherits\:([^\t]*)/){
				$superclass = $1;
				if (exists $subclasses{$class} ){
					$subclasses{$class}->{'super'} = $superclass;
				} else {
					$subclasses{$class} = { super => $superclass };
				}
			}
		} elsif ($type eq 'f') {
			if ($line =~ /\tsignature\:\(([^\)]*)\)/){
				$sig = $1;
				if (exists $subclasses{$class} ){
					$subclasses{$class}->{'sig'} = $1;
				} else {
					$subclasses{$class} = { sig => $sig };
				}
			}
		}
	}
}

foreach $cl ( keys %subclasses ) {
	my $cl_super = $subclasses{$cl}->{'super'};
	my $cl_sig = $subclasses{$cl}->{'sig'};
	#we only care about classes which are subclasses
	if ( $cl_super ne ""){
		print "subclass: $cl inherits $cl_super \n";
		#only inherit signature if signature is empty

	}
}

