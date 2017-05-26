#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 19;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend  { my ($transport, $count, $msg) = @_; $R1 = $msg->as_string(); return 1; }
sub myrecv  { return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r       { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('Afilias::Shared',{clid => 'ClientX'});
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$ok,$cs,$st,$p);

####################################################################################################
## RegistryMessage Extension
$R2=$E1.'<response><result code="1301"><msg lang="en-US">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="2733"><qDate>2014-05-26T14:33:04.0Z</qDate><msg lang="en-US">{"changeType":"update","name":"example.info","addedStatuses":["serverUpdateProhibited"],"removedStatuses":[],"authInfoUpdated":true}</msg></msgQ>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),2733,'message get_info last_id');
is($dri->get_info('qdate','message',2733),'2014-05-26T14:33:04','message get_info qdate');
is($dri->get_info('content','message',2733),'{"changeType":"update","name":"example.info","addedStatuses":["serverUpdateProhibited"],"removedStatuses":[],"authInfoUpdated":true}','message get_info content');
is($dri->get_info('lang','message',2733),'en-US','message get_info lang');
is($dri->get_info('change_type','message',2733),'update','message get_info change_type');
is($dri->get_info('name','message',2733),'example.info','message get_info name');
is_deeply($dri->get_info('added_statuses','message',2733),['serverUpdateProhibited'],'message get_info addedStatuses');
is_deeply($dri->get_info('removed_statuses','message',2733),[],'message get_info removedStatuses');
is($dri->get_info('auth_info_updated','message',2733),1,'message get_info authInfoUpdated');

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="22" id="12345"><qDate>2014-12-22T06:41:03.0Z</qDate><msg lang="en-US">Transfer Auto Approved.</msg></msgQ><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>randomdomain.info</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>ClientY</domain:reID><domain:reDate>2014-12-22T06:41:03.0Z</domain:reDate><domain:acID>ClientX</domain:acID><domain:acDate>2014-12-17T06:41:03.0Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'12345','message_retrieve get_info(last_id)');
is($dri->get_info('lang','message','12345'),'en-US','message get_info lang');
is($dri->get_info('object_type','message','12345'),'domain','message get_info object_type');
is($dri->get_info('object_id','message','12345'),'randomdomain.info','message get_info id');
is($dri->get_info('action','message','12345'),'transfer','message get_info action');
is($dri->get_info('acID','message','12345'),'ClientX','message get_info acID');
is($dri->get_info('reID','message','12345'),'ClientY','message get_info reID');
is($dri->get_info('acDate','message','12345'),'2014-12-17T06:41:03','message get_info acDate');
is($dri->get_info('reDate','message','12345'),'2014-12-22T06:41:03','message get_info reDate');

exit 0;
