#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 468;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('PL');
eval {
  $dri->target('PL')->add_current_profile('p1',
    'epp',
    {
      f_send=> \&mysend,
      f_recv=> \&myrecv
    });
};

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
## Examples taken from draft-zygmuntowicz-epp-pltld-02.txt §4

## Example 1, CORRECTED (domain:hostObj)
## + Example 2 CORRECTED (invalid date in exDate)

$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd">
  <domain:name>przyklad44.pl</domain:name>
  <domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate>
  <domain:exDate>2000-04-03T22:00:00.0Z</domain:exDate>
  </domain:creData>
  </resData>'.$TRID.'</response>'.$E2;
$dh=$dri->local_object('hosts');
$dh->add('ns.przyklad2.pl');
$dh->add('ns5.przyklad.pl');
$rc=$dri->domain_create('przyklad44.pl',{pure_create=>1,ns=>$dh,auth=>{pw=>'authinfo_of_d97'},book=>1,reason=>'nice name'});
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><command><create><domain:create xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>przyklad44.pl</domain:name><domain:ns>ns.przyklad2.pl</domain:ns><domain:ns>ns5.przyklad.pl</domain:ns><domain:authInfo><domain:pw>authinfo_of_d97</domain:pw></domain:authInfo></domain:create></create><extension><extdom:create xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:reason>nice name</extdom:reason><extdom:book/></extdom:create></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_create build with book');
is($rc->is_success(),1,'domain_create is_success');
$d=$dri->get_info('crDate');
is(''.$d,'1999-04-03T22:00:00','domain_create get_info(crDate)');
$d=$dri->get_info('exDate');
is(''.$d,'2000-04-03T22:00:00','domain_create get_info(exDate)');

# domain_update test added by MH while cleaning up PL Domain Extension
my $changes = $dri->local_object('changes');
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('98765'), 'tech');
$changes->add('contact', $cs);
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('12347'), 'tech');
$changes->del('contact', $cs);
$changes->add('ns',$dri->local_object('hosts')->set(['ns3.example.info']));
$rc = $dri->domain_update('uptest.pl', $changes);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>uptest.pl</domain:name><domain:add><domain:ns>ns3.example.info</domain:ns><domain:contact type="tech">98765</domain:contact></domain:add><domain:rem><domain:contact type="tech">12347</domain:contact></domain:rem></domain:update></update><clTRID>ABC-12345</clTRID></command></epp>', 'domain_update build');
is($rc->is_success(), 1, 'domain_update is success');

# domain_info test added by MH while cleaning up PL Domain Extension
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>inftest.pl</domain:name><domain:roid>1234565-NASK</domain:roid><domain:status s="clientDeleteProhibited" lang="en" /><domain:status s="clientUpdateProhibited" lang="en" /><domain:registrant>abc123</domain:registrant><domain:contact type="tech">abc124</domain:contact><domain:ns>ns1.test.net</domain:ns><domain:ns>ns2.test.net</domain:ns><domain:clID>test_rar</domain:clID><domain:crID>prevtest_rar</domain:crID><domain:crDate>2009-09-09T09:09:09.0Z</domain:crDate><domain:upID>test_rar</domain:upID><domain:upDate>2014-09-09T09:09:09.0Z</domain:upDate><domain:exDate>2015-09-09T09:09:09.0Z</domain:exDate><domain:trDate>2013-09-09T09:09:09.0Z</domain:trDate><domain:authInfo><domain:pw>auth*I123</domain:pw></domain:authInfo></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('inftest.pl');
is($R1,$E1.'<command><info><domain:info xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name hosts="all">inftest.pl</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>', 'domain_info build');
is($rc->is_success(), 1, 'domain_info is success');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'1234565-NASK','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['clientDeleteProhibited','clientUpdateProhibited'],'domain_info get_info(status) list');
$ns = $dri->get_info('ns');
is(join(',', $ns->get_names()), 'ns1.test.net,ns2.test.net', 'domain_info get_info(ns)');
$cs=$dri->get_info('contact');
isa_ok($cs,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$cs->types()],['registrant','tech'],'domain_info get_info(contact) types');
is($cs->get('registrant')->srid(),'abc123','domain_info get_info(contact) registrant srid');
is($cs->get('tech')->srid(),'abc124','domain_info get_info(contact) tech srid');
is($dri->get_info('crDate'),'2009-09-09T09:09:09','domain_info get_info(crDate)');
is($dri->get_info('exDate'),'2015-09-09T09:09:09','domain_info get_info(exDate)');
is($dri->get_info('upDate'),'2014-09-09T09:09:09','domain_info get_info(upDate)');
is($dri->get_info('trDate'),'2013-09-09T09:09:09','domain_info get_info(trDate)');

## Examples 3,4,5,6,7,8 are standard EPP, thus not tested here

## Example 9 + Example 10, CORRECTED (type=loc instead of type=int)

$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="http://www.dns.pl/nask-epp-schema/contact-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/contact-2.0 contact-2.0.xsd"><contact:id>sh8013</contact:id><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013');
$co->name('11John Doe');
$co->org('Example Inc.');
$co->street(['123 Example Dr.','Suite 100']);
$co->city('Dulles');
$co->sp('VA');
$co->pc('20166-6503');
$co->cc('US');
$co->voice('+1.7035555555x1234');
$co->fax('+1.7035555556');
$co->email('jdoe@example.tld');
$co->auth({pw=>'2fooBAR'});
$co->individual(1);
$co->consent_for_publishing(1);
$rc=$dri->contact_create($co);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><command><create><contact:create xmlns:contact="http://www.dns.pl/nask-epp-schema/contact-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/contact-2.0 contact-2.0.xsd"><contact:id>sh8013</contact:id><contact:postalInfo type="loc"><contact:name>11John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.tld</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:create></create><extension><extcon:create xmlns:extcon="http://www.dns.pl/nask-epp-schema/extcon-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extcon-2.0 extcon-2.0.xsd"><extcon:individual>1</extcon:individual><extcon:consentForPublishing>1</extcon:consentForPublishing></extcon:create></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_create build');
is($rc->is_success(),1,'contact_create is_success');
$d=$dri->get_info('id');
is($d,'sh8013','contact_create get_info(id)');
$d=$dri->get_info('crDate');
is(''.$d,'1999-04-03T22:00:00','contact_create get_info(crDate)');

## Example 11

$rc=$dri->contact_info($dri->local_object('contact')->srid('666666'),{auth=>{pw=>'2fooBAR'}});
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><command><info><contact:info xmlns:contact="http://www.dns.pl/nask-epp-schema/contact-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/contact-2.0 contact-2.0.xsd"><contact:id>666666</contact:id></contact:info></info><extension><extcon:info xmlns:extcon="http://www.dns.pl/nask-epp-schema/extcon-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extcon-2.0 extcon-2.0.xsd"><extcon:authInfo><extcon:pw>2fooBAR</extcon:pw></extcon:authInfo></extcon:info></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_info build');
is($rc->is_success(),1,'contact_info is_success');

## Example 12 is standard EPP, thus not tested here

## Example 13, CORRECTED (type=loc instead of type=int)
$co=$dri->local_object('contact')->srid('sh8013');
my $toc=$dri->local_object('changes');
my $co2=$dri->local_object('contact');
$co2->org('');
$co2->street(['124 Example Dr.','Suite 200']);
$co2->city('Dulles');
$co2->sp('VA');
$co2->pc('20166-6503');
$co2->cc('US');
$co2->voice('+1.7034444444');
$co2->fax('');
$co2->consent_for_publishing(1);
$toc->set('info',$co2);
$toc->add('status',$dri->local_object('status')->no('delete'));
$rc=$dri->contact_update($co,$toc);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><command><update><contact:update xmlns:contact="http://www.dns.pl/nask-epp-schema/contact-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/contact-2.0 contact-2.0.xsd"><contact:id>sh8013</contact:id><contact:add><contact:status s="clientDeleteProhibited"/></contact:add><contact:chg><contact:postalInfo type="loc"><contact:org/><contact:addr><contact:street>124 Example Dr.</contact:street><contact:street>Suite 200</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.7034444444</contact:voice><contact:fax/></contact:chg></contact:update></update><extension><extcon:update xmlns:extcon="http://www.dns.pl/nask-epp-schema/extcon-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extcon-2.0 extcon-2.0.xsd"><extcon:consentForPublishing>1</extcon:consentForPublishing></extcon:update></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_update build');
is($rc->is_success(),1,'contact_update is_success');

