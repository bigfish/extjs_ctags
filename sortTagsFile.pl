#!/usr/bin/perl
# read a file, sort it, and output it
use File::Basename;
my $file = shift;
#find classes in file
(my $filename, my $filepath, my $ext) = fileparse($file, qr{\..*});
#read file into string
open(HANDLE, $file) || die ("could not open file $file");
my @lines = <HANDLE>;
close(HANDLE);

@lines = sort(@lines);
foreach(@lines){
	print $_;
}
