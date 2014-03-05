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
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('SIDN');
$dri->target('SIDN')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my ($rc,$co,$h,$toc);

####################################################################################################
## Error messages

$R2=$E1.'<response>'.r(2400,'Validation of the transaction failed.').'<extension><urn:ext xmlns:urn="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><urn:response><urn:msg field="deelnemernummer" code="C0013">De deelnemer heeft niet de status \'Active\'.</urn:msg></urn:response></urn:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('whatever.nl');
is($rc->is_success(),0,'error is_success');
is($rc->code(),2400,'error code');
is_deeply([$rc->get_extended_results()],[{from=>'sidn',type=>'text',message=>"De deelnemer heeft niet de status 'Active'.",field=>'deelnemernummer',code=>'C0013'}],'error parsing 1');

$R2=$E1.'<response>'.r(2303,' The specified contact person is unknown.').'<extension><urn:ext xmlns:urn="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><urn:response><urn:msg field="handle" code="F0001">Waarde voldoet niet aan de expressie: [A-Z]{3}[0-9]{6}[-][A-Z0-9]{5}.</urn:msg><urn:msg field="handle" code="T0002">De opgegeven handle is onbekend.</urn:msg></urn:response></urn:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('whatever2.nl');
is_deeply([$rc->get_extended_results()],[{from=>'sidn',type=>'text',message=>'Waarde voldoet niet aan de expressie: [A-Z]{3}[0-9]{6}[-][A-Z0-9]{5}.',field=>'handle',code=>'F0001'},{from=>'sidn',type=>'text',message=>'De opgegeven handle is onbekend.',field=>'handle',code=>'T0002'}],'error parsing 2');


####################################################################################################
## Domain commands

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>doris.nl</domain:name><domain:roid>DNM_700-SIDN</domain:roid><domain:status s="ok"/><domain:registrant>TES000079-SL1SL</domain:registrant><domain:contact type="admin">TES000079-SO1SO</domain:contact><domain:contact type="tech">TES000079-SL1SL</domain:contact><domain:ns><domain:hostObj>ns1.doris.nl</domain:hostObj></domain:ns><domain:host>ns2.doris.nl</domain:host><domain:host>ns3.doris.nl</domain:host><domain:host>ns4.doris.nl</domain:host><domain:host>ns1.doris.nl</domain:host><domain:clID>SIDN0</domain:clID><domain:crID>SIDN0</domain:crID><domain:crDate>2009-08-10T00:00:00.000+02:00</domain:crDate><domain:upID>SIDN0</domain:upID><domain:upDate>2009-08-10T00:00:00.000+02:00</domain:upDate><domain:trDate>2010-08-12T00:00:00.000+02:00</domain:trDate><domain:authInfo><domain:pw>token4556</domain:pw></domain:authInfo></domain:infData></resData><extension xmlns:urn1="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><urn1:ext><urn1:infData><urn1:domain><urn1:optOut>false</urn1:optOut><urn1:limited>false</urn1:limited></urn1:domain></urn1:infData></urn1:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('doris.nl');
is($rc->get_data('opt_out'),0,'domain_info opt_out');
is($rc->get_data('limited'),0,'domain_info limited');

$R2='';
$rc=$dri->domain_undelete('DOMAINdelete37.nl');
is_string($R1,$E1.'<extension><sidn:command xmlns:sidn="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0" xsi:schemaLocation="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0 sidn-ext-epp-1.0.xsd"><sidn:domainCancelDelete><sidn:name>DOMAINdelete37.nl</sidn:name></sidn:domainCancelDelete><sidn:clTRID>ABC-12345</sidn:clTRID></sidn:command></extension>'.$E2,'domain_undelete build');


####################################################################################################
## Contact commands

$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>TST000033-DEMEE</contact:id><contact:roid>CPN_100134-SIDN</contact:roid><contact:status s="pendingUpdate">linked, limited, pendingUpdate</contact:status><contact:postalInfo type="loc"><contact:name>Jan Otten</contact:name><contact:addr><contact:street>Hoofdstraat 126</contact:street><contact:city>Eindhoven</contact:city><contact:pc>4444EE</contact:pc><contact:cc>NL</contact:cc></contact:addr></contact:postalInfo><contact:voice>+31.0612345678</contact:voice><contact:email>otten@sidn.nl</contact:email><contact:clID>400100</contact:clID><contact:crID>DEMEE</contact:crID><contact:crDate>2009-01-02T00:00:00.000+01:00</contact:crDate></contact:infData></resData><extension><urn1:ext xmlns:urn1="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><urn1:infData><urn1:contact><urn1:legalForm>EENMANSZAAK</urn1:legalForm><urn1:legalFormRegNo>8764654.0</urn1:legalFormRegNo><urn1:limited>true</urn1:limited></urn1:contact></urn1:infData></urn1:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_info($dri->local_object('contact')->srid('TST000033-DEMEE'));
$co=$rc->get_data('self');
is($co->legal_form(),'EENMANSZAAK','contact_info legal_form');
is($co->legal_id(),'8764654.0','contact_info legal_id');
is($co->limited(),1,'contact_info limited');

