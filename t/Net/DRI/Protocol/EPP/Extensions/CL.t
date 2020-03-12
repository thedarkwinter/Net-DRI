#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;

use Test::More tests => 185;
use Test::Exception;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('NICChile');
$dri->target('NICChile')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$c1,$c2,$c3,$toc,$pollryrr,$clpoll);


###
# The following tests are based on: NIC_Chile_EPP_Documentation_1.0.4.pdf
###


####################################################################################################
######## Session Commands ########

my $drd = $dri->{registries}->{NICChile}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CL',{}],'CL - epp transport_protocol_default');
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');


####################################################################################################
########  Commands - Domain ########

# Domain Name - 5.2. Creation
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example202.cl</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('ClientX');
$c2=$dri->local_object('contact')->srid('ClientY');
$c3=$dri->local_object('contact')->srid('ClientZ');
$cs->set($c1,'registrant');
$cs->set($c1,'admin');
$cs->set($c2,'billing');
$cs->set($c3,'tech');
$rc=$dri->domain_create('example202.cl',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),ns=>$dri->local_object('hosts')->set(['ns1.example.net'],['secundario.nic.net']),contact=>$cs,auth=>{pw=>'PLAIN::QWERTYUIOP12'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example202.cl</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns1.example.net</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>secundario.nic.net</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>ClientX</domain:registrant><domain:contact type="admin">ClientX</domain:contact><domain:contact type="billing">ClientY</domain:contact><domain:contact type="tech">ClientZ</domain:contact><domain:authInfo><domain:pw>PLAIN::QWERTYUIOP12</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2001-04-03T22:00:00','domain_create get_info(exDate) value');

# Domain Name - 5.3. Modification
$R2='';
$toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->set('ns3.example.net','ns4.example.net'));
$rc=$dri->domain_update('example206.cl',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example206.cl</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>ns3.example.net</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns4.example.net</domain:hostName></domain:hostAttr></domain:ns></domain:add></domain:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');

# Domain Name - 5.5. Renewal
$R2='';
$rc=$dri->domain_renew('example204.cl',{duration => DateTime::Duration->new(years=>1), current_expiration => DateTime->new(year=>2020,month=>8,day=>25)});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example204.cl</domain:name><domain:curExpDate>2020-08-25</domain:curExpDate><domain:period unit="y">1</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($rc->is_success(),1,'domain_renew is_success');

# Domain Name - 5.6. Deletion
$R2='';
$rc=$dri->domain_delete('example203.cl',{pure_delete=>1});
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example203.cl</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build');
is($rc->is_success(),1,'domain_delete is_success');



####################################################################################################
########  Commands - Contact ########

# Contact - 6.1. Creation
$R2='';
$co=$dri->local_object('contact')->srid('ClientX');
$co->name('John Doe');
$co->street(['123 Example Dr.']);
$co->city('San Diego');
$co->sp('California');
$co->cc('us');
$co->voice('+56.29407730');
$co->email('john.doe@example.cl');
$co->auth({pw=>'IUUYQWX87121Zaa'});
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>ClientX</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:addr><contact:street>123 Example Dr.</contact:street><contact:city>San Diego</contact:city><contact:sp>California</contact:sp><contact:cc>us</contact:cc></contact:addr></contact:postalInfo><contact:voice>+56.29407730</contact:voice><contact:email>john.doe@example.cl</contact:email><contact:authInfo><contact:pw>IUUYQWX87121Zaa</contact:pw></contact:authInfo></contact:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');



####################################################################################################
########  Registry messages - v1.0.4 ########

# Messages - 7. Messages from the Registry to the Registrar
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="1928"><qDate>2015-02-11T15:58:47.0Z</qDate><msg>Domain name in dispute. New registrant handle 2975640-RCAL</msg></msgQ><resData><pollryrr:pollt xmlns:pollryrr="urn:ietf:params:xml:ns:pollryrr-1.0"><pollryrr:changeState><pollryrr:roid>1930940-NIC</pollryrr:roid><pollryrr:name>example.cl</pollryrr:name><pollryrr:stateInscription>asignado</pollryrr:stateInscription><pollryrr:stateConflict>dispute</pollryrr:stateConflict><pollryrr:status s="serverDeleteProhibited"/><pollryrr:status s="serverTransferProhibited"/><pollryrr:reason>Domain name in dispute. New registrant handle 2975640-RCAL</pollryrr:reason></pollryrr:changeState></pollryrr:pollt></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),1928,'message get_info last_id');
is($dri->message_count(),1,'message_count');
is(''.$dri->get_info('qdate','message',1928),'2015-02-11T15:58:47','message get_info qdate');
is($dri->get_info('content','message',1928),'Domain name in dispute. New registrant handle 2975640-RCAL','message get_info msg');
is($dri->get_info('lang','message',1928),'en','message get_info lang (pure text message)');
# get pollryrr info
$pollryrr = $dri->get_info('pollryrr','message',1928);
is($pollryrr->{'roid'},'1930940-NIC','message get_info roid (pollryrr)');
is($pollryrr->{'name'},'example.cl','message get_info name (pollryrr)');
is($pollryrr->{'stateInscription'},'asignado','message get_info stateInscription (pollryrr)');
is($pollryrr->{'stateConflict'},'dispute','message get_info stateConflict (pollryrr)');
$s=$pollryrr->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','message get_info status (pollryrr)');
is_deeply([$s->list_status()],['serverDeleteProhibited','serverTransferProhibited'],'message get_info status (pollryrr) list');
is($pollryrr->{'reason'},'Domain name in dispute. New registrant handle 2975640-RCAL','message get_info reason (pollryrr)');

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="7"><qDate>2014-09-04T17:18:46</qDate><msg>Complaint denied.</msg></msgQ><resData><pollryrr:pollt xmlns:pollryrr="urn:ietf:params:xml:ns:pollryrr-1.0"><pollryrr:changeState><pollryrr:roid>6-NIC</pollryrr:roid><pollryrr:name>example.cl</pollryrr:name><pollryrr:stateInscription>registered</pollryrr:stateInscription><pollryrr:stateConflict>not applicable</pollryrr:stateConflict><pollryrr:status s="ok"/><pollryrr:reason>Complaint denied.</pollryrr:reason></pollryrr:changeState></pollryrr:pollt></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),7,'message get_info last_id');
is($dri->message_count(),1,'message_count');
is(''.$dri->get_info('qdate','message',7),'2014-09-04T17:18:46','message get_info qdate');
is($dri->get_info('content','message',7),'Complaint denied.','message get_info msg');
is($dri->get_info('lang','message',7),'en','message get_info lang (pure text message)');
# get pollryrr info
$pollryrr = $dri->get_info('pollryrr','message',7);
is($pollryrr->{'roid'},'6-NIC','message get_info roid (pollryrr)');
is($pollryrr->{'name'},'example.cl','message get_info name (pollryrr)');
is($pollryrr->{'stateInscription'},'registered','message get_info stateInscription (pollryrr)');
is($pollryrr->{'stateConflict'},'not applicable','message get_info stateConflict (pollryrr)');
$s=$pollryrr->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','message get_info status (pollryrr)');
is_deeply([$s->list_status()],['ok'],'message get_info status (pollryrr) list');
is($pollryrr->{'reason'},'Complaint denied.','message get_info reason (pollryrr)');

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="9"><qDate>2014-09-04T17:27:53</qDate><msg>deleted by arbitration award.</msg></msgQ><resData><pollryrr:pollt xmlns:pollryrr="urn:ietf:params:xml:ns:pollryrr-1.0"><pollryrr:changeState><pollryrr:roid>7-NIC</pollryrr:roid><pollryrr:name>example.cl</pollryrr:name><pollryrr:stateInscription>deleted</pollryrr:stateInscription><pollryrr:stateConflict>dispute</pollryrr:stateConflict><pollryrr:status s="inactive"/><pollryrr:reason>deleted by arbitration award.</pollryrr:reason></pollryrr:changeState></pollryrr:pollt></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),9,'message get_info last_id');
is($dri->message_count(),1,'message_count');
is(''.$dri->get_info('qdate','message',9),'2014-09-04T17:27:53','message get_info qdate');
is($dri->get_info('content','message',9),'deleted by arbitration award.','message get_info msg');
is($dri->get_info('lang','message',9),'en','message get_info lang (pure text message)');
# get pollryrr info
$pollryrr = $dri->get_info('pollryrr','message',9);
is($pollryrr->{'roid'},'7-NIC','message get_info roid (pollryrr)');
is($pollryrr->{'name'},'example.cl','message get_info name (pollryrr)');
is($pollryrr->{'stateInscription'},'deleted','message get_info stateInscription (pollryrr)');
is($pollryrr->{'stateConflict'},'dispute','message get_info stateConflict (pollryrr)');
$s=$pollryrr->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','message get_info status (pollryrr)');
is_deeply([$s->list_status()],['inactive'],'message get_info status (pollryrr) list');
is($pollryrr->{'reason'},'deleted by arbitration award.','message get_info reason (pollryrr)');

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="27"><qDate>2014-09-09T16:25:10</qDate><msg>deleted domain names</msg></msgQ><resData><pollryrr:pollt xmlns:pollryrr="urn:ietf:params:xml:ns:pollryrr-1.0"><pollryrr:mega><pollryrr:RGPstatus s="pendingDelete"/><pollryrr:reason>deleted</pollryrr:reason><pollryrr:domain><pollryrr:roid>6-NIC</pollryrr:roid><pollryrr:name>example.cl</pollryrr:name></pollryrr:domain><pollryrr:domain><pollryrr:roid>22-NIC</pollryrr:roid><pollryrr:name>example2.cl</pollryrr:name></pollryrr:domain><pollryrr:domain><pollryrr:roid>24-NIC</pollryrr:roid><pollryrr:name>example3.cl</pollryrr:name></pollryrr:domain><pollryrr:domain><pollryrr:roid>1526-NIC</pollryrr:roid><pollryrr:name>example4.cl</pollryrr:name></pollryrr:domain></pollryrr:mega></pollryrr:pollt></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),27,'message get_info last_id');
is($dri->message_count(),1,'message_count');
is(''.$dri->get_info('qdate','message',27),'2014-09-09T16:25:10','message get_info qdate');
is($dri->get_info('content','message',27),'deleted domain names','message get_info msg');
is($dri->get_info('lang','message',27),'en','message get_info lang (pure text message)');
# get pollryrr info
$pollryrr = $dri->get_info('pollryrr','message',27);
$s=$pollryrr->{'RGPstatus'};
isa_ok($s,'Net::DRI::Data::StatusList','message get_info RGPstatus (pollryrr)');
is_deeply([$s->list_status()],['pendingDelete'],'message get_info RGPstatus (pollryrr) list');
is($pollryrr->{'reason'},'deleted','message get_info reason (pollryrr)');
$d = $pollryrr->{'domain'};
is_deeply(@{$d}[0]->{'roid'},'6-NIC','message get_info domain (pollryrr) - first roid');
is_deeply(@{$d}[0]->{'name'},'example.cl','message get_info domain (pollryrr) - first name');
is_deeply(@{$d}[3]->{'roid'},'1526-NIC','message get_info domain (pollryrr) - last roid');
is_deeply(@{$d}[3]->{'name'},'example4.cl','message get_info domain (pollryrr) - last name');

