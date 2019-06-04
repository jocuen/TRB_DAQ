#!/bin/bash
# Created  20/08/2014 Marcos Seco
# Modified 18/03/2015 Marcos Seco

PATH=$PATH:"/home/shadowfax/bin"
INPUTPATH="/home/shadowfax/data/test01"
EXECPATH="/home/shadowfax/bin/"
TRB_SCRIPT="/home/hadaq/rpc/utilities/setThresholds_OMB_40mV.sh"
TRB_MIXSCRIPT="/home/hadaq/rpc/utilities/setThresholds_OMB_40mV_RPC3-4.sh"
LOGPATH="/home/shadowfax/data/log"
ETRAX_LIST="37"
#ETRAX_LIST="71 88 37"
#=========================================================

setReset() {
  sudo /root/labjack/switch_IO.py 0 &
}

clearReset() {
  sudo /root/labjack/switch_IO.py 1 &
}

initLogs() {
  for a in "$@"; do 
    echo -n > $LOGPATH/trb$(printf "%03.0f" $a).log
  done
}

startTRB() {
  #  This function initializes the TRB given by the first argument.
  #Extra arguments are dropped
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



control_c() {
  #This function is executed if the user presses ctrl-C

  killall daq_evtbuild
  killall daq_netmem
  # In case we interrupt the script during initialization
  #we have to kill all process in background
  JOBS=$(jobs -p)
  if [[ -n $JOBS ]]; then 
    kill -9 $JOBS
  fi
  wait
  echo "SIGINT received, exiting."
  exit 1
}

#========================================================
# Main 
#========================================================

echo Empiezo
trap control_c SIGINT

TRB=$(printf "%03.0f" $1)
initLogs $TRB
echo $TRB
startTRB $TRB

echo Termino