## Example 14 is standard EPP, thus not tested here

####################################################################################################
## Bugs which turned up during production

$R2=$E1.'<response><result code="1000"><msg lang="en-US">Command completed successfully</msg></result><resData><host:chkData xmlns:host="http://www.dns.pl/nask-epp-schema/host-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/host-2.0 host-2.0.xsd"><host:cd><host:name avail="1">ns1.rawr.com</host:name></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;

my $host = $dri->local_object('hosts')->add('ns1.rawr.com');
$rc = $dri->host_check($host);
is($rc->is_success(), 1, 'host_check is_success');
is($dri->get_info('exist', 'host', 'ns1.rawr.com'), 0, 'host does not exist');

## .PL message polling

$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="43" id="27389"><qDate>2008-04-07T09:28:40.163Z</qDate><msg lang="en">domain authInfo</msg></msgQ><resData><extdom:pollAuthInfo xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:domain><extdom:name>test.com.pl</extdom:name><extdom:authInfo><extdom:pw>JuhIFbrKfX4xReybrUe1pZs</extdom:pw></extdom:authInfo></extdom:domain></extdom:pollAuthInfo></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message_retrieve');
is($dri->get_info('last_id'), 27389, 'message get_info last_id 1');
#is_deeply([$dri->get_info('auth_domain', 'domain', 'test.com.pl')], [{ pw => 'JuhIFbrKfX4xReybrUe1pZs' }], 'message get_info auth pw');
is_deeply([$dri->get_info('auth', 'domain', 'test.com.pl')], [{ pw => 'JuhIFbrKfX4xReybrUe1pZs' }], 'message get_info auth pw');
is($dri->get_info('exist', 'domain', 'test.com.pl'), 1, 'Domain exists');
is($dri->get_info('name', 'domain', 'test.com.pl'), 'test.com.pl', 'Domain name is correct');
is($dri->get_info('action', 'message', 27389), 'auth_info', 'Action is poll_auth_info');

$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="8308"><qDate>2008-04-18T07:03:35.880Z</qDate><msg lang="en">domain transfer requested</msg></msgQ><resData><domain:trnData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>syhosting.pl</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>theuser</domain:reID><domain:reDate>2008-04-18T07:03:35.487Z</domain:reDate><domain:acID>irgendwas</domain:acID><domain:acDate>2008-05-18T07:03:35.487Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message_retrieve');
is($dri->get_info('last_id'), 8308, 'message get_info last_id 1');
is($dri->get_info('action', 'message', 8308), 'transfer', 'Action is correct');
is($dri->get_info('content','message', 8308), 'domain transfer requested', 'Content is correct');
is($dri->get_info('object_id', 'message', 8308), 'syhosting.pl', 'Object ID is correct');
is($dri->get_info('object_type', 'message', 8308), 'domain', 'Object type is correct');

## .PL message polling: 5.5.5.1 - NASK_EPP_en_draft.pdf
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="70"><qDate>2003-02-07T11:23:08.0Z</qDate><msg lang="en">Domain transferred.</msg></msgQ><resData><domain:trnData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>example.tld</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2003-02-07T11:23:08.830Z</domain:reDate><domain:acID>NASK EPP Registry</domain:acID><domain:acDate>2003-02-07T11:23:08.830Z</domain:acDate><domain:exDate>2003-05-07T11:23:08.830Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),70,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),70,'message get_info last_id 2');
is($dri->get_info('id','message',70),70,'message get_info id');
is(''.$dri->get_info('qdate','message',70),'2003-02-07T11:23:08','message get info qdate');
is($dri->get_info('content','message',70),'Domain transferred.','message get_info content');
is($dri->get_info('lang','message',70),'en','message get_info lang');
is($dri->get_info('object_type','message',70),'domain','message get_info object type');
is($dri->get_info('object_id','message',70),'example.tld','message get_info id');
is($dri->get_info('action','message',70),'transfer','message get_info action');
is($dri->get_info('name','message',70),'example.tld','message get_info name');
is($dri->get_info('trStatus','message',70),'serverApproved','message get_info trStatus');
is($dri->get_info('reID','message',70),'ClientX','message get_info reID');
is(''.$dri->get_info('reDate','message',70),'2003-02-07T11:23:08','message get_info reDate');
is($dri->get_info('acID','message',70),'NASK EPP Registry','message get_info acID');
is(''.$dri->get_info('acDate','message',70),'2003-02-07T11:23:08','message get_info acDate');
is(''.$dri->get_info('exDate','message',70),'2003-05-07T11:23:08','message get_info exDate');

## 9.1 - NASK_EPP_en_draft.pdf - Domain transfer requested
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="6" id="1651"><qDate>2005-06-03T06:41:41.927Z</qDate><msg lang="en">domain transfer requested</msg></msgQ><resData><domain:trnData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>bryzal.pl</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>wgtat</domain:reID><domain:reDate>2005-03-03T11:41:41.893Z</domain:reDate><domain:acID>dmrt0029000018</domain:acID><domain:acDate>2005-07-03T06:41:41.893Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),1651,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),1651,'message get_info last_id 2');
is($dri->get_info('id','message',1651),1651,'message get_info id');
is($dri->get_info('qdate','message',1651),'2005-06-03T06:41:41','message get_info qdate');
is($dri->get_info('content','message',1651),'domain transfer requested','message get_info content');
is($dri->get_info('lang','message',1651),'en','message get_info lang');
is($dri->get_info('object_type','message',1651),'domain','message get_info object type');
is($dri->get_info('name','message',1651),'bryzal.pl','message get_info name');
is($dri->get_info('trStatus','message',1651),'pending','message get_info status');
is($dri->get_info('reID','message',1651),'wgtat','message get_info reID');
is($dri->get_info('reDate','message',1651),'2005-03-03T11:41:41','message get_info reDate');
is($dri->get_info('acID','message',1651),'dmrt0029000018','message get_info acID');
is($dri->get_info('acDate','message',1651),'2005-07-03T06:41:41','message get_info acDate');

## 9.2 - NASK_EPP_en_draft.pdf - Domain transfer cancelled
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="1849"><qDate>2005-06-22T07:36:52.223Z</qDate><msg lang="en">domain transfer cancelled</msg></msgQ><resData><domain:trnData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>weaktest.pl</domain:name><domain:trStatus>clientCancelled</domain:trStatus><domain:reID>bart</domain:reID><domain:reDate>2005-06-22T07:33:30.0Z</domain:reDate><domain:acID>neta29805</domain:acID><domain:acDate>2005-06-22T07:36:52.202Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),1849,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),1849,'message get_info last_id 2');
is($dri->get_info('id','message',1849),1849,'message get_info id');
is($dri->get_info('qdate','message',1849),'2005-06-22T07:36:52','message get_info qdate');
is($dri->get_info('content','message',1849),'domain transfer cancelled','message get_info content');
is($dri->get_info('lang','message',1849),'en','message get_info lang');
is($dri->get_info('object_type','message',1849),'domain','message get_info object type');
is($dri->get_info('name','message',1849),'weaktest.pl','message get_info name');
is($dri->get_info('trStatus','message',1849),'clientCancelled','message get_info status');
is($dri->get_info('reID','message',1849),'bart','message get_info reID');
is($dri->get_info('reDate','message',1849),'2005-06-22T07:33:30','message get_info reDate');
is($dri->get_info('acID','message',1849),'neta29805','message get_info acID');
is($dri->get_info('acDate','message',1849),'2005-06-22T07:36:52','message get_info acDate');

