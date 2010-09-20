#!/usr/bin/perl
$tags_file=shift;

my %externs;

open(HANDLE, $tags_file) || die ("could not open file $tags_file");
my @taglines = <HANDLE>;
close(HANDLE);

foreach(@taglines){
	my $tagline = $_;
	my $tagname = "";
	my @namespace;
	my $class = "";
	my $type = "";
	my $link = "";
	my $singleton = 0;

	#functions
	if( $tagline =~ /^([^\t]*)\t([^\t]*)\s\/.*\$\/;"\s([a-z])\sclass\:([\S]+).*link\:([\S]*)/){
		$tagname = $1;
		$type = $3;
		$link = $5;
		@namespace = split(/\./, $link);
		$class = pop(@namespace);
		if($type =~ /c/){
			#class -- when Ext.extend() is used to create a class, there will be no constructor function
			#TODO: create Namespace
			#TODO: get signature ? not always possible with inherited classed
			#TODO: get type info + params / return ?
			#class have link == full class name
			print "/**\n";
			print " * \@constructor\n";
			print " */\n";
			print "$link = function () {};\n";
		}
		if($type =~	/m/){
			#method
			#methods have link == class which contains them
			#unless we are in a singleton, attach methods to the prototype of the constructor
			if ($tagline =~ /isstatic\:yes/){
				print "$link\.$tagname = function () {};\n";
			} else {
				print "$link\.prototype\.$tagname = function () {};\n";
			}
		
		}
		if ($type =~ /v/){
			#get type of var
			if($tagline =~ /.*type\:(\S*)/){
				$type_spec = convertType($1);
				print "/**\n";
				print " * \@type {$type_spec}\n";
				print " */\n";
			} else {
				print "var has no type: "
			}
			#TODO default values corresponding to types ?? is this necessary?
			print "$link\.$tagname = {};\n";
		}
	}
}

#TODO
sub convertParams
{

}
#TODO: typedefs ??
sub convertType
{
	my $jsdoc_type = shift;
	#replace / with |
	if ($jsdoc_type =~ /\//){
		$jsdoc_type =~ s/\//\|/g;
		$jsdoc_type = "(" . $jsdoc_type . ")";
	}
	$jsdoc_type =~ s/String/string/g;
	$jsdoc_type =~ s/Number/number/g;
	$jsdoc_type =~ s/int/number/g;
	$jsdoc_type =~ s/Array/array/g;
	$jsdoc_type =~ s/Object/object/g;
	$jsdoc_type =~ s/Function/function/g;
	$jsdoc_type =~ s/Boolean/boolean/g;
	$jsdoc_type =~ s/([A-Za-z0-9_\$\.]*)\[\]/Array\.\<\1\>/g;
	return $jsdoc_type;
}
