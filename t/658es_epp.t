#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 41;

use Data::Dumper;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }
#xmlns:es_creds="urn:red.es:xml:ns:es_creds-1.0"
our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';
our $ES_EXT = '<extension><es_creds:es_creds xmlns:es_creds="urn:red.es:xml:ns:es_creds-1.0" xsi:schemaLocation="urn:red.es:xml:ns:es_creds-1.0 es_creds-1.0"><es_creds:clID>LOGIN</es_creds:clID><es_creds:pw>PASSWORD</es_creds:pw></es_creds:es_creds></extension>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('ES');
$dri->target('ES')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{client_login=>'LOGIN',client_password=>'PASSWORD' });

my $rc;
my $s;
my $d;
my ($dh,@c);
my ($c,$cs,$ns);

####################################################################################################
## Tray / Bandeja Commands
$R2=$E1.'<response>'.r().'<resData xmlns:es_bandeja="urn:red.es:xml:ns:es_bandeja-1.0"><es_bandeja:mostrando>2</es_bandeja:mostrando><es_bandeja:total>2</es_bandeja:total><es_bandeja:infoData><es_bandeja:row><es_bandeja:fecha>2010-03-30T13:20:02</es_bandeja:fecha><es_bandeja:nombreDominio>qwerty.com.es</es_bandeja:nombreDominio><es_bandeja:tipoCategoria code="3">Renovación</es_bandeja:tipoCategoria><es_bandeja:tipoMensaje code="7">Renovación efectuada</es_bandeja:tipoMensaje></es_bandeja:row><es_bandeja:row><es_bandeja:fecha>2010-03-30T13:21:10</es_bandeja:fecha><es_bandeja:nombreDominio>dominio.com.es</es_bandeja:nombreDominio><es_bandeja:tipoCategoria code="3">Renovación</es_bandeja:tipoCategoria><es_bandeja:tipoMensaje code="7">Renovación efectuada</es_bandeja:tipoMensaje></es_bandeja:row></es_bandeja:infoData></resData>'.$TRID.'</response>'.$E2;
$rc = $dri->tray_info({fromDate => '2013-01-01', toDate => '2013-01-21', category => 10, type=>3,domain => 'test1.es'});
is($R1,$E1.'<command><info><es_bandeja:info xmlns:es_bandeja="urn:red.es:xml:ns:es_bandeja-1.0" xsi:schemaLocation="urn:red.es:xml:ns:es_bandeja-1.0 es_bandeja-1.0"><es_bandeja:fechaDesde>2013-01-01T00:00:00</es_bandeja:fechaDesde><es_bandeja:fechaHasta>2013-01-21T00:00:00</es_bandeja:fechaHasta><es_bandeja:nombreDominio>test1.es</es_bandeja:nombreDominio><es_bandeja:tipoCategoria>10</es_bandeja:tipoCategoria><es_bandeja:tipoMensaje>3</es_bandeja:tipoMensaje></es_bandeja:info></info>'.$ES_EXT.'<clTRID>ABC-12345</clTRID></command>'.$E2,'tray_info build');
my $last_id = $dri->get_info('last_id','message','session'); # FIXME, cant do $dri->get_info('last_id');
ok(defined($last_id),'tray get_info lastid');
is($dri->get_info('total','tray',$last_id),2,'tray get_info total');
is($dri->get_info('retrieved','tray',$last_id),2,'tray get_info retrieved');
while (my $next = $dri->get_info('next','tray',$last_id)->()) {
		ok(defined($next),'tray get_info next->()');
}
my $trayitems = $dri->get_info('items','tray',$last_id);
ok(defined($trayitems),'tray get_info trayitems');
is($trayitems->{1}->{qDate},'2010-03-30T13:21:10','tray_info get_info(qDate)');
is($trayitems->{1}->{domain},'dominio.com.es','tray_info get_info(qDate)');
is($trayitems->{1}->{category},'3','tray_info get_info(category)');

####################################################################################################
## Domain commands
#check
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">test1.es</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('test1.es');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test1.es</domain:name></domain:check></check>'.$ES_EXT.'<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','test1.es'),0,'domain_check get_info(exist) from cache');