# test standard poll (without pollryrr) - test from Core.t
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="2"><qDate>2006-09-25T09:09:11.0Z</qDate><msg>Come to the registry office for some beer on friday</msg></msgQ>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),2,'message get_info last_id (pure text message)');
is($dri->message_count(),1,'message_count (pure text message)');
is(''.$dri->get_info('qdate','message',2),'2006-09-25T09:09:11','message get_info qdate (pure text message)');
is($dri->get_info('content','message',2),'Come to the registry office for some beer on friday','message get_info msg (pure text message)');
is($dri->get_info('lang','message',2),'en','message get_info lang (pure text message)');


####################################################################################################
########  Registry messages - v1.0.5 ########

# 7.2.1 - Domain transfer request
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="104"><qDate>2017-03-13T20:44:00.0Z</qDate><msg>Transfer Requested.</msg></msgQ><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.cl</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>registrar2</domain:reID><domain:reDate>2017-03-13T20:44:00.967Z</domain:reDate><domain:acID>registrar1</domain:acID><domain:acDate>2017-03-19T02:59:59.000Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),104,'message get_info last_id');
is($dri->message_count(),1,'message_count');
is(''.$dri->get_info('qdate','message',104),'2017-03-13T20:44:00','message get_info qdate');
is($dri->get_info('content','message',104),'Transfer Requested.','message get_info msg');
is($dri->get_info('lang','message',104),'en','message get_info lang (pure text message)');
is($dri->get_info('name','message',104),'domain.cl','message get_info(name)');
is($dri->get_info('trStatus','message',104),'pending','message get_info(trStatus)');
is($dri->get_info('reID','message',104),'registrar2','message get_info(reID)');
$d=$dri->get_info('reDate','message',104);
isa_ok($d,'DateTime','message get_info(reDate)');
is("".$d,'2017-03-13T20:44:00','message get_info(reDate) value');
is($dri->get_info('acID','message',104),'registrar1','message get_info(acID)');
$d=$dri->get_info('acDate','message',104);
isa_ok($d,'DateTime','message get_info(acDate)');
is("".$d,'2017-03-19T02:59:59','message get_info(acDate) value');

