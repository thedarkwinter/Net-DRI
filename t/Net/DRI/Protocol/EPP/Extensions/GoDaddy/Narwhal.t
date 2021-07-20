#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 3;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
my ($dri,$rc,$s,$d,$dh,@c,$idn);
my @core_modules = map { 'Net::DRI::Protocol::EPP::Core::'.$_ } qw/Session RegistryMessage Domain Contact Host/;

sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

$dri=Net::DRI::TrapExceptions->new({cache_ttl => -1, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });


#TODO
# We should probably test these with greetings??

# To use standard
$dri->add_current_registry('GoDaddy::GoDaddy');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN AllocationToken NeuLevel::CO NeuLevel::Message NeuLevel::EXTContact NeuLevel::WhoisType ARI::KeyValue CentralNic::Fee GoDaddy::MZB/],'GoDaddy (standard): loaded_modules');

# To se ARI extensions instead
$dri->add_current_profile('p2','epp_ari',{f_send=>\&mysend,f_recv=>\&myrecv});
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS AllocationToken ARI::IDNVariant ARI::KeyValue ARI::ExAvail ARI::Price ARI::TMCHApplication ARI::Block NeuLevel::CO NeuLevel::Message NeuLevel::WhoisType NeuLevel::EXTContact/],'Neustar::Narwhal (Ari): loaded_modules');

# To use NGTLD with legacy
$dri->add_current_registry('NGTLD',{provider => 'neustar', 'name' => 'hotels'});
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN AllocationToken NeuLevel::CO NeuLevel::Message CentralNic::Fee/],'NGTLD/Neustar (legacy): loaded_modules');
exit 0;