$co=$dri->local_object('contact')->srid('sh8013');
$co->name('Harry Jansen');
$co->org('De Klusjeman BV');
$co->street(['IJsselkade','100']);
$co->city('Amsterdam');
$co->sp('Limburg');
$co->pc('1234AA');
$co->cc('NL');
$co->voice('+31.612345678');
$co->fax('+31.204578274');
$co->email('epptestteam@sidn.nl');
$co->auth({pw => '2fooBAR'});
$co->disclose({voice => 0,email => 0});
$co->legal_form('EENMANSZAAK');
$co->legal_id('8764654.0');

$R2='';
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:postalInfo type="loc"><contact:name>Harry Jansen</contact:name><contact:org>De Klusjeman BV</contact:org><contact:addr><contact:street>IJsselkade</contact:street><contact:street>100</contact:street><contact:city>Amsterdam</contact:city><contact:sp>Limburg</contact:sp><contact:pc>1234AA</contact:pc><contact:cc>NL</contact:cc></contact:addr></contact:postalInfo><contact:voice>+31.612345678</contact:voice><contact:fax>+31.204578274</contact:fax><contact:email>epptestteam@sidn.nl</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><sidn:ext xmlns:sidn="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0" xsi:schemaLocation="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0 sidn-ext-epp-1.0.xsd"><sidn:create><sidn:contact><sidn:legalForm>EENMANSZAAK</sidn:legalForm><sidn:legalFormRegNo>8764654.0</sidn:legalFormRegNo></sidn:contact></sidn:create></sidn:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');

$R2='';
$co=$dri->local_object('contact')->srid('TEA000031-GOEDA');
$co->name('Herman Jansen');
$co->org('SIDN');
$co->street(['Street 1','Street 2','Street 3']);
$co->city('Arnhem');
$co->pc('1000AA');
$co->cc('NL');
$co->voice('+31.207654321');
$co->fax('+31.201234567');
$co->email('herman@epptestdomein.nl');
$co->legal_form('PERSOON');
$toc=$dri->local_object('changes');
$toc->set('info',$co);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>TEA000031-GOEDA</contact:id><contact:chg><contact:postalInfo type="loc"><contact:name>Herman Jansen</contact:name><contact:org>SIDN</contact:org><contact:addr><contact:street>Street 1</contact:street><contact:street>Street 2</contact:street><contact:street>Street 3</contact:street><contact:city>Arnhem</contact:city><contact:pc>1000AA</contact:pc><contact:cc>NL</contact:cc></contact:addr></contact:postalInfo><contact:voice>+31.207654321</contact:voice><contact:fax>+31.201234567</contact:fax><contact:email>herman@epptestdomein.nl</contact:email></contact:chg></contact:update></update><extension><sidn:ext xmlns:sidn="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0" xsi:schemaLocation="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0 sidn-ext-epp-1.0.xsd"><sidn:update><sidn:contact><sidn:legalForm>PERSOON</sidn:legalForm></sidn:contact></sidn:update></sidn:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');

####################################################################################################
## Host commands

$R2=$E1.'<response>'.r().'<resData><host:infData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><host:name>ns1.domain100.nl</host:name><host:roid>NSR_100-SIDN</host:roid><host:status s="ok"/><host:addr ip="v4">1.2.3.0</host:addr><host:clID>100000</host:clID><host:crID>100000</host:crID><host:crDate>2009-06-10T00:00:00.000+02:00</host:crDate><host:upID>100000</host:upID><host:upDate>2009-06-12T00:00:00.000+02:00</host:upDate></host:infData></resData><extension><urn1:ext xmlns:urn1="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><urn1:infData><urn1:host><urn1:limited>false</urn1:limited></urn1:host></urn1:infData></urn1:ext></extension>'.$TRID.'</response>'.$E2;

$rc=$dri->host_info('ns1.domain100.nl');
$h=$rc->get_data('self');
my @c=$h->get_details(1);
is_deeply($c[-1],{limited => 0},'host_info parse limited');

####################################################################################################
## Notifications

$R2=$E1.'<response>'.r(1301,'The message has been picked up. Please confirm receipt to remove the message from the queue.').'<msgQ count="9" id="100000"><qDate>2009-10-27T10:34:32.000Z</qDate><msg>1202 Change to name server ns1.bol.nl processed</msg></msgQ><resData><sidn-ext-epp:pollData xmlns:sidn-ext-epp="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><sidn-ext-epp:command>host:update</sidn-ext-epp:command><sidn-ext-epp:data><result code="1000"><msg>The name server has been changed after consideration.</msg></result><trID><clTRID>TestWZNMC10T50</clTRID><svTRID>100012</svTRID></trID></sidn-ext-epp:data></sidn-ext-epp:pollData></resData>'.$TRID.'</response>'.$E2;

$rc=$dri->message_retrieve();
is($rc->get_data('message',100000,'command'),'host_update','notification host:update command');
is($rc->get_data('message',100000,'object_type'),'host','notification host:update object_type');
is($rc->get_data('message',100000,'result_code'),'1000','notification host:update result_code');
is($rc->get_data('message',100000,'result_msg'),'The name server has been changed after consideration.','notification host:update result_msg');
is($rc->get_data('message',100000,'trid'),'TestWZNMC10T50','notification host:update cltrid');
is($rc->get_data('message',100000,'svtrid'),'100012','notification host:update svtrid');

exit 0;
