#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 12;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('NGTLD',{provider => 'tci',name=>'tci_gtld'});
$dri->target('tci_gtld')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$c,$co,$cs,$dom_name,$tin,$toc);
my %legalAddr = ();

##################### 
## Contact Extension

# creating a contact for a legal entity
$co = $dri->local_object('contact')->new()->srid('h3PA2YBl-vrdev');
$tin = 123456789; # this is a mandatory attribute for organizations
$co->voice('+7.4951241438');
$co->email('someone@tcinet.ru');
$co->name(['ООО ААА']);
$co->org(['ООО ААА']);
$co->street(['ая 101', '', '']);
$co->city(['Москва']);
$co->sp(['Москва']);
$co->pc(['107140']);
$co->cc(['RU']);
$co->auth({pw=>'EujGiCwW5UwzikUw'});
# Extension
%legalAddr = (legalAddr=>
                {
                  street=>([['ая 101']]),
                  city=>(['Москва']),
                  sp=>(['Москва']),
                  pc=>(['107140']),
                  cc=>(['RU'])
                });
$co->organization({%legalAddr,TIN=>$tin});
$R2='';
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>h3PA2YBl-vrdev</contact:id><contact:postalInfo type="loc"><contact:name>ООО ААА</contact:name><contact:org>ООО ААА</contact:org><contact:addr><contact:street>ая 101</contact:street><contact:street/><contact:street/><contact:city>Москва</contact:city><contact:sp>Москва</contact:sp><contact:pc>107140</contact:pc><contact:cc>RU</contact:cc></contact:addr></contact:postalInfo><contact:voice>+7.4951241438</contact:voice><contact:email>someone@tcinet.ru</contact:email><contact:authInfo><contact:pw>EujGiCwW5UwzikUw</contact:pw></contact:authInfo></contact:create></create><extension><contact:create xmlns:contact="http://www.tcinet.ru/epp/tci-contact-ext-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-contact-ext-1.0 tci-contact-ext-1.0.xsd"><contact:organization><contact:legalAddr type="loc"><contact:street>ая 101</contact:street><contact:city>Москва</contact:city><contact:sp>Москва</contact:sp><contact:pc>107140</contact:pc><contact:cc>RU</contact:cc></contact:legalAddr><contact:TIN>123456789</contact:TIN></contact:organization></contact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create for a legal entity build');
is($rc->is_success(),1,'contact_create for a legal entity is_success');

# creating a contact for an individual
$co = $dri->local_object('contact')->new()->srid('con-1-1384434788');
$tin = 123456789; # this is not a mandatory attribute for individuals. It may be left blank
$co->voice('+7.4951234567x123');
$co->fax('+7.4950004567x123');
$co->email('test@test.ru');
$co->name(['Тестов Тест Тестович','Testov T Test']);
$co->street(['Проспект Мира', 'дом 32', 'строение 6'],['Procpect of Peace','32','building 6']);
$co->city(['Москва','Мoscow']);
$co->sp(['Русский Федерация','Russian Federation']);
$co->pc(['122345','122345']);
$co->cc(['ru','ru']);
$co->auth({pw=>'password'});
# Extension
$co->person({ birthday=>'1970-11-11', passport=>'строка паспорта', TIN=>'444444444444444' });
$R2='';
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>con-1-1384434788</contact:id><contact:postalInfo type="loc"><contact:name>Тестов Тест Тестович</contact:name><contact:addr><contact:street>Проспект Мира</contact:street><contact:street>дом 32</contact:street><contact:street>строение 6</contact:street><contact:city>Москва</contact:city><contact:sp>Русский Федерация</contact:sp><contact:pc>122345</contact:pc><contact:cc>ru</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>Testov T Test</contact:name><contact:addr><contact:street>Procpect of Peace</contact:street><contact:street>32</contact:street><contact:street>building 6</contact:street><contact:city>Мoscow</contact:city><contact:sp>Russian Federation</contact:sp><contact:pc>122345</contact:pc><contact:cc>ru</contact:cc></contact:addr></contact:postalInfo><contact:voice x="123">+7.4951234567</contact:voice><contact:fax x="123">+7.4950004567</contact:fax><contact:email>test@test.ru</contact:email><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:create></create><extension><contact:create xmlns:contact="http://www.tcinet.ru/epp/tci-contact-ext-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-contact-ext-1.0 tci-contact-ext-1.0.xsd"><contact:person><contact:birthday>1970-11-11</contact:birthday><contact:passport>строка паспорта</contact:passport><contact:TIN>444444444444444</contact:TIN></contact:person></contact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create for an individual build');
is($rc->is_success(),1,'contact_create for an individual is_success');

