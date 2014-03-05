#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 27;
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
$dri->add_registry('TANGO');
$dri->target('TANGO')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$idn);

##################### 
## IDN Extension

# check with idn language (iso639-1)
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example1.ruhr</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example1.ruhr',{'idn' => $dri->local_object('idn')->autodetect('','zh') });
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1.ruhr</domain:name></domain:check></check><extension><idn:check xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:lang>zh</idn:lang></idn:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build_xml');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');

# check with idn script (iso15924)
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example2.ruhr</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example2.ruhr',{'idn' => $dri->local_object('idn')->autodetect('','Latn')} );
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.ruhr</domain:name></domain:check></check><extension><idn:check xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:script>Latn</idn:script></idn:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build_xml');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');

# create with idn language and no variants
$idn = $dri->local_object('idn')->autodetect('example3.ruhr','zh');
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.ruhr',{pure_create=>1,auth=>{pw=>'2fooBAR'},'idn' => $idn});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.ruhr</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><idn:create xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:lang>zh</idn:lang><idn:variants/></idn:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');

# create with idn language and variants
$idn->variants(['abc.ruhr','xyz.ruhr']);
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.ruhr',{pure_create=>1,auth=>{pw=>'2fooBAR'},idn => $idn });
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.ruhr</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><idn:create xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:lang>zh</idn:lang><idn:variants><idn:nameVariant>abc.ruhr</idn:nameVariant><idn:nameVariant>xyz.ruhr</idn:nameVariant></idn:variants></idn:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');

# domain info with variants
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><idn:infData xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:lang>zh</idn:lang><idn:variants><idn:nameVariant>abc.ruhr</idn:nameVariant><idn:nameVariant>xyz.ruhr</idn:nameVariant></idn:variants></idn:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example3.ruhr');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('name'),'example3.ruhr','domain_info get_info name');
isa_ok($dri->get_info('idn'),'Net::DRI::Data::IDN','domain_get get idn is a idn object');
is($dri->get_info('idn')->iso639_1(),'zh','domain_info get_info idn language');
is_deeply($dri->get_info('idn')->variants(),['abc.ruhr','xyz.ruhr'],'domain_info get_info idn_variants');

# domain info with no variants
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example1.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><idn:infData xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:lang>de</idn:lang><idn:variants /></idn:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example1.ruhr');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('name'),'example1.ruhr','domain_info get_info name');
isa_ok($dri->get_info('idn'),'Net::DRI::Data::IDN','domain_get get idn is a idn object');
is($dri->get_info('idn')->iso639_1(),'de','domain_info get_info idn language Tag 639_1');

# domain update with variants
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
my $toc=$dri->local_object('changes');
$idn = $dri->local_object('idn');
$toc->add('idn',$idn->clone()->variants(['ggg.ruhr']));
$toc->del('idn',$idn->clone()->variants(['abc.ruhr','xyz.ruhr']));
$rc=$dri->domain_update('example3.ruhr',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.ruhr</domain:name></domain:update></update><extension><idn:update xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:add><idn:nameVariant>ggg.ruhr</idn:nameVariant></idn:add><idn:rem><idn:nameVariant>abc.ruhr</idn:nameVariant><idn:nameVariant>xyz.ruhr</idn:nameVariant></idn:rem></idn:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build_xml');


##################### 
## Auction Extension

# create with bid
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.ruhr',{pure_create=>1,auth=>{pw=>'2fooBAR'},auction=>{'bid'=>'100.00','currency'=>'EUR'}} );
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.ruhr</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><auction:create xmlns:auction="http://xmlns.tango-rs.net/epp/auction-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/auction-1.0 auction-1.0.xsd"><auction:bid currency="EUR">100.00</auction:bid></auction:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');

# domain update bid
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
$toc=$dri->local_object('changes');
$toc->set('auction',{'bid'=>'200.00','currency'=>'EUR'});
$rc=$dri->domain_update('example3.ruhr',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.ruhr</domain:name></domain:update></update><extension><auction:update xmlns:auction="http://xmlns.tango-rs.net/epp/auction-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/auction-1.0 auction-1.0.xsd"><auction:bid currency="EUR">200.00</auction:bid></auction:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><auction:infData xmlns:auction="http://xmlns.tango-rs.net/epp/auction-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/auction-1.0 auction-1.0.xsd"><auction:bid currency="EUR">10000.00</auction:bid></auction:infData></extension>'.$TRID.'</response>'.$E2;$rc=$dri->domain_info('example3.ruhr');
is($dri->get_info('action'),'info','domain_info get_info(action)');
my $auction = $dri->get_info('auction');
is($auction->{bid},'10000.00','domain_info get_info(bid)');
is($auction->{currency},'EUR','domain_info get_info(currency)');

exit 0;
