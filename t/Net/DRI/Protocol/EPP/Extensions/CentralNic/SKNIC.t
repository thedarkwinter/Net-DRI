#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 42;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('CentralNic::SKNIC');
$dri->target('CentralNic::SKNIC')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$csadd,$csdel,$c1,$c2,$co);

####################################################################################################

# domain check multi to test new profile :)
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">example22.sk</domain:name></domain:cd><domain:cd><domain:name avail="0">example23.sk</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example22.sk','example23.sk');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example22.sk</domain:name><domain:name>example23.sk</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','example22.sk'),0,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','example23.sk'),1,'domain_check multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','domain','example23.sk'),'In use','domain_check multi get_info(exist_reason)');


# contact - sk-contact-ident extension
# contact create
$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013');
$co->name('John Doe');
$co->org('Example Inc.');
$co->street(['123 Example Dr.','Suite 100']);
$co->city('Dulles');
$co->sp('VA');
$co->pc('20166-6503');
$co->cc('US');
$co->voice('+1.7035555555x1234');
$co->fax('+1.7035555556');
$co->email('jdoe@example.com');
$co->auth({pw=>'2fooBAR'});
$co->disclose({voice=>0,email=>0});
# skContactIdent extension fields
$co->legal_form('CORP');
$co->ident_value('1234567890');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:postalInfo type="int"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><skContactIdent:create xmlns:skContactIdent="http://www.sk-nic.sk/xml/epp/sk-contact-ident-0.2"><skContactIdent:legalForm>CORP</skContactIdent:legalForm><skContactIdent:identValue><skContactIdent:corpIdent>1234567890</skContactIdent:corpIdent></skContactIdent:identValue></skContactIdent:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');
is($dri->get_info('action'),'create','contact_create get_info(action)');
is($dri->get_info('exist'),1,'contact_create get_info(exist)');

# contact info - pers (same principle for corp!)
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:roid>SH8013-REP</contact:roid><contact:status s="linked"/><contact:status s="clientDeleteProhibited"/><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:clID>ClientY</contact:clID><contact:crID>ClientX</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>ClientX</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate><contact:trDate>2000-04-08T09:00:00.0Z</contact:trDate><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:infData></resData><extension><infData xmlns="http://www.sk-nic.sk/xml/epp/sk-contact-ident-0.2"><legalForm>PERS</legalForm><identValue><persIdent>2017-12-08</persIdent></identValue></infData></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013')->auth({pw=>'2fooBAR'});
$rc=$dri->contact_info($co);
is($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'sh8013','contact_info get_info(self) srid');
is($co->roid(),'SH8013-REP','contact_info get_info(self) roid');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status)');
is_deeply([$s->list_status()],['clientDeleteProhibited','linked'],'contact_info get_info(status) list_status');
is($s->can_delete(),0,'contact_info get_info(status) can_delete');
is($co->name(),'John Doe','contact_info get_info(self) name');
is($co->org(),'Example Inc.','contact_info get_info(self) org');
is_deeply(scalar $co->street(),['123 Example Dr.','Suite 100'],'contact_info get_info(self) street');
is($co->city(),'Dulles','contact_info get_info(self) city');
is($co->sp(),'VA','contact_info get_info(self) sp');
is($co->pc(),'20166-6503','contact_info get_info(self) pc');
is($co->cc(),'US','contact_info get_info(self) cc');
is($co->voice(),'+1.7035555555x1234','contact_info get_info(self) voice');
is($co->fax(),'+1.7035555556','contact_info get_info(self) fax');
is($co->email(),'jdoe@example.com','contact_info get_info(self) email');
is($dri->get_info('clID'),'ClientY','contact_info get_info(clID)');
is($dri->get_info('crID'),'ClientX','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','contact_info get_info(crDate) value');
is($dri->get_info('upID'),'ClientX','contact_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is("".$d,'1999-12-03T09:00:00','contact_info get_info(upDate) value');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','contact_info get_info(trDate)');
is("".$d,'2000-04-08T09:00:00','contact_info get_info(trDate) value');
is_deeply($co->auth(),{pw=>'2fooBAR'},'contact_info get_info(self) auth');
is_deeply($co->disclose(),{voice=>0,email=>0},'contact_info get_info(self) disclose');
# skContactIdent extension fields
is($co->legal_form(),'PERS','contact_info get_info(self) legalForm');
is($co->ident_value(),'2017-12-08','contact_info get_info(self) identValue');


####################################################################################################
exit 0;
