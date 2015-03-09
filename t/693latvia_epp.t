#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 5;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('LV');
$dri->target('LV')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
## Initial Tests
my $drd = $dri->{registries}->{LV}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::LV',{}],'LV - epp transport_protocol_default');

####################################################################################################
## Contacts

### 1.0 Contact Create
$co=$dri->local_object('contact')->srid('josh-12647');
$co->name('James Black');
$co->org('Shark \'n\' Hammer, SIA');
$co->street(['Neverending st.1111']);
$co->city('Rīga');
$co->pc('LV-2000');
$co->cc('LV');
$co->voice('+371.12345678');
$co->fax('+371.87654321');
$co->email('ghepardhus@snailmail.lv');
$co->auth({pw=>'g34gzgh'});
$co->set('vat_nr', 'LV12345678901'); # VAT Number of the legal entity
$co->set('reg_nr', '12345678901'); # 'Personal ID' number of the legal entity
$rc=$dri->contact_create($co);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.dns.pl/nask-epp-schema/epp-2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/epp-2.0 epp-2.0.xsd"><command><create><contact:create xmlns:contact="http://www.dns.pl/nask-epp-schema/contact-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/contact-2.0 contact-2.0.xsd"><contact:id>sh8013</contact:id><contact:postalInfo type="loc"><contact:name>11John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.tld</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:create></create><extension><extcon:create xmlns:extcon="http://www.dns.pl/nask-epp-schema/extcon-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/extcon-2.0 extcon-2.0.xsd"><extcon:individual>1</extcon:individual><extcon:consentForPublishing>1</extcon:consentForPublishing></extcon:create></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_create build');
is($rc->is_success(),1,'contact_create is_success');
exit 0;
####################################################################################################
## Domains

### 2.0 Domain Update 
my $changes = $dri->local_object('changes');
#$cs = $dri->local_object('contactset');
#$cs->add($dri->local_object('contact')->srid('51249'), 'admin');
#$changes->add('contact', $cs);
#$cs = $dri->local_object('contactset');
#$cs->add($dri->local_object('contact')->srid('78496'), 'tech');
#$changes->del('contact', $cs);
#$changes->add('ns',$dri->local_object('hosts')->set(['ns3.example.info']));
$changes->set('auto_renew', 'true'); # 'true/false' 1/0
$changes->set('auto_renew_message',{ lang => 'en', message => 'Client didn\'t pay for domain name: discard it'});
$rc = $dri->domain_update('example-lvnic.lv', $changes);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example-lvnic.lv</domain:name></domain:update></update><extension><lvdomain:update xmlns:lvdomain="http://www.nic.lv/epp/schema/lvdomain-ext-1.0" xsi:schemaLocation="http://www.nic.lv/epp/schema/lvdomain-ext-1.0 lvdomain-ext-1.0.xsd"><lvdomain:add><lvdomain:status lang="en" s="clientAutoRenewProhibited">Client didn\'t pay for domain name: discard it</lvdomain:status></lvdomain:add></lvdomain:update></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain_update build');
