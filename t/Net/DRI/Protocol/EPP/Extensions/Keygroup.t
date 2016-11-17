#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Encode;

use Test::More tests => 35;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my ($rc,$s,$d,$co,$toc,$cs,$h,$dh,@c);

#########################################################################################################

## Extension: KeyGroup

#########################################################################################################

########################################################################################################
## DNSBE uses version 1.0, while Eurid uses 1.1 (with their own namespace declarations)
## So we test both versions here. 1.1 is at the bottom!
my $dri=Net::DRI::TrapExceptions->new({cache_ttl=>10,trid_factory => sub { return 'TRID-0001'}});
$dri->add_registry('BE');
$dri->target('BE')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

## Process greetings to select namespace versions
$R2=$E1.'<greeting><svID>dns.be</svID><svDate>2015-09-17T11:49:35.449Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><svcExtension><extURI>http://www.dns.be/xml/epp/nsgroup-1.0</extURI><extURI>http://www.dns.be/xml/epp/registrar-1.0</extURI><extURI>http://www.dns.be/xml/epp/dnsbe-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.dns.be/xml/epp/keygroup-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'keygroup'}->[0],'http://www.dns.be/xml/epp/keygroup-1.0','keygroup-1.0 for server announcing 1.0');

$rc=$dri->keygroup_create('kwkwwyjzorsqljbvlssqhzz');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><keygroup:create xmlns:keygroup="http://www.dns.be/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>kwkwwyjzorsqljbvlssqhzz</keygroup:name></keygroup:create></create><clTRID>TRID-0001</clTRID></command></epp>','keygroup-1.0 create build 1');