#info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test1.es</domain:name><domain:crDate>2013-01-01T13:00:00.0</domain:crDate><domain:exDate>2014-01-01T13:00:00.0</domain:exDate><domain:es_codPeticion>0</domain:es_codPeticion><domain:ns>ns1.example.com</domain:ns><domain:ns>ns1.example.net</domain:ns><domain:registrant>12345</domain:registrant><domain:contact type="admin">12346</domain:contact><domain:contact type="billing">12348</domain:contact><domain:contact type="tech">12347</domain:contact><domain:authInfo><domain:pw>pass</domain:pw></domain:authInfo><domain:es_marca>123</domain:es_marca><domain:es_inscripcion>12355</domain:es_inscripcion><domain:es_accion_comercial>555</domain:es_accion_comercial><domain:autoRenew>true</domain:autoRenew></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_info('test1.es');
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">test1.es</domain:name></domain:info></info>'.$ES_EXT.'<clTRID>ABC-12345</clTRID></command></epp>', 'domain_info build');
is($rc->is_success(), 1, 'domain_info is success');
is($dri->get_info('exDate'),'2014-01-01T13:00:00','domain_info get_info(exDate)');
$ns = $dri->get_info('ns', 'domain', 'test1.es');
is(join(',', $ns->get_names()), 'ns1.example.com,ns1.example.net', 'domain_info get_info(ns)');
is($dri->get_info('marca'),'123','domain_info get_info(marca)');

#create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test1.es</domain:name><domain:crDate>2013-01-01T13:00:00.0</domain:crDate><domain:exDate>2014-01-01T13:00:00.0</domain:exDate><domain:es_codPeticion>0</domain:es_codPeticion><domain:autoRenew>true</domain:autoRenew></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('12345'), 'registrant');
$cs->add($dri->local_object('contact')->srid('12346'), 'admin');
$cs->add($dri->local_object('contact')->srid('12347'), 'tech');
$cs->add($dri->local_object('contact')->srid('12348'), 'billing');
$rc = $dri->domain_create('test1.es',{
	pure_create =>  1,
	contact =>	$cs,
	ns =>		$dri->local_object('hosts')->set(['ns1.example.com'],['ns1.example.net']),
	auth => { pw => 'pass'},
	marca => '123',
	inscripcion => '12355',
	accion_comercial => '555',
	auto_renew => 1,
	});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test1.es</domain:name><domain:ns>ns1.example.com</domain:ns><domain:ns>ns1.example.net</domain:ns><domain:registrant>12345</domain:registrant><domain:contact type="admin">12346</domain:contact><domain:contact type="billing">12348</domain:contact><domain:contact type="tech">12347</domain:contact><domain:authInfo><domain:pw>pass</domain:pw></domain:authInfo><domain:autoRenew>true</domain:autoRenew><domain:es_marca>123</domain:es_marca><domain:es_inscripcion>12355</domain:es_inscripcion><domain:es_accion_comercial>555</domain:es_accion_comercial></domain:create></create>'.$ES_EXT.'<clTRID>ABC-12345</clTRID></command></epp>', 'domain_create build');
is($rc->is_success(), 1, 'domain_create is success');
is($dri->get_info('exDate'),'2014-01-01T13:00:00','domain_create get_info(exDate)');

#update
undef $R2;
my $changes = $dri->local_object('changes');
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('98765'), 'tech');
$changes->add('contact', $cs);
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('12347'), 'tech');
$changes->del('contact', $cs);
$changes->add('ns',$dri->local_object('hosts')->set(['ns3.example.info']));
$changes->add('auto_renew','no');
$changes->del('auto_renew','yes');
$rc = $dri->domain_update('test1.es', $changes);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test1.es</domain:name><domain:add><domain:ns>ns3.example.info</domain:ns><domain:contact type="tech">98765</domain:contact><domain:autoRenew>false</domain:autoRenew></domain:add><domain:rem><domain:contact type="tech">12347</domain:contact><domain:autoRenew>true</domain:autoRenew></domain:rem></domain:update></update>'.$ES_EXT.'<clTRID>ABC-12345</clTRID></command></epp>', 'domain_update build');
is($rc->is_success(), 1, 'domain_update is success');

#renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test1.es</domain:name><domain:exDate>2015-01-01T00:00:00.01</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
my $du = DateTime::Duration->new( years => 2);
my $exp = DateTime->new(year  => 2013,month => 01,day   => 01);
$rc = $dri->domain_renew('test1.es',{duration=>$du,current_expiration=>$exp} );
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test1.es</domain:name><domain:curExpDate>2013-01-01T00:00:00.01</domain:curExpDate><domain:period unit="y">2</domain:period><domain:renewOp>accept</domain:renewOp></domain:renew></renew>'.$ES_EXT.'<clTRID>ABC-12345</clTRID></command></epp>', 'domain_renew build');
is($rc->is_success(), 1, 'domain_renew is success');
is($dri->get_info('exDate'),'2015-01-01T00:00:00','domain_renew get_info(exDate)');