# update individual contact (change element) - extension mandatory (using the same info used before...)
$c = $dri->local_object('contact')->new()->srid('CLDC1');
$toc = $dri->local_object('changes');
$c->person({birthday=>'1986-11-10',passport=>'01 23 123456, выдан ОВД энского р-на'});
$co = $dri->local_object('contact');
$co->voice('+7.4951234567');
$co->person({birthday=>'1986-11-10',passport=>'01 23 123456, выдан ОВД энского р-на'});
$co->person();
$toc->set('info',$co);
$rc=$dri->contact_update($c,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>CLDC1</contact:id><contact:chg><contact:voice>+7.4951234567</contact:voice></contact:chg></contact:update></update><extension><contact:update xmlns:contact="http://www.tcinet.ru/epp/tci-contact-ext-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-contact-ext-1.0 tci-contact-ext-1.0.xsd"><contact:chg><contact:person><contact:birthday>1986-11-10</contact:birthday><contact:passport>01 23 123456, выдан ОВД энского р-на</contact:passport></contact:person></contact:chg></contact:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update (change element) for an individual build');
is($rc->is_success(),1,'contact_update (change element) for an individual is_success');

# update organization contact (add element)
%legalAddr = (legalAddr=>
                {
                  street=>([['ул. Примерная,','д. 98',''],['98,','Primernaya st.','']]),
                  city=>(['Москва','Моsсow']),
                  pc=>(['123456','123456']),
                  cc=>(['ru','ru'])
                });
$c = $dri->local_object('contact')->srid('CLDC2');
$c->organization({%legalAddr,TIN=>1234567890});
$toc = $dri->local_object('changes');
$toc->add('status',$dri->local_object('status')->no('delete'));
$rc = $dri->contact_update($c,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>CLDC2</contact:id><contact:add><contact:status s="clientDeleteProhibited"/></contact:add></contact:update></update><extension><contact:update xmlns:contact="http://www.tcinet.ru/epp/tci-contact-ext-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-contact-ext-1.0 tci-contact-ext-1.0.xsd"><contact:chg><contact:organization><contact:legalAddr type="loc"><contact:street>ул. Примерная,</contact:street><contact:street>д. 98</contact:street><contact:street/><contact:city>Москва</contact:city><contact:pc>123456</contact:pc><contact:cc>ru</contact:cc></contact:legalAddr><contact:legalAddr type="int"><contact:street>98,</contact:street><contact:street>Primernaya st.</contact:street><contact:city>Моsсow</contact:city><contact:pc>123456</contact:pc><contact:cc>ru</contact:cc></contact:legalAddr><contact:TIN>1234567890</contact:TIN></contact:organization></contact:chg></contact:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update (add element) for a organization build');
is($rc->is_success(),1,'contact_update (add element) for a organization is_success');

# update organization contact (remove element)
$c = $dri->local_object('contact')->srid('CLDC2');
$c->organization({%legalAddr,TIN=>1234567890});
$toc = $dri->local_object('changes');
$toc->del('status',$dri->local_object('status')->no('delete'));
$rc = $dri->contact_update($c,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>CLDC2</contact:id><contact:rem><contact:status s="clientDeleteProhibited"/></contact:rem></contact:update></update><extension><contact:update xmlns:contact="http://www.tcinet.ru/epp/tci-contact-ext-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-contact-ext-1.0 tci-contact-ext-1.0.xsd"><contact:chg><contact:organization><contact:legalAddr type="loc"><contact:street>ул. Примерная,</contact:street><contact:street>д. 98</contact:street><contact:street/><contact:city>Москва</contact:city><contact:pc>123456</contact:pc><contact:cc>ru</contact:cc></contact:legalAddr><contact:legalAddr type="int"><contact:street>98,</contact:street><contact:street>Primernaya st.</contact:street><contact:city>Моsсow</contact:city><contact:pc>123456</contact:pc><contact:cc>ru</contact:cc></contact:legalAddr><contact:TIN>1234567890</contact:TIN></contact:organization></contact:chg></contact:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update (remove element) for a organization build');
is($rc->is_success(),1,'contact_update (remove element) for a organization is_success');

#####################
## Domain Extension

# If we need to register a new domain using DNSSEC the <secDNS:keyData> element is mandatory for this Registry (optional element rfc5910 - 4.1 DS Data Interface)
$R2=$E1.'<greeting><svID>uap.tcinet.ru</svID><svDate>2014-11-10T10:17:48.675Z</svDate><svcMenu><version>1.0</version><lang>ru</lang><lang>en</lang><objURI>urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd</objURI><objURI>urn:ietf:params:xml:ns:eppcom-1.0 eppcom-1.0.xsd</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd</objURI><objURI>urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd</extURI><extURI>http://www.tcinet.ru/epp/tci-contact-ext-1.0 tci-contact-ext-1.0.xsd</extURI><extURI>http://www.tcinet.ru/epp/tci-domain-ext-1.0 tci-domain-ext-1.0.xsd</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]); # greeting to load correct version of secDNS-1.1
$dom_name = 'xn--j1aefbet.xn--80adxhks'; # компот.москва
$cs = $dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('CLDC2'),'registrant');
$cs->set($dri->local_object('contact')->srid('CLDC4'),'admin');
$cs->set($dri->local_object('contact')->srid('CLDC5'),'tech');
$rc = $dri->domain_create($dom_name,
  {
    pure_create=>1,
    duration=>DateTime::Duration->new(years=>'1'),
    contact=>$cs,
    auth=>{pw=>'fooBar'},
    description=>'testing domain description extension',
    secdns=>
    [{
      keyTag=>52143,
      alg=>5,
      digestType=>2, # SHA256 (RFC 4509)
      digest=>'53366012E847CD6136EED5C5BEF796E02B3B02829AC7810C5339EDC1A1912850',
      key_pubKey=>'AwEAAdROg/rGvUCdTNxcbZKamEHh6d/75eKn7tq1BrL5YTiWnTEdP/CX WxRImC+3XqhZpPfb82IMvIiZ/FXfo6x4S6wa6UPsF++dHNTm5dbvc9gw sPG1aX8WMLEQrvRHztQ8vyvqT2FEiXt61hTq37NFV+TS5rHRvwnCUo/a YpV7C2pr',
      key_alg=>5, # RSASHA1
      key_flags=>256,
      key_protocol=>3
    }]
  });
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--j1aefbet.xn--80adxhks</domain:name><domain:period unit="y">1</domain:period><domain:registrant>CLDC2</domain:registrant><domain:contact type="admin">CLDC4</domain:contact><domain:contact type="tech">CLDC5</domain:contact><domain:authInfo><domain:pw>fooBar</domain:pw></domain:authInfo></domain:create></create><extension><domain:create xmlns:domain="http://www.tcinet.ru/epp/tci-domain-ext-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-domain-ext-1.0 tci-domain-ext-1.0.xsd"><domain:description>testing domain description extension</domain:description></domain:create><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:dsData><secDNS:keyTag>52143</secDNS:keyTag><secDNS:alg>5</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>53366012E847CD6136EED5C5BEF796E02B3B02829AC7810C5339EDC1A1912850</secDNS:digest><secDNS:keyData><secDNS:flags>256</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>5</secDNS:alg><secDNS:pubKey>AwEAAdROg/rGvUCdTNxcbZKamEHh6d/75eKn7tq1BrL5YTiWnTEdP/CX WxRImC+3XqhZpPfb82IMvIiZ/FXfo6x4S6wa6UPsF++dHNTm5dbvc9gw sPG1aX8WMLEQrvRHztQ8vyvqT2FEiXt61hTq37NFV+TS5rHRvwnCUo/a YpV7C2pr</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create (DNSSEC)build');
is($rc->is_success(),1,'domain_create (DNSSEC) is_success');

exit 0;
