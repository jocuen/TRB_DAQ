#!/usr/bin/perl -w

use English;
use strict;
use Expect;
use FileHandle;
use Getopt::Long;
use Data::Dumper;

#- the command line option flags
my $opt_help  = 0;
my $opt_readout = 0;
my $opt_eb = 0;
my $opt_system = "";
my $opt_null = 0;
my $opt_dir = "";
my $opt_mode = 0;
my $opt_verbose = 0;
my $opt_ext = "te";
my $opt_trbnr = "0";
my $opt_port = "0";
my $udp_line = "";
my $opt_id="0";

GetOptions ('h|help'      => \$opt_help,
            'r|readout'   => \$opt_readout,
	    'e|eb'        => \$opt_eb,
	    's|system=s'  => \$opt_system,


	    'n|null'      => \$opt_null,
            'd|dir=s'     => \$opt_dir,
	    'x|ext=s'     => \$opt_ext,
	    'v|verbose'   => \$opt_verbose,
            'l|trbnr=s'   => \$opt_trbnr,
            'p|port=s'    => \$opt_port,
            'i|id=s'      => \$opt_id);

if( $opt_help ) {
    &help();
    exit(0);
}

if(&checkOptions()){
    exit(1);
}

#! read DAQ startup sequence  
my $daqstartup      = &getDAQStartup();
#my $trb_script_name = "trb_startup";
my $trb_script_name = "trb_startup" . sprintf("%03d",$opt_id);

if($opt_readout){
    &writeTRBScript();
    sleep 1;
    &startDAQ();
    sleep 5;
}

if($opt_eb){
    &killEB($opt_system);
    &startEB();
}

exit(0);

################ END OF MAIN ###############

sub help
{
    print "\n";
    print << 'EOF';
start_daq_trb.pl

   This script logins to TRBs, programs FPGAs, performs necessary
   settings and starts readout and event building (on lxhadesdaq).
   If you want to change a sequence in which the TRBs are programmed 
   you should change a hash %daq_startup in a subroutine getDAQStartup().
   If you want to change a way how the TRBs are programmed you should
   do changes in a subroutine writeTRBScript().

Usage:
  
   Command line:  start_daq_trb.pl 
   [-h|--help]          - Show this help.
   [-r|--readout]       - Start readout on TRBs.
   [-e|--eb]            - Start event building. 
   -s|--system name     - System to be started (as well as an extension of
                          shared memory name). 
   [-n|--null]          - Write to /dev/null.
   [-d|--dir name]      - Directory name for EB output (must be one dir name without '/').
   [-x|--ext prefix]    - Output hdl file prefix (te,md,to,st...).
   [-v|--verbose]       - More verbose.   

   You must give a system name together with -r or -e arguments.

Requirements:

   Perl module Expect.pm is required.

EOF
}

sub checkOptions
{
    if( !$opt_help && !$opt_readout && !$opt_eb ){
	print "\nSpecify an argument or read help: start_daq_trb.pl -h\n\n";
	return(1);
    }
    
    return(0);
}

sub startEB
{
    my $d_opt = "file";
    if($opt_null){
	$d_opt = "null";
    }

    #- Write down all port numbers for daq_netmem

    my $messages = 0;
    for my $href ( @$daqstartup ){
	if( $href->{'command'} eq 'start_rdo' ){
	    if( $href->{'board'} =~ /etrax(\d+)/ || $href->{'board'} =~ /etraxp(\d+)/){
#		my $port  = 34000 + $1;
		my $port  = 34000 + $opt_port;
		$udp_line = $udp_line . "-i " . $port . " ";
		$messages++;
	    }
	}
    }
    
    my $eb_cmd = "daq_evtbuild -m $messages -d $d_opt --filesize 100 -o /home/pet/datanfs/ -x te -I 1 --ebnum 1 -q 32 -S $opt_trbnr";
    my $netmem_cmd = "daq_netmem -m $messages  -q 32 -i $opt_port -S $opt_trbnr";

    if($opt_verbose){
	print "start EB ...\n";
	print "$eb_cmd\n";
	print "$netmem_cmd\n";
    }

 #   &makeEBdir($opt_dir);

    system("xterm -T \"Event Builder (Lustre OFF)\" -geometry 132x13+100+000 -e '$eb_cmd' &");
    sleep 2;
    system("xterm -T \"Netmem\" -geometry 132x40+100+200 -e '$netmem_cmd' &");
}

