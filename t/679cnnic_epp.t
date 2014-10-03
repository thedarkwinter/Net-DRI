#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use Data::Dumper;


use Test::More tests => 48;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('NGTLD',{provider=>'cnnic',tlds=>['xn--fiqs8s']}); # This TLD is used for testing only as it was used in the documentation
$dri->target('cnnic')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my ($dh,$command,$cdn,@c,$toc,$c1,$c2,$cr,$h);

################################################################################
### Registry And Contact Extensions

# Contact create
$c1 = $dri->local_object('contact');
$c1->srid('abcde')->name('abc')->org('abc.org')->street(['123 d street'])->city('reston')->pc(20194)->sp('NY')->cc('US')->fax('+1.2345678901x1234')->email('xxx@yyy.com')->auth({pw => 123456});
$c1->type('SFZ');
$c1->code('110101190001010001');
$rc=$dri->contact_create($c1,{registry=>'cnnic'});
is($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>abcde</contact:id><contact:postalInfo type="loc"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:fax x="1234">+1.2345678901</contact:fax><contact:email>xxx@yyy.com</contact:email><contact:authInfo><contact:pw>123456</contact:pw></contact:authInfo></contact:create></create><extension><cnnic-registry:create xmlns:cnnic-registry="urn:ietf:params:xml:ns:cnnic-registry-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-registry-1.0 cnnic-registry-1.0.xsd"><cnnic-registry:registry>cnnic</cnnic-registry:registry></cnnic-registry:create><cnnic-contact:create xmlns:cnnic-contact="urn:ietf:params:xml:ns:cnnic-contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-contact-1.0 cnnic-contact-1.0.xsd"><cnnic-contact:contact type="SFZ">110101190001010001</cnnic-contact:contact></cnnic-contact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build_xml');

# Contact update
$c2 = $c1->clone();
$c2->type('JGZ');
$c2->code('55555555');
$toc = $dri->local_object('changes');
$toc->set('info',$c2);
$rc=$dri->contact_update($c1,$toc);
is($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>abcde</contact:id><contact:chg><contact:postalInfo type="loc"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:fax x="1234">+1.2345678901</contact:fax><contact:email>xxx@yyy.com</contact:email><contact:authInfo><contact:pw>123456</contact:pw></contact:authInfo></contact:chg></contact:update></update><extension><cnnic-contact:update xmlns:cnnic-contact="urn:ietf:params:xml:ns:cnnic-contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-contact-1.0 cnnic-contact-1.0.xsd"><cnnic-contact:chg><cnnic-contact:contact type="JGZ">55555555</cnnic-contact:contact></cnnic-contact:chg></cnnic-contact:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_updatre nexus build_xml');

# Contact info
$R2 = $E1 . '<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>abcde</contact:id></contact:infData></resData><extension><cnnic-registry:infData xmlns:cnnic-registry="urn:ietf:params:xml:ns:cnnic-registry-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-registry-1.0 cnnic-registry-1.0.xsd"><cnnic-registry:registry>cnnic</cnnic-registry:registry></cnnic-registry:infData><cnnic-contact:infData xmlns:cnnic-contact="urn:ietf:params:xml:ns:cnnic-contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-contact-1.0 cnnic-contact-1.0.xsd"><cnnic-contact:contact type="SFZ">110101190001010001</cnnic-contact:contact></cnnic-contact:infData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->contact_info($dri->local_object('contact')->srid('abcde'));
is_string($R1,$E1 . '<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>abcde</contact:id></contact:info></info><clTRID>ABC-12345</clTRID></command>' . $E2,'contact_info build');
$cr=$dri->get_info('self');
isa_ok($cr,'Net::DRI::Data::Contact::CNNIC','contact_info get_info (self)');
is($cr->type(),'SFZ','contact_info get_info (type)');
is($cr->code(),'110101190001010001','contact_info get_info (code)');
is($dri->get_info('registry'),'cnnic','contact_info get_info (registry)');

# Host create
$R2=$E1.'<response>'.r().'<resData><host:creData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns101.example1.com</host:name><host:crDate>1999-04-03T22:00:00.0Z</host:crDate></host:creData></resData>'.$TRID.'</response>'.$E2;
$h = $dri->local_object('hosts')->add('ns101.example1.com',['193.0.2.2','193.0.2.29'],['2000:0:0:0:8:800:200C:417A']);
$rc=$dri->host_create($h,{registry => 'cnnic'});
is($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns101.example1.com</host:name><host:addr ip="v4">193.0.2.2</host:addr><host:addr ip="v4">193.0.2.29</host:addr><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr></host:create></create><extension><cnnic-registry:create xmlns:cnnic-registry="urn:ietf:params:xml:ns:cnnic-registry-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-registry-1.0 cnnic-registry-1.0.xsd"><cnnic-registry:registry>cnnic</cnnic-registry:registry></cnnic-registry:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create build');
is($dri->get_info('action'),'create','host_create get_info(action)');
is($dri->get_info('exist'),1,'host_create get_info(exist)');

# Host info
$R2=$E1.'<response>'.r().'<resData><host:infData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns100.example2.com</host:name><host:roid>NS1_EXAMPLE1-REP</host:roid><host:status s="linked"/><host:status s="clientUpdateProhibited"/><host:addr ip="v4">193.0.2.2</host:addr><host:addr ip="v4">193.0.2.29</host:addr><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr><host:clID>ClientY</host:clID><host:crID>ClientX</host:crID><host:crDate>1999-04-03T22:00:00.0Z</host:crDate><host:upID>ClientX</host:upID><host:upDate>1999-12-03T09:00:00.0Z</host:upDate><host:trDate>2000-04-08T09:00:00.0Z</host:trDate></host:infData></resData><extension><cnnic-registry:infData xmlns:cnnic-registry="urn:ietf:params:xml:ns:cnnic-registry-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-registry-1.0 cnnic-registry-1.0.xsd"><cnnic-registry:registry>cnnic</cnnic-registry:registry></cnnic-registry:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->host_info('ns100.example2.com');
is($R1,$E1.'<command><info><host:info xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns100.example2.com</host:name></host:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'host_info build');
is($dri->get_info('action'),'info','host_info get_info(action)');
is($dri->get_info('exist'),1,'host_info get_info(exist)');
is($dri->get_info('roid'),'NS1_EXAMPLE1-REP','host_info get_info(roid)');
is($dri->get_info('registry'),'cnnic','contact_info get_info (registry)');


################################################################################
### CDN (Chinese Domain Name) Extension
### EPP Query Commands ###

# Info with punycode
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>xn--fsq270a.xn--fiqs8s</domain:name><domain:roid>58812678-domain</domain:roid><domain:status s="ok" /><domain:registrant>123</domain:registrant><domain:contact type="admin">123</domain:contact><domain:contact type="tech">123</domain:contact><domain:ns><domain:hostObj>ns1.example.cn</domain:hostObj></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2011-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2012-04-03T22:00:00.0Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><cdn:infData xmlns:cdn="urn:ietf:params:xml:ns:cdn-1.0"><cdn:OCDNPunycode>xn--fsq270a.xn--fiqs8s</cdn:OCDNPunycode><cdn:SCDN>实例.中国</cdn:SCDN><cdn:SCDNPunycode>xn--fsq270a.xn--fiqs8s</cdn:SCDNPunycode><cdn:TCDN>實例.中國</cdn:TCDN><cdn:TCDNPunycode>xn--fsqz41a.xn--fiqz9s</cdn:TCDNPunycode><cdn:VCDNList><cdn:VCDN>実例.中國</cdn:VCDN><cdn:VCDNPunycode>xn--fsq470a.xn--fiqz9s</cdn:VCDNPunycode></cdn:VCDNList></cdn:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('xn--fsq270a.xn--fiqs8s');
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">xn--fsq270a.xn--fiqs8s</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build');
is($rc->is_success(),1,'domain_info is is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'xn--fsq270a.xn--fiqs8s','domain_info get_info (name)');
$cdn = $dri->get_info('cdn');
is_deeply($cdn->{ocdn},{ace=>'xn--fsq270a.xn--fiqs8s',idn=>'实例.中国'},'domain_info get_info (cdn) ocdn');
is_deeply($cdn->{scdn},{ace=>'xn--fsq270a.xn--fiqs8s',idn=>'实例.中国'},'domain_info get_info (cdn) scdn');
is_deeply($cdn->{tcdn},{ace=>'xn--fsqz41a.xn--fiqz9s',idn=>'實例.中國'},'domain_info get_info (cdn) tcdn');
is_deeply($cdn->{vcdns}->[0],{ace=>'xn--fsq470a.xn--fiqz9s',idn=>'実例.中國'},'domain_info get_info (cdn) vcdns');

# Transfer query
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--fsq270a.xn--fiqs8s</domain:name><domain:roid>58812678-domain</domain:roid><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-06T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-11T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData><extension><cdn:trnData xmlns:cdn="urn:ietf:params:xml:ns:cdn-1.0"><cdn:SCDN>实例.中国</cdn:SCDN><cdn:TCDN>實例.中國</cdn:TCDN><cdn:VCDNList><cdn:VCDN>実例.中國</cdn:VCDN></cdn:VCDNList></cdn:trnData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_query('xn--fsq270a.xn--fiqs8s');
is($dri->get_info('action'),'transfer','domain_transfer_query get_transfer (action)');
is($dri->get_info('name'),'xn--fsq270a.xn--fiqs8s','domain_transfer_query get_info (name)');
is($dri->get_info('trStatus'),'pending','domain_transfer_query get_info (trStatus)');
$cdn = $dri->get_info('cdn');
is_deeply($cdn->{scdn},{ace=>'xn--fsq270a.xn--fiqs8s',idn=>'实例.中国'},'domain_transfer_query get_info (cdn) scdn');
is_deeply($cdn->{tcdn},{ace=>'xn--fsqz41a.xn--fiqz9s',idn=>'實例.中國'},'domain_transfer_query get_info (cdn) tcdn');
is_deeply($cdn->{vcdns}->[0],{ace=>'xn--fsq470a.xn--fiqz9s',idn=>'実例.中國'},'domain_transfer_query get_info (cdn) vcdns');

################################################################################
### EPP Transform Commands ###

## Create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--fsq270a.xn--fiqs8s</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('xn--fsq270a.xn--fiqs8s',{
  pure_create=>1,
  duration=>DateTime::Duration->new(years=>2),
  auth=>{pw=>'2fooBAR'},
  cdn=>{vcdns=>[{idn=>'実例.中國'}]},
  });
$command = $E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--fsq270a.xn--fiqs8s</domain:name><domain:period unit="y">2</domain:period><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><cdn:create xmlns:cdn="urn:ietf:params:xml:ns:cdn-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cdn-1.0 cdn-1.0.xsd"><cdn:VCDNList><cdn:VCDN>実例.中國</cdn:VCDN></cdn:VCDNList></cdn:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2;
is_string($R1,$command,'domain_create build');
is($rc->is_success(),1,'domain_create is is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');


## Delete
$R2=$E1.'<response>'.r().'<extension><cdn:delData xmlns:cdn="urn:ietf:params:xml:ns:cdn-1.0"><cdn:SCDN>实例.中国</cdn:SCDN><cdn:TCDN>實例.中國</cdn:TCDN><cdn:VCDNList><cdn:VCDN>実例.中國</cdn:VCDN></cdn:VCDNList></cdn:delData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('xn--fsq270a.xn--fiqs8s');
is($rc->is_success(),1,'domain_delete is is_success');
$cdn = $dri->get_info('cdn');
is_deeply($cdn->{scdn},{ace=>'xn--fsq270a.xn--fiqs8s',idn=>'实例.中国'},'domain_delete get_info (cdn) scdn');
is_deeply($cdn->{tcdn},{ace=>'xn--fsqz41a.xn--fiqz9s',idn=>'實例.中國'},'domain_delete get_info (cdn) tcdn');
is_deeply($cdn->{vcdns}->[0],{ace=>'xn--fsq470a.xn--fiqz9s',idn=>'実例.中國'},'domain_delete get_info (cdn) vcdns');


## Renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--fsq270a.xn--fiqs8s</domain:name><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData><extension><cdn:renData xmlns:cdn="urn:ietf:params:xml:ns:cdn-1.0"><cdn:SCDN>实例.中国</cdn:SCDN><cdn:TCDN>實例.中國</cdn:TCDN><cdn:VCDNList><cdn:VCDN>実例.中國</cdn:VCDN></cdn:VCDNList></cdn:renData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('xn--fsq270a.xn--fiqs8s',{duration => DateTime::Duration->new(years=>5), current_expiration => DateTime->new(year=>2000,month=>4,day=>3)});
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--fsq270a.xn--fiqs8s</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($rc->is_success(),1,'domain_renew is is_success');
$cdn = $dri->get_info('cdn');
is_deeply($cdn->{scdn},{ace=>'xn--fsq270a.xn--fiqs8s',idn=>'实例.中国'},'domain_renew get_info (cdn) scdn');
is_deeply($cdn->{tcdn},{ace=>'xn--fsqz41a.xn--fiqz9s',idn=>'實例.中國'},'domain_renew get_info (cdn) tcdn');
is_deeply($cdn->{vcdns}->[0],{ace=>'xn--fsq470a.xn--fiqz9s',idn=>'実例.中國'},'domain_renew get_info (cdn) vcdns');

## Transfer
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--fsq270a.xn--fiqs8s</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-08T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-13T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData><extension><cdn:trnData xmlns:cdn="urn:ietf:params:xml:ns:cdn-1.0"><cdn:SCDN>实例.中国</cdn:SCDN><cdn:TCDN>實例.中國</cdn:TCDN><cdn:VCDNList><cdn:VCDN>実例.中國</cdn:VCDN></cdn:VCDNList></cdn:trnData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('xn--fsq270a.xn--fiqs8s',{auth => {pw=>'2fooBAR',roid=>"JD1234-REP"},duration=>DateTime::Duration->new(years=>1),fee=>{currency=>'USD',fee=>'5.00'}});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--fsq270a.xn--fiqs8s</domain:name><domain:period unit="y">1</domain:period><domain:authInfo><domain:pw roid="JD1234-REP">2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer build');
is($rc->is_success(),1,'domain_transfer is is_success');
is_deeply($cdn->{scdn},{ace=>'xn--fsq270a.xn--fiqs8s',idn=>'实例.中国'},'domain_transfer get_info (cdn) scdn');
is_deeply($cdn->{tcdn},{ace=>'xn--fsqz41a.xn--fiqz9s',idn=>'實例.中國'},'domain_transfer get_info (cdn) tcdn');
is_deeply($cdn->{vcdns}->[0],{ace=>'xn--fsq470a.xn--fiqz9s',idn=>'実例.中國'},'domain_transfer get_info (cdn) vcdns');

## Update
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$toc=Net::DRI::Data::Changes->new();
my $adddelcdn = { vcdns=>[ {idn=>'実例.中國'} ] };
my $chgcdn = { tcdn=> {ace=>'xn--fsqz41a.xn--fiqz9s'} };
$toc->set('cdn',$chgcdn);
$toc->add('cdn',$adddelcdn);
$toc->del('cdn',$adddelcdn);

$rc=$dri->domain_update('xn--fsq270a.xn--fiqs8s',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--fsq270a.xn--fiqs8s</domain:name></domain:update></update><extension><cdn:update xmlns:cdn="urn:ietf:params:xml:ns:cdn-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cdn-1.0 cdn-1.0.xsd"><cdn:add><cdn:VCDN>実例.中國</cdn:VCDN></cdn:add><cdn:rem><cdn:VCDN>実例.中國</cdn:VCDN></cdn:rem><cdn:chg><cdn:TCDN>實例.中國</cdn:TCDN></cdn:chg></cdn:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is is_success');

################################################################################


exit 0;