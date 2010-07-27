#!/bin/bash

tags:	$(EXT_HOME)/genAllExtTags $(EXT_HOME)/genExtTags $(EXT_HOME)/getExtTags.pl $(EXT_HOME)/replacePointers.pl
	$(EXT_HOME)/genAllExtTags "${EXT_SRC}" 
	cp $(EXT_HOME)/tags $(VIM4JS_HOME)/tags/extjs/tags