## 9.3 - NASK_EPP_en_draft.pdf - Domain transfer expired
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="3" id="1900"><qDate>2005-06-22T12:04:18.323Z</qDate><msg lang="en">domain transfer expired</msg></msgQ><resData><domain:trnData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>pajac.pl</domain:name><domain:trStatus>serverCancelled</domain:trStatus><domain:reID>beep</domain:reID><domain:reDate>2005-05-12T12:38:49.0Z</domain:reDate><domain:acID>iap07</domain:acID><domain:acDate>2005-06-22T12:04:18.304Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),1900,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),1900,'message get_info last_id 2');
is($dri->get_info('id','message',1900),1900,'message get_info id');
is($dri->get_info('qdate','message',1900),'2005-06-22T12:04:18','message get_info qdate');
is($dri->get_info('content','message',1900),'domain transfer expired','message get_info content');
is($dri->get_info('lang','message',1900),'en','message get_info lang');
is($dri->get_info('object_type','message',1900),'domain','message get_info object type');
is($dri->get_info('name','message',1900),'pajac.pl','message get_info name');
is($dri->get_info('trStatus','message',1900),'serverCancelled','message get_info status');
is($dri->get_info('reID','message',1900),'beep','message get_info reID');
is($dri->get_info('reDate','message',1900),'2005-05-12T12:38:49','message get_info reDate');
is($dri->get_info('acID','message',1900),'iap07','message get_info acID');
is($dri->get_info('acDate','message',1900),'2005-06-22T12:04:18','message get_info acDate');

## 9.4 - NASK_EPP_en_draft.pdf - Domain transferred
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="5" id="1652"><qDate>2005-06-03T06:55:40.253Z</qDate><msg lang="en">domain transferred</msg></msgQ><resData><domain:trnData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>brzydal6.pl</domain:name><domain:trStatus>clientApproved</domain:trStatus><domain:reID>agnat1</domain:reID><domain:reDate>2005-06-03T06:41:41.0Z</domain:reDate><domain:acID>dmrt0029000018</domain:acID><domain:acDate>2005-06-03T06:55:40.186Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),1652,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),1652,'message get_info last_id 2');
is($dri->get_info('id','message',1652),1652,'message get_info id');
is($dri->get_info('qdate','message',1652),'2005-06-03T06:55:40','message get_info qdate');
is($dri->get_info('content','message',1652),'domain transferred','message get_info content');
is($dri->get_info('lang','message',1652),'en','message get_info lang');
is($dri->get_info('object_type','message',1652),'domain','message get_info object type');
is($dri->get_info('name','message',1652),'brzydal6.pl','message get_info name');
is($dri->get_info('trStatus','message',1652),'clientApproved','message get_info status');
is($dri->get_info('reID','message',1652),'agnat1','message get_info reID');
is($dri->get_info('reDate','message',1652),'2005-06-03T06:41:41','message get_info reDate');
is($dri->get_info('acID','message',1652),'dmrt0029000018','message get_info acID');
is($dri->get_info('acDate','message',1652),'2005-06-03T06:55:40','message get_info acDate');

## 9.5 - NASK_EPP_en_draft.pdf - Broken delegation
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="15" id="2013"><qDate>2005-06-30T14:58:29.579Z</qDate><msg lang="en">broken delegation</msg></msgQ><resData><extdom:dlgData xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:name>makota.com.pl</extdom:name><extdom:name>pikawa.net.pl</extdom:name><extdom:name>bzdziagwa.pl</extdom:name><extdom:ns>ns1.wisla.pl</extdom:ns></extdom:dlgData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),2013,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),2013,'message get_info last_id 2');
is($dri->get_info('id','message',2013),2013,'message get_info id');
is($dri->get_info('qdate','message',2013),'2005-06-30T14:58:29','message get_info qdate');
is($dri->get_info('content','message',2013),'broken delegation','message get_info content');
is($dri->get_info('lang','message',2013),'en','message get_info lang');
is($dri->get_info('object_type','message',2013),'domain','message get_info object type');
is($dri->get_info('action','message',2013),'dlgData','message get_info action');
is_deeply($dri->get_info('extdom_names','message',2013),['makota.com.pl','pikawa.net.pl','bzdziagwa.pl'],'message get_info extdom_names');
is($dri->get_info('ns','message',2013),'ns1.wisla.pl','message get_info ns');

## 9.6 - NASK_EPP_en_draft.pdf - Future transfer requested
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="1536"><qDate>2005-05-25T09:37:46.581Z</qDate><msg lang="en">future transfer requested</msg></msgQ><resData><future:trnData xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>zombi.pl</future:name><future:trStatus>pending</future:trStatus><future:reID>ceti1</future:reID><future:reDate>2005-05-25T09:37:46.549Z</future:reDate><future:acID>cet352</future:acID><future:acDate>2005-06-24T09:37:46.549Z</future:acDate></future:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),1536,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),1536,'message get_info last_id 2');
is($dri->get_info('id','message',1536),1536,'message get_info id');
is($dri->get_info('qdate','message',1536),'2005-05-25T09:37:46','message get_info qdate');
is($dri->get_info('content','message',1536),'future transfer requested','message get_info content');
is($dri->get_info('lang','message',1536),'en','message get_info lang');
is($dri->get_info('object_type','message',1536),'future','message get_info object type');
is($dri->get_info('name','message',1536),'zombi.pl','message get_info name');
is($dri->get_info('trStatus','message',1536),'pending','message get_info status');
is($dri->get_info('reID','message',1536),'ceti1','message get_info reID');
is($dri->get_info('reDate','message',1536),'2005-05-25T09:37:46','message get_info reDate');
is($dri->get_info('acID','message',1536),'cet352','message get_info acID');
is($dri->get_info('acDate','message',1536),'2005-06-24T09:37:46','message get_info acDate');

## 9.7 - NASK_EPP_en_draft.pdf - Future transfer cancelled
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="6" id="1334"><qDate>2005-05-16T22:05:39.228Z</qDate><msg lang="en">future transfer cancelled</msg></msgQ><resData><future:trnData xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>futureexample.pl</future:name><future:trStatus>clientCancelled</future:trStatus><future:reID>infomix</future:reID><future:reDate>2005-05-16T22:03:44.0Z</future:reDate><future:acID>inm023</future:acID><future:acDate>2005-05-16T22:05:39.212Z</future:acDate></future:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),1334,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),1334,'message get_info last_id 2');
is($dri->get_info('id','message',1334),1334,'message get_info id');
is(''.$dri->get_info('qdate','message',1334),'2005-05-16T22:05:39','message get_info qdate');
is($dri->get_info('content','message',1334),'future transfer cancelled','message get_info content');
is($dri->get_info('lang','message',1334),'en','message get_info lang');
is($dri->get_info('object_type','message',1334),'future','message get_info object type');
is($dri->get_info('name','message',1334),'futureexample.pl','message get_info name');
is($dri->get_info('trStatus','message',1334),'clientCancelled','message get_info status');
is($dri->get_info('reID','message',1334),'infomix','message get_info reID');
is($dri->get_info('reDate','message',1334),'2005-05-16T22:03:44','message get_info reDate');
is($dri->get_info('acID','message',1334),'inm023','message get_info acID');
is($dri->get_info('acDate','message',1334),'2005-05-16T22:05:39','message get_info acDate');

## 9.8 - NASK_EPP_en_draft.pdf - Future transfer request expired
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="6" id="1334"><qDate>2005-05-16T22:05:39.228Z</qDate><msg lang="en">future transfer request expired</msg></msgQ><resData><future:trnData xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>futureexample.pl</future:name><future:trStatus>serverCancelled</future:trStatus><future:reID>infomax</future:reID><future:reDate>2005-05-16T22:02:52.0Z</future:reDate><future:acID>inm_test02</future:acID><future:acDate>2005-06-24T09:52:27.727Z</future:acDate></future:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),1334,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),1334,'message get_info last_id 2');
is($dri->get_info('id','message',1334),1334,'message get_info id');
is(''.$dri->get_info('qdate','message',1334),'2005-05-16T22:05:39','message get_info qdate');
is($dri->get_info('content','message',1334),'future transfer request expired','message get_info content');
is($dri->get_info('lang','message',1334),'en','message get_info lang');
is($dri->get_info('object_type','message',1334),'future','message get_info object type');
is($dri->get_info('name','message',1334),'futureexample.pl','message get_info name');
is($dri->get_info('trStatus','message',1334),'serverCancelled','message get_info status');
is($dri->get_info('reID','message',1334),'infomax','message get_info reID');
is($dri->get_info('reDate','message',1334),'2005-05-16T22:02:52','message get_info reDate');
is($dri->get_info('acID','message',1334),'inm_test02','message get_info acID');
is($dri->get_info('acDate','message',1334),'2005-06-24T09:52:27','message get_info acDate');

