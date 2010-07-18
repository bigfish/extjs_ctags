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

my $getMember = 0;
my $getClass = 0;
my $getConstructor = 0;
my $tagStr = "";
my $TAB = '	';
my $class = "";
my $full_class = "";
my $full_class_re = "";
my $parent_class = "";
my $class_re;
my $cons_re;
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

foreach(@lines){
	chomp;
	my $line = $_;
	my $re;

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
		$getConstructor = 1;
		$getClass = 1;
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

		$cons_re = '^\s*'.$full_class.'\s*=\s*function\(([^)]*)\).*$';
		if($line =~ /$cons_re/) {
			#print "CONSTRUCTOR: $_\n";
			$typeToken = "f";
			#construct tag
			$tagStr = $class.$TAB.$file.$TAB.'/^'.$_.'$/;"'.$TAB.$typeToken.$TAB.'class:'.$parent_class;
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
			}
		}
		$getDescr = 0;
	}
	#when comment starts clear some vars
	if($line =~ /^\s*\/\*\*/) {
		$getMember = 1;
		$getDescr = 1;#get next line
	}
	
	#function parameters
	if ($line =~ /^\s*[\*]?\s*\@param\s+\{([^}]*)\}\s([a-zA-Z0-9_\$]+)/g) {

		$param_type = $1;
		$param_name = $2;
		#append ? to optional parameter name
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
	if ($line =~ /^\s*\*\s*\@type\s+\}?([A-Za-z0-9_]*)\}?/g) {
		#print "found type: $1\n";
		$type = $1;
	}
	if($line =~ /^\s*\*\//) {
		#print "ending doc comment\n";
		#expect function or property declaration on next line
		#set flag to capture next match
		$getMember = 1;
	}

	if ($getMember == 1) {
		#match member declaration	
		if($line =~ /^\s*([a-zA-Z_\$][a-zA-Z_0-9\$]*)\s*:\s*(.*)$/) {
			my $mName = $1;
			my $mValue = $2;
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
						$sig .= '' ;
						$isfirstparam = 0;
					} else {
						$sig .= ", " . '<+'.$param_name.":".$param_type.'+>' ;
						#$sig .=  ", " . $param_type . " " . $param_name;
					}
				}
				$sig .= ")";
			} else {
				#is property
				#print "found property: $mName \n";
				$typeToken = "v";#f = field?
			}

			#rename constructor to class name
			if ($mName =~ /constructor/){
				$mName = $class;
				$typeToken = 'f';
				$return = $class;
			}

			#construct tag
			$tagStr = $mName.$TAB.$file.$TAB.'/^'.$_.'$/;"'.$TAB.$typeToken.$TAB.'class:'.$class;
			if (length($sig) > 0) {
				$tagStr = $tagStr.$TAB.'signature:'.$sig;
			}
			#add return type as type
			if (length($return) > 0) {
				$tagStr = $tagStr.$TAB.'type:'.$return;
			} elsif (length($type) > 0) {
				$tagStr = $tagStr.$TAB.'type:'.$type;
			}

			#add full class name as link for help docs
			$tagStr = $tagStr.$TAB.'link:'.$full_class;
			#if singleton, members are static
			#ie: they are called on the class name directly
			#we will simply check for the existence od this field
			if ($singleton) {
				$tagStr = $tagStr.$TAB.'static:true'
			}
			#add description if any
			if ($descr) {
				$tagStr = $tagStr.$TAB.'descr:'.$descr;
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
	$singleton = 0;
	$descr = "";
}




