#!/bin/bash
# Created  20/08/2014 Marcos Seco
# Modified 18/03/2015 Marcos Seco
# Modified 16/06/2015 Marcos Seco
# Modified 15/05/2019 Jose Cuenca

PATH=$PATH:/home/trasgo/bin
INPUTPATH="/home/daq/data/test03"
EXECPATH="/home/daq/bin/"
TRB_SCRIPT="/home/hadaq/rpc/utilities/setThresholds_OMB_40mV.sh"
TRB_MIXSCRIPT="/home/hadaq/rpc/utilities/setThresholds_OMB_40mV_RPC3-4.sh"
LOGPATH="/home/daq/data/log"
ETRAX_LIST="32"
TEST_OUTPUT="$LOGPATH/unpacker_test.log"
CONVERTDATESTRING="s/\([0-9]\{2\}\)\([0-9]\{3\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\).hld/\1-01-01 +\2 days -1 day  \3:\4:\5/"
#=========================================================


initLogs() {
  for a in "$@"; do 
    echo -n > $LOGPATH/trb$(printf "%03.0f" $a).log
  done
}

startTRB() {
  #  This function initializes the TRB given by the first argument.
  #Extra arguments are dropped5
  exec 1>>$LOGPATH/trb$1.log 2>&1

  $EXECPATH/start_daq_trb_test.pl -l etraxp$1 -s trb_test -p 50$1 -i ${1#0} -r
 sleep 30
  if [[ "$1" == "088" ]]; then
     $EXECPATH/command_client.pl -e etraxp$1 -c $TRB_MIXSCRIPT
  else
     $EXECPATH/command_client.pl -e etraxp$1 -c $TRB_SCRIPT
  fi
  sleep 10
}

rotateScreenLogs() {
  now=$(date "+%s")
  if [[ $(date "+%H") < 1 ]]; then
    for a in $@;do 
      logfile=$(sed -n -e '/logfile.*log/{s/logfile //;p}' $a)
      filetime=$(stat -c %Z $logfile.1.bz2) || filetime="$now"
      if [[ $(($now - $filetime)) > 3600 ]]; then
         rm $logfile.4.bz2
         mv $logfile.{3,4}.bz2
         mv $logfile.{2,3}.bz2
         mv $logfile.{1,2}.bz2
         mv $logfile.{,1}
	 bzip2 $logfile.1
         touch $logfile
      fi
    done
  fi
}

startProgs() {
  #This function starts the data adquisition programs. 
  #Its arguments are the list of TRB's normalized to
  #a three digits integer padded with 0's.

  #If the list provided is "071 099" the sed command
  #transforms it to:
  #     "-i 50071 -i 50099"
  NUM_OF_ETRAX=$(echo "$@" | wc -w)
  NETMEM_ARGS="-m $NUM_OF_ETRAX -q 8 -S 1 $(echo "$@" | sed -e 's/ / -i 50/g;/^[0-9]/{s/^/-i 50/}')"
  EVTBUILD_ARGS="--debug trignr -m $NUM_OF_ETRAX -q 8 -S 1 --filesize 10M -d file -x tr -o $INPUTPATH"
  SED_PROG="s/[[:blank:]]\+\(.*\)[[:blank:]]\+(.*/\1/;p"
  EVTBUILD_SCREENCFG=/tmp/ev_screenrc
  NETMEM_SCREENCFG=/tmp/nm_screenrc

  rotateScreenLogs $EVTBUILD_SCREENCFG $NETMEM_SCREENCFG

  echo -e "logfile $LOGPATH/eventBuilder.log\nlogfile flush 1" > $EVTBUILD_SCREENCFG
  echo "screen -c $EVTBUILD_SCREENCFG -L -d -m -S eventBuilder $EXECPATH/daq_evtbuild $EVTBUILD_ARGS"
  screen -c $EVTBUILD_SCREENCFG -L -d -m -S eventBuilder $EXECPATH/daq_evtbuild $EVTBUILD_ARGS 
  echo $?
  echo "eventBuilder running on screen: "$(screen -ls | sed -n -e "/eventBuilder/{$SED_PROG}")
  sleep 5

  echo -e "logfile $LOGPATH/netmem.log\nlogfile flush 1" > $NETMEM_SCREENCFG
  echo "screen -c $NETMEM_SCREENCFG -L -d -m -S netmem  $EXECPATH/daq_netmem $NETMEM_ARGS"
  screen -c $NETMEM_SCREENCFG -L -d -m -S netmem $EXECPATH/daq_netmem $NETMEM_ARGS
  echo $?
  echo "netmem running on screen: "$(screen -ls | sed -n -e "/netmem/{$SED_PROG}")
  sleep 5
}

start_DAQ() {
  #  This function starts the data adquisition. Its input arguments are
  #the list of TRB's to be initialized. 
  #
  #  The TRB's are initialized in parallel but the fu5nction stops its 
  #execution until all of them are ready.
  #
  #setReset

  killall daq_evtbuild
  killall daq_netmem

  NORM_ETRAX_LIST=""
  for a in "$@";do
    ETRAX=$(printf "%03.0f" $a) || (echo "the argument must be an integer";return 1)
    NORM_ETRAX_LIST="$NORM_ETRAX_LIST $ETRAX"
    startTRB $ETRAX &
  done

  wait 

  sleep 5

  startProgs $NORM_ETRAX_LIST

  #clearReset
}

control_c() {
  #This function is executed if the user presses ctrl-C

  killall daq_evtbuild
  killall daq_netmem
  # In case we interrupt the script during initialization
  #we have to kill all process in background
  JOBS=$(jobs -p)
  if [[ -n $JOBS ]]; then 5
    kill -9 $JOBS
  fi
  wait
  echo "SIGINT received, exiting."
  exit 1
}

#========================================================
# Main 
#========================================================


trap control_c SIGINT


initLogs $ETRAX_LIST
start_DAQ $ETRAX_LIST
