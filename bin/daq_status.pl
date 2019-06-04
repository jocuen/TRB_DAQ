#!/usr/bin/perl -w

use English;
use strict;
use Expect;
use FileHandle;
use Getopt::Long;
use Data::Dumper;

#$Expect::Multiline_Matching = 0;

#- Following TRB numbers are the default if
#- no --beam option is provided.
my @trbnum = (23, 31, 34, 32, 51..54);

#- the command line option flags
my $opt_help  = 0;
my $opt_etrax = "";
my $opt_address = -1;
my $opt_scan = 0;
my $opt_beam = 0;
my $opt_dump = 0;

GetOptions ('h|help'      => \$opt_help,
            'e|etrax=s'   => \$opt_etrax,
	    'a|address=i' => \$opt_address,
	    'b|beam'      => \$opt_beam,
	    'd|dump'      => \$opt_dump);

if( $opt_help ) {
    &help();
    exit(0);
}

if( !$opt_dump ){
    &checkOptions();
}

#! read hash with a map of bits of FPGA registers  
my $FPGA_registers_map = &getFPGAregisters();

my %FPGA_registers_val_hash; #! values of registers returned by FPGA
my $FPGA_registers_val = \%FPGA_registers_val_hash; #! reference

#! get a list of TRBs in the system
my @trbsys = ();
if( $opt_etrax ) {
    push( @trbsys, $opt_etrax );
}
else{
    @trbsys = &getTRBs();
    if( !(@trbsys) ) {
	print "Number of TRBs in the DAQ is none! Please, specify the etrax name. \n";
	exit(0);
    }
}

#! Check the status of TRBs
if( $opt_address >= 0 ){

    &readFPGARegisters( $FPGA_registers_val, $opt_address, @trbsys);

    &printStatusExpert( $opt_address );
}

exit(0);

################# end of main ###################

sub checkOptions
{
    if( !(grep {$_ eq $opt_address} (1,2,4,5,6,7,8)) ){

	print "Address $opt_address is not supported!\n";
	print "Address range: 1,2,4,5,6,7,8\n";
	&usage();
	exit(0);
    }	
}

sub usage
{
    print "Usage:\n";
    print "Command line: daq_status.pl [-h|--help]\n";
    print "[-e|--etrax etrax_name] - name of the etrax (etrax032)\n";
    print " -a|--address address   - address to be read\n";
}

sub help
{
    print "\n";
    print << 'EOF';
This script logins to TRB(s) and extracts the status of the board 
by reading FPGA registers. The following addresses are supported:
1,2,4,5,6,7,8. 

Examples:
Get status for the etrax032, address 5:
daq_status.pl -e etrax032 -a 5

Get status for all TRBs, address 5:
daq_status.pl -a 5

EOF

    &usage();
}