sub killEB()
{
    my ($pattern) = @_;

    my @ps_list = `ps axu`;

    foreach my $ps_line (@ps_list){
	chop($ps_line);
	if($ps_line =~ /$pattern/ && ($ps_line =~ /daq_evtbuild/ || $ps_line =~ /daq_netmem/) ){
	    my @this_ps = split(" ", $ps_line);
	    my $proc_num = $this_ps[1];
	    
	    if($opt_verbose){
		print "Selected process: $ps_line\n";
		print "Kill process: $proc_num\n";
	    }

	    system("kill $proc_num");
	}
    }
}

sub makeEBdir()
{
    my ($pattern) = @_;
    my $check = 0;
    my @dir_list = `ls -lrt /data/lxhadesdaq/trb_test/`;

    foreach my $ps_line (@dir_list){
	if($ps_line =~ /$opt_trbnr/){
	  $check = 1
	}
    }

    if($check == 0)
    {
	print $pattern;
	system("mkdir /data/lxhadesdaq/trb_test/$opt_trbnr");
    }
}

sub startDAQ
{
    print "program TRBs and start readout...\n";

    my $delay = 0;

    for my $href ( @$daqstartup ){
	
	if( defined $href->{'delay_before'} ){
	    $delay = $href->{'delay_before'};
	    sleep $delay;
	}

	&spawnTelnet( $href );

	if( defined $href->{'delay_after'} ){
	    $delay = $href->{'delay_after'};
	    sleep $delay;
	}
    }
}

sub spawnTelnet
{
    my ($href) = @_;

    #! Here we use the Expect module to access etrax
    #! and to program FPGA ... and to start readout.

    my $board = $href->{'board'};
    my $cmd   = $href->{'command'};
    print "%%%%%%%%% Command : $cmd\n, Board : $board\n";
    my $timeout  = 30;
    my $username = "root";
    my $password = "pass";    
    my $errexp   = 1;

    my $exp = new Expect;
    #$exp->exp_internal(1); #! debug: more verbose

    $exp->spawn("telnet $board")
	or die "Cannot spawn telnet: $!\n";

    $exp->expect(60,  [ "[Ll]ogin"    => sub { $errexp = 0;
					      $_[0]->send("$username\n"); 
					      exp_continue;} ],
                     [ "[Pp]assword" => sub { $_[0]->send("$password\n"); 
					      exp_continue;} ],
	             [ "# "          => sub { $_[0]->send("cd /home/hadaq; #chmod u+x /home/hadaq/scripts/$trb_script_name\n");}],
	             [ eof           => sub { if (!$errexp) {
			                        print "ERROR: premature EOF in login.\n";
		                              }
					      else{
						print "ERROR: could not spawn telnet.\n";
					      } } ],
	             [ timeout       => sub { print "No login.\n"; } ],
		 );


    

    if( $errexp == 0 ) {
	if( $cmd eq "start_rdo" && ! $opt_verbose){
	    $cmd = "/home/hadaq/scripts/" . $trb_script_name . " " . $board . " " . $cmd . " &";
	}
	else{
	    $cmd = "/home/hadaq/scripts/" . $trb_script_name . " " . $board . " " . $cmd;
	}

	print "\nexec on $board cmd: $cmd\n";
	$exp->expect(60,  [ "# " => sub { $_[0]->send("$cmd\n"); } ] );
	$exp->expect(60,  [ "# " => sub { $_[0]->send("\n"); } ] );
	sleep 1;
    }
    else {
	print "ERROR detected, while trying to login to $board ....\n";
    }

    $exp->soft_close();
}

