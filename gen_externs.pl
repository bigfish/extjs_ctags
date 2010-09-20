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
			print "$link\.$tagname = function () {};\n";
		
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
			print "$link\.$tagname = {};\n";
		}
		#print "$tagname $type $class $link\n";
	}
}

sub convertType
{
	my $jsdoc_type = shift;
	#replace / with |
	$jsdoc_type =~ s/\//\|/g;
	#TODO: lowercase native types
	$jsdoc_type =~ s/String/string/g;
	$jsdoc_type =~ s/Number/number/g;
	$jsdoc_type =~ s/int/number/g;
	$jsdoc_type =~ s/Array/array/g;
	$jsdoc_type =~ s/Object/object/g;
	$jsdoc_type =~ s/Function/function/g;
	$jsdoc_type =~ s/Boolean/boolean/g;
	#TODO: replace Union types [] with ()
	#TODO: replace foo[] with Array.<foo>
	#TODO replace foo? with foo=
	#TODO replace foo* with ...foo
	return $jsdoc_type;
}
