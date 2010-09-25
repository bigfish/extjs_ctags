#!/usr/bin/perl
$tags_file=shift;
#load global classes to avoid redeclaring
$globals_file="global_classes.txt";

my %externs = ();

open(HANDLE, $tags_file) || die ("could not open file $tags_file");
my @taglines = <HANDLE>;
my @outlines = ();
close(HANDLE);

foreach(@taglines){
	my $tagline = $_;
	my $tagname = "";
	my @namespace;
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
	my @extern_jsdoc;
	my $extern_js;
	my @externs_deps;
	my %meta;

	if( $tagline =~ /^([^\t]*)\t([^\t]*)\t.*\$\/;"\t([a-z]).*link\:([\S]*)/){

		$tagname = $1;
		$type = $3;
		$link = $4;

		@extern_jsdoc = ();
		$extern_js = "";
		@extern_deps = ();

		# handle namespaces
		if($link =~ /\./){
			@namespace = split(/\./, $link);
		} else {
			@namespace = ($link);
		}
		$ns_len = scalar @namespace;
		#create Namespace component objects if they do not exist
		@namespaceDecl = ();
		# loop through the namespace bits, removing the last bit until there's none left
		while ($ns_len > 0){
			if($ns_len > 1){
				$namespaceStr = join(".", @namespace);
			} else {
				$namespaceStr = $namespace[0];
			}
			if (!exists $externs{$namespaceStr}){
				if ($namespaceStr =~ /\./){
					$extern_js = "$namespaceStr = {};\n";
					@deps = getNSDeps($namespaceStr);
				} else {
					if(!is_external($namespaceStr)){
						#single element namespace object requies var
						$extern_js = "var $namespaceStr;\n";
					}
					@deps = ();
				}
				#construct extern data object
				$externs{$namespaceStr} = {
					jsdoc => "/** @type {Object} */\n",
					js => $extern_js,
					deps => @deps,
					symbol => $namespaceStr
				}
			}
			#decrement 
			pop(@namespace);
			$ns_len = scalar(@namespace);
		}

		#classes / constructors
		if($type =~ /c/){
				
			if(!exists $externs{$link} && !is_external($link)){

				push(@extern_jsdoc, "/**\n");
				push(@extern_jsdoc, " * \@constructor\n");
				if ($tagline =~ /inherits\:([^\t]+)\t/) {
					push(@extern_jsdoc, " * \@extends {$1}\n");
				}
				#parse constructor function for parameters, args, and deps
				%meta = getFnMeta($tagline);
				$args = $meta{'args'};
				foreach $param(@meta{'params'}){
					push(@extern_jsdoc, $param);
				}
				push(@extern_jsdoc, " */\n");

				#construct data object for this extern 
				$externs{$link} = {
					jsdoc => @extern_jsdoc,
					js => "$link = function ($args) {};\n",
					deps => @meta{'deps'},
					symbol => $link
				};
			}

		} elsif($type =~ /m/){ #method

			#methods have link == class which contains them
			#attach methods to the prototype of the constructor,
			#except static methods ( which are simply members of the 'class' object)
			
			$extern = "$link\.$tagname";

			if(!exists $externs{$extern} && !is_external($tagname)){

				push(@extern_jsdoc, "/**\n");
				%meta = getFnMeta($tagline);
				$args = $meta{'args'};

				#if has type: use type as return
				if($tagline =~ /\ttype\:([^\t]*)/){
					$return = $1;
					$return = convertType($return);
					push(@extern_jsdoc, " * \@return {$return}\n");
				}
				push(@extern_jsdoc, " */\n");

				if ($tagline =~ /\tisstatic\:yes/){
					$extern_js = "$link\.$tagname = function($args){};\n";
				} else {
					#add method to constructor prototype
					$extern_js = "$link\.prototype\.$tagname = function($args){};\n";
				}

				#construct extern data object
				$externs{$extern} = { 
					jsdoc => @extern_jsdoc,
				   	js => $extern_js,
				   	deps => @meta{'deps'},
					symbol => $extern
				};
			}
		
		} elsif ($type =~ /v/){ #vars

			$extern = "$link\.$tagname";
			if(!exists $externs{$extern} && !is_external($tagname)){
				#get type of var
				if($tagline =~ /\ttype\:(\S*)/){
					$type_spec = $1;
					#get jsdoc style type declaration
					$type_spec = convertType($type_spec);
					push(@extern_deps, $type_spec);
					#get default value
					$def_val = getDefVal($type_spec);
					push(@extern_jsdoc, "/**\n");
					push(@extern_jsdoc, " * \@type {$type_spec}\n");
					push(@extern_jsdoc, " */\n");

					if($def_val eq "undefined"){
						$extern_js = "$extern;\n";
					} else {
						$extern_js = "$extern = $def_val;\n";
					}
				}
				#construct extern object
				$externs{$extern} = { 
					jsdoc => \@extern_jsdoc,
					js => $extern_js,
					deps => @meta{'deps'},
					symbol => $extern
				};
			}
		}
	}
}

# sort deps
# copy externs hash into an array
my @unsorted_externs = %externs;
#make another copy  so we don't change the ordering while iterating
my @sorted_externs = @unsorted_externs;
# for each extern:
foreach $unsorted_extern(@unsorted_externs)
{
	print $unsorted_extern->{'symbol'} ."\n";
}
#  --> get a list of the dependencies
#  --> for each dependency
#  -------> find the index of the dependency in the externs
#  -------> add that index to a list
#  ---> get the largest index from that list
#  ---> move the extern to a position in the externs just after that index
#  repeat until no moves are required (set a flag when moving extern)

#output
#foreach $extern_key(keys %externs){

	#$jsdocs = $externs{$extern_key}{'jsdoc'};
	
	#foreach $jsdoc_line( @$jsdocs ){
		#print $jsdoc_line;
	#}
	#print $externs{$extern_key}{'js'};

#}

sub getNSDeps
{
	my $namespace = shift;
	my @ns_deps = ();
	my $ns_dep = "";
	#split on dots
	@namespace = split(/\./, $namespace);
	#lose last bit .. this is the method, class, or var itself
	pop(@namespace);
	$ns_len = scalar(@namespace);
	$ns_idx = 0;
	$ns_base = "";
	while($ns_idx < $ns_len){
		$ns_base .= $namespace[$ns_idx];
		$ns_dep = "{$ns_base}";
		push(@ns_deps, $ns_dep);
		$ns_idx++;
	}
	return @ns_deps;
}

sub is_external
{
	my $check = shift;
	my $res = `grep $check $globals_file`;
	if($res){
		return 1;
	} else {
		return 0;
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
	my @fn_params = ();
	my @deps = ();

	if($tag =~ /\tsignature\:\(([^\)]+)\)/){
		$sig = $1;
		#normalize parms into an array
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

		#iterate over the params.. parse name & type
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
					#add param to array of parameter jsdoc declarations
					push(@fn_params, " * \@param {$ptype} $pname \n");
					#add the type declaration as a dependency
					push(@fn_deps, $ptype);
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
    return { args => $args, params => @fn_params, deps => @deps};
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
