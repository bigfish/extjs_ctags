#!/bin/bash
tags:	$(EXT_HOME)/genAllExtTags $(EXT_HOME)/genExtTags $(EXT_HOME)/getExtTags.pl $(EXT_HOME)/replacePointers.pl $(EXT_HOME)/replaceSignatures.pl
	$(EXT_HOME)/genAllExtTags "${EXT_SRC}" $(EXT_HOME) 

#externs:	$(EXT_HOME)/tags
	#cat $(EXT_HOME)/ext_typedefs.js > $(EXT_HOME)/externs.js
	#$(EXT_HOME)/gen_externs.pl $(EXT_HOME)/tags >> $(EXT_HOME)/externs.js
