#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 5;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }


my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('CentralNic');
$dri->target('CentralNic')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c);

####################################################################################################
## Pricing extension

$R2=$E1.'<response>'.r(1000,'Command completed successfully.').'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">example.uk.com</domain:name></domain:cd></domain:chkData></resData><extension><pricing:chkData xmlns:pricing="urn:centralnic:params:xml:ns:pricing-1.0"><pricing:currency>GBP</pricing:currency><pricing:action>create</pricing:action><pricing:period unit="y">1</pricing:period><pricing:price>32.50</pricing:price></pricing:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example.uk.com',{pricing=>{currency=>'GBP',action=>'create',duration=>$dri->local_object('duration','years',1)}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.uk.com</domain:name></domain:check></check><extension><pricing:check xmlns:pricing="urn:centralnic:params:xml:ns:pricing-1.0" xsi:schemaLocation="urn:centralnic:params:xml:ns:pricing-1.0 pricing-1.0.xsd"><pricing:currency>GBP</pricing:currency><pricing:action>create</pricing:action><pricing:period unit="y">1</pricing:period></pricing:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Pricing extension: domain_check build');
$d=$rc->get_data('pricing');
is($d->{currency},'GBP','Pricing extension: domain_check parse currency');
is($d->{action},'create','Pricing extension: domain_check parse action');
is($d->{duration}->years(),1,'Pricing extension: domain_check parse duration');
is($d->{price},32.50,'Pricing extension: domain_check parse price');

####################################################################################################
exit 0;