sub printStatusExpert
{
    my ($addr) = @_;

    if( $addr == 8 ) {
	printf("\n\n");
	printf("----------------------------------------------------------------\n");
	printf("INFO:\n");
	printf("----------------------------------------------------------------\n");	
	printf("%-10s%-5s%-7s%-7s%-7s%-7s\n",
	       "TRB","adr","spi",  "spi",  "spi",  "spi");
	printf("%-10s%-5s%-7s%-7s%-7s%-7s\n",
	       "",   "",   "sdi_a","sdi_b","sdi_c","sdi_d");
	
	for my $trb ( sort keys %$FPGA_registers_val) {
	    
	    printf("%-10s%-5s%-7s%-7s%-7s%-7s\n",$trb,$addr, 
		   $FPGA_registers_val->{$trb}->{$addr}->{'data04'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data03'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data02'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data01'}->{'bitval'});
	}
    }

    if( $addr == 7 ) {
	printf("\n\n");
	printf("----------------------------------------------------------------\n");
	printf("INFO:\n");
	printf("----------------------------------------------------------------\n");	
	printf("%-10s%-5s%-7s%-7s%-6s%-7s%-7s%-6s%-7s%-7s%-6s%-7s%-7s%-6s\n",
	       "TRB","adr","spi",  "spi",  "spi", "spi",  "spi",  "spi", "spi",  "spi",  "spi", "spi",  "spi",  "spi");
	printf("%-10s%-5s%-7s%-7s%-6s%-7s%-7s%-6s%-7s%-7s%-6s%-7s%-7s%-6s\n",
	       "",   "",   "sck_a","sdo_a","cs_a","sck_b","sdo_b","cs_b","sck_c","sdo_c","cs_c","sck_d","sdo_d","cs_d");
	
	for my $trb ( sort keys %$FPGA_registers_val) {
	    
	    printf("%-10s%-5s%-7s%-7s%-6s%-7s%-7s%-6s%-7s%-7s%-6s%-7s%-7s%-6s\n",$trb,$addr, 
		   $FPGA_registers_val->{$trb}->{$addr}->{'data12'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data11'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data10'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data09'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data08'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data07'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data06'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data05'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data04'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data03'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data02'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data01'}->{'bitval'});
	}
    }

    if( $addr == 6 ) {
	printf("\n\n");
	printf("----------------------------------------------------------------\n");
	printf("INFO:\n");
	printf("%-40s\n","JTAG TDC:     enable JTAG for TDC");
	printf("%-40s\n","test sig1:    enable test signal(1)-1kHz");
	printf("%-40s\n","test sig2:    enable test signal(2)-1kHz");
	printf("%-40s\n","TDC clock:    enable TDC clock (trbva)");
	printf("%-40s\n","SPI RPC:      enable SPI for RPC");
	printf("%-40s\n","DelTrig TDCs: additional delay time for trigger to TDCs");
	printf("----------------------------------------------------------------\n");	
	printf("%-10s%-5s%-6s%-6s%-6s%-8s%-7s%-6s%-7s%-6s%-6s%-5s%-10s%-9s\n",
	       "TRB","adr","JTAG","test","test","dsp bm","dsp",  "dsp", "TDC",  "self","ext", "SPI","add data","DelTrig");
	printf("%-10s%-5s%-6s%-6s%-6s%-8s%-7s%-6s%-7s%-6s%-6s%-5s%-10s%-9s\n",
	       "",   "",   "TDC", "sig1","sig2","bms",   "reset","boff","clock","trig","trig","RPC","counters","TDCs");
	
	for my $trb ( sort keys %$FPGA_registers_val) {
	    
	    printf("%-10s%-5s%-6s%-6s%-6s%-8s%-7s%-6s%-7s%-6s%-6s%-5s%-10s%-9s\n",$trb,$addr, 
		   $FPGA_registers_val->{$trb}->{$addr}->{'data12'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data11'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data10'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data09'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data08'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data07'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data06'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data05'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data04'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data03'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data02'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data01'}->{'bitval'},
);

	}
    }


    if( $addr == 5 ) {
	printf("\n\n");
	printf("----------------------------------------------------------------\n");
	printf("INFO:\n");
	printf("%-40s\n","LVL1 ended: received token counter");
	printf("%-40s\n","LVL2 ended: LVL2 busy ended counter");
	printf("----------------------------------------------------------------\n");	
	printf("%-10s%-5s%-8s%-8s%-8s%-8s\n",
	       "TRB","adr","LVL1",  "LVL1","LVL2",  "LVL2");
	printf("%-10s%-5s%-8s%-8s%-8s%-8s\n",
	       "",   "",   "strted","ended","strted","ended");
	
	for my $trb ( sort keys %$FPGA_registers_val) {
	    
	    printf("%-10s%-5s%-8s%-8s%-8s%-8s\n", $trb, $addr, 
		   $FPGA_registers_val->{$trb}->{$addr}->{'data01'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data02'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data03'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data04'}->{'bitval'});
	}
    }
    
    if( $addr == 4 ) {
	printf("\n\n");
	printf("----------------------------------------------------------------\n");
	printf("INFO:\n");
	printf("%-40s\n","LVL1 DelSM:  LVL1 delay state machine");
	printf("%-40s\n","LVL1 TrigSM: LVL1 trigger state machine");
	printf("----------------------------------------------------------------\n");
	printf("%-10s%-5s%-13s%-13s\n",
	       "TRB","adr","LVL1",  "LVL1");
	printf("%-10s%-5s%-13s%-13s\n",
	       "",   "",   "DelSM", "TrigSM");
	
	for my $trb ( sort keys %$FPGA_registers_val) {
	    
	    printf("%-10s%-5s%-13s%-13s\n", $trb, $addr, 
		   $FPGA_registers_val->{$trb}->{$addr}->{'data01'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data02'}->{'bitval'});
	}	
    }

    if( $addr == 2 ) {
	printf("\n\n");
	printf("----------------------------------------------------------------\n");
	printf("INFO:\n");
	printf("%-40s\n","words in evt: number of words in event");
	printf("%-40s\n","DelTrig FSM:  Delay Trigger FState Machine");
	printf("----------------------------------------------------------------\n");
	printf("%-10s%-5s%-9s%-9s%-19s%-18s\n",
	       "TRB","adr","words", "DelTrig","LVL1","LVL2");
	printf("%-10s%-5s%-9s%-9s%-19s%-18s\n",
	       "",   "",   "in evt","FSM",    "state","debug");
	
	for my $trb ( sort keys %$FPGA_registers_val) {
	    
	    printf("%-10s%-5s%-9s%-9s%-19s%-18s\n", $trb, $addr, 
		   $FPGA_registers_val->{$trb}->{$addr}->{'data01'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data02'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data03'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data04'}->{'bitval'});
	}	
    }

    if( $addr == 1 ) {
	printf("\n\n");
	printf("----------------------------------------------------------------\n");
	printf("INFO:\n");
	printf("%-40s\n","LVL1 buff:    words in LVL1 buffer");
	printf("%-40s\n","LVL2 membusy: LVL2 memory busy");
	printf("----------------------------------------------------------------\n");
	printf("%-10s%-5s%-6s%-6s%-6s%-6s%-6s%-6s%-9s%-11s%-11s%-6s\n",
	       "TRB","adr","TDCA","TDCB","TDCC","TDCD","LVL1","LVL1","LVL1/2","LVL1 FIFO","LVL1 FIFO","LVL2");
	printf("%-10s%-5s%-6s%-6s%-6s%-6s%-6s%-6s%-9s%-11s%-11s%-6s\n",
	       "",   "",   "erro","erro","erro","erro","buff","busy","busy","counter","wr en","busy");

	for my $trb ( sort keys %$FPGA_registers_val) {
	    
	    printf("%-10s%-5s%-6s%-6s%-6s%-6s%-6s%-6s%-9s%-11s%-11s%-6s\n", $trb, $addr, 
		   $FPGA_registers_val->{$trb}->{$addr}->{'data01'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data02'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data03'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data04'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data05'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data06'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data07'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data08'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data09'}->{'bitval'},
		   $FPGA_registers_val->{$trb}->{$addr}->{'data10'}->{'bitval'});
	}	
    }
}

sub checkTRBsys
{


}

sub extractBits 
{
    my ($val, $bit) = @_;

    #! extract bits accordning to the 'bit' borders
    #! from the binary 'val'

    my $trunc = 0;

    if( $bit =~ /(\d+)-(\d+)/ ) {
	my $front = 31 - $1;
	my $end   = $2;

	if( $end > 0 ) {
	    $trunc = substr($val, $front, -$end);
	}
	else {
	    $trunc = substr($val, $front);
	}
    }
    
    return $trunc;
}
    
sub convertBits
{
    my ($var, $type, $mask) = @_;

    #! convert bits 'var' to a meaningfull value
    #! according to a type and a mask.
    my $retval = 0;

    if( $type eq 'dec' ) {
	#! should be converted to decimal
	if( $mask eq 'none' ) { return bin2dec($var); }
    }
    elsif( $type eq 'bin' ) {
	#! should be binary (no conversion needed)
	if( $mask eq 'none' ) { return $var; }
	elsif( &testMask( $var, $mask) !~ /-1/ ) {
	    $retval = &testMask( $var, $mask); #! successful test -> mask found
	}
    }
    elsif( $type eq 'hex' ) {
	#! should be converted to hex
	my $hex = bin2hex($var);

	if( $mask eq 'none' ) { return $hex;  }
	elsif( &testMask( $hex, $mask) !~ /-1/ ) {
	    $retval = &testMask( $hex, $mask); #! successful test -> mask found
	}
    }
    else{
	die "Unknown data type: $type! exiting...\n";
    }

    return $retval;
}

sub testMask 
{
    my ($var, $mask) = @_;
    my $retval = -1;

    #! loop over available masks and compare
    #! each mask with the test variable
    for my $m ( sort keys %{$mask}) {
	if( $m eq $var) {
	    $retval = $mask->{$m};
	}   
    }

    return $retval;
}

sub bin2dec 
{
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub dec2bin 
{
    my $str = unpack("B32", pack("N", shift));
    $str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
    return $str;
}

sub bin2hex
{
    my $int = unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
    my $hex = sprintf("%x", $int );
    return $hex;
}

sub getTRBs
{
    my $DAQ_SETUP = $ENV{DAQ_SETUP};
    chop($DAQ_SETUP); 
    chop($DAQ_SETUP); #! get rid of "eb"    

    #! full path to subsystems
    my $config_file = $DAQ_SETUP . "subsystems_for_daq";
    my $subsys;    

    unless ($subsys = do $config_file) {
	die "couldn't parse $config_file: $@, stopped"  if $@;
	die "couldn't do $config_file: $!, stopped"     unless defined $subsys;
	die "couldn't run $config_file, stopped"        unless $subsys;
    }
    
    #! remove non-trb subsystems
    my @trbsys;
    
    if( $opt_beam ){
	foreach (@$subsys) {
	    if( $_ =~ /trb(\d+)/ ) {
		my $etrax = sprintf( "etrax%03d", $1 );
		push( @trbsys, $etrax );
	    }
	}
    }
    else{
	foreach my $num (@trbnum) {
	    my $etrax = sprintf( "etrax%03d", $num );
	    push( @trbsys, $etrax );
	}
    }

    return sort(@trbsys);
}

sub readFPGARegisters
{
    my ($FPGA_val, $addr, @subSys) = @_;

    #! Here we try to spawn a process which will access
    #! etrax using an Expect module functionality.
    #! fork works in a strange way... -> disable fork
    my $fork = 0; #! enable/disable fork
    
    my @process_list = ();
	
    foreach my $trb (@subSys) {

	if( $fork ) {

	    my $child = fork();
	    if( $child ) {
		#! PARENT
		push( @process_list, $child );
	    }
	    else {
		#! CHILD
		&spawnTelnet( $FPGA_val, $trb, $addr );
	    }
	}
	else {
	    #! no fork
	    &spawnTelnet( $FPGA_val, $trb, $addr );
	}
    }

    if( $fork ) {
	#! wait for children
	foreach my $child_pid (@process_list) {
	    waitpid( $child_pid, 0 );
	}
    }

    #! In this part we extract bit-wise information
    #! from the output of "rw_trbv2 r 0" and fill it
    #! into a hash together with the text information

    for my $trb ( sort keys %$FPGA_val) {
	my $val = $FPGA_val->{$trb}->{$addr}->{'val'};    

	for my $data ( sort keys %{$FPGA_registers_map->{'address'}->{$addr}} ) {
	    
	    my $bit  = $FPGA_registers_map->{'address'}->{$addr}->{$data}->{'bit'};
	    my $type = $FPGA_registers_map->{'address'}->{$addr}->{$data}->{'type'};
	    my $mask = $FPGA_registers_map->{'address'}->{$addr}->{$data}->{'mask'};
	    my $text = $FPGA_registers_map->{'address'}->{$addr}->{$data}->{'text'};
	    
	    my $bitval;
	    if( $val eq 'none') {
		$bitval = '-';
	    }
	    else {
		$bitval = &extractBits( $val, $bit ); 
		$bitval = &convertBits( $bitval, $type, $mask );
	    }

	    $FPGA_val->{$trb}->{$addr}->{$data}->{'bitval'} = $bitval;
	    $FPGA_val->{$trb}->{$addr}->{$data}->{'text'}   = $text;
	}
    }
}
    
sub spawnTelnet
{
    my ($FPGA_val, $host, $address) = @_;

    #! Here we use the Expect module to access etrax
    #! and to readout registers of FPGA.
    #! A content of the register is converted to a binary.

    my $timeout  = 10;
    my $username = "root";
    my $password = "pass";    
    my $errexp   = 1;

    my $exp = new Expect;
    #$exp->exp_internal(1); #! debug: more verbose

    $exp->spawn("telnet $host")
	or die "Cannot spawn telnet: $!\n";
    
    $exp->expect(5,  [ "[Ll]ogin"    => sub { $errexp = 0;
					      $_[0]->send("$username\n"); 
					      exp_continue;} ],
                     [ "[Pp]assword" => sub { $_[0]->send("$password\n"); 
					      exp_continue;} ],
	             [ "# "          => sub { $_[0]->send("cd /home/hadaq\n"); } ],
	             [ eof           => sub { if (!$errexp) {
			                        print "ERROR: premature EOF in login.\n";
		                              }
					      else{
						print "ERROR: could not spawn telnet.\n";
					      } } ],
	             [ timeout       => sub { print "No login.\n"; } ],
		 );

    if( $errexp == 0 ) {
	$exp->expect(5, [ "# " => sub { $_[0]->send("rw_trbv2 r 0 $address\n"); } ] );

	#$exp->expect(5, [ "0x[0-9a-fA-F]{1,8}" => sub { $read = $exp->match(); } ]);
	$exp->expect(5, '-re', "0x[0-9a-fA-F]{1,8}");

	my $hex = $exp->match();
	my $bin = sprintf( "%032b", hex($hex) ); #! from hex to bin

	#! Save the content of the register in the hash
	$FPGA_val->{$host}->{$address}->{'val'} = $bin;
    }
    else {
	$FPGA_val->{$host}->{$address}->{'val'} = 'none';
    }

    $exp->hard_close();
}

sub getFPGAregisters
{

    my %fpga_registers = (
    'address' => { 
	1 => {'data10' => {'bit'  => '31-31',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'LVL2 busy'},
	      'data09' => {'bit'  => '30-30',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'LVL1 FIFO wr en'},
	      'data08' => {'bit'  => '29-16',
		           'type' => 'dec',
		           'mask' => 'none',
			   'text' => 'LVL1 FIFO counter'},
	      'data07' => {'bit'  => '15-15',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'LVL1/2 busy'},
	      'data06' => {'bit'  => '14-14',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'LVL1 busy'},
	      'data05' => {'bit'  => '13-04',
			   'type' => 'dec',
			   'mask' => 'none',
			   'text' => 'words in LVL1 buffer'},
	      'data04' => {'bit'  => '03-03',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'TDC-D error'},
	      'data03' => {'bit'  => '02-02',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'TDC-C error'},
	      'data02' => {'bit'  => '01-01',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'TDC-B error'},
	      'data01' => {'bit'  => '00-00',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'TDC-A error'},
	  },
	2 => {'data04' => {'bit'  => '26-24',
			   'type' => 'bin',
			   'mask' => {'001' => 'idle',
				      '010' => 'readout word1',
				      '011' => 'readout word2',
				      '100' => 'save event size',
				      '101' => 'send data1'},
			   'text' => 'LVL2 debug'},
	      'data03' => {'bit'  => '23-20',
			   'type' => 'hex',
			   'mask' => {'1' => 'idle',
				      '2' => 'send LVL1 trig 1',
				      '3' => 'send LVL1 trig 2',
				      '4' => 'send LVL1 trig 3',
				      '5' => 'send LVL1 trig 4',
				      '6' => 'wait for token',
				      '7' => 'save add data 1',
				      '8' => 'save add data 2',
				      '9' => 'save add data 3',
				      'a' => 'save add data 4'},
			   'test' => 'LVL1 state'},
	      'data02' => {'bit'  => '19-18',
			   'type' => 'bin',
			   'mask' => {'01' => 'idle',
				      '10' => 'delay 1',
				      '11' => 'delay 2'},
			   'test' => 'delay trigger FSM'},
	      'data01' => {'bit'  => '15-00',
			   'type' => 'dec',
			   'mask' => 'none',
			   'text' => 'words in event'},
	  },
	3 => {'data01' => {'bit'  => '31-00',
			   'type' => 'hex',
			   'mask' => 'none',
			   'text' => 'data from LVL1 FIFO'},
	  },
	4 => {'data02' => {'bit'  => '07-04',
			   'type' => 'hex',
			   'mask' => {'0' => 'invalid',
				      '1' => 'idle',
				      '2' => 'send LVL1 trig 1',
				      '3' => 'send LVL1 trig 2',
				      '4' => 'send LVL1 trig 3',
				      '5' => 'send LVL1 trig 4',
				      '6' => 'wait for token',
				      '7' => 'save add data 1',
				      '8' => 'save add data 2',
				      '9' => 'save add data 3',
				      'a' => 'save add data 4'},
			   'text' => 'LVL1 trigger state machine'},
	      'data01' => {'bit'  => '01-00',
			   'type' => 'bin',
			   'mask' => {'00' => 'invalid',
				      '11' => 'idle',
				      '01' => 'delay 1',
				      '10' => 'delay 2'},
			   'text' => 'LVL1 delay state machine'},
	  },
	5 => {'data04' => {'bit'  => '31-24',
			   'type' => 'dec',
			   'mask' => 'none',
			   'text' => 'LVL2 busy ended'},
	      'data03' => {'bit'  => '23-16',
			   'type' => 'dec',
			   'mask' => 'none',
			   'text' => 'LVL2 started'},
	      'data02' => {'bit'  => '15-08',
			   'type' => 'dec',
			   'mask' => 'none',
			   'text' => 'token recieved'},
	      'data01' => {'bit'  => '07-00',
			   'type' => 'dec',
			   'mask' => 'none',
		           'text' => 'LVL1 started'},
	  },
	6 => {'data12' => {'bit'  => '31-24',
			   'type' => 'dec',
			   'mask' => 'none',
			   'text' => 'additional delay time for trigger to TDCs'},
	      'data11' => {'bit'  => '23-16',
			   'type' => 'dec',
			   'mask' => 'none',
			   'text' => 'add data counters'},
	      'data10' => {'bit'  => '09-09',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'eneble SPI for RPC'},
	      'data09' => {'bit'  => '08-08',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'enable ext. trigger'},
	      'data08' => {'bit'  => '07-07',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'enable self trigger'},
	      'data07' => {'bit'  => '06-06',
			   'type' => 'bin',
			   'mask' => 'none',
			   'task' => 'enable TDC clock (trbva)'},
	      'data06' => {'bit'  => '05-05',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'dsp boff (active low)'},
	      'data05' => {'bit'  => '04-04',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'dsp reset (active low)'},
	      'data04' => {'bit'  => '03-03',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'dsp bm and bms'},
	      'data03' => {'bit'  => '02-02',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'enable test signal(2)-1kHz'},
	      'data02' => {'bit'  => '01-01',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'enable test signal(1)-1kHz'},
	      'data01' => {'bit'  => '00-00',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'enable JTAG for TDC'},
	  },
	7 => {'data12' => {'bit'  => '11-11',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_cs_d'},
	      'data11' => {'bit'  => '10-10',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sdo_d'},
	      'data10' => {'bit'  => '09-09',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sck_d'},
	      'data09' => {'bit'  => '08-08',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_cs_c'},
	      'data08' => {'bit'  => '07-07',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sdo_c'},
	      'data07' => {'bit'  => '06-06',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sck_c'},
	      'data06' => {'bit'  => '05-05',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_cs_b'},
	      'data05' => {'bit'  => '04-04',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sdo_b'},
	      'data04' => {'bit'  => '03-03',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sck_b'},
	      'data03' => {'bit'  => '02-02',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_cs_a'},
	      'data02' => {'bit'  => '01-01',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sdo_a'},
	      'data01' => {'bit'  => '00-00',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sck_a'},
	  },
	8 => {'data04' => {'bit'  => '03-03',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sdi_d'},
	      'data03' => {'bit'  => '02-02',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sdi_c'},
	      'data02' => {'bit'  => '01-01',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sdi_b'},
	      'data01' => {'bit'  => '00-00',
			   'type' => 'bin',
			   'mask' => 'none',
			   'text' => 'spi_sdi_a'},
	  },
     }
    );
    
    return \%fpga_registers;  
}

