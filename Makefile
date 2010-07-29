#!/bin/bash
tags:	$(EXT_HOME)/genAllExtTags $(EXT_HOME)/genExtTags $(EXT_HOME)/getExtTags.pl $(EXT_HOME)/replacePointers.pl
	$(EXT_HOME)/genAllExtTags "${EXT_SRC}" $(EXT_HOME) 
