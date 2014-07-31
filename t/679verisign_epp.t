#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 18;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend	{ my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv	{ return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r       { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }
sub r1      { my ($c,$m)=@_; return '<result code="'.($c || 1001).'"><msg>'.($m || 'Command completed successfully; action pending').'</msg></result>'; }
sub r2      { my ($c,$m)=@_; return '<result code="'.($c || 1301).'"><msg>'.($m || 'Command completed successfully; ack to dequeue').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('NGTLD',{provider=>'verisign'});
$dri->target('verisign')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$dri->protocol->default_parameters()->{premium_domain}=0; # ENABLE PREMIUM

=cut
# for the mark processing
my $po=$dri->{registries}->{pir}->{profiles}->{p1}->{protocol};
eval { Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::setup(undef,$po,undef);};
my $parser=XML::LibXML->new();

my ($rc,$dh,$cs,$toc,$v,$lp,$lpres,$s);
my ($crdate,$exdate,$d);
=cut
my ($rc,$co);

## NAMESTORE EXTENSION

# domain check - autodetect product
my $premium_string = '<premiumdomain:check xmlns:premiumdomain="http://www.verisign.com/epp/premiumdomain-1.0" xsi:schemaLocation="http://www.verisign.com/epp/premiumdomain-1.0 premiumdomain-1.0.xsd"><premiumdomain:flag>0</premiumdomain:flag></premiumdomain:check>';
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example22.career</domain:name></domain:cd></domain:chkData></resData><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>CAREER</namestoreExt:subProduct></namestoreExt:namestoreExt></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example22.career');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.career</domain:name></domain:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>CAREER</namestoreExt:subProduct></namestoreExt:namestoreExt>'.$premium_string.'</extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build with namestore fixed in add_current_profile()');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('subproductid'),'CAREER','domain_check multi get_info(subproductid)');

# host check - using previous (current) product
$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="0">ns2.example2.com</host:name><host:reason>In use</host:reason></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_check('ns2.example2.com');
is($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns2.example2.com</host:name></host:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>CAREER</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($dri->get_info('action'),'check','host_check get_info(action)');
is($dri->get_info('exist'),1,'host_check get_info(exist)');
is($dri->get_info('exist','host','ns2.example2.com'),1,'host_check get_info(exist) from cache');
is($dri->get_info('exist_reason'),'In use','host_check reason');

# host check - manually setting current_product
$dri->protocol()->{current_product} = 'BLAH';
$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="0">ns3.example2.com</host:name><host:reason>In use</host:reason></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_check('ns3.example2.com');
is($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns3.example2.com</host:name></host:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>BLAH</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($dri->get_info('action'),'check','host_check get_info(action)');

# host check - manually setting product in RD
$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="0">ns4.example2.com</host:name><host:reason>In use</host:reason></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_check('ns4.example2.com',{subproductid=>'FOO'});
is($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns4.example2.com</host:name></host:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>FOO</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($dri->get_info('action'),'check','host_check get_info(action)');

# contact check - using previous (current) product
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="1">sh8000</contact:id></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8000'); #->auth({pw=>'2fooBAR'});
$rc=$dri->contact_check($co);
is($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8000</contact:id></contact:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>FOO</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check build'); 
is($rc->is_success(),1,'contact_check is_success');
is($dri->get_info('action'),'check','contact_check get_info(action)');
is($dri->get_info('exist'),0,'contact_check get_info(exist)');
is($dri->get_info('exist','contact','sh8000'),0,'contact_check get_info(exist) from cache');


exit 0;
