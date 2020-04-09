#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use Test::More tests => 76;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('InternetNZ');
$dri->target('InternetNZ')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my ($rc,$s,$d,$dh,@c,$c1,$c2,$co,$co2,$cs,$toc);


### Contact commands ###

## contact:check - multi
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns="urn:ietf:params:xml:ns:contact-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:cd><contact:id avail="1">example</contact:id></contact:cd><contact:cd><contact:id avail="0">test</contact:id><contact:reason>In use</contact:reason></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_check(map { $dri->local_object('contact')->srid($_) } ('example','test'));
is_string($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>example</contact:id><contact:id>test</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check build');
is($rc->is_success(),1,'contact_check multi is_success');

## contact:create
$R2='';
$co=$dri->local_object('contact')->srid('abc1');
$co->name('John Doe');
$co->street(['Sample Building','Example street, 5-7']);
$co->city('Cityname');
$co->pc('1234');
$co->cc('NZ');
$co->voice('+64.44721600');
$co->fax('+64.49316979');
$co->email('support@example.co.nz');
$co->auth({pw=>''});
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>abc1</contact:id><contact:postalInfo type="int"><contact:name>John Doe</contact:name><contact:addr><contact:street>Sample Building</contact:street><contact:street>Example street, 5-7</contact:street><contact:city>Cityname</contact:city><contact:pc>1234</contact:pc><contact:cc>NZ</contact:cc></contact:addr></contact:postalInfo><contact:voice>+64.44721600</contact:voice><contact:fax>+64.49316979</contact:fax><contact:email>support@example.co.nz</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');

## contact:info
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>con12345</contact:id><contact:roid>12345-NZRS</contact:roid><contact:status s="ok"/><contact:postalInfo type="int"><contact:name>Smith Jane</contact:name><contact:addr><contact:street>Exchange Place</contact:street><contact:street>Willeston Street, 5-7</contact:street><contact:city>Wellington</contact:city><contact:pc>1234</contact:pc><contact:cc>NZ</contact:cc></contact:addr></contact:postalInfo><contact:voice>+64.44721600</contact:voice><contact:fax>+64.49316979</contact:fax><contact:email>support@nzrs.net.nz</contact:email><contact:clID>90</contact:clID><contact:crID>90</contact:crID><contact:crDate>2008-12-21T10:02:45.514Z</contact:crDate></contact:infData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('con12345');
$rc=$dri->contact_info($co);
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>con12345</contact:id></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'con12345','contact_info get_info(self) srid');
is($co->roid(),'12345-NZRS','contact_info get_info(self) roid');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'contact_info get_info(status) list_status');
is(($co->name())[1],'Smith Jane','contact_info get_info(self) name');
is_deeply(($co->street())[1],['Exchange Place','Willeston Street, 5-7'],'contact_info get_info(self) street');
is(($co->city())[1],'Wellington','contact_info get_info(self) city');
is(($co->pc())[1],'1234','contact_info get_info(self) pc');
is(($co->cc())[1],'NZ','contact_info get_info(self) cc');
is($co->voice(),'+64.44721600','contact_info get_info(self) voice');
is($co->fax(),'+64.49316979','contact_info get_info(self) fax');
is($co->email(),'support@nzrs.net.nz','contact_info get_info(self) email');
is($dri->get_info('clID'),'90','contact_info get_info(clID)');
is($dri->get_info('crID'),'90','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is("".$d,'2008-12-21T10:02:45','contact_info get_info(crDate) value');

## contact:update
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('con12345');
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->street(['New Building','New Street 123']);
$co2->city('New City');
$co2->pc('1111');
$co2->cc('AU');
$co2->voice('+61.12345678');
$co2->fax('');
$co2->email('support@nzrs.net.nz');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);

is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>con12345</contact:id><contact:chg><contact:postalInfo type="int"><contact:addr><contact:street>New Building</contact:street><contact:street>New Street 123</contact:street><contact:city>New City</contact:city><contact:pc>1111</contact:pc><contact:cc>AU</contact:cc></contact:addr></contact:postalInfo><contact:voice>+61.12345678</contact:voice><contact:fax/><contact:email>support@nzrs.net.nz</contact:email></contact:chg></contact:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');

## contact:delete
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->contact_delete($dri->local_object('contact')->srid('con3846'));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><delete><contact:delete xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>con3846</contact:id></contact:delete></delete><clTRID>ABC-12345</clTRID></command></epp>','contact_delete build');
is($rc->is_success(),1,'contact_delete is_success');


### Domain commands ###

## domain:check
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="0">example.co.nz</domain:name></domain:cd><domain:cd><domain:name avail="1">availabledomain.co.nz</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example.co.nz','availabledomain.co.nz');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.co.nz</domain:name><domain:name>availabledomain.co.nz</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','example.co.nz'),1,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','availabledomain.co.nz'),0,'domain_check multi get_info(exist) 2/2');

## domain:create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>mytestdomain.co.nz</domain:name><domain:crDate>2008-01-01T12:07:06.978Z</domain:crDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('con3846');
$c2=$dri->local_object('contact')->srid('con3248');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$dh=$dri->local_object('hosts');
$dh->add('ns.server.co.nz');
$dh->add('ns.mytestdomain.co.nz',['192.0.32.10']);
$rc=$dri->domain_create('mytestdomain.co.nz',{pure_create=>1,duration=>DateTime::Duration->new(months=>3),ns=>$dh,contact=>$cs});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>mytestdomain.co.nz</domain:name><domain:period unit="m">3</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns.server.co.nz</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.mytestdomain.co.nz</domain:hostName><domain:hostAddr ip="v4">192.0.32.10</domain:hostAddr></domain:hostAttr></domain:ns><domain:registrant>con3846</domain:registrant><domain:contact type="admin">con3248</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'2008-01-01T12:07:06','domain_create get_info(crDate) value');