# 7.2.2 - Domain transfer reject
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="74"><qDate>2017-03-03T17:47:28.000Z</qDate><msg>Transfer has been rejected.</msg></msgQ><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.cl</domain:name><domain:trStatus>clientRejected</domain:trStatus><domain:reID>registrar2</domain:reID><domain:reDate>2017-03-02T14:07:57.000Z</domain:reDate><domain:acID>registar1</domain:acID><domain:acDate>2017-03-03T17:47:28.478Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),74,'message get_info last_id');
is($dri->message_count(),1,'message_count');
is(''.$dri->get_info('qdate','message',74),'2017-03-03T17:47:28','message get_info qdate');
is($dri->get_info('content','message',74),'Transfer has been rejected.','message get_info msg');
is($dri->get_info('lang','message',74),'en','message get_info lang (pure text message)');
is($dri->get_info('name','message',74),'domain.cl','message get_info(name)');
is($dri->get_info('trStatus','message',74),'clientRejected','message get_info(trStatus)');
is($dri->get_info('reID','message',74),'registrar2','message get_info(reID)');
$d=$dri->get_info('reDate','message',74);
isa_ok($d,'DateTime','message get_info(reDate)');
is("".$d,'2017-03-02T14:07:57','message get_info(reDate) value');
is($dri->get_info('acID','message',74),'registar1','message get_info(acID)');
$d=$dri->get_info('acDate','message',74);
isa_ok($d,'DateTime','message get_info(acDate)');
is("".$d,'2017-03-03T17:47:28','message get_info(acDate) value');

