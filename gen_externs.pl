#!/usr/bin/perl
$tags_file=shift;
#load global classes to avoid redeclaring
$globals_file="global_classes.txt";
#externs is a hash of hash objects where key is the symbol name (fully qualified)
#and the value is a hash with the following structure
#		jsdoc => ref to an array of lines which are the JSDoc comments
#		js => "actual line of javascript;"
#		deps => ref to an array of strings which are the dependencies of the symbol (as keys in the externs hash hash)
#		symbol => same as the key

my %classes = ();
my %externs = ();

# read tags file into @lines array
open(HANDLE, $tags_file) || die ("could not open file $tags_file");
my @taglines = <HANDLE>;
close(HANDLE);

#PREPARE
#index the constructor functions 
foreach(@taglines){
	chomp;
	my $line = $_;
	my $sig; 
	my $class;
	my $type;
	my $superclass;

	#get type token
	if ($line =~ /^([A-Z]+[^\t]*)\t.*\/;"\t([a-z]).*link\:([\S]*)/){

		$class = $1;
		$type = $2;
		$full_class = $3;

		if ($type eq "c"){#class
			
			if ($line =~ /\tinherits\:([^\t]*)/){
				$superclass = $1;
				if (exists $classes{$class} ){
					#add 'super' property to exisiting subclass hash ref
					$classes{$class}->{'super'} = $superclass;
				} else {
					#create new subclass hash with super property
					$classes{$class} = { 'super' => $superclass };
				}
			}

		} elsif ($type eq 'f') {#function

			if (exists $classes{$class} ){
				$classes{$class}->{'meta'} = getFnMeta($line);
			} else {
				$classes{$class} = {'meta' => getFnMeta($line) };
			}
		}
	}
}

foreach $classname(keys %classes){

	print "class: $classname: \n";

	my %class_meta = %{$classes{$classname}->{'meta'}};
	my $args = $class_meta{'args'};
	print "args: $args \n";
	my @deps = @{$class_meta{'deps'}};

	if (exists %{$classes{$classname}}->{'super'} ){
		my $superclass = $classes{$classname}->{'super'};
		print "superclass : $superclass \n";
		#add superclass to dependencies
		push(@deps, $superclass);
	}
	
	print "deps: @deps \n";
	#print "args: " . %{$classes{$classname}}->{'meta'}->{'args'} . "\n";
	#print "params:  @{%{$classes{$classname}}->{'meta'}->{'params'}} \n";
}

#outlines buffers output
my @outlines = ();

