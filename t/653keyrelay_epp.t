#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 9;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['KeyRelay']});

my $ro=$dri->remote_object('domain');
$ro->keyrelay('example.com',{secdns => [{key_flags=>256,key_protocol=>3,key_alg=>8,key_pubKey=>'cmlraXN0aGViZXN0'}],
                             auth => { pw => 'JnSdBAZSxxzJ'}, 
                             expiry => $dri->local_object('duration','months',1,'days',13)
                            });

is_string($R1,$E1.'<extension><keyrelay:command xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:keyrelay="urn:ietf:params:xml:ns:keyrelay-1.0" xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd urn:ietf:params:xml:ns:keyrelay-1.0 keyrelay-1.0.xsd urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><keyrelay:keyrelay><keyrelay:name>example.com</keyrelay:name><keyrelay:keyData><secDNS:flags>256</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>8</secDNS:alg><secDNS:pubKey>cmlraXN0aGViZXN0</secDNS:pubKey></keyrelay:keyData><keyrelay:authInfo><domain:pw>JnSdBAZSxxzJ</domain:pw></keyrelay:authInfo><keyrelay:expiry><keyrelay:relative>P1M1W6D</keyrelay:relative></keyrelay:expiry></keyrelay:keyrelay><keyrelay:clTRID>ABC-12345</keyrelay:clTRID></keyrelay:command></extension>'.$E2,'keyrelay build');


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:keyrelay="urn:ietf:params:xml:ns:keyrelay-1.0"><response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="5" id="12345"><qDate>1999-04-04T22:01:00.0Z</qDate><msg>Key Relay action completed successfully.</msg></msgQ><resData><keyrelay:response><keyrelay:panData><keyrelay:name paResult="true">example.com</keyrelay:name><keyrelay:paDate>1999-04-04T22:01:00.0Z</keyrelay:paDate><keyrelay:keyData><secDNS:flags>256</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>8</secDNS:alg><secDNS:pubKey>cmlraXN0aGViZXN0</secDNS:pubKey></keyrelay:keyData><keyrelay:authInfo><domain:pw>JnSdBAZSxxzJ</domain:pw></keyrelay:authInfo><keyrelay:expiry><keyrelay:relative>P24D</keyrelay:relative></keyrelay:expiry><keyrelay:reID>ClientX</keyrelay:reID><keyrelay:acID>ClientY</keyrelay:acID></keyrelay:panData></keyrelay:response></resData>'.$TRID.'</response>'.$E2;
my $rc=$dri->message_retrieve();
my $rk=$rc->get_data('domain','example.com','keyrelay');
is($rc->get_data('domain','example.com','action'),'review','get_data action');
is($rc->get_data('domain','example.com','result'),1,'get_data result');
is(''.$rc->get_data('domain','example.com','date'),'1999-04-04T22:01:00','get_data date');
is_deeply($rk->{secdns},[{key_flags=>256,key_protocol=>3,key_alg=>8,key_pubKey=>'cmlraXN0aGViZXN0'}],'get_data keyrelay secdns');
is_deeply($rk->{auth},{pw=>'JnSdBAZSxxzJ'},'get_data keyrelay auth');
is_deeply([$rk->{expiry}->in_units('weeks','days')],[3,3],'get_data keyrelay expiry');
is($rk->{reID},'ClientX','get_data keyrelay reID');
is($rk->{acID},'ClientY','get_data keyrelay acID');

exit 0;