# 7.2.3 - Domain transfer approve
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="119"><qDate>2017-03-27T15:58:14.000Z</qDate><msg>Time period to cancel Transfer has been expired.</msg></msgQ><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.cl</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>registrar2</domain:reID><domain:reDate>2017-03-02T14:07:57.000Z</domain:reDate><domain:acID>registrar1</domain:acID><domain:acDate>2017-03-27T15:58:14.672Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),119,'message get_info last_id');
is($dri->message_count(),10,'message_count');
is(''.$dri->get_info('qdate','message',119),'2017-03-27T15:58:14','message get_info qdate');
is($dri->get_info('content','message',119),'Time period to cancel Transfer has been expired.','message get_info msg');
is($dri->get_info('lang','message',119),'en','message get_info lang (pure text message)');
is($dri->get_info('name','message',119),'domain.cl','message get_info(name)');
is($dri->get_info('trStatus','message',119),'serverApproved','message get_info(trStatus)');
is($dri->get_info('reID','message',119),'registrar2','message get_info(reID)');
$d=$dri->get_info('reDate','message',119);
isa_ok($d,'DateTime','message get_info(reDate)');
is("".$d,'2017-03-02T14:07:57','message get_info(reDate) value');
is($dri->get_info('acID','message',119),'registrar1','message get_info(acID)');
$d=$dri->get_info('acDate','message',119);
isa_ok($d,'DateTime','message get_info(acDate)');
is("".$d,'2017-03-27T15:58:14','message get_info(acDate) value');