## 9.9 - NASK_EPP_en_draft.pdf - Future transferred
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="9" id="1538"><qDate>2005-05-25T09:51:20.909Z</qDate><msg lang="en">future transferred</msg></msgQ><resData><future:trnData xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>example.pl</future:name><future:trStatus>clientApproved</future:trStatus><future:reID>ceti1</future:reID><future:reDate>2005-05-25T09:37:46.0Z</future:reDate><future:acID>zet352</future:acID><future:acDate>2005-05-25T09:51:20.836Z</future:acDate></future:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),1538,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),1538,'message get_info last_id 2');
is($dri->get_info('id','message',1538),1538,'message get_info id');
is(''.$dri->get_info('qdate','message',1538),'2005-05-25T09:51:20','message get_info qdate');
is($dri->get_info('content','message',1538),'future transferred','message get_info content');
is($dri->get_info('lang','message',1538),'en','message get_info lang');
is($dri->get_info('object_type','message',1538),'future','message get_info object type');
is($dri->get_info('name','message',1538),'example.pl','message get_info name');
is($dri->get_info('trStatus','message',1538),'clientApproved','message get_info status');
is($dri->get_info('reID','message',1538),'ceti1','message get_info reID');
is($dri->get_info('reDate','message',1538),'2005-05-25T09:37:46','message get_info reDate');
is($dri->get_info('acID','message',1538),'zet352','message get_info acID');
is($dri->get_info('acDate','message',1538),'2005-05-25T09:51:20','message get_info acDate');

## 9.10 - NASK_EPP_en_draft.pdf - Soon domain expiration
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="2001"><qDate>2005-06-27T21:00:19.538Z</qDate><msg lang="en">soon domain expiration</msg></msgQ><resData><extdom:expData xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:name>ala.pl</extdom:name><extdom:name>ma.pl</extdom:name><extdom:name>kota.pl</extdom:name><extdom:exDate>2005-06-29T21:00:19.512Z</extdom:exDate></extdom:expData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),2001,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),2001,'message get_info last_id 2');
is($dri->get_info('id','message',2001),2001,'message get_info id');
is(''.$dri->get_info('qdate','message',2001),'2005-06-27T21:00:19','message get_info qdate');
is($dri->get_info('content','message',2001),'soon domain expiration','message get_info content');
is($dri->get_info('lang','message',2001),'en','message get_info lang');
is($dri->get_info('object_type','message',2001),'domain','message get_info object type');
is($dri->get_info('action','message',2001),'expData','message get_info action');
is_deeply($dri->get_info('extdom_names','message',2001),['ala.pl','ma.pl','kota.pl'],'message get_info extdom_names');
is($dri->get_info('exDate','message',2001),'2005-06-29T21:00:19','message get_info exDate');

## 9.11 - NASK_EPP_en_draft.pdf - Domain authorization information
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="2000"><qDate>2005-06-29T20:37:57.133Z</qDate><msg lang="en">domain authInfo</msg></msgQ><resData><extdom:pollAuthInfo xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:domain><extdom:name>nask.pl</extdom:name><extdom:authInfo><extdom:pw>cPxWt418</extdom:pw></extdom:authInfo></extdom:domain><extdom:registrant><extdom:id>tst12</extdom:id><extdom:authInfo><extdom:pw>Wct59Nka5</extdom:pw></extdom:authInfo></extdom:registrant></extdom:pollAuthInfo></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),2000,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),2000,'message get_info last_id 2');
is($dri->get_info('id','message',2000),2000,'message get_info id');
is(''.$dri->get_info('qdate','message',2000),'2005-06-29T20:37:57','message get_info qdate');
is($dri->get_info('content','message',2000),'domain authInfo','message get_info content');
is($dri->get_info('lang','message',2000),'en','message get_info lang');
is($dri->get_info('object_type','message',2000),'domain','message get_info object type');
is($dri->get_info('object_id','message',2000),'nask.pl','message get_info id');
is($dri->get_info('action','message',2000),'auth_info','message get_info action');
is($dri->get_info('name','message',2000),'nask.pl','message get_info name');
is($dri->get_info('auth','message',2000)->{pw},'cPxWt418','message get_info authInfo (domain)');
is($dri->get_info('id_registrant','message',2000),'tst12','message get_info id_registrant');
is($dri->get_info('auth_registrant','message',2000)->{pw},'Wct59Nka5','message get_info authInfo (registrant)');

## 9.12 - NASK_EPP_en_draft.pdf - Future finalized
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="2002"><qDate>2005-06-29T21:13:57.335Z</qDate><msg lang="en">future finalized</msg></msgQ><resData><domain:creData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>example.pl</domain:name><domain:crDate>2005-06-29T21:13:57.327Z</domain:crDate><domain:exDate>2005-07-06T21:13:57.327Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),2002,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),2002,'message get_info last_id 2');
is($dri->get_info('id','message',2002),2002,'message get_info id');
is(''.$dri->get_info('qdate','message',2002),'2005-06-29T21:13:57','message get_info qdate');
is($dri->get_info('content','message',2002),'future finalized','message get_info content');
is($dri->get_info('lang','message',2002),'en','message get_info lang');
is($dri->get_info('object_type','message',2002),'domain','message get_info object type');
is($dri->get_info('object_id','message',2002),'example.pl','message get_info id');
is($dri->get_info('action','message',2002),'create','message get_info action');
is($dri->get_info('name','message',2002),'example.pl','message get_info name');
is($dri->get_info('crDate','message',2002),'2005-06-29T21:13:57','message get_info crDate');
is($dri->get_info('exDate','message',2002),'2005-07-06T21:13:57','message get_info exDate');

## 9.13 - NASK_EPP_en_draft.pdf - Near password expiration
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="2003"><qDate>2005-06-29T21:17:26.288Z</qDate><msg lang="en">soon password expiration</msg></msgQ><resData><extepp:passwdReminder xmlns:extepp="http://www.dns.pl/nask-epp-schema/extepp-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extepp-2.0 extepp-2.0.xsd"><extepp:exDate>2005-07-06T21:17:26.273Z</extepp:exDate></extepp:passwdReminder></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),2003,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),2003,'message get_info last_id 2');
is($dri->get_info('id','message',2003),2003,'message get_info id');
is(''.$dri->get_info('qdate','message',2003),'2005-06-29T21:17:26','message get_info qdate');
is($dri->get_info('content','message',2003),'soon password expiration','message get_info content');
is($dri->get_info('lang','message',2003),'en','message get_info lang');
is($dri->get_info('object_type','message','extepp'),undef,'message get_info object type');
is($dri->get_info('object_id','message',2003),'domain','message get_info id');
is($dri->get_info('action','message',2003),'passwd_reminder','message get_info action');
is($dri->get_info('name','message',2003),'domain','message get_info name');
is($dri->get_info('exDate','message',2003),'2005-07-06T21:17:26','message get_info exDate extepp');

## 9.15 - NASK_EPP_en_draft.pdf - Domain unblocked
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="2003"><qDate>2007-07-29T21:17:26.288Z</qDate><msg lang="en">domain unblocked</msg></msgQ><resData><extdom:pollDomainUnblocked xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:domain><extdom:name>domena.pl</extdom:name><extdom:date>2007-07-06T21:17:26.273Z</extdom:date></extdom:domain></extdom:pollDomainUnblocked></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message_retrieve');
is($dri->get_info('last_id'), 2003, 'message get_info last_id 1');
is($dri->get_info('id','message',2003),2003,'message get_info id');
is(''.$dri->get_info('qdate','message',2003),'2007-07-29T21:17:26','message get info qdate');
is($dri->get_info('content','message',2003),'domain unblocked','message get_info content');
is($dri->get_info('lang','message',2003),'en','message get_info lang');
is($dri->get_info('object_type','message',2003),'domain','message get_info object_type');
is($dri->get_info('object_id','message',2003),'domena.pl','message get_info object_id');
is($dri->get_info('action','message',2003),'domain_unblocked','message get_info action');
is($dri->get_info('name','message',2003),'domena.pl','message get_info name');
is(''.$dri->get_info('date','message',2003),'2007-07-06T21:17:26','message get_info date');

