#!/usr/bin/perl

use warnings;
use strict;
use Device::BCM2835;
use Proc::ProcessTable;

#main program routine
killscripts();
print "initalizing GPIO \n";
rpigpioset();
print "Killing power to heating elements and led indicators \n";
ctl6(); ctl7(); ctl8(); ctlc(); ctld();
print "Sleeping for 90 seconds \n";
sleep 90;
ctl5();
print "killing fan power\n shutdown completed \n";

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

sub killscripts {
my $proc_name = '/usr/bin/perl /home/iceman/runtime.pl';
#find and kill perl scripts
my $pid = '';
my $pt;
while (defined $pid) {
$pid = '';
$pt = Proc::ProcessTable->new();
foreach my $proc (@{$pt->table}) {
    next if $proc->cmndline =~ /$0.*$proc_name/;  # not this script
    if ($proc->cmndline =~ /\Q$proc_name/) {
        $pid = $proc->pid;
        last;
    }   
}
if (defined $pid && $pid ne '') {
print "Killing PID: " . $pid . "\n";
kill 15, $pid;                    # must it be 9 (SIGKILL)? 15
my $gone_pid = waitpid $pid, 0;  # then check that it's gone
} else {print "Done Killing PIDs\n"; last;}
}
}