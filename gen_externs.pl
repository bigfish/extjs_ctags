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
	my @namespaceDecl;
	my $extends;
	my $return;
    my $args;
	#functions
	if( $tagline =~ /^([^\t]*)\t([^\t]*)\s\/.*\$\/;"\s([a-z])\sclass\:([\S]+).*link\:([\S]*)/){
		$tagname = $1;
		$type = $3;
		$link = $5;
		@namespace = split(/\./, $link);
		$class = pop(@namespace);
		$ns_len = scalar @namespace;
		#create Namespace component objects if they do not exist
		@namespaceDecl = ();
		while ($ns_len > 0){
			if($ns_len > 1){
				$namespaceStr = join(".", @namespace);
			} else {
				#global vars must be declared
				$namespaceStr = "var " . $namespace[0];
			}
			if (!exists $externs{$namespaceStr}){
				#keep track of externs so we don't add duplicates
				$externs{$namespaceStr} = "{}";
				push(@namespaceDecl, "$namespaceStr = {};\n");
			}
			pop(@namespace);
			$ns_len = scalar(@namespace);
		}
		#now reverse the namespace declarations so they are in the right order
		@namespaceDecl = reverse(@namespaceDecl);
		foreach $ns(@namespaceDecl){
			print $ns;
		}
		if($type =~ /c/){
			#class have link == full class name
			if(!exists $externs{$link}){
				print "/**\n";
				print " * \@constructor\n";
				if ($tagline =~ /inherits\:([^\t]+)\t/){
					print " * \@extends {$1}\n";
				}
				$args = getFnMeta($tagline);
				print " */\n";
				$externs{$link} = "function () {};";
				print "$link = function ($args) {};\n";
				#also create a typedef for the class 
				if(!exists $externs{$tagname}){
					print "/** \@typedef {".$link."} */\n";
					print "var $tagname;\n";
					$externs{$tagname} = 1;
				}
			}
		}
		if($type =~	/m/){
			#method
			#methods have link == class which contains them
			#attach methods to the prototype of the constructor,
			#except static methods ( which are simply members of the 'class' object)
			if ($tagline =~ /\tisstatic\:yes/){
				$extern = "$link\.$tagname";
			} else {
				$extern = "$link\.prototype\.$tagname";
			}
			if(!exists $externs{$extern}){
				print "/**\n";
				$args = getFnMeta($tagline);
				#if has type: use type as return
				if($tagline =~ /\ttype\:([^\t]*)/){
					$return = $1;
					$return = convertType($return);
					print " * \@return {$return}\n";
				}
				print " */\n";
				print "$extern = function($args){};\n";
			}
		
		}
		if ($type =~ /v/){
			$extern = "$link\.$tagname";
			if(!exists $externs{$extern}){
				#get type of var
				if($tagline =~ /\ttype\:(\S*)/){
					$type_spec = convertType($1);
					$def_val = getDefVal($type_spec);
					print "/**\n";
					print " * \@type {$type_spec}\n";
					print " */\n";
					if($def_val eq "undefined"){
						print "$extern;\n";
					} else {
						print "$extern = $def_val;\n";
					}
				}
			}
		}
	}
}

#process a tag with a constructor or method and print the params and return type, if any
#returns args for signature
sub getFnMeta
{
	my $tag = shift;
	my $sig;
	my @params;
	my $clean_param;
	my $pname;
	my $ptype;
    my $args = "";

	if($tag =~ /\tsignature\:\(([^\)]+)\)/){
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
			if($param =~ /\<\+([^\+]+)\+\>/){
				$clean_param = $1;
				#split on :
				if($clean_param =~ /([^\:]+)\:(.*)/){
					$pname = $1;
					$ptype = $2;
					$ptype = convertType($ptype);
                    #remove ? or * after and change type to indicate optional or varargs
                    if ($pname =~ /\?$/){
                        $pname =~ s/\?$//;
                        $ptype .= '=';
                    } elsif ($pname =~ /\*$/){
                        $pname =~ s/\*$// ;
                        $ptype = '...' . $ptype;
                    }
					print " * \@param {$ptype} $pname \n";

                    #add pname to args
                    if ($args eq ""){
                        $args = $pname;
                    } else {
                        $args = $args.",$pname";
                    }
				}
			}
		}
	}
    return $args;
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
	$jsdoc_type =~ s/array/Array/g;
	$jsdoc_type =~ s/object/Object/g;
	$jsdoc_type =~ s/Function/function()/g;
	$jsdoc_type =~ s/Boolean/boolean/g;
	$jsdoc_type =~ s/([A-Za-z0-9_\$\.]*)\[\]/Array\.\<\1\>/g;
    #$jsdoc_type =~ s/Mixed/\*/g;
	return $jsdoc_type;
}

sub getDefVal
{
	my $type = shift;
	if($type =~ /string/){
		return "''";
	} elsif ($type =~ /number/){
		return "1";
	} elsif ($type =~ /Array/){
		return "[]";
	} elsif ($type =~ /Object/){
		return "{}";
	} elsif ($type =~ /boolean/){
		return "true";
	} elsif ($type =~ /undefined/){
		return "undefined";
	} elsif ($type =~ /null/){
		return "null";
	} elsif ($type =~ /function/){
		return "function () {}";
	}  else {
		return "{}";
	}
}
