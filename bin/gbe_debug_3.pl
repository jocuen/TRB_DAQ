#!/usr/bin/perl

#use strict;
#use warnings;
use Switch;
use Data::Dumper; #library to draw data
use Gtk2 '-init';

Gtk2::Rc->parse_string(<<__);
style "normal" {
	font_name = "sans 8"
	bg[NORMAL] = "#ffffff"
}

style "yellow" {
	font_name = "sans 8"
	fg[NORMAL] = "#808000"
}

style "green" {
	font_name = "sans 8"
	fg[NORMAL] = "#00a000"
}

style "red" {
	font_name = "sans 8"
	fg[NORMAL] = "#a00000"
}

widget "*" style "normal"
widget "*yellow*" style "yellow"
widget "*green*" style "green"
widget "*red*" style "red"
__


package main;


use constant TRUE => 1;
use constant FALSE => 0;

my %hubs = ();

my $table = Gtk2::Table->new(1, 1, TRUE);

my $noteBuf = Gtk2::TextBuffer->new();
my $textView = Gtk2::TextView->new_with_buffer($noteBuf);

my $endMark = $noteBuf->create_mark("end", $noteBuf->get_end_iter, FALSE);
$noteBuf->signal_connect (insert_text => sub { $textView->scroll_to_mark($endMark, 0.0, TRUE, 0.0, 1.0); } );

my $scroll = Gtk2::ScrolledWindow->new();
$scroll->set_policy("never", "automatic");
$scroll->add($textView);

my $window = Gtk2::Window->new('toplevel');

my $vbox = Gtk2::VBox->new(FALSE, 5);
my $kbpsLabel = Gtk2::Label->new();
my $eventsLabel = Gtk2::Label->new();
my $avgLabel = Gtk2::Label->new();
my $hubNumLabel = Gtk2::Label->new();

my $old_number_events = 0;

sub get_data {
	
 	my $data = qx(trbcmd rm 0xff7f 0x83f3 0xa 0);
# 	my $data = qx(cat /tmp/hub_out.txt);

 	return split('\n', $data);
}

sub get_hubs {
	my @input = @_;
	
	%hubs = ();
	
	#print Dumper @input;
	foreach (@input) {
		next if(!/H: /);
		my @t = split(/\s+/, $_);
		#print Dumper \@t;
		$hubs{$t[1]}->{"idLabel"} = Gtk2::Label->new($t[1]);
		$hubs{$t[1]}->{"bytesLabel"} = Gtk2::Label->new("0");
		$hubs{$t[1]}->{"sentLabel"} = Gtk2::Label->new("0");
		$hubs{$t[1]}->{"droppedLabel"} = Gtk2::Label->new("0");
		$hubs{$t[1]}->{"headersLabel"} = Gtk2::Label->new("0");
		$hubs{$t[1]}->{"smallLabel"} = Gtk2::Label->new("0");
		$hubs{$t[1]}->{"largeLabel"} = Gtk2::Label->new("0");
		$hubs{$t[1]}->{"emptyLabel"} = Gtk2::Label->new("0");
		$hubs{$t[1]}->{"statusLabel"} = Gtk2::Label->new();
	}
	#exit;
	#print "hubs: ";
	#print Dumper \%hubs;

}

