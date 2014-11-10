#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 4;
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

my ($rc,$co,$tin);
my %legalAddr;

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
is($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>h3PA2YBl-vrdev</contact:id><contact:postalInfo type="loc"><contact:name>ООО ААА</contact:name><contact:org>ООО ААА</contact:org><contact:addr><contact:street>ая 101</contact:street><contact:street/><contact:street/><contact:city>Москва</contact:city><contact:sp>Москва</contact:sp><contact:pc>107140</contact:pc><contact:cc>RU</contact:cc></contact:addr></contact:postalInfo><contact:voice>+7.4951241438</contact:voice><contact:email>someone@tcinet.ru</contact:email><contact:authInfo><contact:pw>EujGiCwW5UwzikUw</contact:pw></contact:authInfo></contact:create></create><extension><contact:create xmlns:contact="http://www.tcinet.ru/epp/tci-contact-ext-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-contact-ext-1.0 tci-contact-ext-1.0.xsd"><contact:organization><contact:legalAddr type="loc"><contact:street>ая 101</contact:street><contact:city>Москва</contact:city><contact:sp>Москва</contact:sp><contact:pc>107140</contact:pc><contact:cc>RU</contact:cc></contact:legalAddr><contact:TIN>123456789</contact:TIN></contact:organization></contact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create for a legal entity build');
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
is($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>con-1-1384434788</contact:id><contact:postalInfo type="loc"><contact:name>Тестов Тест Тестович</contact:name><contact:addr><contact:street>Проспект Мира</contact:street><contact:street>дом 32</contact:street><contact:street>строение 6</contact:street><contact:city>Москва</contact:city><contact:sp>Русский Федерация</contact:sp><contact:pc>122345</contact:pc><contact:cc>ru</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>Testov T Test</contact:name><contact:addr><contact:street>Procpect of Peace</contact:street><contact:street>32</contact:street><contact:street>building 6</contact:street><contact:city>Мoscow</contact:city><contact:sp>Russian Federation</contact:sp><contact:pc>122345</contact:pc><contact:cc>ru</contact:cc></contact:addr></contact:postalInfo><contact:voice x="123">+7.4951234567</contact:voice><contact:fax x="123">+7.4950004567</contact:fax><contact:email>test@test.ru</contact:email><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:create></create><extension><contact:create xmlns:contact="http://www.tcinet.ru/epp/tci-contact-ext-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tcinet.ru/epp/tci-contact-ext-1.0 tci-contact-ext-1.0.xsd"><contact:person><contact:birthday>1970-11-11</contact:birthday><contact:passport>строка паспорта</contact:passport><contact:TIN>444444444444444</contact:TIN></contact:person></contact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create for an individual build');
is($rc->is_success(),1,'contact_create for an individual is_success');

# TODO: add SecDNS tests. <secDNS:keyData> element is mandatory for this Registry. Optional element rfc5910 - 4.1 DS Data Interface


exit 0;