# 7.2.4 - Domain awarded
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="9" id="128"><qDate>2017-03-27T15:58:14.000Z</qDate><msg>Transfer Approved.</msg></msgQ><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.cl</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>registrar2</domain:reID><domain:reDate>2017-03-02T19:01:33.000Z</domain:reDate><domain:acID>registrar1</domain:acID><domain:acDate>2017-03-27T15:58:14.937Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),128,'message get_info last_id');
is($dri->message_count(),9,'message_count');
is(''.$dri->get_info('qdate','message',128),'2017-03-27T15:58:14','message get_info qdate');
is($dri->get_info('content','message',128),'Transfer Approved.','message get_info msg');
is($dri->get_info('lang','message',128),'en','message get_info lang (pure text message)');
is($dri->get_info('name','message',128),'domain.cl','message get_info(name)');
is($dri->get_info('trStatus','message',128),'serverApproved','message get_info(trStatus)');
is($dri->get_info('reID','message',128),'registrar2','message get_info(reID)');
$d=$dri->get_info('reDate','message',128);
isa_ok($d,'DateTime','message get_info(reDate)');
is("".$d,'2017-03-02T19:01:33','message get_info(reDate) value');
is($dri->get_info('acID','message',128),'registrar1','message get_info(acID)');
$d=$dri->get_info('acDate','message',128);
isa_ok($d,'DateTime','message get_info(acDate)');
is("".$d,'2017-03-27T15:58:14','message get_info(acDate) value');

# 7.3.1 - Domain expired
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="127"><qDate>2017-04-06T15:00:55.000Z</qDate></msgQ><resData><clpoll:changeState xmlns:clpoll="urn:ietf:params:xml:ns:clpoll-1.0"><clpoll:domain><clpoll:roid>149-NIC</clpoll:roid><clpoll:name>domain.cl</clpoll:name></clpoll:domain><clpoll:status>pendingDelete</clpoll:status><clpoll:rgpStatus>redemptionPeriod</clpoll:rgpStatus><clpoll:reason>Domain deleted.</clpoll:reason></clpoll:changeState></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),127,'message get_info last_id');
is($dri->message_count(),1,'message_count');
is(''.$dri->get_info('qdate','message',127),'2017-04-06T15:00:55','message get_info qdate');
# get clpoll info
is($dri->get_info('roid','message',127),'149-NIC','message get_info(roid) - clpoll');
is($dri->get_info('name','message',127),'domain.cl','message get_info(name) - clpoll');
$s=$dri->get_info('status','message',127);
isa_ok($s,'Net::DRI::Data::StatusList','message get_info(status) - clpoll');
is_deeply([$s->list_status()],['pendingDelete'],'message get_info(status) list - clpoll');
is($dri->get_info('rgpStatus','message',127),'redemptionPeriod','message get_info(rgpStatus) - clpoll');
is($dri->get_info('reason','message',127),'Domain deleted.','message get_info(reason) - clpoll');

# 7.3.2 - Domain Redemption Period Ended
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="127"><qDate>2017-04-06T15:00:55.000Z</qDate></msgQ><resData><clpoll:changeState xmlns:clpoll="urn:ietf:params:xml:ns:clpoll-1.0"><clpoll:domain><clpoll:roid>XXXXXX-NIC</clpoll:roid><clpoll:name>domain.cl</clpoll:name></clpoll:domain><clpoll:status>pendingDelete</clpoll:status><clpoll:rgpStatus>pendingDelete</clpoll:rgpStatus><clpoll:reason>Closed Redemption</clpoll:reason></clpoll:changeState></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),127,'message get_info last_id');
is($dri->message_count(),1,'message_count');
is(''.$dri->get_info('qdate','message',127),'2017-04-06T15:00:55','message get_info qdate');
# get clpoll info
is($dri->get_info('roid','message',127),'XXXXXX-NIC','message get_info(roid) - clpoll');
is($dri->get_info('name','message',127),'domain.cl','message get_info(name) - clpoll');
$s=$dri->get_info('status','message',127);
isa_ok($s,'Net::DRI::Data::StatusList','message get_info(status) - clpoll');
is_deeply([$s->list_status()],['pendingDelete'],'message get_info(status) list - clpoll');
is($dri->get_info('rgpStatus','message',127),'pendingDelete','message get_info(rgpStatus) - clpoll');
is($dri->get_info('reason','message',127),'Closed Redemption','message get_info(reason) - clpoll');