sub writeTRBScript
{
    #- Write TRB script with all the commands
    #- for all boards

    my $eb_ip = "140.181.75.158"; #lxhadesdaq
  #  my $ebp_ip = "192.168.100.50"; #lxhadesdaq privat
    my $ebp_ip = "10.0.0.1"; #lxhadesdaq privat
    #my $eb_ip = "140.181.93.18";  #hadeb05
    
    my $trbfreq = ($opt_mode-1);
    my $trbmode = $trbfreq . "0000002";

    my $trb_script = <<EOF;

## Attention: This script is automatically generated by the start_daq program
## Do not edit, the changes will be lost...

HOSTNAME=\$1
CMD=\$2


## ETRAX 0xx
     if [ \$CMD = start_rdo ] ; then
     ############## NO DMA ####################


     killall readout_nodma_trbv2_for_beam
#     spi_trbv2 /home/hadaq/tof/thresholds_trb072
#     jam_trbv2 --trb -aRUN_XILINX_PROC /home/hadaq/develop_board/trbv2_stand_alone_readout_g.stapl # was  ok
      jam_trbv2 --trb -aRUN_XILINX_PROC /home/hadaq/develop_board/trb_v2b_fpga_C_PS_Sync_h.stapl
#     jam_trbv2 --trb -aRUN_XILINX_PROC /home/hadaq/develop_board/trb_v2b_fpga_e.stapl
#     jam_trbv2 --trb -aRUN_XILINX_PROC /home/hadaq/develop_board/trb_v2b_fpga_land_d.stapl
#     jam_trbv2 --trb -aRUN_XILINX_PROC /home/hadaq//develop_board/trbv2_sdram_stand_alone.stapl
#     jam_trbv2 --addon -aFP develop_board/tester_board/trb_tester.stp
#     rwv2_addon w 0 c0 20
     export DAQ_SETUP=trb0$opt_id
     cd /home/hadaq/scripts/
     #./trbv2_TDCs_configure.sh 001 #hres calibration
     #./trbv2_TDCs_configure.sh 000 #hres with on chip interpolation
     ./trbv2_TDCs_configure.sh 038 #normall 
#     print "TDC config file: $opt_id"; 
     rw_trbv2 --trb w 0 c2 00500000
#Trigger input delay
     rw_trbv2 --trb w 0 c0 15000000
     rw_trbv2 --trb w 0 c3 00000100
     rw_trbv2 --trb w 0 c5 400
     cd /home/hadaq/trb_old_files_19_08_2009/
     readout_nodma_trbv2_for_beam -w 10000 -o UDP:$ebp_ip:$opt_port &
     fi
     
EOF
     
    my $trb_script_fn = "/var/diskless/etrax_fs/scripts/$trb_script_name";
    my $fh = new FileHandle(">$trb_script_fn");

    if(!$fh) {
	my $txt = "error! Could not open file \"$trb_script_fn\" for output. exit \n";
	print STDERR $txt;
	print $txt;
	exit(128);
    }

    print $fh $trb_script;
    $fh->close();

    chmod 0775, $trb_script_fn 
	or die "Error! could not make file \"$trb_script_fn\" user and group executable"; 
}

sub getDAQStartup
{

    my @daq_startup;
    print "system: $opt_system\n";

    if( $opt_system eq "trb_test" ){
	@daq_startup = (
			{
			    'board'        => $opt_trbnr,
			    'delay_before' => 0, 
			    'delay_after'  => 0,          # seconds 
			    'command'      => 'start_rdo'},
			);
    }
    else{
	print "\nValid system is not defined! Read help.\n";
	exit(1);
    }

    return \@daq_startup;
}

		     

