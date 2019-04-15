#!/usr/bin/perl

use warnings;
use strict;
use Socket;
use IO::Socket;
use Time::HiRes qw(usleep nanosleep);
use Device::BCM2835;
use JSON;
use POSIX qw(strftime);
use LWP::UserAgent;
use Sys::SigAction qw( timeout_call );
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
use IPC::Shareable;

#main program
my $json_text;
my $buffer;
my $handle = tie $buffer, 'IPC::Shareable', undef, { destroy => 1 };
rpigpioset();
my $pid = fork(); if ($pid == -1) { die; } elsif ($pid == 0) { dht22(); exit 0; }

$pid = fork(); if ($pid == -1) { die; } elsif ($pid == 0) { cycleloop(); exit 0; }

$pid = fork(); if ($pid == -1) { die; } elsif ($pid == 0) { webreport(); exit 0; }

while () {sleep 5;};

# Subroutines
sub ctl1 {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_11, 1); return "OK";}
sub ctl2 {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_12, 1); return "OK";}
sub ctl3 {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_15, 1); return "OK";}
sub ctl4 {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_16, 1); return "OK";}
sub ctl5 {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_11, 0); return "OK";}
sub ctl6 {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_12, 0); return "OK";}
sub ctl7 {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_15, 0); return "OK";}
sub ctl8 {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_16, 0); return "OK";}
sub ctl9 {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_18, 1); return "OK";}
sub ctl0 {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_22, 1); return "OK";}
sub ctlc {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_18, 0); return "OK";}
sub ctld {Device::BCM2835::gpio_write(&Device::BCM2835::RPI_V2_GPIO_P1_22, 0); return "OK";}

sub ctlA {
 chomp(my $cpuclock = `/opt/vc/bin/vcgencmd measure_clock arm`);
 chomp(my $cputemp = `/opt/vc/bin/vcgencmd measure_temp`);
 chomp(my $memtotal = `cat /proc/meminfo | grep MemTotal`);
 chomp(my $memfree = `cat /proc/meminfo | grep MemFree`);
 ($cpuclock) = ($cpuclock =~ /(?:=|:\s*)(\d+\.?\d*)/);
 ($cputemp) = ($cputemp =~ /(?:=|:\s*)(\d+\.?\d*)/);
 ($memtotal) = ($memtotal =~ /(?:=|:\s*)(\d+\.?\d*)/);
 ($memfree) = ($memfree =~ /(?:=|:\s*)(\d+\.?\d*)/);
 $cpuclock /= 1000000;
 my $memused =  sprintf("%.2f", (($memtotal - $memfree) / $memtotal)*100);
 my @reportdht22 = tempf();
 my %report = (
 7 => Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_V2_GPIO_P1_07),
 11 => Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_V2_GPIO_P1_11),
 12 => Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_V2_GPIO_P1_12),
 13 => Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_V2_GPIO_P1_13),
 15 => Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_V2_GPIO_P1_15),
 16 => Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_V2_GPIO_P1_16),
 18 => Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_V2_GPIO_P1_18),
 22 => Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_V2_GPIO_P1_22),
 24 => Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_V2_GPIO_P1_24),
 26 => Device::BCM2835::gpio_lev(&Device::BCM2835::RPI_V2_GPIO_P1_26),
 cpuclock => $cpuclock,
 cputemp => $cputemp,
 memused => $memused,
 dht22tempc => $reportdht22[2],
 dht22tempf => $reportdht22[0],
 dht22rh => $reportdht22[1],
 host => "evergreen",
 );
 my $reportref = \%report;
 $json_text = encode_json $reportref;
 return $json_text;
}

sub rpigpioset {
# Setup Rpi GPIO pins
Device::BCM2835::init()
 || die "Could not init library";
#Set GPIO Output pins
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_V2_GPIO_P1_11,
                           &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_V2_GPIO_P1_12,
                           &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_V2_GPIO_P1_15,
                           &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_V2_GPIO_P1_16,
                           &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_V2_GPIO_P1_18,
                           &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_V2_GPIO_P1_22,
                           &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
#Set GPIO Input Pins and Pullup High
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_V2_GPIO_P1_07,
                           &Device::BCM2835::BCM2835_GPIO_FSEL_INPT);
Device::BCM2835::gpio_set_pud(&Device::BCM2835::RPI_V2_GPIO_P1_07,
                           &Device::BCM2835::BCM2835_GPIO_PUD_UP);
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_V2_GPIO_P1_13,
                           &Device::BCM2835::BCM2835_GPIO_FSEL_INPT);
