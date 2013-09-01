#!/bin/bash

export OBERON=.:$OFRONT_HOME/linux2/V4:$OFRONT_HOME/V4:$OFRONT_HOME/fonts
export LD_LIBRARY_PATH=$OFRONT_HOME/linux2/lib

$OFRONT_HOME/linux2/bin/oberon $* &
