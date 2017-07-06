#!/usr/bin/perl

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
$dri->add_registry('Neustar::Narwhal'); # for testing EXTContact
$dri->target('nyc')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['NeuLevel::EXTContact']});

my $rc;
my ($fee,$c,$c2,$toc);

################################################################################
## Contact Extensions

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

exit 0;