## 9.16 - NASK_EPP_en_draft.pdf - Future removed due to a domain blockade
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="2" id="2003"><qDate>2007-07-29T21:17:26.288Z</qDate><msg lang="en">future removed due to domain blockade</msg></msgQ><resData><extdom:pollFutureRemoved xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:future><extdom:name>b01.pl</extdom:name><extdom:date>2007-07-06T21:17:26.273Z</extdom:date></extdom:future></extdom:pollFutureRemoved></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message_retrieve');
is($dri->get_info('last_id'), 2003, 'message get_info last_id 1');
is($dri->get_info('id','message',2003),2003,'message get_info id');
is(''.$dri->get_info('qdate','message',2003),'2007-07-29T21:17:26','message get info qdate');
is($dri->get_info('content','message',2003),'future removed due to domain blockade','message get_info content');
is($dri->get_info('lang','message',2003),'en','message get_info lang');
is($dri->get_info('object_type','message',2003),'domain','message get_info object_type');
is($dri->get_info('object_id','message',2003),'b01.pl','message get_info object_id');
is($dri->get_info('action','message',2003),'future_removed','message get_info action');
is($dri->get_info('name','message',2003),'b01.pl','message get_info name');
is(''.$dri->get_info('date','message',2003),'2007-07-06T21:17:26','message get_info date');

## 9.17 - NASK_EPP_en_draft.pdf - Domain taste removed due to a domain blockade
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="2003"><qDate>2007-07-29T21:17:26.288Z</qDate><msg lang="en">taste removed due to domain blockade</msg></msgQ><resData><extdom:pollTasteRemoved xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:taste><extdom:name>b02.pl</extdom:name><extdom:date>2007-07-06T21:17:26.273Z</extdom:date></extdom:taste></extdom:pollTasteRemoved></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message_retrieve');
is($dri->get_info('last_id'), 2003, 'message get_info last_id 1');
is($dri->get_info('id','message',2003),2003,'message get_info id');
is(''.$dri->get_info('qdate','message',2003),'2007-07-29T21:17:26','message get info qdate');
is($dri->get_info('content','message',2003),'taste removed due to domain blockade','message get_info content');
is($dri->get_info('lang','message',2003),'en','message get_info lang');
is($dri->get_info('object_type','message',2003),'domain','message get_info object_type');
is($dri->get_info('object_id','message',2003),'b02.pl','message get_info object_id');
is($dri->get_info('action','message',2003),'taste_removed','message get_info action');
is($dri->get_info('name','message',2003),'b02.pl','message get_info name');
is(''.$dri->get_info('date','message',2003),'2007-07-06T21:17:26','message get_info date');

## 9.18 - NASK_EPP_en_draft.pdf - Domain judicially removed
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="17830"><qDate>2008-01-04T12:34:52.238Z</qDate><msg lang="en">domain removed due to a legal valid decision of the court</msg></msgQ><resData><extdom:pollDomainJudicialRemoved xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:domain><extdom:name>judicialtest.pl</extdom:name><extdom:date>2007-07-06T21:17:26.273Z</extdom:date></extdom:domain></extdom:pollDomainJudicialRemoved></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message_retrieve');
is($dri->get_info('last_id'), 17830, 'message get_info last_id 1');
is($dri->get_info('id','message',17830),17830,'message get_info id');
is(''.$dri->get_info('qdate','message',17830),'2008-01-04T12:34:52','message get info qdate');
is($dri->get_info('content','message',17830),'domain removed due to a legal valid decision of the court','message get_info content');
is($dri->get_info('lang','message',17830),'en','message get_info lang');
is($dri->get_info('object_type','message',17830),'domain','message get_info object_type');
is($dri->get_info('object_id','message',17830),'judicialtest.pl','message get_info object_id');
is($dri->get_info('action','message',17830),'domain_judicial_removed','message get_info action');
is($dri->get_info('name','message',17830),'judicialtest.pl','message get_info name');
is(''.$dri->get_info('date','message',17830),'2007-07-06T21:17:26','message get_info date');

## 9.19 Non-sufficient funds on prepaid account
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="4" id="89010"><qDate>2009-10-19T09:34:31.178Z</qDate><msg lang="en">non-sufficient funds</msg></msgQ><resData><extepp:accountBalanceInsufficient xmlns:extepp="http://www.dns.pl/nask-epp-schema/extepp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extepp-2.0 extepp-2.0.xsd"><extepp:accountLevel>4.90</extepp:accountLevel><extepp:accountType>DOMAIN</extepp:accountType><extepp:serviceName>PREPAID_DOMAIN_FUNC_CREATE_1</extepp:serviceName><extepp:name>pp14.pl</extepp:name></extepp:accountBalanceInsufficient></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),89010,'message get_info last_id 1');
is($dri->get_info('id','message',89010),89010,'message get_info id');
is(''.$dri->get_info('qdate','message',89010),'2009-10-19T09:34:31','message get_info qdate');
is($dri->get_info('content','message',89010),'non-sufficient funds','message get_info content');
is($dri->get_info('lang','message',89010),'en','message get_info lang');
is($dri->get_info('object_type','message','extepp'),undef,'message get_info object type');
is($dri->get_info('object_id','message',89010),'domain','message get_info id');
is($dri->get_info('action','message',89010),'account_balance_insufficient','message get_info action');
is($dri->get_info('account_level','message',89010),'4.90','message get_info accountLevel');
is($dri->get_info('account_type','message',89010),'DOMAIN','message get_info accountType');
is($dri->get_info('service_name','message',89010),'PREPAID_DOMAIN_FUNC_CREATE_1','message get_info serviceName');
is($dri->get_info('domain_name','message',89010),'pp14.pl','message get_info domain of future name');
is($dri->get_info('name','message',89010),'domain','message get_info name');

## 9.20 Prepaid account balance notification level reached
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="3" id="89021"><qDate>2009-10-19T09:44:24.118Z</qDate><msg lang="en">account balance notification level reached</msg></msgQ><resData><extepp:accountBalanceCrossed xmlns:extepp="http://www.dns.pl/nask-epp-schema/extepp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extepp-2.0 extepp-2.0.xsd"><extepp:notificationLevel>100.00</extepp:notificationLevel><extepp:accountType>DOMAIN</extepp:accountType></extepp:accountBalanceCrossed></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),89021,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),89021,'message get_info last_id 2');
is($dri->get_info('id','message',89021),89021,'message get_info id');
is(''.$dri->get_info('qdate','message',89021),'2009-10-19T09:44:24','message get_info qdate');
is($dri->get_info('content','message',89021),'account balance notification level reached','message get_info content');
is($dri->get_info('lang','message',89021),'en','message get_info lang');
is($dri->get_info('object_type','message','extepp'),undef,'message get_info object type');
is($dri->get_info('object_id','message',89021),'domain','message get_info id');
is($dri->get_info('action','message',89021),'account_balance_crossed','message get_info action');
is($dri->get_info('name','message',89021),'domain','message get_info name');
is($dri->get_info('notification_level','message',89021),'100.00','message get_info notificationLevel');
is($dri->get_info('account_type','message',89021),'DOMAIN','message get_info accountType');

## 9.21 - NASK_EPP_en_draft.pdf
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="2" id="89024"><qDate>2009-10-19T09:52:31.128Z</qDate><msg lang="en">domain renewed automatically</msg></msgQ><resData><extdom:pollDomainAutoRenewed xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:name>ppr13.pl</extdom:name></extdom:pollDomainAutoRenewed></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),89024,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),89024,'message get_info last_id 2');
is($dri->get_info('id','message',89024),89024,'message get_info id');
is(''.$dri->get_info('qdate','message',89024),'2009-10-19T09:52:31','message get_info qdate');
is($dri->get_info('content','message',89024),'domain renewed automatically','message get_info content');
is($dri->get_info('lang','message',89024),'en','message get_info lang');
is($dri->get_info('object_type','message',89024),'domain','message get_info object type');
is($dri->get_info('object_id','message',89024),'ppr13.pl','message get_info id');
is($dri->get_info('action','message',89024),'domain_auto_renewed','message get_info action');
is($dri->get_info('name','message',89024),'ppr13.pl','message get_info name');