## domain:info
# before starting tests for <domain:info> send greeting to load correct version of secDNS. Default on Net-DRI is secDNS-1.0. If the server return secDNS-1.1 the version change!
$R2=$E1.'<greeting><svID>srsepp.srs.net.nz</svID><svDate>2008-12-20T09:50:21+00:00</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:epp:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:epp:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcMenu><dcp><access><personalAndOther/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/></recipient><retention><business/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]); # greeting to load correct version of secDNS-1.1
# continue test for <domain:info>
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns="urn:ietf:params:xml:ns:domain-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>dnssec-epptest4.ac.nz</domain:name><domain:roid>f6f69cc74faa-DOM</domain:roid><domain:status lang="en" s="ok"/><domain:registrant>dbconepp1</domain:registrant><domain:contact type="admin">dbconepp1</domain:contact><domain:contact type="tech">dbconepp1</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns1.dnssec-epptest4.ac.nz</domain:hostName><domain:hostAddr ip="v4">1.2.3.4</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr></domain:ns><domain:clID>922</domain:clID><domain:crDate>2014-11-13T13:05:26+13:00</domain:crDate><domain:upID>922</domain:upID><domain:upDate>2014-11-14T09:10:09+13:00</domain:upDate><domain:exDate>2015-09-13T13:05:26+12:00</domain:exDate></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:dsData><secDNS:keyTag>23403</secDNS:keyTag><secDNS:alg>7</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>82E4E46622B646086C1051A6093DEB897BD1C022</secDNS:digest></secDNS:dsData></secDNS:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('dnssec-epptest4.ac.nz',{auth=>{pw=>'cFaHPPQc'}});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name hosts="all">dnssec-epptest4.ac.nz</domain:name><domain:authInfo><domain:pw>cFaHPPQc</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build with auth');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'f6f69cc74faa-DOM','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'dbconepp1','domain_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'dbconepp1','domain_info get_info(contact) admin srid');
is($s->get('tech')->srid(),'dbconepp1','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.dnssec-epptest4.ac.nz'],'domain_info get_info(ns) get_names');
@c=$dh->get_details(1);
is($c[0],'ns1.dnssec-epptest4.ac.nz','domain_info get_info(ns) get_details(1) 0-name');
is_deeply($c[1],['1.2.3.4'],'domain_info get_info(ns) get_details(1) 1-ipv4');
is_deeply($c[2],['1080:0:0:0:8:800:200C:417A'],'domain_info get_info(ns) get_details(1) 2-ipv6');
is($dri->get_info('clID'),'922','domain_info get_info(clID)');
is($dri->get_info('upID'),'922','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'2014-11-13T13:05:26','domain_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is("".$d,'2014-11-14T09:10:09','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2015-09-13T13:05:26','domain_info get_info(exDate) value');
# domain extension (dnssec)
is_deeply($rc->get_data('secdns'),[{keyTag=>23403,alg=>7,digestType=>1,digest=>'82E4E46622B646086C1051A6093DEB897BD1C022'}],'domain_info parse secDNS-1.1 dsData with keyData');

## domain update
$R2='';
$toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->set('ns.whatever.co.nz'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('54321'),'tech');
$toc->add('contact',$cs);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('12345'),'tech');
$toc->del('contact',$cs);
$rc=$dri->domain_update('mytestdomain.co.nz',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>mytestdomain.co.nz</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>ns.whatever.co.nz</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="tech">54321</domain:contact></domain:add><domain:rem><domain:contact type="tech">12345</domain:contact></domain:rem></domain:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');
## domain update (secDNS-1.1)
$R2='';
$toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->add('ns2.dnssec-epptest4.ac.nz',['1.2.3.4'],['1080:0:0:0:8:800:200C:417A'],1));
$toc->add('secdns',{keyTag=>1,alg=>7,digestType=>2,digest=>'85DB78AF90EB23B5B346528482ABA500A445DDB40F5BE2F04911EE7CF7CF2335'});
$rc=$dri->domain_update('dnssec-epptest4.ac.nz',$toc);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>dnssec-epptest4.ac.nz</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>ns2.dnssec-epptest4.ac.nz</domain:hostName><domain:hostAddr ip="v4">1.2.3.4</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr></domain:ns></domain:add></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:add><secDNS:dsData><secDNS:keyTag>1</secDNS:keyTag><secDNS:alg>7</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>85DB78AF90EB23B5B346528482ABA500A445DDB40F5BE2F04911EE7CF7CF2335</secDNS:digest></secDNS:dsData></secDNS:add></secDNS:update></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update secDNS-1.1 build');

## domain delete
# NOTE: To re-instate a domain name (.NZ) a simple update command needs to be sent. Please check the Update Domain command.
$R2='';
$rc=$dri->domain_delete('testdomain.co.nz');
is_string($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>testdomain.co.nz</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build');
is($rc->is_success(),1,'domain_delete is_success');

## domain transfer
# Note: The op attribute value of a .nz EPP transfer command can only be "request".
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('example.co.nz',{auth=>{pw=>'ABCD1234'}});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.co.nz</domain:name><domain:authInfo><domain:pw>ABCD1234</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_start build');
is($rc->is_success(),1,'domain_transfer_start is_success');

## domain renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.nz</domain:name><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('example.nz',{duration => DateTime::Duration->new(years=>5), current_expiration => DateTime->new(year=>2000,month=>4,day=>3)});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.nz</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is("".$d,'2005-04-03T22:00:00','domain_renew get_info(exDate) value');

exit 0;
