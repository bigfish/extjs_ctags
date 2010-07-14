#!/usr/bin/perl
#!/usr/bin/perl
use File::Basename;
#script to extract exuberant ctags from Ext js source code
my $file = shift;

#find classes in file
(my $filename, my $filepath, my $ext) = fileparse($file, qr{\..*});
#read file into string
open(HANDLE, $file) || die ("could not open file $file");
my @lines = <HANDLE>;
close(HANDLE);

my %pointers = ();
my %targets = ();
my @parts;

#loop through lines 3 times : once to get pointers, second to get tags they point at, third to substitute pointers
#first loop get lines which are pointer references and put into pointers hash
foreach(@lines){
	chomp;
	my $line = $_;
	if( index($line, "==>" ) > -1 ) {
		@parts = split(/==>/, $line);
		#the value of the pointer is a hash with the following structure:
		# member: tagname (last part of full dotted name)
		# class: class where pointer is defined (second last part of full dotted name)
		# targetMember: tag name of target of reference (last part of target full name)
		# targetClass: class where target of reference is defined (second last part of full name of target)
		#print "parts: @parts \n";
		my $pointer_name = $parts[0];
		#print "pointer_name: $pointer_name \n";
		#my %pointers{$pointer_name} = ();

		my %pointer_name_value = getMemberAndClass($pointer_name);
		$pointers{$pointer_name}{"member"} = $pointer_name_value{"member"};
		$pointers{$pointer_name}{"class"} = $pointer_name_value{"class"};

		my %targ_value = getMemberAndClass($parts[1]);
		$pointers{$pointer_name}{"targetMember"} = $targ_value{"member"};
		$pointers{$pointer_name}{"targetClass"} = $targ_value{"class"};

		#enable reverse lookup by combination member for next stage
		#use class name + member name to be unique
		$targets{$targ_value{"class"}.".".$targ_value{"member"}} = $pointer_name;

	}
}

##second loop
foreach(@lines){
	chomp;
	my $line = $_;

	#if line starts with target of pointer, insert pointer 'tagline' value with tag string
	foreach(keys %targets) {
		my $targetName = $_;
		my @bits = split(/\./, $targetName);
		my $targetClass = @bits[0];
		my $targetMember = @bits[1];
		#if ($line =~ /^$targetMember.*class:\s?$targetClass.*/) {
		if ($line =~ /^$targetMember/) {


			#inject tagline into pointers hash
			my $pointerName = $targets{$targetName};
			#instead of duplicating the target tag line
			#we must replace the targetMember and targetClass with member and class
			my $member = $pointers{$pointerName}{"member"};
			my $class = $pointers{$pointerName}{"class"};
			$line =~ s/class:$targetClass/class:$class/;
			$line =~ s/^$targetMember/$member/;
			$pointers{$pointerName}{"tagline"} = $line;
		} 
	
	}
	
}
my @outlines = [];
#third loop -- output replaced tag line if pointer found, or else just output original line
foreach(@lines){
	chomp;
	my $line = $_;
	my $tag;
	if( index($line, "==>" ) > -1 ) {
		@parts = split(/==>/, $line);
		my $pointer_name = $parts[0];
		$tag = $pointers{$pointer_name}{"tagline"}."\n";
		push(@outlines, $tag);
	} else {
		push(@outlines, $line."\n");
	}
}

#sort lines and spit out
my @output = sort(@outlines);
foreach(@output){
	my $l = $_;
	#skip empty lines
	if($l !~ /^\s*$/) {
		print $_;
	}
}

sub getMemberAndClass
{
	my $full_name = shift;
	#print "full name: $full_name \n";
	my %result = ();

	if (index($full_name, '.') > -1) {

		my @full_name_parts = split(/\./, $full_name);
		#print "full_name_parts @full_name_parts \n";
		if ( scalar (@full_name_parts) > 1) {
			#member is last part of dotted name
			$result{'member'} = pop(@full_name_parts);
			#class is second last part (class is actually just an object...)
			$result{'class'} = pop(@full_name_parts);
		}
		
	}

	return %result;

}


