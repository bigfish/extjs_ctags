#!/usr/bin/perl
use File::Basename;
my $file = shift;

#read file into string
open(HANDLE, $file) || die ("could not open file $file");
my @lines = <HANDLE>;
close(HANDLE);

my %classes;
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
				#we only want the class name
				if ($superclass =~ /\.([^\.]*)$/){
					$superclass = $1;
				} 
				if (exists $subclasses{$class} ){
					$subclasses{$class}->{'super'} = $superclass;
				} else {
					$subclasses{$class} = { super => $superclass };
				}
			}
		} elsif ($type eq 'f') {
			if ($line =~ /\tsignature\:\(([^\)]*)\)/){
				$sig = $1;
				#print "got sig $sig for $class \n";
				if (exists $subclasses{$class} ){
					$subclasses{$class}->{'sig'} = $1;
				} else {
					$subclasses{$class} = { sig => $sig };
				}
			}
		}
	}
}
my $supersig;
foreach $cls ( keys %subclasses ) {
	$supersig = getSignature($cls);
	#print "derived sig $supersig for class $cls \n";
	#replace signature value in tag
	foreach(@lines){
		chomp;
		my $line = $_;
		my $sig; 
		my $class;

		if ($line =~ /^$cls/){
			if ($line =~ /\tsignature\:[^\t]*/){
				$line =~ s/\tsignature\:[^\t]*/\tsignature\:\($supersig\)/;
			}
		}
		print $line . "\n";
	}
}

sub getSignature
{
	my $cl = shift;
	my $cl_sig = $subclasses{$cl}->{'sig'};
	my $cl_super;

	if (exists $subclasses{$cl}->{'super'}){
		$cl_super = $subclasses{$cl}->{'super'};
	} else {
		#no superclass, return signature
		return $cl_sig;
	}

	#we only care about classes which are subclasses
	if ( $cl_super ne ""){
		#print "subclass: $cl inherits $cl_super \n";
		#only inherit signature if signature is empty
		if ( $cl_sig =~ /^\s*$/){
			$scl = getSignature( $cl_super );
			return $scl;
		} else {
			return $cl_sig;
		}
	}
}
