#!/bin/bash


#	Set internal variables
MCRROOT=${HOME}/mcr/petdaq/MCR/R2010b/32-bits/v714
MCRJRE=${MCRROOT}/sys/java/jre/glnx86/jre/lib/i386


#	Set path to include MCR directory
PATH=${PATH}:$MCRROOT

export PATH


#	Set LD_LIBRARY_PATH
if [ $LD_LIBRARY_PATH ]; then
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/runtime/glnx86 ;
else
	LD_LIBRARY_PATH=${MCRROOT}/runtime/glnx86 ;
fi

LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnx86
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnx86
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE} 
#LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${HOME}/Documents/Stand-Alone-Applications/Needed-Libs

export LD_LIBRARY_PATH


#	Set XAPPLRESDIR
if [ $XAPPLRESDIR ]; then
	XAPPLRESDIR=${XAPPLRESDIR}:${MCRROOT}/X11/app-defaults ;
else
	XAPPLRESDIR=${MCRROOT}/X11/app-defaults ;
fi

export XAPPLRESDIR