Device::BCM2835::gpio_set_pud(&Device::BCM2835::RPI_V2_GPIO_P1_13,
                           &Device::BCM2835::BCM2835_GPIO_PUD_UP);
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_V2_GPIO_P1_24,
                           &Device::BCM2835::BCM2835_GPIO_FSEL_INPT);
Device::BCM2835::gpio_set_pud(&Device::BCM2835::RPI_V2_GPIO_P1_24,
                           &Device::BCM2835::BCM2835_GPIO_PUD_UP);
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_V2_GPIO_P1_26,
                           &Device::BCM2835::BCM2835_GPIO_FSEL_INPT);
Device::BCM2835::gpio_set_pud(&Device::BCM2835::RPI_V2_GPIO_P1_26,
                           &Device::BCM2835::BCM2835_GPIO_PUD_UP);
}

sub cycleloop {
# Temperature Cycle Loop
 while () {
 ctl0();
 my $targetmin = '96.5';
 my $targetinc = $targetmin + '0.25';
 my $targetmax = '99.25';
 my @dht22 = tempf();
 #print "Temperature at " . tstamp() . " is " . $dht22[0] . " degrees F - Humidity " . $dht22[1] . "%\n";
 if ($dht22[0] < $targetmin ) {
   ctl9(); 
   #print "Heat Cycle starting at " . tstamp() . " \n"; 
   ctl1(); sleep 1; ctl3(); my $i = 0; 
   while ($dht22[0] < $targetinc) {
     @dht22 = tempf();
     #print "Temperature at " . tstamp() . " is " . $dht22[0] . " degrees F - Humidity " . $dht22[1] . "%\n";
     foreach my $j (0..3) {
      red2flash();
      }
	 }
   ctl9(); 
   #print "Temperature increase detected at " . tstamp() . " \n";
   }
 elsif ($dht22[0] >= $targetmax ) {
   #print "Heating elements shut off at " . tstamp() . " \n";
   ctl7(); my $i = 0; 
   while ($i < 9) {
     @dht22 = tempf();
     #print "Temperature at " . tstamp() . " is " . $dht22[0] . " degrees F - Humidity " . $dht22[1] . "%\n";
     foreach my $j (0..6) {
      redflash();
     }
     $i++; }
   ctl5(); 
   #print "Cooldown cycle completed at " . tstamp() . " \n";
   while ($dht22[0] >= $targetmax ) { sleep 5; @dht22 = tempf(); 
   #print "Temperature at " . tstamp() . " is " . $dht22[0] . " degrees F - Humidity " . $dht22[1] . "%\n";
   }; }
 else {};
 sleep 5;
 }
 print "Loop has been broken";
 ctld();
}

sub redflash {
ctl9(); usleep 1130000; ctlc(); usleep 1130000;
}

sub red2flash {
ctlc(); usleep 100000; ctl9(); usleep 200000; ctlc(); usleep 100000; ctl9(); usleep 900000;
}

sub dht22 {
 while () {
  chomp(my $dht22raw = `python /home/iceman/Adafruit_Python_DHT/examples/AdafruitDHT.py 22 4`);
  $handle->shlock();
  $buffer = $dht22raw;
  $handle->shunlock();
  sleep 4;
 }
}

sub timestamp {
 return strftime "%F %T %Z", localtime;
}

sub tstamp {
 return strftime "%T", localtime;
}

sub tempf {
 my $dht22raw = $buffer;
 $dht22raw ||= "Temp=50.0*  Humidity=10.0%";
 my $dht22regex = '^[^0-9]*([0-9\\.]+)[^0-9]*([0-9\\.]+)[^0-9]*$';
 $dht22raw =~ m/$dht22regex/g;
 my $dht22tempc = $1;
 my $dht22humid = $2;
 my $subdht22tempf = (9 * $dht22tempc/5) + 32;
 my @subdht;
 @subdht[0] = $subdht22tempf;
 @subdht[1] = $dht22humid;
 @subdht[2] = $dht22tempc;
 return @subdht;
}

sub webreport {

while() {
sleep 5;
httppost();
}

}

sub httppost {

my $uri = 'https://cbomatic.bctech.org/etph.aspx';
my $json = ctlA();
my $req = HTTP::Request->new( 'POST', $uri );
$req->header( 'Content-Type' => 'application/json' );
$req->content( $json );

my $lwp = LWP::UserAgent->new;
$lwp->request( $req );


}