# 7.4.1 - Domain in Dispute
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="2" id="125"><qDate>2017-04-06T14:32:25.000Z</qDate></msgQ><resData><clpoll:changeState xmlns:clpoll="urn:ietf:params:xml:ns:clpoll-1.0"><clpoll:domain><clpoll:roid>YYY-NIC</clpoll:roid><clpoll:name>domain.cl</clpoll:name></clpoll:domain><clpoll:status>serverDeleteProhibited</clpoll:status><clpoll:status>serverTransferProhibited</clpoll:status><clpoll:disputeStatus>inDispute</clpoll:disputeStatus><clpoll:reason>Domain in dispute. Registrant cloned. New handle: ZZZ-RCAL</clpoll:reason></clpoll:changeState></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),125,'message get_info last_id');
is($dri->message_count(),2,'message_count');
is(''.$dri->get_info('qdate','message',125),'2017-04-06T14:32:25','message get_info qdate');
# get clpoll info
is($dri->get_info('roid','message',125),'YYY-NIC','message get_info(roid) - clpoll');
is($dri->get_info('name','message',125),'domain.cl','message get_info(name) - clpoll');
$s=$dri->get_info('status','message',125);
isa_ok($s,'Net::DRI::Data::StatusList','message get_info(status) - clpoll');
is_deeply([$s->list_status()],['serverDeleteProhibited','serverTransferProhibited'],'message get_info(status) list - clpoll');
is($dri->get_info('disputeStatus','message',125),'inDispute','message get_info(disputeStatus) - clpoll');
is($dri->get_info('reason','message',125),'Domain in dispute. Registrant cloned. New handle: ZZZ-RCAL','message get_info(reason) - clpoll');

# 7.4.2 - Domain Dispute Withdrawed
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="2" id="125"><qDate>2017-04-06T14:32:25.000Z</qDate></msgQ><resData><clpoll:changeState xmlns:clpoll="urn:ietf:params:xml:ns:clpoll-1.0"><clpoll:domain><clpoll:roid>XXXXXXX-NIC</clpoll:roid><clpoll:name>domain.cl</clpoll:name></clpoll:domain><clpoll:status>ok</clpoll:status><clpoll:disputeStatus causeDisputeTermination="disputeDismissed">disputeClosed</clpoll:disputeStatus><clpoll:reason>Dispute Closed</clpoll:reason></clpoll:changeState></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),125,'message get_info last_id');
is($dri->message_count(),2,'message_count');
is(''.$dri->get_info('qdate','message',125),'2017-04-06T14:32:25','message get_info qdate');
# get clpoll info
is($dri->get_info('roid','message',125),'XXXXXXX-NIC','message get_info(roid) - clpoll');
is($dri->get_info('name','message',125),'domain.cl','message get_info(name) - clpoll');
$s=$dri->get_info('status','message',125);
isa_ok($s,'Net::DRI::Data::StatusList','message get_info(status) - clpoll');
is_deeply([$s->list_status()],['ok'],'message get_info(status) list - clpoll');
is($dri->get_info('disputeStatus','message',125),'disputeClosed','message get_info(disputeStatus) - clpoll');
is($dri->get_info('causeDisputeTermination','message',125),'disputeDismissed','message get_info(causeDisputeTermination) - clpoll');
is($dri->get_info('reason','message',125),'Dispute Closed','message get_info(reason) - clpoll');

