#!/usr/bin/perl
use strict;
use JSON;
use POSIX qw(strftime);
my %hash;
my $hashref = \%hash;

while () {
chomp($hashref->{'dht22raw'} = `python /home/iceman/Adafruit_Python_DHT/examples/AdafruitDHT.py 22 4`);
$hashref->{'dht22regex'} = '^[^0-9]*([0-9\\.]+)[^0-9]*([0-9\\.]+)[^0-9]*$';
$hashref->{'dht22raw'} =~ m/$hashref->{'dht22regex'}/g;
$hashref->{'dht22tempc'} = sprintf("%.2f", $1);
$hashref->{'dht22rh'} = sprintf("%.2f", $2);
unless ( $hashref->{'dht22tempc'} >= 0  and  $hashref->{'dht22tempc'} <= 99  and  $hashref->{'dht22rh'} >= 0  and  $hashref->{'dht22rh'} <= 99 )  { $hashref->{'dht22tempc'} = 0; $hashref->{'dht22rh'} = 0; };
$hashref->{'dht22tempf'} = sprintf("%.2f", (9 * $hashref->{'dht22tempc'}/5) + 32);

chomp($hashref->{'bme280json'} = `/usr/bin/bme280`);
my $plcres = decode_json $hashref->{'bme280json'};
@{$hashref}{keys %$plcres} = values %$plcres;
$hashref->{'bme280tempf'} = sprintf("%.2f", (9 * $hashref->{'temperature'}/5) + 32);
$hashref->{'humidity'} = sprintf("%.2f", $hashref->{'humidity'});
$hashref->{'temperature'} = sprintf("%.2f", $hashref->{'temperature'});
$hashref->{'bme280inhg'} = sprintf("%.2f", $hashref->{'pressure'} * 0.029529983071445);
$hashref->{'bme280feet'} = sprintf("%.2f", $hashref->{'altitude'} * 3.28084);
$hashref->{'bme280time'} = strftime '%T', $hashref->{'timestamp'};
$hashref->{'bme280date'} = strftime '%F', $hashref->{'timestamp'};

print "DHT-22," . $hashref->{'dht22tempf'} . "," . $hashref->{'dht22tempc'} . "," . $hashref->{'dht22rh'} . ",";
print $hashref->{'sensor'} . "," . $hashref->{'bme280tempf'} . "," . $hashref->{'temperature'} . "," . $hashref->{'humidity'} . "," . $hashref->{'bme280inhg'} . "," . $hashref->{'bme280feet'} . "," . $hashref->{'bme280date'} . "," . $hashref->{'bme280time'} . "\n";
#print "\n";

sleep(10);
}
exit 0;