$rc=$dri->keygroup_create('uvmsfcextoydtsltky',{ 'keys' => [{keyTag=>49049,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0='},
{keyTag=>57695,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0='}] });
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><keygroup:create xmlns:keygroup="http://www.dns.be/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>uvmsfcextoydtsltky</keygroup:name><keygroup:key><keygroup:keyTag>49049</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0=</keygroup:pubKey></keygroup:key><keygroup:key><keygroup:keyTag>57695</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0=</keygroup:pubKey></keygroup:key></keygroup:create></create><clTRID>TRID-0001</clTRID></command></epp>','keygroup-1.0 create build 2');

$rc=$dri->keygroup_delete('dvnqbnzfwnxraquhyjcsizpxdjrclifavmfmebjir');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><keygroup:delete xmlns:keygroup="http://www.dns.be/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>dvnqbnzfwnxraquhyjcsizpxdjrclifavmfmebjir</keygroup:name></keygroup:delete></delete><clTRID>TRID-0001</clTRID></command></epp>','keygroup-1.0 delete build');

$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:keygroup="http://www.dns.be/xml/epp/keygroup-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><keygroup:chkData><keygroup:cd><keygroup:name avail="true">zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar</keygroup:name></keygroup:cd><keygroup:cd><keygroup:name avail="false">jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name></keygroup:cd><keygroup:cd><keygroup:name avail="false">dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi</keygroup:name></keygroup:cd><keygroup:cd><keygroup:name avail="false">bcoriadjxfgdtrapgkjwlyatof</keygroup:name></keygroup:cd></keygroup:chkData></resData><trID><svTRID>eurid-0</svTRID></trID></response></epp>';
$rc=$dri->keygroup_check(qw/zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar jbzrndytpkijpejbmogzdoxmtfqzxus dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi bcoriadjxfgdtrapgkjwlyatof/);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><keygroup:check xmlns:keygroup="http://www.dns.be/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar</keygroup:name><keygroup:name>jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name><keygroup:name>dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi</keygroup:name><keygroup:name>bcoriadjxfgdtrapgkjwlyatof</keygroup:name></keygroup:check></check><clTRID>TRID-0001</clTRID></command></epp>','keygroup-1.0 check build');
is($rc->get_data('keygroup','zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar','exist'),0,'keygroup-1.0 check get_data 1');
is($rc->get_data('keygroup','jbzrndytpkijpejbmogzdoxmtfqzxus','exist'),1,'keygroup-1.0 check get_data 2');
is($rc->get_data('keygroup','dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi','exist'),1,'keygroup-1.0 check get_data 3');

$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:keygroup="http://www.dns.be/xml/epp/keygroup-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><keygroup:infData><keygroup:name>jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name><keygroup:key><keygroup:keyTag>49049</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0=</keygroup:pubKey></keygroup:key><keygroup:key><keygroup:keyTag>57695</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0=</keygroup:pubKey></keygroup:key></keygroup:infData></resData><trID><svTRID>eurid-0</svTRID></trID></response></epp>';
$rc=$dri->keygroup_info('jbzrndytpkijpejbmogzdoxmtfqzxus');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><keygroup:info xmlns:keygroup="http://www.dns.be/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name></keygroup:info></info><clTRID>TRID-0001</clTRID></command></epp>','keygroup-1.0 info build');
is($rc->get_data('exist'),1,'keygroup-1.0 info get_data(exist)');
is_deeply($rc->get_data('keys'),[{keyTag=>49049,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0='},{keyTag=>57695,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0='}],'keygroup-1.0 info get_data(keys)');

$rc=$dri->keygroup_update('krqkdcnjtiigrbvgrsom',$dri->local_object('changes')->set('keys',[]));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><keygroup:update xmlns:keygroup="http://www.dns.be/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>krqkdcnjtiigrbvgrsom</keygroup:name></keygroup:update></update><clTRID>TRID-0001</clTRID></command></epp>','keygroup-1.0 update empty keys');

$rc=$dri->keygroup_update('latrvxveoruzciiuuqfurexahnxqf',$dri->local_object('changes')->set('keys',[{keyTag=>49049,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0='},{keyTag=>57695,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZ YEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0='}]));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><keygroup:update xmlns:keygroup="http://www.dns.be/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>latrvxveoruzciiuuqfurexahnxqf</keygroup:name><keygroup:key><keygroup:keyTag>49049</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0=</keygroup:pubKey></keygroup:key><keygroup:key><keygroup:keyTag>57695</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZ YEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0=</keygroup:pubKey></keygroup:key></keygroup:update></update><clTRID>TRID-0001</clTRID></command></epp>','keygroup-1.0 update add 2 keys');

########################################################################################################
## DNSBE uses version 1.0, while Eurid uses 1.1 (with their own namespace declarations)
## 1.0 is at the top, this is 1.1
## Examples taken from EPP_Guidelines_2_2_1, and edited

$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

## Process greetings to select namespace versions
$R2=$E1.'<greeting><svID>eurid.eu</svID><svDate>2016-06-02T08:27:10.390Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrar-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/nsgroup-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/keygroup-1.1</objURI><svcExtension><extURI>http://www.eurid.eu/xml/epp/contact-ext-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-2.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/idn-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/dynUpdate-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/dnsQuality-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/authInfo-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.2</extURI><extURI>http://www.eurid.eu/xml/epp/homoglyph-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'keygroup'}->[0],'http://www.eurid.eu/xml/epp/keygroup-1.1','keygroup 1.1 for server announcing 1.1');

##KEYGROUP_CHECK
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><keygroup:chkData><keygroup:cd><keygroup:name avail="false">keygroup-135089830472</keygroup:name><keygroup:reason lang="en">in use</keygroup:reason></keygroup:cd><keygroup:cd><keygroup:name avail="true">keygroup-1350898304165</keygroup:name></keygroup:cd></keygroup:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->keygroup_check('keygroup-135089830472','keygroup-1350898304165');
is_string($R1,$E1.'<command><check><keygroup:check xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.1 keygroup-1.1.xsd"><keygroup:name>keygroup-135089830472</keygroup:name><keygroup:name>keygroup-1350898304165</keygroup:name></keygroup:check></check><clTRID>TRID-0001</clTRID></command>'.$E2,'keygroup-1.1 check_multi build_xml');
is($rc->is_success(),1,'keygroup-1.1 check_multi is_success');
is($dri->get_info('exist','keygroup','keygroup-135089830472'),1,'keygroup-1.1 check_multi get_info(exist) 1/2');
is($dri->get_info('exist','keygroup','keygroup-1350898304165'),0,'keygroup-1.1 check_multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','keygroup','keygroup-135089830472'),'in use','keygroup-1.1 check_multi get_info(exist_reason) 2/2');

##KEYGROUP_CREATE
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result>'.$TRID.'</response>'.$E2;
$rc=$dri->keygroup_create('keygroup-135089830472');
is_string($R1,$E1.'<command><create><keygroup:create xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.1 keygroup-1.1.xsd"><keygroup:name>keygroup-135089830472</keygroup:name></keygroup:create></create><clTRID>TRID-0001</clTRID></command>'.$E2,'keygroup-1.1 create build_xml');
is($rc->is_success(),1,'keygroup-1.1 create is_success');

##KEYGROUP_CREATE with keys
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result>'.$TRID.'</response>'.$E2;
my $keys = [
      { flags => 256, protocol => 3, alg => 7, pubKey => 'AwEAAc7CI/9hE5joz6gD207+xb35OkEjwYoqBi0r2BnLzcuUPhmn1yivxF3QREEKlFnyzEnfglOqm2hbnE/2881qHMVDrEzyR6huPOuTNMNusko7FPgm7+yTBa5aSFCE/h988G6LQ0maKXHF82MV+sd+H8Js74DFRdSbNV1GStMxT4Lj' },
      { flags => 256, protocol => 3, alg => 7, pubKey => 'AwEAAbXYFoGoDNgTY8ralYgCMwOmZNdG00yfyGJ5PojCAKWTskWGdASORHzYwuxzg/mpF2cCs7LG8ZsVO15W0UOY1JZZ2shWEWq598yqDr5MvH34F5aGoDiXEuoT180BEZZnTjRrD5CA9ZmJqm6CX05diGpN7McKM909EclYIpnn0ydf' },
      { flags => 257, protocol => 3, alg => 7, pubKey => 'AwEAAdPt8/+PqYJWaj40ub1sTXo0L3T7iPaHxs+U/DT5XBoGFQgQLZun8VpFhca3QsUkymjuVkBS+27yXDy8Bp+r0oGTzWA5TjWX68wZGtvpNbvsSY4EZSjNxn28632oHjvIjSuVXJlzV+YxWdOapsBPzetCPoLjxpi0hZ+dGFhhYMvx' },
      { flags => 257, protocol => 3, alg => 7, pubKey => 'AwEAAdrZUdSYSlOUSPqL6BohnJt5qCzVxNTZwhmjZBeMTu4abOMdBuwRG9WCnbmfv7SrXRe4qrRPaqS5SYlEulxmi/v02zhTm5rTdJv0JRv/104hkR+2FfYAfEXpq//Y9Qu+MZyb4TSd0LsZaN4siZ+MtHWj9tRU9m+xLU/drgz0pZ3T' },
    ];
$rc=$dri->keygroup_create('keygroup-1350898304275',{ 'keys' => $keys });
is_string($R1,$E1.'<command><create><keygroup:create xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.1 keygroup-1.1.xsd"><keygroup:name>keygroup-1350898304275</keygroup:name><keygroup:keyData><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:alg>7</keygroup:alg><keygroup:pubKey>AwEAAc7CI/9hE5joz6gD207+xb35OkEjwYoqBi0r2BnLzcuUPhmn1yivxF3QREEKlFnyzEnfglOqm2hbnE/2881qHMVDrEzyR6huPOuTNMNusko7FPgm7+yTBa5aSFCE/h988G6LQ0maKXHF82MV+sd+H8Js74DFRdSbNV1GStMxT4Lj</keygroup:pubKey></keygroup:keyData><keygroup:keyData><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:alg>7</keygroup:alg><keygroup:pubKey>AwEAAbXYFoGoDNgTY8ralYgCMwOmZNdG00yfyGJ5PojCAKWTskWGdASORHzYwuxzg/mpF2cCs7LG8ZsVO15W0UOY1JZZ2shWEWq598yqDr5MvH34F5aGoDiXEuoT180BEZZnTjRrD5CA9ZmJqm6CX05diGpN7McKM909EclYIpnn0ydf</keygroup:pubKey></keygroup:keyData><keygroup:keyData><keygroup:flags>257</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:alg>7</keygroup:alg><keygroup:pubKey>AwEAAdPt8/+PqYJWaj40ub1sTXo0L3T7iPaHxs+U/DT5XBoGFQgQLZun8VpFhca3QsUkymjuVkBS+27yXDy8Bp+r0oGTzWA5TjWX68wZGtvpNbvsSY4EZSjNxn28632oHjvIjSuVXJlzV+YxWdOapsBPzetCPoLjxpi0hZ+dGFhhYMvx</keygroup:pubKey></keygroup:keyData><keygroup:keyData><keygroup:flags>257</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:alg>7</keygroup:alg><keygroup:pubKey>AwEAAdrZUdSYSlOUSPqL6BohnJt5qCzVxNTZwhmjZBeMTu4abOMdBuwRG9WCnbmfv7SrXRe4qrRPaqS5SYlEulxmi/v02zhTm5rTdJv0JRv/104hkR+2FfYAfEXpq//Y9Qu+MZyb4TSd0LsZaN4siZ+MtHWj9tRU9m+xLU/drgz0pZ3T</keygroup:pubKey></keygroup:keyData></keygroup:create></create><clTRID>TRID-0001</clTRID></command>'.$E2,'keygroup-1.1 create_keys build_xml');
is($rc->is_success(),1,'keygroup-1.1 create_keys is_success');

##KEYGROUP_DELETE
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result>'.$TRID.'</response>'.$E2;
$rc=$dri->keygroup_delete('keygroup-135089830472');
is_string($R1,$E1.'<command><delete><keygroup:delete xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.1 keygroup-1.1.xsd"><keygroup:name>keygroup-135089830472</keygroup:name></keygroup:delete></delete><clTRID>TRID-0001</clTRID></command>'.$E2,'keygroup-1.1 delete build_xml');
is($rc->is_success(),1,'keygroup-1.1 delete is_success');

##KEYGROUP_INFO empty
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><keygroup:infData><keygroup:name>keygroup-empty</keygroup:name></keygroup:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->keygroup_info('keygroup-empty');
is_string($R1,$E1.'<command><info><keygroup:info xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.1 keygroup-1.1.xsd"><keygroup:name>keygroup-empty</keygroup:name></keygroup:info></info><clTRID>TRID-0001</clTRID></command>'.$E2,'keygroup-1.1 info build_xml');
is($rc->is_success(),1,'keygroup-1.1 info is_success');

##KEYGROUP_INFO full
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><keygroup:infData><keygroup:infData><keygroup:name>keygroup-full</keygroup:name><keygroup:keyData><keygroup:flags>257</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:alg>7</keygroup:alg><keygroup:pubKey>AwEAAdrZUdSYSlOUSPqL6BohnJt5qCzVxNTZwhmjZBeMTu4abOMdBuwRG9WCnbmfv7SrXRe4qrRPaqS5SYlEulxmi/v02zhTm5rTdJv0JRv/104hkR+2FfYAfEXpq//Y9Qu+MZyb4TSd0LsZaN4siZ+MtHWj9tRU9m+xLU/drgz0pZ3T</keygroup:pubKey></keygroup:keyData><keygroup:keyData><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:alg>7</keygroup:alg><keygroup:pubKey>AwEAAc7CI/9hE5joz6gD207+xb35OkEjwYoqBi0r2BnLzcuUPhmn1yivxF3QREEKlFnyzEnfglOqm2hbnE/2881qHMVDrEzyR6huPOuTNMNusko7FPgm7+yTBa5aSFCE/h988G6LQ0maKXHF82MV+sd+H8Js74DFRdSbNV1GStMxT4Lj</keygroup:pubKey></keygroup:keyData><keygroup:keyData><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:alg>7</keygroup:alg><keygroup:pubKey>AwEAAbXYFoGoDNgTY8ralYgCMwOmZNdG00yfyGJ5PojCAKWTskWGdASORHzYwuxzg/mpF2cCs7LG8ZsVO15W0UOY1JZZ2shWEWq598yqDr5MvH34F5aGoDiXEuoT180BEZZnTjRrD5CA9ZmJqm6CX05diGpN7McKM909EclYIpnn0ydf</keygroup:pubKey></keygroup:keyData><keygroup:keyData><keygroup:flags>257</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:alg>7</keygroup:alg><keygroup:pubKey>AwEAAdPt8/+PqYJWaj40ub1sTXo0L3T7iPaHxs+U/DT5XBoGFQgQLZun8VpFhca3QsUkymjuVkBS+27yXDy8Bp+r0oGTzWA5TjWX68wZGtvpNbvsSY4EZSjNxn28632oHjvIjSuVXJlzV+YxWdOapsBPzetCPoLjxpi0hZ+dGFhhYMvx</keygroup:pubKey></keygroup:keyData></keygroup:infData></keygroup:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->keygroup_info('keygroup-full', {auth => {'pw' => 'XXXX-2MRN-MRAP-MXVR'}});
is_string($R1,$E1.'<command><info><keygroup:info xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.1 keygroup-1.1.xsd"><keygroup:name>keygroup-full</keygroup:name><keygroup:authInfo><keygroup:pw>XXXX-2MRN-MRAP-MXVR</keygroup:pw></keygroup:authInfo></keygroup:info></info><clTRID>TRID-0001</clTRID></command>'.$E2,'keygroup-1.1 info build_xml');
is($rc->is_success(),1,'keygroup-1.1 info is_success');
$keys = $dri->get_info('keys', 'keygroup', 'keygroup-full');
isa_ok($keys,'ARRAY','keygroup-1.1 info get_info(keys)');
is_deeply($keys->[0],{ flags => 257, protocol => 3, alg => 7, pubKey => 'AwEAAdrZUdSYSlOUSPqL6BohnJt5qCzVxNTZwhmjZBeMTu4abOMdBuwRG9WCnbmfv7SrXRe4qrRPaqS5SYlEulxmi/v02zhTm5rTdJv0JRv/104hkR+2FfYAfEXpq//Y9Qu+MZyb4TSd0LsZaN4siZ+MtHWj9tRU9m+xLU/drgz0pZ3T' },'keygroup-1.1 info get_info(keys key1)');

##KEYGROUP_UPDATE remove all keys
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result>'.$TRID.'</response>'.$E2;
$rc=$dri->keygroup_update('keygroup-1350898304275',$dri->local_object('changes')->set('keys',[]));
is_string($R1,$E1.'<command><update><keygroup:update xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.1 keygroup-1.1.xsd"><keygroup:name>keygroup-1350898304275</keygroup:name></keygroup:update></update><clTRID>TRID-0001</clTRID></command>'.$E2,'keygroup-1.1 update remove_all_keys build_xml');
is($rc->is_success(),1,'keygroup-1.1 update remove_all_keys is_success');

##KEYGROUP_UPDATE set keys
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result>'.$TRID.'</response>'.$E2;
$keys = [
    { flags => 256, protocol => 3, alg => 7, pubKey => 'AwEAAdbzku0qyxDmfz+SL004uyKeuunGWwSqqi50+raR5SSevi31N/KqKqBi0K75zg3dUkEKxZGSGW1DJ5+jpNNH9LfgNQZIlaes3Ckfi2FmpQYIWa0ftbZkY6fqXlN6oK2faT2+wqspzeb7+AhpVvQcLe/1iOeqit+oNzgSBDe0JKWD' },
    { flags => 256, protocol => 3, alg => 7, pubKey => 'AwEAAdhNT6jMSwx3ikD/yEA1rpT8qJijWf5BkiAXMI4JMCgwyJiab2rku6URqhVYtbgovt/8r7VIqFtWkbRe70vTxiKlUdg7UyluNUIWboxGhBAE0gEdMNjhudSZP7hE77BcudZuf0NFv5yRMAS+3LDxPO8t2gYvIxeEXRfMXnaH5wwn' },
];
$rc=$dri->keygroup_update('keygroup-1350898304165',$dri->local_object('changes')->set('keys',$keys));
is_string($R1,$E1.'<command><update><keygroup:update xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.1 keygroup-1.1.xsd"><keygroup:name>keygroup-1350898304165</keygroup:name><keygroup:keyData><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:alg>7</keygroup:alg><keygroup:pubKey>AwEAAdbzku0qyxDmfz+SL004uyKeuunGWwSqqi50+raR5SSevi31N/KqKqBi0K75zg3dUkEKxZGSGW1DJ5+jpNNH9LfgNQZIlaes3Ckfi2FmpQYIWa0ftbZkY6fqXlN6oK2faT2+wqspzeb7+AhpVvQcLe/1iOeqit+oNzgSBDe0JKWD</keygroup:pubKey></keygroup:keyData><keygroup:keyData><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:alg>7</keygroup:alg><keygroup:pubKey>AwEAAdhNT6jMSwx3ikD/yEA1rpT8qJijWf5BkiAXMI4JMCgwyJiab2rku6URqhVYtbgovt/8r7VIqFtWkbRe70vTxiKlUdg7UyluNUIWboxGhBAE0gEdMNjhudSZP7hE77BcudZuf0NFv5yRMAS+3LDxPO8t2gYvIxeEXRfMXnaH5wwn</keygroup:pubKey></keygroup:keyData></keygroup:update></update><clTRID>TRID-0001</clTRID></command>'.$E2,'keygroup-1.1 update set_keys build_xml');
is($rc->is_success(),1,'keygroup-1.1 update set_keys is_success');

exit 0;
