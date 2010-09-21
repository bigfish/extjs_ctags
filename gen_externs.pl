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
	my $extern;
	my $ns_len;
	my $namespaceStr;
	my $extends;
	my $return;
	#functions
	if( $tagline =~ /^([^\t]*)\t([^\t]*)\s\/.*\$\/;"\s([a-z])\sclass\:([\S]+).*link\:([\S]*)/){
		$tagname = $1;
		$type = $3;
		$link = $5;
		@namespace = split(/\./, $link);
		$class = pop(@namespace);
		$ns_len = scalar @namespace;
		#create Namespace component objects if they do not exist
		while ($ns_len > 0){
			if($ns_len > 1){
				$namespaceStr = join(".", @namespace);
			} else {
				$namespaceStr = $namespace[0];
			}
			if (!exists $externs{$namespaceStr}){
				#keep track of externs so we don't add duplicates
				$externs{$namespaceStr} = "{}";
				print "var $namespaceStr = {};\n";
			}
			pop(@namespace);
			$ns_len = scalar(@namespace);
		}
		if($type =~ /c/){
			#class -- when Ext.extend() is used to create a class, there will be no constructor function
			#TODO: get signature ? not always possible with inherited classed
			#TODO: get type info + params / return ?
			#class have link == full class name
			if(!exists $externs{$link}){
				print "/**\n";
				print " * \@constructor\n";
				if ($tagline =~ /inherits\:([^\t]+)\t/){
					print " * \@extends {$1}\n";
				}
				getFnMeta($tagline);
				print " */\n";
				#TODO: params
				$externs{$link} = "function () {};";
				print "$link = function () {};\n";
			}
		}
		if($type =~	/m/){
			#method
			#methods have link == class which contains them
			#attach methods to the prototype of the constructor,
			#except static methods ( which are simply members of the 'class' object)
			if ($tagline =~ /isstatic\:yes/){
				$extern = "$link\.$tagname";
			} else {
				$extern = "$link\.prototype\.$tagname";
			}
			if(!exists $externs{$extern}){
				print "/**\n";
				getFnMeta($tagline);
				#if has type: use type as return
				if($tagline =~ /type\:([^\t]*)/){
					$return = convertType($1);
					print " * \@return {$return}\n";
				}
				print " */\n";
				print "$extern = function(){}\n";
			}
		
		}
		if ($type =~ /v/){
			$extern = "$link\.$tagname";
			if(!exists $externs{$extern}){
				#get type of var
				if($tagline =~ /.*type\:(\S*)/){
					$type_spec = convertType($1);
					print "/**\n";
					print " * \@type {$type_spec}\n";
					print " */\n";
				}
				#make value same type as type?
				print "$extern = {};\n";
			}
		}
	}
}

#process a tag with a constructor or method and print the params and return type, if any
sub getFnMeta
{
	my $tag = shift;
	my $sig;
	my @params;
	my $clean_param;
	my $pname;
	my $ptype;
	if($tag =~ /signature\:\(([^\)]+)\)/){
		$sig = $1;
		if(length($sig) > 0){
			if(index($sig, /\,/) > -1){
				@params = split(/\,/, $sig);
			} else {
				#single arg
				@params = ($sig);
			}
		} else {
			#no params
			@params = ();
		}
		foreach $param(@params){
			#remove <++>
			if($param =~ /\<\+([^+]+)\+\>/){
				$clean_param = $1;
				#split on :
				if($clean_param =~ /([^:]+)\:(.*)/){
					$pname = $1;
					$ptype = $2;
					$ptype = convertType($ptype);
					print " * \@param {$ptype} $pname \n";
				}
			}
		}
	}
}
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
