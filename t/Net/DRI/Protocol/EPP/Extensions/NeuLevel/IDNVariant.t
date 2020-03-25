#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 9;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
my ($dri,$rc,$s,$d,$dh,@c,$idn);

sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

$dri=Net::DRI::TrapExceptions->new({cache_ttl => -1, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
# $rc = $dri->add_registry('NGTLD',{provider => 'ari'});
# To use ARI extensions instead
$rc = $dri->add_current_registry('Neustar::Narwhal');
$dri->add_current_profile('p2','epp_ari',{f_send=>\&mysend,f_recv=>\&myrecv});

#####################
## IDN Extension + Variants Extensions (both use the Net::DRI::Data::IDN Object) : IDNVariant.pm

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><idn:infData xmlns:idn="urn:ar:params:xml:ns:idn-1.0"><idn:languageTag>und-Zyyy</idn:languageTag></idn:infData><variant:infData xmlns:variant="urn:ar:params:xml:ns:variant-1.1"><variant:variant>xn--eqrt2gr10cmna.menu</variant:variant></variant:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example3.menu');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('name'),'example3.menu','domain_info get_info name');
isa_ok($dri->get_info('idn'),'Net::DRI::Data::IDN','domain_get get idn is a idn object');
is($dri->get_info('idn')->iso15924(),'Zyyy','domain_info get_info idn language Tag 15924');
is($dri->get_info('idn')->iso639_2(),'und','domain_info get_info idn language Tag 639_2');
is_deeply($dri->get_info('idn')->variants(),['xn--eqrt2gr10cmna.menu'],'domain_info get_info idn_variants');

# domain create with idn language and variants
$idn = $dri->local_object('idn')->autodetect('example3.art','und-Zyyy');
$idn->variants(['abc.menu','xyz.menu']);
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},idn => $idn });
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><idn:create xmlns:idn="urn:ar:params:xml:ns:idn-1.0"><idn:languageTag>und-Zyyy</idn:languageTag></idn:create><variant:create xmlns:variant="urn:ar:params:xml:ns:variant-1.1"><variant:variant>abc.menu</variant:variant><variant:variant>xyz.menu</variant:variant></variant:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create idn_variants build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');

# domain update with variants
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
my $toc=$dri->local_object('changes');
$idn = $dri->local_object('idn');
$toc->add('idn',$idn->clone()->variants(['ggg.menu']));
$toc->del('idn',$idn->clone()->variants(['abc.menu','xyz.menu']));
$rc=$dri->domain_update('example3.menu',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.menu</domain:name></domain:update></update><extension><variant:update xmlns:variant="urn:ar:params:xml:ns:variant-1.1"><variant:add><variant:variant>ggg.menu</variant:variant></variant:add><variant:rem><variant:variant>abc.menu</variant:variant><variant:variant>xyz.menu</variant:variant></variant:rem></variant:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update variants build_xml');

exit 0;
