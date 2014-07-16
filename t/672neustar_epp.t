#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 22;
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
$dri->add_registry('NGTLD',{provider => 'NEUSTAR',name=>'buzz'}); # for testing Fee
$dri->target('buzz')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$dri->add_registry('NGTLD',{provider => 'NEUSTAR',name=>'nyc'}); # for testing EXTContact 
$dri->target('nyc')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my ($fee,$c,$c2,$toc);

################################################################################
## Fee extension
$dri->target('buzz');

# domain check
my $price = { duration=>DateTime::Duration->new(years=>5) };
$R2=$E1.'<response>'.r().'<extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>TierName=Tier2 AnnualTierPrice=50</neulevel:unspec></neulevel:extension></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example9.buzz',{fee => 1} );
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example9.buzz</domain:name></domain:check></check><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>FeeCheck=Y</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check price build_xml');
$fee = $dri->get_info('fee');
is($fee->{tier},'Tier2','domain_check get_info fee tier');
is($fee->{price},'50','domain_check get_info fee price');
# using the standardised methods
is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium)');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('price_category'),'Tier2','domain_check get_info (price_category)');
is($dri->get_info('create_price'),'50','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),'50','domain_check get_info (renew_price)');
is($dri->get_info('transfer_price'),undef,'domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),undef,'domain_check get_info (restore_price) undef');

$fee = { tier => 'Tier3', 'price' => 100 };
# domain create - # domain renew and domain transfer work exactly the same
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example9.buzz</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example9.buzz',{pure_create=>1,auth=>{pw=>'2fooBAR'},fee => $fee });
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example9.buzz</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>TierName=Tier3 AnnualTierPrice=100</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create price build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');

################################################################################
## Contact Extensions

# First check it doesn't mess up other Neustar registries
$dri->target('buzz'); 
$c = $dri->local_object('contact');
$c->srid('abcde')->name('abc')->org('abc.org')->street(['123 d street'])->city('reston')->pc(20194)->sp('NY')->cc('US')->fax('+1.2345678901x1234')->email('xxx@yyy.com')->auth({pw => 123456});
$c->nexus_category('ORG');
$rc=$dri->contact_create($c);
is($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>abcde</contact:id><contact:postalInfo type="loc"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:fax x="1234">+1.2345678901</contact:fax><contact:email>xxx@yyy.com</contact:email><contact:authInfo><contact:pw>123456</contact:pw></contact:authInfo></contact:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create nexus build_xml');
$c2 = $c->clone();
$c2->nexus_category('Indiv');
$toc = $dri->local_object('changes');
$toc->set('info',$c2);
$rc=$dri->contact_update($c,$toc);
is($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>abcde</contact:id><contact:chg><contact:postalInfo type="loc"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:fax x="1234">+1.2345678901</contact:fax><contact:email>xxx@yyy.com</contact:email><contact:authInfo><contact:pw>123456</contact:pw></contact:authInfo></contact:chg></contact:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_updatre nexus build_xml');

## NYC Nexus Contact
$dri->target('nyc');
#Contact Create
$c = $dri->local_object('contact');
$c->srid('abcde')->name('abc')->org('abc.org')->street(['123 d street'])->city('reston')->pc(20194)->sp('NY')->cc('US')->fax('+1.2345678901x1234')->email('xxx@yyy.com')->auth({pw => 123456});
$c->nexus_category('ORG');
$rc=$dri->contact_create($c);
is($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>abcde</contact:id><contact:postalInfo type="loc"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:fax x="1234">+1.2345678901</contact:fax><contact:email>xxx@yyy.com</contact:email><contact:authInfo><contact:pw>123456</contact:pw></contact:authInfo></contact:create></create><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>EXTContact=Y NexusCategory=ORG</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create nexus build_xml');

# Contact Update
$c2 = $c->clone();
$c2->nexus_category('Indiv');
$toc = $dri->local_object('changes');
$toc->set('info',$c2);
$rc=$dri->contact_update($c,$toc);
is($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>abcde</contact:id><contact:chg><contact:postalInfo type="loc"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:fax x="1234">+1.2345678901</contact:fax><contact:email>xxx@yyy.com</contact:email><contact:authInfo><contact:pw>123456</contact:pw></contact:authInfo></contact:chg></contact:update></update><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>EXTContact=Y NexusCategory=INDIV</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_updatre nexus build_xml');

#Contact Info
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>abcde</contact:id><contact:postalInfo type="loc"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>abc</contact:name><contact:org>abc.org</contact:org><contact:addr><contact:street>123 d street</contact:street><contact:city>reston</contact:city><contact:sp>NY</contact:sp><contact:pc>20194</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:fax x="1234">+1.2345678901</contact:fax><contact:email>xxx@yyy.com</contact:email><contact:authInfo><contact:pw>123456</contact:pw></contact:authInfo></contact:infData></resData><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>EXTContact=Y NexusCategory=INDIV</neulevel:unspec></neulevel:extension></extension>'.$TRID.'</response>'.$E2;
undef $c;
$c=$dri->local_object('contact')->srid('abcde');
$rc=$dri->contact_info($c);
$c=$dri->get_info('self','contact','abcde');
is($c->nexus_category(),'INDIV','contact_info parse nexus_category');
is($c->ext_contact(),'Y','contact_info parse ext_contact');
################################################################################
## Domain Extensions
$dri->target('nyc');

## EXTContact (eg. NYC)
# Domain create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example1.nyc</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example1.nyc',{pure_create=>1,auth=>{pw=>'2fooBAR'},'ext_contact'=>'abcde'});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1.nyc</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>EXTContact=abcde</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create EXTContact build_xml');

# Domain update
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
$toc=$dri->local_object('changes');
$toc->set('ext_contact','newsrid');
$rc=$dri->domain_update('example1.nyc',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1.nyc</domain:name></domain:update></update><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>EXTContact=newsrid</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update EXTContact build_xml');

# Domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example2.nyc</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>EXTContact=abcde</neulevel:unspec></neulevel:extension></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example2.nyc');
is($dri->get_info('ext_contact'),'abcde','domain_info get_info ext_contact');

exit 0;