sub parse_data {
    	my(@input) = @_;
	my $c = ''; 
	
	foreach (@input) { #iterate through all input lines
		next if(/^Remo/ || /^\s*$/); #skip the remote... and empty lines
		#s/"\n"/ /g; #changes all new lines to spaces
		$c .= $_." "; #create a string with data lines
	}
	#print "c:\n"; 	print Dumper \$c;
	my (@r) = split (/\s*H\: /, $c); #split the whole string into an array of strings containing data of each hub
	shift(@r);

### remake table in case hubs configuration has changed
	#print "r: "; print  scalar @r; print  "\n";
	#print "h: "; print scalar keys (%hubs); print  "\n";
	#print Dumper sort @r; print Dumper %hubs;

 	if ((scalar @r) != (scalar keys(%hubs))) {

 		get_hubs(@input);
		#print Dumper sort keys %hubs;
		$vbox->remove($table);
		$vbox->remove($scroll);
		my $d = qx(date +"20%y/%m/%d %H:%M:%S");
		chomp($d);
		$note = "[".$d."]: Hubs configuration has changed\n"; 		
	        create_table();
 		$noteBuf->insert_at_cursor($note);
		$vbox->pack_start($scroll, FALSE, FALSE, 0);
		$window->show_all;
 	}
	
	foreach (@r) { #foreach hub data;
		my @l = split(/\s+/, $_); # split the line on spaces
		
		my $id = shift @l; #remove the first word with the hub address
		my @l2 = (); #clear the array
		my $ctr = 0;
		foreach my $li (@l) { #go through the rest of data
				
			next if ($li =~ /0x\w\w\w\w$/); #skip the register addresses
			if ($ctr != 6) {  # do not convert status info to decimal
				push (@l2, hex($li)); # push the data into another array
			}
			else {
				push(@l2, $li);
			}
			$ctr++;
		}
		
		my @ta = @l2; #create a copy of the array to store it
		
		next if !defined($ta[5]);
		
		#create hash with hub ids and corresponding also hashed data
		$hubs{$id}->{"bytes"} = $ta[0];
		$hubs{$id}->{"sent"} = $ta[1];
		$hubs{$id}->{"dropped"} = $ta[2];
		$hubs{$id}->{"small"} = $ta[3];
		$hubs{$id}->{"large"} = $ta[4];
		$hubs{$id}->{"headers"} = $ta[5];
		$hubs{$id}->{"status"} = $ta[6];
		$hubs{$id}->{"empty"} = $ta[9];
	}
### add information about gbe enabled
	my @d = split('\n', qx(daqop trbcmd r 0xff7f 0x8305));
#	my @d = split('\n', qx(cat /tmp/hub_out_gbe.txt));
	foreach my $dd (@d) {
		next if !($dd =~ /0x....\s+0x\d+/);
 		@ddd = split(" ", $dd);
 		$hubs{$ddd[0]}->{"gbeEnabled"} = $ddd[1];
	}
}