# 7.4.3 - Domain Dispute Ended, holder keeps the domain
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="2" id="125"><qDate>2017-04-06T14:32:25.000Z</qDate></msgQ><resData><clpoll:changeState xmlns:clpoll="urn:ietf:params:xml:ns:clpoll-1.0"><clpoll:domain><clpoll:roid>foobar-NIC</clpoll:roid><clpoll:name>foobar.cl</clpoll:name></clpoll:domain><clpoll:status>ok</clpoll:status><clpoll:disputeStatus causeDisputeTermination="keepsDomainName">disputeClosed</clpoll:disputeStatus><clpoll:reason>Dispute Closed</clpoll:reason></clpoll:changeState></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),125,'message get_info last_id');
is($dri->message_count(),2,'message_count');
is(''.$dri->get_info('qdate','message',125),'2017-04-06T14:32:25','message get_info qdate');
# get clpoll info
is($dri->get_info('roid','message',125),'foobar-NIC','message get_info(roid) - clpoll');
is($dri->get_info('name','message',125),'foobar.cl','message get_info(name) - clpoll');
$s=$dri->get_info('status','message',125);
isa_ok($s,'Net::DRI::Data::StatusList','message get_info(status) - clpoll');
is_deeply([$s->list_status()],['ok'],'message get_info(status) list - clpoll');
is($dri->get_info('disputeStatus','message',125),'disputeClosed','message get_info(disputeStatus) - clpoll');
is($dri->get_info('causeDisputeTermination','message',125),'keepsDomainName','message get_info(causeDisputeTermination) - clpoll');
is($dri->get_info('reason','message',125),'Dispute Closed','message get_info(reason) - clpoll');

# 7.4.4 - Domain Dispute Ended, domain awarded to complainant
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="2" id="125"><qDate>2017-04-06T14:32:25.000Z</qDate></msgQ><resData><clpoll:changeState xmlns:clpoll="urn:ietf:params:xml:ns:clpoll-1.0"><clpoll:domain><clpoll:roid>XXXXXXX-NIC</clpoll:roid><clpoll:name>domain.cl</clpoll:name></clpoll:domain><clpoll:status>inactive</clpoll:status><clpoll:disputeStatus causeDisputeTermination ="transferredToComplainant">disputeClosed</clpoll:disputeStatus><clpoll:reason>Domain name transferred to the complainant</clpoll:reason></clpoll:changeState></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),125,'message get_info last_id');
is($dri->message_count(),2,'message_count');
is(''.$dri->get_info('qdate','message',125),'2017-04-06T14:32:25','message get_info qdate');
# get clpoll info
is($dri->get_info('roid','message',125),'XXXXXXX-NIC','message get_info(roid) - clpoll');
is($dri->get_info('name','message',125),'domain.cl','message get_info(name) - clpoll');
$s=$dri->get_info('status','message',125);
isa_ok($s,'Net::DRI::Data::StatusList','message get_info(status) - clpoll');
is_deeply([$s->list_status()],['inactive'],'message get_info(status) list - clpoll');
is($dri->get_info('disputeStatus','message',125),'disputeClosed','message get_info(disputeStatus) - clpoll');
is($dri->get_info('causeDisputeTermination','message',125),'transferredToComplainant','message get_info(causeDisputeTermination) - clpoll');
is($dri->get_info('reason','message',125),'Domain name transferred to the complainant','message get_info(reason) - clpoll');


####################################################################################################
########  Unavailable operations ########
dies_ok { $dri->domain_transfer_accept('foobar-accept.cl',{auth => {pw => '2fooBAR'}}); } 'Net-DRI die due unavailable operation: domain transfer op="accept"';
dies_ok { $dri->domain_transfer_stop('foobar-cancel.cl',{auth => {pw => '2fooBAR'}}); } 'Net-DRI die due unavailable operation: domain transfer op="cancel"';
# lets test just 1 avail operation
lives_ok { $dri->domain_transfer_query('foobar-cancel.cl',{auth=>{pw=>'2fooBAR',roid=>'JD1234-REP'}}); } 'Net-DRI didnt die due available operation: domain transfer op="query"' ;


#####################################################################################################
######### Session Commands - close ########

$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

exit 0;