## 9.22 - NASK_EPP_en_draft.pdf
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="89025"><qDate>2009-10-19T09:56:51.131Z</qDate><msg lang="en">domain auto renewal failure due to domain status</msg></msgQ><resData><extdom:pollDomainAutoRenewFailed xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:name>ppr13.pl</extdom:name><extdom:date>2009-11-09T09:07:23.609Z</extdom:date></extdom:pollDomainAutoRenewFailed></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve');
is($dri->get_info('last_id'),89025,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),89025,'message get_info last_id 2');
is($dri->get_info('id','message',89025),89025,'message get_info id');
is(''.$dri->get_info('qdate','message',89025),'2009-10-19T09:56:51','message get_info qdate');
is($dri->get_info('content','message',89025),'domain auto renewal failure due to domain status','message get_info content');
is($dri->get_info('lang','message',89025),'en','message get_info lang');
is($dri->get_info('object_type','message',89025),'domain','message get_info object_type');
is($dri->get_info('object_id','message',89025),'ppr13.pl','message get_info object_id');
is($dri->get_info('action','message',89025),'domain_auto_renew_failed','message get_info action');
is($dri->get_info('name','message',89025),'ppr13.pl','message get_info name');
is(''.$dri->get_info('date','message',89025),'2009-11-09T09:07:23','message get_info date');

## Multiple level domain registration

is($dri->verify_name_domain('sygroup.com.pl', 'info'), '',
  'third.com.pl registrability');
is($dri->verify_name_domain('sygroup.net.pl', 'info'), '',
  'third.net.pl registrability');
  
  
## Parsing contact:info
$R2=$E1.'<response><result code="1000"><msg lang="en">Command completed successfully</msg></result><resData><contact:infData xmlns:contact="http://www.dns.pl/nask-epp-schema/contact-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><contact:id>A0001</contact:id><contact:roid>478522-NASK</contact:roid><contact:status s="ok" lang="en" /><contact:postalInfo type="loc"><contact:name>B G</contact:name><contact:org>B G</contact:org><contact:addr><contact:street>RN 20</contact:street><contact:street /><contact:street /><contact:city>THECITY</contact:city><contact:cc>FR</contact:cc></contact:addr></contact:postalInfo><contact:voice>+33.12345678</contact:voice><contact:email>here@there.com</contact:email><contact:clID>A2</contact:clID><contact:crID>A2</contact:crID><contact:crDate>2011-08-23T14:08:27.0Z</contact:crDate><contact:authInfo><contact:pw>pass</contact:pw></contact:authInfo></contact:infData></resData><extension><extcon:infData xmlns:extcon="http://www.dns.pl/nask-epp-schema/extcon-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extcon-2.0 extcon-2.0.xsd"><extcon:individual>false</extcon:individual><extcon:consentForPublishing>true</extcon:consentForPublishing></extcon:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_info($dri->local_object('contact')->srid('A0001'));
my $c1=$dri->get_info('self');
my $c2=$dri->get_info('self','contact','A0001');
my $c3=$rc->get_data('contact','A0001','self');
isa_ok($c1,'Net::DRI::Data::Contact::PL','contact_info get_info(self) isa Net::DRI::Data::Contact::PL');
is_deeply($c1,$c2,'contact_info get_info(self)=get_info(self,contact,id)');
is_deeply($c1,$c3,'contact_info get_info(self)=get_data(contact,id,self)');
is($c1->individual(),0,'get_info(self)->is_individual()');
is($c1->consent_for_publishing(),1,'get_info(self)->consent_for_publishing()');

####################################################################################################
## Reports

$R2=$E1.'<response><result code="1000"><msg lang="en">Command completed successfully</msg></result><extension><extreport:reportData xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:domDataRsp><extreport:domData><extreport:name>example1.pl</extreport:name><extreport:roid>1234-NASK</extreport:roid><extreport:exDate>2007-03-18T23:00:00.0Z</extreport:exDate><extreport:statuses><extreport:status>serverHold</extreport:status></extreport:statuses></extreport:domData><extreport:domData><extreport:name>example2.pl</extreport:name><extreport:roid>1235-NASK</extreport:roid><extreport:exDate>2007-04-19T15:25:31.0Z</extreport:exDate><extreport:statuses><extreport:status>serverHold</extreport:status></extreport:statuses></extreport:domData></extreport:domDataRsp><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit><extreport:size>2</extreport:size></extreport:reportData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->report_create(1234,{type=>'domain',state=>'registered',exDate=>$dri->local_object('datetime',year=>2007,month=>5,day=>7,hour=>11,minute=>23),status=>$dri->local_object('status')->add('serverHold'),status_in=>1,offset=>0,limit=>50});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><extension><extreport:report xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:domain><extreport:state>STATE_REGISTERED</extreport:state><extreport:exDate>2007-05-07T11:23:00Z</extreport:exDate><extreport:statuses statusesIn="true"><extreport:status>serverHold</extreport:status></extreport:statuses></extreport:domain><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit></extreport:report></extension></epp>','report domain build');
is($rc->get_data('offset'),0,'report domain get_data(offset)');
is($rc->get_data('limit'),50,'report domain get_data(limit)');
is($rc->get_data('size'),2,'report domain get_data(size)');
is($rc->get_data('type'),'domain','report domain get_data(type)');
my $report=$rc->get_data('results');
is(scalar @$report,2,'report domain get_data(results) size');
my $det=$report->[0];
is($det->{name},'example1.pl','report domain get_data(results) 1 name');
is($det->{roid},'1234-NASK','report domain get_data(results) 1 roid');
is(''.$det->{exDate},'2007-03-18T23:00:00','report domain get_data(results) 1 exDate');
is_deeply([$det->{status}->list_status()],['serverHold'],'report domain get_data(results) 1 status');
$det=$report->[1];
is($det->{name},'example2.pl','report domain get_data(results) 2 name');
is($det->{roid},'1235-NASK','report domain get_data(results) 2 roid');
is(''.$det->{exDate},'2007-04-19T15:25:31','report domain get_data(results) 2 exDate');
is_deeply([$det->{status}->list_status()],['serverHold'],'report domain get_data(results) 2 status');


$R2=$E1.'<response><result code="1000"><msg lang="en">Command completed successfully</msg></result><extension><extreport:reportData xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:conDataRsp><extreport:conData><extreport:conId>k13</extreport:conId><extreport:roid>654321-NASK</extreport:roid></extreport:conData></extreport:conDataRsp><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit><extreport:size>1</extreport:size></extreport:reportData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->report_create(1235,{type=>'contact',id=>'k13',offset=>0,limit=>50});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><extension><extreport:report xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:contact><extreport:conId>k13</extreport:conId></extreport:contact><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit></extreport:report></extension></epp>','report contact build');
is($rc->get_data('offset'),0,'report contact get_data(offset)');
is($rc->get_data('limit'),50,'report contact get_data(limit)');
is($rc->get_data('size'),1,'report contact get_data(size)');
is($rc->get_data('type'),'contact','report contact get_data(type)');
$report=$rc->get_data('results');
is(scalar @$report,1,'report contact get_data(results) size');
$det=$report->[0];
isa_ok($det,'Net::DRI::Data::Contact');
is($det->srid(),'k13','report contact get_data(results) 1 srid');
is($det->roid(),'654321-NASK','report contact get_data(results) 1 roid');



$R2=$E1.'<response><result code="1000"><msg lang="en">Command completed successfully</msg></result><extension><extreport:reportData xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:hosDataRsp><extreport:hosData><extreport:name>ns1.temp.pl</extreport:name><extreport:roid>632381-NASK</extreport:roid></extreport:hosData></extreport:hosDataRsp><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit><extreport:size>1</extreport:size></extreport:reportData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->report_create(1236,{type=>'host',name=>'ns1.temp.pl',offset=>0,limit=>50});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><extension><extreport:report xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:host><extreport:name>ns1.temp.pl</extreport:name></extreport:host><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit></extreport:report></extension></epp>','report host build');
is($rc->get_data('offset'),0,'report host get_data(offset)');
is($rc->get_data('limit'),50,'report host get_data(limit)');
is($rc->get_data('size'),1,'report host get_data(size)');
is($rc->get_data('type'),'host','report host get_data(type)');
$report=$rc->get_data('results');
$det=$report;
isa_ok($det,'Net::DRI::Data::Hosts');
is($det->count(),1,'report host get_data(results) 1 count');
is_deeply($det->as_string(),'ns1.temp.pl {roid=632381-NASK}','report host get_data(results) 1 as_string');