#foreach(@taglines){
	#my $tagline = $_;
	#my $tagname = "";
	#my $type = "";
	#my $link = "";
	#my $singleton = 0;
	#my $extern;
	#my $ns_len;
	#my $extends;
	#my $return;
    #my $args;
	#my @deps;
	#my @extern_jsdoc;
	#my $extern_js;
	#my @externs_deps;
	#my %meta;
	#my $superclass;
	
	##generic pattern to parse taglines
	#if( $tagline =~ /^([^\t]*)\t([^\t]*)\t.*\$\/;"\t([a-z]).*link\:([\S]*)/){

		#$tagname = $1;
		#$type = $3;
		#$extern = $4;#this is the fully qualified classname

		##reset value objects
		#@extern_jsdoc = ();
		#$extern_js = "";
		#@extern_deps = ();
		#@deps = ();

		##classes / constructors
		#if($type =~ /c/){

			#if(!exists $externs{$extern} && !is_external($extern)){

				#push(@extern_jsdoc, "/**\n");
				#push(@extern_jsdoc, " * \@constructor\n");
				#if ($tagline =~ /inherits\:([^\t]+)\t/) {
					#$superclass = $1;
					#push(@extern_jsdoc, " * \@extends {$superclass}\n");
					##add the superclass to the dependencies
					#push(@extern_deps, $superclass);
				#}

				##parse constructor function for parameters, args, and deps
				#$meta = getFnMeta($tagline);

				#$args = $meta->{'args'};
				#print "ARGS: $args \n";

				#@deps = @{$meta->{'deps'}};
				#print "$link DEPS: @deps \n";

				#@extern_deps = (@extern_deps, @deps);
				#print "ALL_DEPS: @extern_deps \n";

				#foreach $param(@{$meta->{'params'}}){
					#push(@extern_jsdoc, $param);
				#}
				#push(@extern_jsdoc, " */\n");

				##construct data object for this extern 
				#$externs{$link} = {
					#jsdoc => \@extern_jsdoc,
					#js => "$link = function ($args) {};\n",
					#deps => \@extern_deps,
					#symbol => $link
				#};

			#}

		#} elsif($type =~ /m/){ #method

			##methods have link == class which contains them
			##attach methods to the prototype of the constructor,
			##except static methods ( which are simply members of the 'class' object)
			
			##$extern = "$link\.$tagname";

			##if(!exists $externs{$extern} && !is_external($tagname)){

				##push(@extern_jsdoc, "/**\n");
				##$meta = getFnMeta($tagline);
				##$args = $meta->{'args'};
				##@extern_deps = @{$meta->{'deps'}};

				###print "deps: @deps \n";
				###if has type: use type as return
				##if($tagline =~ /\ttype\:([^\t]*)/){
					##$return = $1;
					##$return = convertType($return);
					##push(@extern_jsdoc, " * \@return {$return}\n");
					##push(@extern_deps, "{$return}");
				##}
				##push(@extern_jsdoc, " */\n");

				##if ($tagline =~ /\tisstatic\:yes/){
					##$extern_js = "$link\.$tagname = function($args){};\n";
				##} else {
					###add method to constructor prototype
					##$extern_js = "$link\.prototype\.$tagname = function($args){};\n";
				##}

				###construct extern data object
				##$externs{$extern} = { 
					##jsdoc  => \@extern_jsdoc,
					##js     => $extern_js,
					##deps   => \@extern_deps,
					##symbol => $extern
				##};
			##}
		#} elsif ($type =~ /v/){ #vars
			##$extern = "$link\.$tagname";
			##if(!exists $externs{$extern} && !is_external($tagname)){
				###get type of var
				##if($tagline =~ /\ttype\:(\S*)/){
					##$type_spec = $1;
					###get jsdoc style type declaration
					##$type_spec = convertType($type_spec);
					##push(@extern_deps, $type_spec);
					###get default value
					##$def_val = getDefVal($type_spec);
					##push(@extern_jsdoc, "/**\n");
					##push(@extern_jsdoc, " * \@type {$type_spec}\n");
					##push(@extern_jsdoc, " */\n");

					##if($def_val eq "undefined"){
						##$extern_js = "$extern;\n";
					##} else {
						##$extern_js = "$extern = $def_val;\n";
					##}
				##}
				###construct extern object
				##$externs{$extern} = { 
					##jsdoc => \@extern_jsdoc,
					##js => $extern_js,
					##deps => \@extern_deps,
					##symbol => $extern
				##};
			##}
		#}
	#}
#}

##namespaces
#foreach(@taglines){
	#my $tagline = $_;
	#my $tagname = "";
	#my @namespace;
	#my $type = "";
	#my $link = "";
	#my $singleton = 0;
	#my $extern;
	#my $ns_len;
	#my $namespaceStr;
	#my $extends;
	#my $return;
	#my $args;
	#my @deps;
	#my @extern_jsdoc;
	#my $extern_js;
	##my @externs_deps;
	#my %meta;

	#if( $tagline =~ /^([^\t]*)\t([^\t]*)\t.*\$\/;"\t([a-z]).*link\:([\S]*)/){
		#$tagname = $1;
		#$type = $3;
		#$link = $4;

		#@extern_jsdoc = ();
		#$extern_js = "";
		#@extern_deps = ();

		## handle namespaces
		#if($link =~ /\./){
			#@namespace = split(/\./, $link);
		#} else {
			#@namespace = ($link);
		#}
		#$ns_len = scalar(@namespace);
		##create Namespace component objects if they do not exist
		## loop through the namespace bits, removing the last bit until there's none left
		#while ($ns_len > 0){
			#if($ns_len > 1){
				#$namespaceStr = join(".", @namespace);
			#} else {
				#$namespaceStr = $namespace[0];
			#}
			#if (!exists $externs{$namespaceStr}){
				#if ($namespaceStr =~ /\./){
					#$extern_js = "$namespaceStr = {};\n";
					#@extern_deps = getNSDeps($namespaceStr);
				#} else {
					#if(!is_external($namespaceStr)){
						##single element namespace object requies var
						#$extern_js = "var $namespaceStr;\n";
					#}
				#}
				#push(@extern_jsdoc, "/** @type {Object} */\n");
				##construct extern data object
				#$externs{$namespaceStr} = {
					#jsdoc => \@extern_jsdoc,
					#js => $extern_js,
					#deps => \@extern_deps,
					#symbol => $namespaceStr
				#}
			#}
			##decrement 
			#pop(@namespace);
			#$ns_len = scalar(@namespace);
		#}
	#}
