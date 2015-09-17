#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Encode;

use Test::More tests => 6;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.1">';
our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my ($rc,$s,$d,$co,$toc,$cs,$h,$dh,@c);

############################################################################################################
## Keygroups 1.0 tests (still used be .BE)
my $dri=Net::DRI::TrapExceptions->new({cache_ttl=>10,trid_factory => sub { return 'clientref-123007'}});
$dri->add_registry('BE');
$dri->target('BE')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
my ($rc,$toc);

## Process greetings to select namespace versions
$R2=$E1.'<greeting><svID>dns.be</svID><svDate>2015-09-17T11:49:35.449Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><svcExtension><extURI>http://www.dns.be/xml/epp/nsgroup-1.0</extURI><extURI>http://www.dns.be/xml/epp/registrar-1.0</extURI><extURI>http://www.dns.be/xml/epp/dnsbe-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.dns.be/xml/epp/keygroup-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'secDNS'}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.0 + 1.1');
is($dri->protocol()->ns()->{'keygroup'}->[0],'http://www.dns.be/xml/epp/keygroup-1.0','keygroup 1.0 for server announcing 1.0');

SKIP: {
  skip 'TODO: fix Keygroup-1.0 tests!',1;

$rc=$dri->keygroup_create('kwkwwyjzorsqljbvlssqhzz');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><keygroup:create xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>kwkwwyjzorsqljbvlssqhzz</keygroup:name></keygroup:create></create><clTRID>TRID-0001</clTRID></command></epp>','keygroup_create build 1');


$rc=$dri->keygroup_create('uvmsfcextoydtsltky',{ 'keys' => [{keyTag=>49049,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0='},
{keyTag=>57695,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0='}] });
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><keygroup:create xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>uvmsfcextoydtsltky</keygroup:name><keygroup:key><keygroup:keyTag>49049</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0=</keygroup:pubKey></keygroup:key><keygroup:key><keygroup:keyTag>57695</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0=</keygroup:pubKey></keygroup:key></keygroup:create></create><clTRID>TRID-0001</clTRID></command></epp>','keygroup_create build 2');


$rc=$dri->keygroup_delete('dvnqbnzfwnxraquhyjcsizpxdjrclifavmfmebjir');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><delete><keygroup:delete xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>dvnqbnzfwnxraquhyjcsizpxdjrclifavmfmebjir</keygroup:name></keygroup:delete></delete><clTRID>TRID-0001</clTRID></command></epp>','keygroup_delete build');



$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><keygroup:chkData><keygroup:cd><keygroup:name avail="true">zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar</keygroup:name></keygroup:cd><keygroup:cd><keygroup:name avail="false">jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name></keygroup:cd><keygroup:cd><keygroup:name avail="false">dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi</keygroup:name></keygroup:cd><keygroup:cd><keygroup:name avail="false">bcoriadjxfgdtrapgkjwlyatof</keygroup:name></keygroup:cd></keygroup:chkData></resData><trID><svTRID>eurid-0</svTRID></trID></response></epp>';
$rc=$dri->keygroup_check(qw/zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar jbzrndytpkijpejbmogzdoxmtfqzxus dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi bcoriadjxfgdtrapgkjwlyatof/);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><check><keygroup:check xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar</keygroup:name><keygroup:name>jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name><keygroup:name>dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi</keygroup:name><keygroup:name>bcoriadjxfgdtrapgkjwlyatof</keygroup:name></keygroup:check></check><clTRID>TRID-0001</clTRID></command></epp>','keygroup_check build');
is($rc->get_data('keygroup','zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar','exist'),0,'keygroup_check get_data 1');
is($rc->get_data('keygroup','jbzrndytpkijpejbmogzdoxmtfqzxus','exist'),1,'keygroup_check get_data 2');
is($rc->get_data('keygroup','dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi','exist'),1,'keygroup_check get_data 3');


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><keygroup:infData><keygroup:name>jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name><keygroup:key><keygroup:keyTag>49049</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0=</keygroup:pubKey></keygroup:key><keygroup:key><keygroup:keyTag>57695</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0=</keygroup:pubKey></keygroup:key></keygroup:infData></resData><trID><svTRID>eurid-0</svTRID></trID></response></epp>';
$rc=$dri->keygroup_info('jbzrndytpkijpejbmogzdoxmtfqzxus');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><info><keygroup:info xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name></keygroup:info></info><clTRID>TRID-0001</clTRID></command></epp>','keygroup_info build');
is($rc->get_data('exist'),1,'keygroup_info get_data(exist)');
is_deeply($rc->get_data('keys'),[{keyTag=>49049,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0='},{keyTag=>57695,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0='}],'keygroup_info get_data(keys)');


$rc=$dri->keygroup_update('krqkdcnjtiigrbvgrsom',$dri->local_object('changes')->set('keys',[]));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><keygroup:update xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>krqkdcnjtiigrbvgrsom</keygroup:name></keygroup:update></update><clTRID>TRID-0001</clTRID></command></epp>','keygroup_update empty keys');


$rc=$dri->keygroup_update('latrvxveoruzciiuuqfurexahnxqf',$dri->local_object('changes')->set('keys',[{keyTag=>49049,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0='},{keyTag=>57695,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZ YEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0='}]));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><keygroup:update xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>latrvxveoruzciiuuqfurexahnxqf</keygroup:name><keygroup:key><keygroup:keyTag>49049</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0=</keygroup:pubKey></keygroup:key><keygroup:key><keygroup:keyTag>57695</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZ YEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0=</keygroup:pubKey></keygroup:key></keygroup:update></update><clTRID>TRID-0001</clTRID></command></epp>','keygroup_update add 2 keys');


};




########################################################################################################
## Keygroups 1.1 tests (.EU)
## Examples taken from EPP_Guidelines_2_1_09

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'TRID-0001'; };
$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});


## Process greetings to select namespace versions
$R2=$E1.'<greeting><svID>eurid.eu</svID><svDate>2014-09-13T09:31:14.123Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrar-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/nsgroup-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/keygroup-1.1</objURI><svcExtension><extURI>http://www.eurid.eu/xml/epp/contact-ext-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-1.2</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/idn-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/dynUpdate-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/authInfo-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.2</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'secDNS'}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.0 + 1.1');
is($dri->protocol()->ns()->{'keygroup'}->[0],'http://www.eurid.eu/xml/epp/keygroup-1.1','keygroup 1.1 for server announcing 1.1');





exit 0;