$R2=$E1.'<response><result code="1000"><msg lang="en">Command completed successfully</msg></result><extension><extreport:reportData xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:futDataRsp><extreport:futData><extreport:name>ns1.temp.pl</extreport:name><extreport:roid>632381-NASK</extreport:roid><extreport:exDate>2007-04-19T15:25:31.0Z</extreport:exDate></extreport:futData></extreport:futDataRsp><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit><extreport:size>1</extreport:size></extreport:reportData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->report_create(1237,{type=>'future',exDate=>$dri->local_object('datetime',year=>2007,month=>4,day=>23,hour=>15,minute=>22,second=>34),offset=>0,limit=>50});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><extension><extreport:report xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:future><extreport:exDate>2007-04-23T15:22:34Z</extreport:exDate></extreport:future><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit></extreport:report></extension></epp>','report future build');
is($rc->get_data('offset'),0,'report future get_data(offset)');
is($rc->get_data('limit'),50,'report future get_data(limit)');
is($rc->get_data('size'),1,'report future get_data(size)');
is($rc->get_data('type'),'future','report future get_data(type)');
$report=$rc->get_data('results');
is(scalar @$report,1,'report future get_data(results) size');
$det=$report->[0];
is($det->{name},'ns1.temp.pl','report future get_data(results) 1 name');
is($det->{roid},'632381-NASK','report future get_data(results) 1 roid');
is(''.$det->{exDate},'2007-04-19T15:25:31','report future get_data(results) 1 exDate');


$R2=$E1.'<response><result code="1000"><msg lang="en">Command completed successfully</msg></result><extension><extreport:reportData xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:paymentDataRsp><extreport:paymentData><extreport:roid>14-NASK</extreport:roid><extreport:crDate>2009-06-17T08:08:40.0Z</extreport:crDate><extreport:grossValue>1220.0</extreport:grossValue><extreport:vatPercent>22</extreport:vatPercent><extreport:vatValue>220.0</extreport:vatValue><extreport:initialFunds>1000.0</extreport:initialFunds><extreport:currentFunds>1000.0</extreport:currentFunds></extreport:paymentData></extreport:paymentDataRsp><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit><extreport:size>1</extreport:size></extreport:reportData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->report_create(1238,{type=>'payment',account_type=>'domain',offset=>0,limit=>50});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><extension><extreport:report xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:prepaid><extreport:payment><extreport:accountType>domain</extreport:accountType></extreport:payment></extreport:prepaid><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit></extreport:report></extension></epp>','report payment build');
is($rc->get_data('offset'),0,'report payment get_data(offset)');
is($rc->get_data('limit'),50,'report payment get_data(limit)');
is($rc->get_data('size'),1,'report payment get_data(size)');
is($rc->get_data('type'),'payment','report payment get_data(type)');
$report=$rc->get_data('results');
is(scalar @$report,1,'report payment get_data(results) size');
$det=$report->[0];
is($det->{roid},'14-NASK','report payment get_data(results) roid');
is(''.$det->{crDate},'2009-06-17T08:08:40','report payment get_data(results) 1 exDate');
is($det->{gross_value},1220,'report payment get_data(results) gross_value');
is($det->{vat_percent},22,'report payment get_data(results) vat_percent');
is($det->{vat_value},220,'report payment get_data(results) vat_value');
is($det->{initial_funds},1000,'report payment get_data(results) initial_funds');
is($det->{current_funds},1000,'report payment get_data(results) current_funds');

$R2=$E1.'<response><result code="1000"><msg lang="en">Command completed successfully</msg></result><extension><extreport:reportData xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:paymentFundsDataRsp><extreport:paymentFundsData><extreport:currentBalance>803.86</extreport:currentBalance></extreport:paymentFundsData></extreport:paymentFundsDataRsp><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit><extreport:size>1</extreport:size></extreport:reportData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->report_create(1238,{type=>'funds',account_type=>'domain',offset=>0,limit=>50});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><extension><extreport:report xmlns:extreport="http://www.dns.pl/nask-epp-schema/extreport-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extreport-2.0 extreport-2.0.xsd"><extreport:prepaid><extreport:paymentFunds><extreport:accountType>domain</extreport:accountType></extreport:paymentFunds></extreport:prepaid><extreport:offset>0</extreport:offset><extreport:limit>50</extreport:limit></extreport:report></extension></epp>','report funds build');
is($rc->get_data('offset'),0,'report funds get_data(offset)');
is($rc->get_data('limit'),50,'report funds get_data(limit)');
is($rc->get_data('size'),1,'report funds get_data(size)');
is($rc->get_data('type'),'funds','report funds get_data(type)');
$report=$rc->get_data('results');
isa_ok($report,'HASH','report funds get_data(results)');
is_deeply($report,{current_balance=>803.86},'report funds get_data(results) current_balance');


####################################################################################################
## Future - info
$R2=$E1.'<response>'.r().'<resData><future:infData xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd">
  <future:name>example.pl</future:name>
  <future:roid>EXAMPLE1-REP</future:roid>
  <future:registrant>jd1234</future:registrant>
  <future:clID>ClientX</future:clID>
  <future:crID>ClientY</future:crID>
  <future:crDate>1999-04-03T22:00:00.0Z</future:crDate>
  <future:upID>ClientX</future:upID>
  <future:upDate>1999-12-03T09:00:00.0Z</future:upDate>
  <future:exDate>2005-04-03T22:00:00.0Z</future:exDate>
  <future:trDate>2000-04-08T09:00:00.0Z</future:trDate>
  <future:authInfo>
  <future:pw>2fooBAR</future:pw>
  </future:authInfo>
  </future:infData>
  </resData>'.$TRID.'</response>'.$E2;