sub update_labels {
	my $ctr = 0;
	my $kbpsT = 0;
	my $eventsT = 0;
	foreach my $k (keys %hubs) {
		next if !defined ($hubs{$k}->{"bytesLabel"});

		my $t = int(($hubs{$k}->{"bytes"} - $hubs{$k}->{"bytesP"}) / 1000);
		if ($t > 0) {
			$kbpsT += $t;
		}
		$hubs{$k}->{"bytesP"} = $hubs{$k}->{"bytes"};
		if ($t == 0) {
			$hubs{$k}->{"bytesLabel"}->set_text($t);
			$hubs{$k}->{"bytesLabel"}->set_name("red".$ctr);
		}
		elsif (($t > 0) && ($t < 20000)) {
			$hubs{$k}->{"bytesLabel"}->set_text($t);
			$hubs{$k}->{"bytesLabel"}->set_name("green".$ctr);
		}
		elsif ($t >= 20000) {
			$hubs{$k}->{"bytesLabel"}->set_text($t);
			$hubs{$k}->{"bytesLabel"}->set_name("yellow".$ctr);
		}
		
		$hubs{$k}->{"sentLabel"}->set_text(int($hubs{$k}->{"sent"} / 1000));
		$eventsT += $hubs{$k}->{"sent"};
		$hubs{$k}->{"droppedLabel"}->set_text($hubs{$k}->{"dropped"});
		if ($hubs{$k}->{"dropped"} == 0) {
			$hubs{$k}->{"droppedLabel"}->set_name("green".$ctr);
		}
		else {
			$hubs{$k}->{"droppedLabel"}->set_name("red".$ctr);
		}
		
		
		$hubs{$k}->{"smallLabel"}->set_text($hubs{$k}->{"small"});
		if ($hubs{$k}->{"small"} == 0) {
			$hubs{$k}->{"smallLabel"}->set_name("green".$ctr);
		}
		else {
			$hubs{$k}->{"smallLabel"}->set_name("red".$ctr);
		}
		
		$hubs{$k}->{"largeLabel"}->set_text($hubs{$k}->{"large"});
		if ($hubs{$k}->{"large"} == 0) {
			$hubs{$k}->{"largeLabel"}->set_name("green".$ctr);
		}
		else {
			$hubs{$k}->{"largeLabel"}->set_name("red".$ctr);
		}

		$hubs{$k}->{"headersLabel"}->set_text($hubs{$k}->{"headers"});
		if ($hubs{$k}->{"headers"} == 0) {
			$hubs{$k}->{"headersLabel"}->set_name("green".$ctr);
		}
		else {
			$hubs{$k}->{"headersLabel"}->set_name("red".$ctr);
		}
		
		$hubs{$k}->{"emptyLabel"}->set_text($hubs{$k}->{"empty"});
		if ($hubs{$k}->{"empty"} == 0) {
			$hubs{$k}->{"emptyLabel"}->set_name("green".$ctr);
		}
		else {
			$hubs{$k}->{"emptyLabel"}->set_name("red".$ctr);
		}
##status column		
		my @x = split('', $hubs{$k}->{"status"});
		my $s = "";
		$hubs{$k}->{"statusLabel"}->set_name("red".$ctr);
#ipu
		if ($x[9] eq "f") {
			$s .= "! ipu buffer full ";
		}
#packet
		if (($x[8] eq "f") || ($x[8] eq "3")) {
			$s .= "! packet buffer full ";
		}
#frame
		if ($x[7] eq "f") {
			$s .= "! frame buffer full ";
		}
#link
		if ($x[6] eq "f") {
			$s .= "! no link ";
		}
#enabled
		if ($hubs{$k}->{"gbeEnabled"} eq "0x00000000") {
			$s .= "! gbe disabled ";
		}
#ok	
		if($s eq "") {
			$s = "OK";
			$hubs{$k}->{"statusLabel"}->set_name("green".$ctr);
		}
		$hubs{$k}->{"statusLabel"}->set_text($s);
			
		$ctr++;
	}
#overall
	
#	$kbpsT = $kbpsT/1000 . "." . substr($kbpsT;
	$kbpsLabel->set_text($kbpsT);

	# events/s, fix by Michael
	my $evtps = (-$old_number_events + $eventsT) / ($ctr>0 ? $ctr : 1);
	#my $evtps = ($old_number_events - $eventsT ) / $ctr;
	$eventsLabel->set_text(abs(int($evtps)));
	$old_number_events = $eventsT ;

	$avgLabel->set_text(int($kbpsT*1E3 / $evtps)) if ($evtps != 0);
	$hubNumLabel->set_text($ctr);
}


#my $l;