#delete - not testing because its not modified

#transfer
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test1.es</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>re123</domain:reID><domain:reDate>2013-03-06T02:45:23</domain:reDate><domain:acID>ac32</domain:acID><domain:acDate>2013-04-01T13:00:00</domain:acDate><domain:exDate>2015-01-01T00:00:00.00</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_transfer_start('test1.es',{auto_renew=>'no'} );
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test1.es</domain:name><domain:autoRenew>false</domain:autoRenew></domain:transfer></transfer>'.$ES_EXT.'<clTRID>ABC-12345</clTRID></command></epp>', 'domain_transfer_start build');
is($rc->is_success(), 1, 'domain_transfer_start is success');
is($dri->get_info('acDate'),'2013-04-01T13:00:00','domain_transfer_start get_info(acDate)');

####################################################################################################
## Contact Commands

#check
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="true">12345</contact:id></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$rc = $dri->contact_check($dri->local_object('contact')->srid('12345'));
is($R1, $E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>12345</contact:id></contact:check></check>'.$ES_EXT.'<clTRID>ABC-12345</clTRID></command></epp>', 'contact_check build');
is($rc->is_success(), 1, 'contact_check is_success');
is($dri->get_info('exist', 'contact', '12345'), 0, 'contact_check : contact does not exist');

#info
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>12345</contact:id><contact:roid>12345</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Mike Ekim</contact:name><contact:org>Ekim Inc</contact:org><contact:addr><contact:street>123 Long Road</contact:street><contact:city>Boglog</contact:city><contact:pc>BG123</contact:pc><contact:cc>ES</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.1234561</contact:voice><contact:fax>+1.1234569</contact:fax><contact:email>mike@ekim.es</contact:email><contact:es_tipo_identificacion>1</contact:es_tipo_identificacion><contact:es_identificacion>ME123</contact:es_identificacion></contact:infData></resData>'.$TRID.'</response>'.$E2;
$rc = $dri->contact_info($dri->local_object('contact')->srid('12345'));
is($R1, $E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>12345</contact:id></contact:info></info>'.$ES_EXT.'<clTRID>ABC-12345</clTRID></command></epp>', 'contact_info build');
is($rc->is_success(), 1, 'contact_info is_success');
$c = $dri->get_info('self', 'contact', '12345');
isa_ok($c, 'Net::DRI::Data::Contact::ES');
is($c->tipo_identificacion(),1,'contact_info get_info');

#create
$c = $dri->local_object('contact');
$c->srid(12345);
$c->name('Mike Ekim');
$c->org('Ekim Inc');
$c->street(['123 Long Road']);
$c->pc('BG123');
$c->city('Boglog');
$c->cc('ES');
$c->voice('+1.1234561');
$c->fax('+1.1234569');
$c->email('mike@ekim.es');
$c->tipo_identificacion(1);
$c->identificacion('ME123');
$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>12345</contact:id><contact:crDate>2009-10-14T14:48:35.0</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$rc = $dri->contact_create($c);
is($R1, $E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:postalInfo type="loc"><contact:name>Mike Ekim</contact:name><contact:org>Ekim Inc</contact:org><contact:addr><contact:street>123 Long Road</contact:street><contact:city>Boglog</contact:city><contact:pc>BG123</contact:pc><contact:cc>ES</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.1234561</contact:voice><contact:email>mike@ekim.es</contact:email><contact:es_tipo_identificacion>1</contact:es_tipo_identificacion><contact:es_identificacion>ME123</contact:es_identificacion></contact:create></create>'.$ES_EXT.'<clTRID>ABC-12345</clTRID></command></epp>', 'contact_create build');
is($rc->is_success(), 1, 'contact_create is_success');


#update - not supported by es

####################################################################################################

####################################################################################################
## Host commands
#create
$rc=$dri->host_create($dri->local_object('hosts')->add('ns14.testepp.es',['192.168.0.14'],['2001:0DB8:02de::0e13'],1));
is($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns14.testepp.es</host:name><host:addr ip="v4">192.168.0.14</host:addr><host:addr ip="v6">2001:0DB8:02de::0e13</host:addr></host:create></create><extension><es_creds:es_creds xmlns:es_creds="urn:red.es:xml:ns:es_creds-1.0" xsi:schemaLocation="urn:red.es:xml:ns:es_creds-1.0 es_creds-1.0"><es_creds:clID>LOGIN</es_creds:clID><es_creds:pw>PASSWORD</es_creds:pw></es_creds:es_creds></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create build');
####################################################################################################

exit(0);