$rc = $dri->future_info('example.pl',{auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><info><future:info xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>example.pl</future:name><future:authInfo><future:pw>2fooBAR</future:pw></future:authInfo></future:info></info><clTRID>ABC-12345</clTRID></command></epp>','future_info build');
is($dri->get_info('name'),'example.pl','future_info({id => "example.pl"})');
is($dri->get_info('roid'),'EXAMPLE1-REP','future_info({roid => "EXAMPLE1-REP"})');
is($dri->get_info('registrant'),'jd1234','future_info({registrant => "jd1234"})');
is($dri->get_info('clID'),'ClientX','future_info({clID => "ClientX"})');
is($dri->get_info('crID'),'ClientY','future_info({crID => "ClientY"})');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','future_info get_info(crDate)');
is($d,'1999-04-03T22:00:00','future_info get_info(crDate) value=>"1999-04-03T22:00:00"');
is($dri->get_info('upID'),'ClientX','future_info({upID => "ClientX"})');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','future_info get_info(upDate)');
is($d,'1999-12-03T09:00:00','future_info get_info(upDate) value=>"1999-12-03T09:00:00"');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','future_info get_info(exDate)');
is($d,'2005-04-03T22:00:00','future_info get_info(exDate) value=>"2005-04-03T22:00:00"');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','future_info get_info(trDate)');
is($d,'2000-04-08T09:00:00','future_info get_info(trDate) value=>"2000-04-08T09:00:00"');
#is($dri->get_info('authInfo'),'2fooBAR','future_info({pw => "2fooBAR"})');
is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'future_info({pw => "2fooBAR"})');
####################################################################################################

####################################################################################################
## Future - check
$R2=$E1.'<response>'.r().'<resData><future:chkData xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd">
  <future:cd>
  <future:name avail="true">ala.pl</future:name>
  </future:cd>
  <future:cd>
  <future:name avail="false">ela.com.pl</future:name>
  <future:reason>4005</future:reason>
  </future:cd>
  <future:cd>
  <future:name avail="false">ola.org.pl</future:name>
  <future:reason>4012</future:reason>
  </future:cd>
  </future:chkData>
  </resData>'.$TRID.'</response>'.$E2;
$rc = $dri->future_check('ala.pl'); 
is($R1,$E1.'<command><check><future:check xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>ala.pl</future:name></future:check></check><clTRID>ABC-12345</clTRID></command></epp>','future_check({name => "ala.pl"})');
is($rc->is_success(),1,'future_check is_success');
is($dri->get_info('action','domain','ala.pl'),'check','future_check get_info(action)');
is($dri->get_info('exist','domain','ala.pl'),0,'future_check get_info(exist)');

$rc = $dri->future_check('ela.com.pl');
is_string($R1,$E1.'<command><check><future:check xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>ela.com.pl</future:name></future:check></check><clTRID>ABC-12345</clTRID></command></epp>','future_check build');
is($rc->is_success(),1,'future_check is_success');
is($dri->get_info('action','domain','ela.com.pl'),'check','future_check get_info(action)');
is($dri->get_info('exist','domain','ela.com.pl'),1,'future_check get_info(exist)');
is($dri->get_info('exist_reason','domain','ela.com.pl'),4005,'future_check get_info(exist_reason)');

$rc = $dri->future_check(qw/ala.pl ela.com.pl ola.org.pl/);
is($R1,$E1.'<command><check><future:check xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>ala.pl</future:name><future:name>ela.com.pl</future:name><future:name>ola.org.pl</future:name></future:check></check><clTRID>ABC-12345</clTRID></command></epp>','future_check({multiple domain_check name => ("ala.pl","ela.com.pl","ola.org.pl")})');
is($rc->is_success(),1,'future_check multi is_success');
is($dri->get_info('action','domain','ala.pl'),'check','future_check get_info(action,domain1)');
is($dri->get_info('exist','domain','ala.pl'),0,'future_check multi get_info(exist,domain1)');
is($dri->get_info('action','domain','ela.com.pl'),'check','future_check get_info(action,domain2)');
is($dri->get_info('exist','domain','ela.com.pl'),1,'future_check multi get_info(exist,domain2)');
is($dri->get_info('exist_reason','domain','ela.com.pl'),4005,'future_check multi get_info(exist_reason,domain2');
is($dri->get_info('action','domain','ola.org.pl'),'check','future_check get_info(action,domain3)');
is($dri->get_info('exist','domain','ola.org.pl'),1,'future_check multi get_info(exist,domain3)');
is($dri->get_info('exist_reason','domain','ola.org.pl'),4012,'future_check multi get_info(exist_reason,domain3');

####################################################################################################
## Future - create
$R2=$E1.'<response>'.r().'<resData><future:creData xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd">
  <future:name>example.pl</future:name>
  <future:crDate>1999-04-03T22:00:00.0Z</future:crDate>
  <future:exDate>2002-04-03T22:00:00.0Z</future:exDate>
  </future:creData>
  </resData>'.$TRID.'</response>'.$E2;
$rc = $dri->future_create("example.pl", {duration => DateTime::Duration->new(years=>3), registrant => ("jd1234"), auth=>{pw=>"2fooBAR"}});
is($R1,$E1.'<command><create><future:create xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>example.pl</future:name><future:period unit="y">3</future:period><future:registrant>jd1234</future:registrant><future:authInfo><future:pw>2fooBAR</future:pw></future:authInfo></future:create></create><clTRID>ABC-12345</clTRID></command></epp>', 'future_create build');
is($rc->is_success(),1,'future_create is_success');
is($dri->get_info('name'),'example.pl','future_create get_info(name)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','future_create get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','future_create get_info(crDate) value=>"1999-04-03T22:00:00"');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','future_create get_info(exDate)');
is("".$d,'2002-04-03T22:00:00','future_create get_info(exDate) value=>"2002-04-03T22:00:00"');

####################################################################################################
## Future - renew
$R2=$E1.'<response>'.r().'<resData><future:renData xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd">
  <future:name>example.pl</future:name>
  <future:exDate>2013-10-30T22:00:00.0Z</future:exDate>
  </future:renData>
  </resData>'.$TRID.'</response>'.$E2;
$rc = $dri->future_renew("example.pl", {current_expiration => DateTime->new(year=>2010,month=>10,day=>30), duration => DateTime::Duration->new(years=>3)});
is($R1,$E1.'<command><renew><future:renew xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>example.pl</future:name><future:curExpDate>2010-10-30</future:curExpDate><future:period unit="y">3</future:period></future:renew></renew><clTRID>ABC-12345</clTRID></command></epp>', 'future_renew build');
is($rc->is_success(),1,'future_renew is_success');
is($dri->get_info('name'),'example.pl','future_renew get_info(name)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','future_renew get_info(exDate)');
is($d,'2013-10-30T22:00:00','future_renew get_info(exDate) value=>"2013-10-30T22:00:00"');

####################################################################################################
## Future - delete
$R2=$E1.'<response>'.r().'<msgQ count="1671" id="79340" />'.$TRID.'</response>'.$E2;
#$rc = $dri->future_delete({name => "futuretest.pl"}); # old del func
$rc = $dri->future_delete('futuretest.pl');
is($R1,$E1.'<command><delete><future:delete xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>futuretest.pl</future:name></future:delete></delete><clTRID>ABC-12345</clTRID></command></epp>', 'future_delete build');
is($rc->is_success(),1,'future_delete is_success');

####################################################################################################
## Future - update
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
my $todo = $dri->local_object('changes');
$todo->set('registrant',$dri->local_object('contact')->srid('mak21'));
$todo->set('auth',{pw=>'2BARfoo'});
$rc = $dri->future_update('example7.pl', $todo);
is($R1,$E1.'<command><update><future:update xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>example7.pl</future:name><future:chg><future:registrant>mak21</future:registrant><future:authInfo><future:pw>2BARfoo</future:pw></future:authInfo></future:chg></future:update></update><clTRID>ABC-12345</clTRID></command></epp>', 'future_update build');
is($rc->is_success(),1,'future_update is_success');

####################################################################################################
## Future - transfer
$R2=$E1.'<response>'.r().'<resData><future:trnData xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd">
  <future:name>example.pl</future:name>
  <future:trStatus>pending</future:trStatus>
  <future:reID>ClientX</future:reID>
  <future:reDate>2000-06-08T22:00:00.0Z</future:reDate>
  <future:acID>ClientY</future:acID>
  <future:acDate>2000-06-13T22:00:00.0Z</future:acDate>
  </future:trnData>
  </resData>'.$TRID.'</response>'.$E2;
$rc = $dri->future_transfer_request('example.pl', {auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><transfer op="request"><future:transfer xmlns:future="http://www.dns.pl/nask-epp-schema/future-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/future-2.0 future-2.0.xsd"><future:name>example.pl</future:name><future:authInfo><future:pw>2fooBAR</future:pw></future:authInfo></future:transfer></transfer><clTRID>ABC-12345</clTRID></command></epp>', 'future_transfer_request build');
is($rc->is_success(),1,'future_transfer_request is_success');
is($dri->get_info('name'),'example.pl','future_transfer_request get_info(name)');
is($dri->get_info('trStatus'),'pending','future_transfer_request get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','future_transfer_request get_info(reID)');
is($dri->get_info('acID'),'ClientY','future_transfer_request get_info(acID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','future_transfer_request get_info(reDate)');
is($d,'2000-06-08T22:00:00','future_transfer_request get_info(reDate) value=>"2000-06-08T22:00:00"');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','future_transfer_request get_info(acDate)');
is($d,'2000-06-13T22:00:00','future_transfer_request get_info(acDate) value=>"2000-06-13T22:00:00"');


####################################################################################################
## Domain - check (test some regional domains)
$rc = $dri->domain_check(qw/example.babia-gora.pl example.czest.pl example.elk.pl/);
is($R1,$E1.'<command><check><domain:check xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>example.babia-gora.pl</domain:name><domain:name>example.czest.pl</domain:name><domain:name>example.elk.pl</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command></epp>','domain_check({multiple domain_check name => ("example.babia-gora.pl","example.czest.pl","example.elk.pl")})');
is($rc->is_success(),1,'domain_check multi is_success');


####################################################################################################
## domain renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>example123.pl</domain:name><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('example123.pl',{duration => DateTime::Duration->new(years=>5), current_expiration => DateTime->new(year=>2000,month=>4,day=>3)});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>example123.pl</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is("".$d,'2005-04-03T22:00:00','domain_renew get_info(exDate) value');

## domain restore / reactivate
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>example456.pl</domain:name><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('example456.pl',{reactivate => 1, duration => DateTime::Duration->new(years=>5), current_expiration => DateTime->new(year=>2000,month=>4,day=>3)});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>example456.pl</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><extension><extdom:renew xmlns:extdom="http://www.dns.pl/nask-epp-schema/extdom-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extdom-2.0 extdom-2.0.xsd"><extdom:reactivate/></extdom:renew></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is("".$d,'2005-04-03T22:00:00','domain_renew get_info(exDate) value');

exit 0;