#}
# sort deps
#for $extrn ( keys %externs )
#{
	##get deps
	#my @deps = @{$externs{$extrn}->{'deps'}};
	#my $numdeps = scalar(@deps);
	#print "extrn_deps: $numdeps\n";

#}
foreach $extern_key(keys %externs){
	#print "$extern_key deps: ";
	@deps = @{$externs{$extern_key}->{'deps'}};
	my $numdeps = scalar(@deps);
	print "extrn_deps: $numdeps\n";
	#print " @deps\n";
	#print $externs{$extern_key}{'js'};

}
#  --> for each dependency
#  -------> find the index of the dependency in the externs
#  -------> add that index to a list
#  ---> get the largest index from that list
#  ---> move the extern to a position in the externs just after that index
#  repeat until no moves are required (set a flag when moving extern)

#output
foreach $extern_key(keys %externs){

	$jsdocs = $externs{$extern_key}{'jsdoc'};
	
	foreach $jsdoc_line( @{$jsdocs} ){
		#print $jsdoc_line;
	}
	#print $externs{$extern_key}{'js'};

}

sub getNSDeps
{
	my $namespace = shift;
	my @ns_deps = ();
	my $ns_dep = "";
	#split on dots
	my @namespace = split(/\./, $namespace);
	#lose last bit .. this is the method, class, or var itself
	pop(@namespace);
	$ns_len = scalar(@namespace);
	$ns_idx = 0;
	$ns_base = "";
	while($ns_idx < $ns_len){
		if ($ns_base eq ""){
			$ns_base = $namespace[$ns_idx];
		} else {
			$ns_base = "$ns_base.$namespace[$ns_idx]";
		}
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
	my @fn_deps = ();
	#print "TAG: $tag \n";

	if($tag =~ /\tsignature\:\(([^\)]+)\)/){

		$sig = $1;
		print "SIG: $sig \n";
		#normalize parms into an array
		if(length($sig) > 0){
			if(index($sig, ",") > -1){
				print "MULTIPLE_PARAM \n";
				@params = split(/\,/, $sig);
			} else {
				#single arg
				print "SINGLE_PARAM \n";
				@params = ($sig);
			}
		} else {
			#no params
			@params = ();
		}
		print "PARAMS: @params \n";
		my $np = scalar(@params);
		print "NUMPARAMS = $np \n";
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
					print "PNAME: $pname , PTYPE: $ptype \n";
					#add param to array of parameter jsdoc declarations
					push(@fn_params, " * \@param {$ptype} $pname \n");
					#add the type declaration as a dependency
					#extract classes from type spec
					my @type_deps = extractTypeDeps($ptype);
					foreach $type_dep(@type_deps){
						if(grep $_ eq $type_dep, @fn_deps){
							next;
						} else {
							push(@fn_deps, $type_dep);
						}
					}
					#push(@fn_deps, $ptype);
                    #add pname to args
                    if ($args eq ""){
                        $args = $pname;
                    } else {
                        $args = $args.",$pname";
                    }
				}
			}
		}
		#debug
		my $np = scalar(@fn_params);
		print "NUM_PARAMS = $np \n";
		foreach $parm(@fn_params){
			print "FN_PARAM: $parm \n";
		}
		print "ARG: $args \n";
		print "DEPS: @fn_deps \n";
	}

    return { 
		args => $args,
	   	params => \@fn_params,
	   	deps => \@fn_deps
	};
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

sub extractTypeDeps
{
	my $typeStr = shift;
	if($typeStr =~ /\(?([^\)]*)\)?/){
		$typeStr = $1;
	}
	my @typeArr = split(/\|/, $typeStr);
	#filter out js builtin objects
	#they are not really dependencies
	my @deps = ();
	foreach $type(@typeArr){
		#clean up quantifier markers
		if($type =~ /(.*)\=$/){
			$type = $1;
		}
		if($type ne "string" && $type ne "number" && $type ne "Array" && $type ne "Object" && $type ne "function()" && $type ne "boolean"){
			push(@deps, $type);
		}
	}
	return @deps;
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
