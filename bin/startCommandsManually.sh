#!/bin/bash

PATH=$PATH:/home/pet/bin

	/root/labjack/setReset.sh &
	killall daq_evtbuild
	killall daq_netmem 
su pet << ENDSU 
	PATH=$PATH:/home/pet/bin
	/home/pet/bin/startDAQ38_auger.sh
	sleep 30
	/home/pet/bin/command_client.pl -e etraxp038 -c '/home/hadaq/rpc/utilities/setThresholds_OMB_40mV.sh'
	sleep 10
	/home/pet/bin/startDAQ88_auger.sh
	sleep 30
	/home/pet/bin/command_client.pl -e etraxp088 -c '/home/hadaq/rpc/utilities/setThresholds_OMB_40mV.sh'
	sleep 10
	lxterminal -e /home/pet/bin/startBuilder_auger_test.sh &
	echo $?
	sleep 5
	lxterminal -e  /home/pet/bin/startnetmem_auger_test.sh &
	echo $?
	sleep 5
ENDSU
	/root/labjack/clearReset.sh &
