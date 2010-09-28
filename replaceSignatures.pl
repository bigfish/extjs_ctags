#!/usr/bin/perl
use File::Basename;
my $file = shift;

open(HANDLE, $file) || die ("could not open file $file");
my @lines = <HANDLE>;
close(HANDLE);

my %classes;
my %subclasses;

#PREPARE
#collect the pairs of class and constructor tags into pairs 
foreach(@lines){
	chomp;
	my $line = $_;
	my $sig; 
	my $class;
	my $type;
	my $superclass;
	#get type token
	if ($line =~ /^([A-Z]+[^\t]*)\t.*\/;"\t([a-z])/){
		$class = $1;
		print "CLASS: $class \n";
		$type = $2;
		if ($type eq "c"){#class
			if ($line =~ /\tinherits\:([^\t]*)/){
				$superclass = $1;
				#we only want the class name
				if ($superclass =~ /\.([^\.]*)$/){
					$superclass = $1;
					print "SUPERCLASS: $superclass \n";
				} 
				if (exists $subclasses{$class} ){
					#add 'super' property to exisiting subclass hash ref
					$subclasses{$class}->{'super'} = $superclass;
				} else {
					#create new subclass hash with super property
					$subclasses{$class} = { 'super' => $superclass };
				}
			}
		} elsif ($type eq 'f') {#function
			if ($line =~ /\tsignature\:\(([^\)]*)\)/){
				$sig = $1;
				#print "got sig $sig for $class \n";
				if (exists $subclasses{$class} ){
					#add sig property to subclass hash ref
					$subclasses{$class}->{'sig'} = $1;
				} else {
					#create new subclass hash with sig property
					$subclasses{$class} = { 'sig' => $sig };
				}
			}
		}
	}
}

#MAIN -- replace signatures
my $class;
my $supersig;
foreach(@lines){
	chomp;
	my $line = $_;
	#get type token
	if ($line =~ /^([A-Z]+[^\t]*)\t.*\tsignature\:\(([^\)]*)\)/){
		my $class = $1;
		if (exists $subclasses{$class}){
			$supersig = getSignature($class);
			$line =~ s/\tsignature\:\([^)]*\)/\tsignature\:\($supersig\)/;
		}
	}
	print $line . "\n";
}

sub getSignature
{
	my $cl = shift;
	print "getSignature($cl) \n";
	my $cl_sig = $subclasses{$cl}->{'sig'};
	#if there is a signature on the class, just return it
	if ( $cl_sig !~ /^\s*$/){
		return $cl_sig;
	# otherwise get superclass
	} elsif (exists $subclasses{$cl}->{'super'}){
		$cl_super = $subclasses{$cl}->{'super'};
		return getSignature( $cl_super );
	} 
}
