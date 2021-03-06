#!/usr/bin/perl
use File::Basename;
use Switch;
#script to extract exuberant ctags from Ext js source code
my $file = shift;
my $infofile = shift;
my $infolinenum = shift;
#find classes in file
(my $filename, my $filepath, my $ext) = fileparse($file, qr{\..*});
#read file into string
open(HANDLE, $file) || die ("could not open file $file");
my @lines = <HANDLE>;
close(HANDLE);

my $getMember = 0;
my $getClass = 0;
my $getConstructor = 0;
my $tagStr = "";
my $TAB = "	";
my $class = "";
my $full_class = "";
my $full_class_re = "";
my $parent_class = "";
my $class_re;
my $cons_re;
my $cons_re2;
my $cons_re3;
my $cons_re4;
my $inherit = "";
my $sig;
my $param_name;
my $param_type;
my @params = ();
my $property = "";
my $type = "";
my $method = "";
my $return = "";
my $getDescr = 0;
my $descr = "";
my $singleton = 0;
my $static = 0;
my @infolines = ();
my $in_doc_comment = 0;
my $ignoreComment = 0;

foreach(@lines){
	chomp;
	my $line = $_;
	my $re;

    #ignore definition on line following // private
	if ($private){
		next;
	}
    if ($line =~ /^\s*\/\/\s*private/){
        $private = 1;
        next;
    }
    if ($line =~ /^\s*\/\/\s*inherit docs/){
        $private = 1;
        next;
    }
    if ($ignoreComment && $line =~ /\s*\*/){
        next;
    }
    
	if($line =~ /^\s*[\*]?\s*\@class\s([A-Za-z0-9_\$\.]*).*$/) {
		$full_class = $1;
        #if full_class name contains a dot, set class to last part
        if ($full_class =~ /(.*)\.([^.]*)$/) {
            $class = $2;
            #get parent class -- used by class and constructor tags as class property
            $parent_class = $1;
            #if parent class has a dor, get last portion
            if($parent_class =~ /(.*)\.([^.]*)$/) {
                  $parent_class = $2;
            }
        } else  {
            $class = $full_class;#full class has no dots .. single word class
        }
		resetVars();
		$singleton = 0;
		$getConstructor = 1;
		$getClass = 1;
        $in_doc_comment = 1;
	}
	#if the class is singleton there will not be a constructor
	if($line =~ /^\s*[\*]?\s*\@singleton/) {
		$singleton = 1;
		$getConstructor = 0;
	}
	# parse class 
	if ($getClass) {
		$full_class_re = $full_class;
		$full_class_re =~ s/\./\\\./g;
		#print "Class RE: $class_re \n";
		$re = '^\s*'.$full_class_re.'\s+=\s+';
		if($line =~ /$re/) {
			if ($line =~ /Ext\.extend\(([A-Za-z0-9_\$\.]*)\s*/) {
				$inherit = $1;
			}
			$typeToken = "c";
			#construct tag
			$tagStr = $class.$TAB.$file.$TAB.'/^'.$_.'$/;"'.$TAB.$typeToken.$TAB.'class:'.$parent_class;
			if ($inherit ne '') {
				$tagStr = $tagStr.$TAB.'inherits:'.$inherit;
			}
			#if 'singleton' (actually an object literal)
			if ($singleton) {
				$tagStr = $tagStr.$TAB.'singleton:true'
			}
			#add link for help
			$tagStr = $tagStr.$TAB.'link:'.$full_class;
			print $tagStr."\n";
			$getClass = 0;
		}
	}
	# the class constructor has same name as class but is function type 
	if ($getConstructor) {

		$cons_re = '^\s*'.$full_class.'\s*\=\s*function\s*\(([^)]*)\).*$';
		$cons_re2 = '^\s*constructor\s*\:\s*function\s*\(([^)]*)\).*$';
		$cons_re3 = '^\s*'.$full_class.'\s*\=\s*Ext\.extend\(.*$';
		$cons_re4 = '^\s*constructor\s*\:\s*Ext\.extend\(.*$';

		if($line =~ /$cons_re/ || $line =~ /$cons_re2/ ) {
			#print "CONSTRUCTOR: $_\n";
			$typeToken = "f";
				#construct signature
				$sig = "(";
				my $isfirstparam = 1;
                my $numparams = scalar(@params);
				for (my $p = 0; $p < $numparams; $p++ ) {

                    my $param_name = $params[$p]{'name'};
                    my $param_type = $params[$p]{'type'};

					if ($isfirstparam) {
						$sig .= '<+'.$param_name.":".$param_type.'+>' ;
						$isfirstparam = 0;
					} else {
						$sig .= "," . '<+'.$param_name.":".$param_type.'+>' ;
						#$sig .=  ", " . $param_type . " " . $param_name;
					}
				}
				$sig .= ")";
			#construct tag
			$tagStr = $class.$TAB.$file.$TAB.'/^'.$_.'$/;"'.$TAB.$typeToken.$TAB.'class:'.$parent_class;
			#if (length($sig) > 0) {
				$tagStr = $tagStr.$TAB.'signature:'.$sig;
			#}
			#add link for help
			$tagStr = $tagStr.$TAB.'link:'.$full_class;
			print $tagStr."\n";
			$getConstructor = 0;

		} elsif ($line =~ /$cons_re3/ || $line =~ /$cons_re3/){

			$typeToken = "f";

			#construct tag
			$tagStr = $class.$TAB.$file.$TAB.'/^'.$_.'$/;"'.$TAB.$typeToken.$TAB.'class:'.$parent_class;
			#we have no sig for Ext.extend ...
			$tagStr = $tagStr.$TAB.'signature:()';
			#add link for help
			$tagStr = $tagStr.$TAB.'link:'.$full_class;
			print $tagStr."\n";
			$getConstructor = 0;
		
		}
	}
	#get first line of member comment as description
	if ($getDescr) {
		#ignore @ lines -- not descriptions
		if ($line !~ /^\s*\*?\s*\@/){
			if ($line =~ /^\s*\*?\s*(.*)/){
				$descr = $1;
				push(@infolines, $descr);
			}
		}
		$getDescr = 0;
	}
	#when comment starts clear some vars
	if($line =~ /^\s*\/\*\*/) {
		$getMember = 0;#avoid getting members inside comments
		$getDescr = 1;#get next line
		$in_doc_comment = 1;
		$private = 0;
	}
	
	#function parameters
	if ($line =~ /^\s*[\*]?\s*\@param\s+\{([^}]*)\}\s([a-zA-Z0-9_\$]+)/g) {

		$param_type = $1;
		$param_name = $2;
		#append = to optional parameter name
		if(index($line, "(optional)") > -1) {
			$param_name .= "?";
		}
		push(@params, { name => $param_name, type => $param_type });#$1 = name , $2 = type

	}
	#function return value
	if ($line =~ /^\s*[\*]?\s*\@return\s+\{([^}]*)\}/g) {
		#print "found return: $1\n";
		$return = $1;
	}
	#function name
	if ($line =~ /^\s*[\*]?\s*\@method\s+([a-zA-Z_\$]+)/g) {
		#print "found method: $1\n";
		$method = $1;
	}
	#property type
	if ($line =~ /^\s*\*\s*\@type\s+\{?([^}]*)\}?/g) {
		#print "found type: $1\n";
		$type = $1;
	}
	#cfg type
	if ($line =~ /^\s*\*\s*\@cfg\s+\{?([^}]*)\}?/g) {
		#print "found type: $1\n";
		$type = $1;
	}
	#event declaration (ignore)
	if ($line =~ /^\s*\*\s*\@event\s+/g) {
        $ignoreComment = 1;
        next;
	}
	#static marker
	if ($line =~ /^\s*[\*]?\s*\@static/g) {
		$static = 1;
	}
	if($in_doc_comment && $line =~ /^\s*\*\//) {
		#print "ending doc comment\n";
		#expect function or property declaration on next line
		#set flag to capture next match
		$getMember = 1;
        $in_doc_comment = 0;
        $ignoreComment = 0;
	}


	if ($getMember == 1) {
		#match member declaration	
		if($line =~ /^\s*([a-zA-Z_\$][a-zA-Z_0-9\$]*)\s*:\s*(.*)$/) {
			my $mName = $1;
			my $mValue = $2;

			if ($mName eq "constructor"){
				next;
			}
			#check if function or property
			if ($mValue =~ /function/) {

				#print "found method: $mName \n";
				$typeToken = "m";#method

				#construct signature
				$sig = "(";
				my $isfirstparam = 1;
                my $numparams = scalar(@params);
				for (my $p = 0; $p < $numparams; $p++ ) {

                    my $param_name = $params[$p]{'name'};
                    my $param_type = $params[$p]{'type'};

					if ($isfirstparam) {
						$sig .= '<+'.$param_name.":".$param_type.'+>' ;
						$isfirstparam = 0;
					} else {
						$sig .= "," . '<+'.$param_name.":".$param_type.'+>' ;
						#$sig .=  ", " . $param_type . " " . $param_name;
					}
				}
				$sig .= ")";

			} else {
				#is property
				#print "found property: $mName \n";
				$typeToken = "v";#f = field?
				#try to infer type if we have don't have it yet
				if($tagStr !~ /type\:[^\t]+/ || $type eq ""){
					if($mValue =~ /^[\d\.\-]+/){
						$type = "Number";
					} elsif ($mValue =~ /^'.*/) {
						$type = "String";
					} elsif ($mValue =~ /^".*/) {
						$type = "String";
					} elsif ($mValue =~ /^true|false/) {
						$type = "Boolean";
						#by convention, variables starting with 'is' are Boolean
					} elsif ($mValue =~ /^is/) {
						$type = "Boolean";
					} elsif ($mValue =~ /^\[.*/) {
						$type = "Array";
					} elsif ($mValue =~ /^\{.*/) {
						$type = "Object";
					} elsif ($mValue =~ /^new ([^(]*)\(/) {
						$type = $1;
					} elsif ($mValue =~ /^Ext\.emptyFn/){
						$type = "Function";
					} elsif ($mValue =~ /^undefined/){
						$type = "undefined";
					} elsif ($mValue =~ /^null/){
						$type = "null";
					} elsif ($mValue =~ /^this/){
						$type = $class;
					} elsif ($mValue =~ /^NaN/){
						$type = "NaN";
					} elsif ($mValue =~ /^\//){
						$type = "RegExp";
					} elsif ($mValue =~ /^Number\.[A-Z_]+/){
						$type = "Number";
					} 
					else {
						#deal with a few outliers manually:
						if($mName eq "BLANK_IMAGE_URL"){
							$type = "String";
						} 
						if ($mName eq "useShims"){
							$type = "Boolean";
						}
						if($class =~ /ComponentMgr/){
							if($mName =~ /all/){
								$type = "MixedCollection";
							} elsif ($mName =~ /ptypes/){
								$type = "Object";
							} elsif ($mName =~ /types/){
								$type = "Object";
							}
						} elsif ($class =~ /DatePicker/){
							if($mName =~ /dayNames/){
								$type = "Array";
							} elsif ($mName =~ /monthNames/){
								$type = "Array";
							}
						} elsif ($class =~ /EventManager/){
							if($mName =~ /^id/){
								#skip privates
								$private = 1;
								next;
							} elsif ($mName =~ /^fireDocReady/){
								$type = "Object";
							}
						} elsif ($class eq "JSON" && $mName eq "default") {
							#skip privates
							$private = 1;
							next;
						} elsif ($class eq "MemoryProxy" && $mName eq "api") {
							$type = "Object";
						} elsif ($class eq "XTemplate" && $mName eq "default") {
							#skip privates
							$private = 1;
							next;
						} elsif ($class eq "PropertyStore" && $mName eq "recordType"){
							$type = "PropertyRecord";
						}
						#if ($class =~ /Date/ && $mName =~ /_xMonth/){
						if ($type eq ""){
							#print " TYPE DETECTION FAIL in $class : $line \n";
						}
					}
					$tagStr = $tagStr.$TAB.'type:'.$type;
				}
			}

			#rename constructor to class name
			#if ($mName =~ /constructor/){
				#$mName = $class;
				#$typeToken = 'f';
				#$return = $class;
				#$tagStr = $class.$TAB.$file.$TAB.'/^'.$_.'$/;"'.$TAB.$typeToken.$TAB.'class:'.$class;
			#} else {
				$tagStr = $mName.$TAB.$file.$TAB.'/^'.$_.'$/;"'.$TAB.$typeToken.$TAB.'class:'.$class;
			#}

			if (length($sig) > 0) {
				$tagStr = $tagStr.$TAB.'signature:'.$sig;
			}

			#add return type as type
			if (length($return) > 0) {
				$tagStr = $tagStr.$TAB.'type:'.$return;
			} elsif (length($type) > 0) {
				$tagStr = $tagStr.$TAB.'type:'.$type;
			} #if we have not found the type yet we will infer it later...

			#add full class name as link for help docs
			$tagStr = $tagStr.$TAB.'link:'.$full_class;
			#if singleton, members are static
			#ie: they are called on the class name directly
			#this can also be explicitly declared on methods or properties
			#Note: it is not possible to have non-static methods on singletons
			#since singletons are just POJOs they cannot be instantiated
			if ($singleton || $static) {
				#using the field name 'static' was causing errors
				$tagStr = $tagStr.$TAB.'isstatic:yes'
			} else {
				$tagStr = $tagStr.$TAB.'isstatic:no'
			}
			#add description if any
			if ($descr) {
				#make sure there are no tabs in description
				#still seems to be a problem with including description text.. causes errors in vim
				#perhaps lines are too long, or whitespace in comments is a problem?
				#$tagStr = $tagStr.$TAB.'descr:'.$descr;
				#lets juts use a line index
				$infolinenum += 1;
				$tagStr = $tagStr.$TAB.'info:'.$infofile . '|' . $infolinenum;

			}
			#exclude any globals -- there are only a few which are not needed -- everything should hang off Ext...
			if ($class ne '') {
				print "$tagStr\n";
			}
			#reset flag until next doc comment
			$getMember = 0;
			resetVars();
		}
	}

	#if we have a shortcut assignment to another function or member, write a stub token which will be rewritten in 
	#post-processing stage
	if ($line =~ /^\s*(Ext[\.a-zA-Z_0-9]+)\s*=\s*(Ext[\.a-zA-Z_0-9]+).*$/ ) {
		my $cmd = $_;
		my $pointer = $1;
		my $pointee = $2;

		#Note: this only captures all the fully qualified references (Ext...)
		#there are some exceptions to the pattern
		if ($pointee !~ /Ext\.extend/ && $pointee !~ /\.prototype\./ && $pointee !~ /Ext\.apply/) {
		
			#spit out stub tag
			$tagStr = $pointer."==>".$pointee."\n";
			print $tagStr;
		}
	}
}

#write infolines to info file
open (INFO, '>>info');
foreach (@infolines){
	print INFO $_."\n";
}
close (INFO); 


sub resetVars {
	$property = "";
	$type = "";
	@params = ();
	$method = "";
	$return = "";
	$memberType = "";
	$getMember = 0;
	$getClass = 0;
	$getConstructor = 0;
	$tagStr = "";
	$inherit = "";
	$sig = "";
	$getDescr = 0;
	$static = 0;
	$descr = "";
}