sub create_table {
    #my $t = bless \Gtk2::Table->new(scalar keys(%hubs), 8, TRUE), 'Gtk2::Table';
    my $t = Gtk2::Table->new(scalar keys(%hubs), 8, TRUE);

	my $l;
	$l = Gtk2::Label->new("Hub address");
	$t->attach($l, 0, 1, 0, 1, GTK_SHRINK, GTK_SHRINK, 4, 3);



	$l = Gtk2::Label->new("kB/s");
	$t->attach($l, 1, 2, 0, 1, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("sent events * 1000");
	$t->attach($l, 2, 3, 0, 1, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("events with errors");
	$t->attach($l, 3, 4, 0, 1, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("invalid headers");
	$t->attach($l, 4, 5, 0, 1, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("small events");
	$t->attach($l, 5, 6, 0, 1, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("large events");
	$t->attach($l, 6, 7, 0, 1, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("empty events");
	$t->attach($l, 7, 8, 0, 1, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("status");
	$t->attach($l, 8, 9, 0, 1, GTK_SHRINK, GTK_SHRINK, 4, 3);

	my $ctr = 1;
	foreach my $k (sort(keys %hubs)) {
		next if !defined $hubs{$k}->{"idLabel"};
		
		$t->attach($hubs{$k}->{"idLabel"}, 0, 1, $ctr, $ctr+1, GTK_SHRINK, GTK_SHRINK, 4, 3);
		$t->attach($hubs{$k}->{"bytesLabel"}, 1, 2, $ctr, $ctr+1, GTK_SHRINK, GTK_SHRINK, 4, 3);
		$t->attach($hubs{$k}->{"sentLabel"}, 2, 3, $ctr, $ctr+1, GTK_SHRINK, GTK_SHRINK, 4, 3);
		$t->attach($hubs{$k}->{"droppedLabel"}, 3, 4, $ctr, $ctr+1, GTK_SHRINK, GTK_SHRINK, 4, 3);
		$t->attach($hubs{$k}->{"headersLabel"}, 4, 5, $ctr, $ctr+1, GTK_SHRINK, GTK_SHRINK, 4, 3);
		$t->attach($hubs{$k}->{"smallLabel"}, 5, 6, $ctr, $ctr+1, GTK_SHRINK, GTK_SHRINK, 4, 3);
		$t->attach($hubs{$k}->{"largeLabel"}, 6, 7, $ctr, $ctr+1, GTK_SHRINK, GTK_SHRINK, 4, 3);
		$t->attach($hubs{$k}->{"emptyLabel"}, 7, 8, $ctr, $ctr+1, GTK_SHRINK, GTK_SHRINK, 4, 3);
		$t->attach($hubs{$k}->{"statusLabel"}, 8, 9, $ctr, $ctr+1, GTK_SHRINK, GTK_SHRINK, 4, 3);
		$ctr += 1;
	}
	
	$l = Gtk2::Label->new("Overall:");
	$t->attach($l, 0, 1, $ctr, $ctr + 1, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("kB/s");
	$t->attach($l, 0, 1, $ctr + 1, $ctr + 2, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("events/s");
	$t->attach($l, 1, 2, $ctr + 1, $ctr + 2, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("B/event");
	$t->attach($l, 2, 3, $ctr + 1, $ctr + 2, GTK_SHRINK, GTK_SHRINK, 4, 3);
	$l = Gtk2::Label->new("hubs");
	$t->attach($l, 3, 4, $ctr + 1, $ctr + 2, GTK_SHRINK, GTK_SHRINK, 4, 3);


    $kbpsLabel = Gtk2::Label->new();
    $eventsLabel = Gtk2::Label->new();
    $avgLabel = Gtk2::Label->new();
    $hubNumLabel = Gtk2::Label->new();

        $t->attach($kbpsLabel, 0, 1,   $ctr + 3, $ctr + 4, GTK_SHRINK, GTK_SHRINK, 4, 4);
	$t->attach($eventsLabel, 1, 2, $ctr + 3, $ctr + 4, GTK_SHRINK, GTK_SHRINK, 4, 4);
	$t->attach($avgLabel, 2, 3,    $ctr + 3, $ctr + 4, GTK_SHRINK, GTK_SHRINK, 4, 4);
	$t->attach($hubNumLabel, 3, 4, $ctr + 3, $ctr + 4, GTK_SHRINK, GTK_SHRINK, 4, 4);
	
	$l = Gtk2::Label->new("");
	$t->attach($l, 0, 1, $ctr + 4, $ctr + 5, GTK_SHRINK, GTK_SHRINK, 4, 3);	

	
	$table = $t;

	$table->set_col_spacings(1);
	$table->set_homogeneous(0);
	
	$vbox->pack_start($table, FALSE, FALSE, 0);
	$window->show_all;


}


#### main


Gtk2->init;


#get_hubs(get_data());
#create_table();



$window->signal_connect(destroy => sub { Gtk2->main_quit; });
$window->signal_connect(delete_event => sub { exit; });

$window->set_title("GbE Monitor");
$window->set_border_width(5);

my $d = qx(date +"20%y/%m/%d %H:%M:%S");
chomp($d);
$note = "[".$d."]: Start\n";
$noteBuf->insert_at_cursor($note);
$vbox->pack_start($table, FALSE, FALSE, 0);
$vbox->pack_start($scroll, FALSE, FALSE, 0);
$window->add($vbox);
$window->show_all;



while (1) {
	parse_data(get_data());
	update_labels();

	for(1..10) {
	    while (Gtk2->events_pending) {
		Gtk2->main_iteration;
	    }
	    Gtk2::Gdk->flush;
	    select(undef, undef, undef, 0.1);

	}
	
}

