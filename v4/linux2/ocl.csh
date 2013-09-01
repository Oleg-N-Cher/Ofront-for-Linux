#!/bin/csh
#
# compile and link an Oberon module
#
# SYNOPSIS
#   ocl moduleName [ofrontOption [ccOption]]
#
# use single character "-" to skip ofrontOption
# example: ocl hello - -g

# translate .Mod to .c
ofront $1.Mod $2

# compile .c to .o
cc -c $3 $1.c

# link .o into lib$1.so
cc -shared -L. -lOberonV4 $1.o -o lib$1.so

# remove unnecessary files and show result
rm $1.c $1.o
ls -l lib$1.so
