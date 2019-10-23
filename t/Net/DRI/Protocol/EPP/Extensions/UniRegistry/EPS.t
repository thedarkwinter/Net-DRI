#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper; # TODO: remove me

use Test::More tests => 83;
use Test::Exception;
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
$dri->add_current_registry('UniRegistry::EPS');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my ($d,$e,$enc,$lp);
my (@labels);

##########################################
## EPS - EPP Query Commands

### eps check - single
$R2=$E1.'<response>'.r().'<resData><eps:chkData xmlns:eps="http://ns.uniregistry.net/eps-1.0"><eps:cd><eps:label>test-validate</eps:label><eps:roids><eps:roid>EP_ad755e69ce0af2c8b565acb6d98fc6b0-UR</eps:roid></eps:roids></eps:cd></eps:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->eps_check('test-validate');
is_string($R1,$E1.'<command><check><eps:check xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:label>test-validate</eps:label></eps:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'eps_check build (single)');
is($rc->is_success(),1,'eps_check single is_success');
is_deeply(shift @{$dri->get_info('roids','eps','test-validate')},'EP_ad755e69ce0af2c8b565acb6d98fc6b0-UR','eps_check get_info(roids) test-validate');

### eps check - multi
$R2=$E1.'<response>'.r().'<resData><eps:chkData xmlns:eps="http://ns.uniregistry.net/eps-1.0"><eps:cd><eps:label>test-validate</eps:label><eps:roids><eps:roid>EP_ad755e69ce0af2c8b565acb6d98fc6b0-UR</eps:roid></eps:roids></eps:cd><eps:cd><eps:label>foobar-validate</eps:label><eps:roids><eps:roid>EP_ad755e69ce0af2c8b565acb6d98fc6b1-UR</eps:roid><eps:roid>EP_ad755e69ce0af2c8b565acb6d98fc6b2-UR</eps:roid></eps:roids></eps:cd></eps:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->eps_check(qw/test-validate foobar-validate/);
is_string($R1,$E1.'<command><check><eps:check xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:label>test-validate</eps:label><eps:label>foobar-validate</eps:label></eps:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'eps_check build (multi)');
is($rc->is_success(),1,'eps_check multi is_success');
is_deeply(shift @{$dri->get_info('roids','eps','test-validate')},'EP_ad755e69ce0af2c8b565acb6d98fc6b0-UR','eps_check multi get_info(roids) test-validate');
is_deeply($dri->get_info('roids','eps','foobar-validate'),['EP_ad755e69ce0af2c8b565acb6d98fc6b1-UR','EP_ad755e69ce0af2c8b565acb6d98fc6b2-UR'],'eps_check multi get_info(roids) foobar-validate');

### eps info
$R2=$E1.'<response>'.r().'<resData><eps:infData xmlns:eps="http://ns.uniregistry.net/eps-1.0"><eps:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</eps:roid><eps:labels><eps:label>test-andvalidate</eps:label><eps:label>test-validate</eps:label></eps:labels><eps:registrant>lm39</eps:registrant><eps:clID>registry_a</eps:clID><eps:crID>registry_a</eps:crID><eps:crDate>2019-02-22T14:14:10</eps:crDate><eps:exDate>2020-02-22T14:14:10</eps:exDate><eps:releases><eps:release><eps:name>test-andvalidate.isc</eps:name><eps:authInfo><eps:pw>uniregistry</eps:pw></eps:authInfo><eps:crDate>2019-02-22T14:14:10.697Z</eps:crDate></eps:release></eps:releases><eps:authInfo><eps:pw>abcd1234</eps:pw></eps:authInfo></eps:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->eps_info('EP_e726f81a44c5c4bd00d160973808825c-UR');
is_string($R1,$E1.'<command><info><eps:info xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</eps:roid></eps:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'eps_info build');
is($rc->is_success(),1,'eps_info is_success');
$rc=$dri->eps_info('EP_e726f81a44c5c4bd00d160973808825c-UR',{auth=>{pw=>'abcd1234'}});
is_string($R1,$E1.'<command><info><eps:info xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</eps:roid><eps:authInfo><eps:pw>abcd1234</eps:pw></eps:authInfo></eps:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'eps_info build (with auth)');
is($rc->is_success(),1,'eps_info (with auth) is_success');
is($dri->get_info('action'),'info','eps_info get_info(action)');
is($dri->get_info('type'),'eps','eps_info get_info(type)');
is($dri->get_info('roid'),'EP_e726f81a44c5c4bd00d160973808825c-UR','eps_info get_info(roid)');
is_deeply($dri->get_info('labels'),['test-andvalidate','test-validate'],'eps_info get_info(labels)');
is($dri->get_info('registrant'),'lm39','eps_info get_info(registrant)');
is($dri->get_info('clID'),'registry_a','eps_info get_info(clID)');
is($dri->get_info('crID'),'registry_a','eps_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','eps_info get_info(crDate)');
is("".$d,'2019-02-22T14:14:10','eps_info get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','eps_info get_info(exDate)');
is("".$d,'2020-02-22T14:14:10','eps_info get_info(exDate) value');
$e=shift @{$dri->get_info('releases')->{'release'}};
is($e->{name},'test-andvalidate.isc','eps_info get_info(releases) first release name value');
is_deeply($e->{auth},{pw=>'uniregistry'},'eps_info get_info(releases) first release auth value');
is($e->{crDate},'2019-02-22T14:14:10.697Z','eps_info get_info(releases) first release crDate value');
is_deeply($dri->get_info('auth'),{pw=>'abcd1234'},'eps_info get_info(auth)');

# test multiple release elements!
$R2='';
$R2=$E1.'<response>'.r().'<resData><eps:infData xmlns:eps="http://ns.uniregistry.net/eps-1.0"><eps:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</eps:roid><eps:labels><eps:label>test-andvalidate</eps:label><eps:label>test-validate</eps:label></eps:labels><eps:registrant>lm39</eps:registrant><eps:clID>registry_a</eps:clID><eps:crID>registry_a</eps:crID><eps:crDate>2019-02-22T14:14:10</eps:crDate><eps:exDate>2020-02-22T14:14:10</eps:exDate><eps:releases><eps:release><eps:name>test-andvalidate.isc</eps:name><eps:authInfo><eps:pw>uniregistry</eps:pw></eps:authInfo><eps:crDate>2019-02-22T14:14:10.697Z</eps:crDate></eps:release><eps:release><eps:name>foobar.isc</eps:name><eps:authInfo><eps:pw>foobar</eps:pw></eps:authInfo><eps:crDate>2019-09-24T14:14:10.697Z</eps:crDate></eps:release></eps:releases><eps:authInfo><eps:pw>abcd1234</eps:pw></eps:authInfo></eps:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->eps_info('EP_e726f81a44c5c4bd00d160973808825c-UR');
is($rc->is_success(),1,'eps_info is_success');
$e=$dri->get_info('releases')->{'release'};
is($e->[0]->{name},'test-andvalidate.isc','eps_info get_info(releases) first release name value');
is_deeply($e->[0]->{auth},{pw=>'uniregistry'},'eps_info get_info(releases) first release auth value');
is($e->[0]->{crDate},'2019-02-22T14:14:10.697Z','eps_info get_info(releases) first release crDate value');
is($e->[1]->{name},'foobar.isc','eps_info get_info(releases) second release name value');
is_deeply($e->[1]->{auth},{pw=>'foobar'},'eps_info get_info(releases) second release auth value');
is($e->[1]->{crDate},'2019-09-24T14:14:10.697Z','eps_info get_info(releases) second release crDate value');

### eps info response for an unauthorized client
$R2='';
$R2=$E1.'<response>'.r().'<resData><eps:infData xmlns:eps="http://ns.uniregistry.net/eps-1.0"><eps:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</eps:roid><eps:labels><eps:label>test-andvalidate</eps:label><eps:label>test-validate</eps:label></eps:labels><eps:registrant>lm39</eps:registrant><eps:clID>registry_a</eps:clID><eps:crID>registry_a</eps:crID><eps:crDate>2019-02-22T14:14:10</eps:crDate><eps:exDate>2020-02-22T14:14:10</eps:exDate></eps:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->eps_info('EP_e726f81a44c5c4bd00d160973808825c-UR');
is_string($R1,$E1.'<command><info><eps:info xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</eps:roid></eps:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'eps_info build for an unauthorized client');
is($rc->is_success(),1,'eps_info is_success for an unauthorized client');
is($dri->get_info('action'),'info','eps_info get_info(action) for an unauthorized client');
is($dri->get_info('type'),'eps','eps_info get_info(type) for an unauthorized client');
is($dri->get_info('roid'),'EP_e726f81a44c5c4bd00d160973808825c-UR','eps_info get_info(roid) for an unauthorized client');
is_deeply($dri->get_info('labels'),['test-andvalidate','test-validate'],'eps_info get_info(labels) for an unauthorized client');
is($dri->get_info('registrant'),'lm39','eps_info get_info(registrant) for an unauthorized client');
is($dri->get_info('clID'),'registry_a','eps_info get_info(clID) for an unauthorized client');
is($dri->get_info('crID'),'registry_a','eps_info get_info(crID) for an unauthorized client');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','eps_info get_info(crDate)');
is("".$d,'2019-02-22T14:14:10','eps_info get_info(crDate) value for an unauthorized client');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','eps_info get_info(exDate) for an unauthorized client');
is("".$d,'2020-02-22T14:14:10','eps_info get_info(exDate) value for an unauthorized client');

# eps exempt
$R2=$E1.'<response>'.r().'<resData><eps:empData xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:ed><eps:label>test-validate</eps:label><eps:exemptions><eps:exemption><eps:iprID>3111246</eps:iprID><eps:labels><eps:label>test-andvalidate</eps:label><eps:label>test-validate</eps:label></eps:labels></eps:exemption></eps:exemptions></eps:ed></eps:empData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->eps_exempt('test-validate');
is_string($R1,$E1.'<command><check><eps:exempt xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:label>test-validate</eps:label></eps:exempt></check><clTRID>ABC-12345</clTRID></command>'.$E2,'eps_exempt build (single label)');
is($rc->is_success(),1,'eps_exempt single label is_success');
is($dri->get_info('action'),'exempt','eps_exempt get_info(action)');
is($dri->get_info('type'),'eps','eps_exempt get_info(type)');
is($dri->get_info('label'),'test-validate','eps_exempt get_info(label)');
$e=$dri->get_info('exemptions');
is($e->{iprID},'3111246','eps_exempt get_exemptions(iprID)');
is_deeply($e->{labels},['test-andvalidate','test-validate'],'eps_exempt get_exemptions(labels)');

# eps exempt - multi (they don't have a sample but let create one based on their doc specs)
$R2=$E1.'<response>'.r().'<resData><eps:empData xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:ed><eps:label>test-validate</eps:label><eps:exemptions><eps:exemption><eps:iprID>3111246</eps:iprID><eps:labels><eps:label>test-andvalidate</eps:label><eps:label>test-validate</eps:label></eps:labels></eps:exemption></eps:exemptions></eps:ed><eps:ed><eps:label>foobar-validate</eps:label><eps:exemptions><eps:exemption><eps:iprID>20190925</eps:iprID><eps:labels><eps:label>foobar-andvalidate</eps:label><eps:label>foobar-validate</eps:label></eps:labels></eps:exemption></eps:exemptions></eps:ed></eps:empData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->eps_exempt(qw/test-validate foobar-validate/);
is_string($R1,$E1.'<command><check><eps:exempt xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:label>test-validate</eps:label><eps:label>foobar-validate</eps:label></eps:exempt></check><clTRID>ABC-12345</clTRID></command>'.$E2,'eps_exempt build (multi label)');
is($rc->is_success(),1,'eps_exempt multi is_success');
is($dri->get_info('action'),'exempt_multi','eps_exempt multi get_info(action)');
is($dri->get_info('type'),'eps','eps_exempt multi get_info(type)');
$e=$dri->get_info('exemptions','eps','test-validate');
is($e->{iprID},'3111246','eps_exempt multi get_exemptions(iprID) - test-validate label');
is_deeply($e->{labels},['test-andvalidate','test-validate'],'eps_exempt multi get_exemptions(labels) - test-validate label');
$e=$dri->get_info('exemptions','eps','foobar-validate');
is($e->{iprID},'20190925','eps_exempt multi get_exemptions(iprID) - foobar-validate label');
is_deeply($e->{labels},['foobar-andvalidate','foobar-validate'],'eps_exempt multi get_exemptions(labels) - foobar-validate label');

# eps create
$R2=$E1.'<response>'.r().'<resData><eps:creData xmlns:eps="http://ns.uniregistry.net/eps-1.0"><eps:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</eps:roid><eps:crDate>2019-02-22T14:14:10</eps:crDate><eps:exDate>2020-02-22T14:14:10</eps:exDate></eps:creData></resData>'.$TRID.'</response>'.$E2;
@labels = qw/test-andvalidate test-validate/;
$rc=$dri->eps_create(\@labels, {product_type => "standard", duration => DateTime::Duration->new(years=>1), registrant => ("lm39"), auth=>{pw=>"abcd1234"}});
is_string($R1,$E1.'<command><create><eps:create xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd" type="standard"><eps:labels><eps:label>test-andvalidate</eps:label><eps:label>test-validate</eps:label></eps:labels><eps:period>1</eps:period><eps:registrant>lm39</eps:registrant><eps:authInfo><eps:pw>abcd1234</eps:pw></eps:authInfo></eps:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'eps_create build');
is($rc->is_success(),1,'eps_create is_success');
is($dri->get_info('action'),'create','eps_create get_info(action)');
is($dri->get_info('type'),'eps','eps_create get_info(type)');
is($dri->get_info('roid'),'EP_e726f81a44c5c4bd00d160973808825c-UR','eps_create get_info(roid)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','eps_create get_info(crDate)');
is("".$d,'2019-02-22T14:14:10','eps_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','eps_create get_info(exDate)');
is("".$d,'2020-02-22T14:14:10','eps_create get_info(exDate) value');
# test mandatory fields
throws_ok { $dri->eps_create(\@labels, {registrant => ("lm39"), auth=>{pw=>"abcd1234"}}) } qr/type must be standard or plus/, 'eps_create build error check - no product_type';
throws_ok { $dri->eps_create(\@labels, {product_type => "standard", registrant => ("lm39"), auth=>{pw=>"abcd1234"}}) } qr/period\/duration is mandatory/, 'eps_create build error check - no period/duration';
throws_ok { $dri->eps_create(\@labels, {product_type => "standard", duration => DateTime::Duration->new(years=>1), auth=>{pw=>"abcd1234"}}) } qr/registrant is mandatory/, 'eps_create build error check - no registrant';
throws_ok { $dri->eps_create(\@labels, {product_type => "standard", duration => DateTime::Duration->new(years=>1), registrant => ("lm39")}) } qr/authInfo is mandatory/, 'eps_create build error check - no authInfo';

# eps create with SMD file validation
$R2=$E1.'<response>'.r().'<resData><eps:creData xmlns:eps="http://ns.uniregistry.net/eps-1.0"><eps:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</eps:roid><eps:crDate>2019-02-22T14:14:10</eps:crDate><eps:exDate>2020-02-22T14:14:10</eps:exDate></eps:creData></resData>'.$TRID.'</response>'.$E2;
@labels = qw/test-andvalidate test-validate/;
# Encoded signed mark validation model
$enc=<<'EOF';
<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWduZWRNYXJrIHht
bG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRNYXJrLTEuMCIgaWQ9Il85M2Yz
Y2M5Yy1mOTNlLTQ5ZDgtYmU2Yi04NmJlOWQ4ZDQ1ODkiPjxzbWQ6aWQ+MDAwMDAwODUxNTI2MDc2
ODYwMjM0LTY1NTM1PC9zbWQ6aWQ+PHNtZDppc3N1ZXJJbmZvIGlzc3VlcklEPSI2NTUzNSI+PHNt
ZDpvcmc+SUNBTk4gVE1DSCBURVNUSU5HIFRNVjwvc21kOm9yZz48c21kOmVtYWlsPm5vdGF2YWls
YWJsZUBleGFtcGxlLmNvbTwvc21kOmVtYWlsPjxzbWQ6dXJsPnd3dy5leGFtcGxlLmNvbTwvc21k
OnVybD48c21kOnZvaWNlPiszMi4yMDAwMDAwMDwvc21kOnZvaWNlPjwvc21kOmlzc3VlckluZm8+
PHNtZDpub3RCZWZvcmU+MjAxOC0wNS0xMVQyMjoxNDoyMC4yMzRaPC9zbWQ6bm90QmVmb3JlPjxz
bWQ6bm90QWZ0ZXI+MjAyMi0wOC0xOFQxNDo1NzozNi42ODFaPC9zbWQ6bm90QWZ0ZXI+PG1hcms6
bWFyayB4bWxuczptYXJrPSJ1cm46aWV0ZjpwYXJhbXM6eG1sOm5zOm1hcmstMS4wIj48bWFyazpj
b3VydD48bWFyazppZD4wMDAxMzcxNTAzMDY3ODY4MTUwMzA2Nzg2OC0xPC9tYXJrOmlkPjxtYXJr
Om1hcmtOYW1lPlRlc3QgJmFtcDsgVmFsaWRhdGU8L21hcms6bWFya05hbWU+PG1hcms6aG9sZGVy
IGVudGl0bGVtZW50PSJvd25lciI+PG1hcms6bmFtZT5Ub255IEhvbGxhbmQ8L21hcms6bmFtZT48
bWFyazpvcmc+QWcgY29ycG9yYXRpb248L21hcms6b3JnPjxtYXJrOmFkZHI+PG1hcms6c3RyZWV0
PjEzMDUgQnJpZ2h0IEF2ZW51ZTwvbWFyazpzdHJlZXQ+PG1hcms6Y2l0eT5BcmNhZGlhPC9tYXJr
OmNpdHk+PG1hcms6cGM+OTAwMjg8L21hcms6cGM+PG1hcms6Y2M+VVM8L21hcms6Y2M+PC9tYXJr
OmFkZHI+PC9tYXJrOmhvbGRlcj48bWFyazpjb250YWN0IHR5cGU9ImFnZW50Ij48bWFyazpuYW1l
PlRvbnkgSG9sbGFuZDwvbWFyazpuYW1lPjxtYXJrOm9yZz5BZyBjb3Jwb3JhdGlvbjwvbWFyazpv
cmc+PG1hcms6YWRkcj48bWFyazpzdHJlZXQ+QnJpZ2h0IEF2ZW51ZSAxMzA1IDwvbWFyazpzdHJl
ZXQ+PG1hcms6Y2l0eT5BcmNhZGlhPC9tYXJrOmNpdHk+PG1hcms6c3A+Q0E8L21hcms6c3A+PG1h
cms6cGM+OTAwMjg8L21hcms6cGM+PG1hcms6Y2M+VVM8L21hcms6Y2M+PC9tYXJrOmFkZHI+PG1h
cms6dm9pY2U+KzEuMjAyNTU2MjMwMjwvbWFyazp2b2ljZT48bWFyazpmYXg+KzEuMjAyNTU2MjMw
MTwvbWFyazpmYXg+PG1hcms6ZW1haWw+aW5mb0BhZ2NvcnBvcmF0aW9uLmNvbTwvbWFyazplbWFp
bD48L21hcms6Y29udGFjdD48bWFyazpsYWJlbD50ZXN0LS0tdmFsaWRhdGU8L21hcms6bGFiZWw+
PG1hcms6bGFiZWw+dGVzdC0tdmFsaWRhdGU8L21hcms6bGFiZWw+PG1hcms6bGFiZWw+dGVzdC1h
bmQtdmFsaWRhdGU8L21hcms6bGFiZWw+PG1hcms6bGFiZWw+dGVzdC1hbmR2YWxpZGF0ZTwvbWFy
azpsYWJlbD48bWFyazpsYWJlbD50ZXN0LXZhbGlkYXRlPC9tYXJrOmxhYmVsPjxtYXJrOmxhYmVs
PnRlc3RhbmQtdmFsaWRhdGU8L21hcms6bGFiZWw+PG1hcms6bGFiZWw+dGVzdGFuZHZhbGlkYXRl
PC9tYXJrOmxhYmVsPjxtYXJrOmxhYmVsPnRlc3R2YWxpZGF0ZTwvbWFyazpsYWJlbD48bWFyazpn
b29kc0FuZFNlcnZpY2VzPmd1aXRhcjwvbWFyazpnb29kc0FuZFNlcnZpY2VzPjxtYXJrOnJlZk51
bT4xMjM0PC9tYXJrOnJlZk51bT48bWFyazpwcm9EYXRlPjIwMTMtMDEtMDFUMDA6MDA6MDAuMDAw
WjwvbWFyazpwcm9EYXRlPjxtYXJrOmNjPlVTPC9tYXJrOmNjPjxtYXJrOmNvdXJ0TmFtZT5Ib3Zl
PC9tYXJrOmNvdXJ0TmFtZT48L21hcms6Y291cnQ+PC9tYXJrOm1hcms+PGRzOlNpZ25hdHVyZSB4
bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgSWQ9Il82MDFiMTM0
Ni1iZGUwLTRkM2MtYTA3ZC1hMjgxY2ZjODg4YTciPjxkczpTaWduZWRJbmZvPjxkczpDYW5vbmlj
YWxpemF0aW9uTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwt
ZXhjLWMxNG4jIi8+PGRzOlNpZ25hdHVyZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMu
b3JnLzIwMDEvMDQveG1sZHNpZy1tb3JlI3JzYS1zaGEyNTYiLz48ZHM6UmVmZXJlbmNlIFVSST0i
I185M2YzY2M5Yy1mOTNlLTQ5ZDgtYmU2Yi04NmJlOWQ4ZDQ1ODkiPjxkczpUcmFuc2Zvcm1zPjxk
czpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcj
ZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3
LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2Vz
dE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI3NoYTI1
NiIvPjxkczpEaWdlc3RWYWx1ZT5LUjgxL08yQlZ2cmxLR3ZJa3U3WkFUcHhPUlhnd2xFK2R1NnVE
L1B6WEVvPTwvZHM6RGlnZXN0VmFsdWU+PC9kczpSZWZlcmVuY2U+PGRzOlJlZmVyZW5jZSBVUkk9
IiNfMTYzY2RhMGYtMjliZC00MDNlLWI5MmEtOWVjZDc3MDA0NDU1Ij48ZHM6VHJhbnNmb3Jtcz48
ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhj
LWMxNG4jIi8+PC9kczpUcmFuc2Zvcm1zPjxkczpEaWdlc3RNZXRob2QgQWxnb3JpdGhtPSJodHRw
Oi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGVuYyNzaGEyNTYiLz48ZHM6RGlnZXN0VmFsdWU+RUlF
SXBPelFQZVhkaEw5K3ZLaFBGMDRKWjVJT3lid3Jzb0ZjRGhSU2QvOD08L2RzOkRpZ2VzdFZhbHVl
PjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWUgSWQ9Il85
ZjM5NWZmZi03OTFhLTRmMTctODQ4Zi1hYTQyZGQ4MmU3YjAiPnNGUjkwOGFvcG9CNzN6U3R1NERt
a0dIVHZML0lYZjdvdWVxL1JpakZlQ0d4MklYbDM0aE1wUzJHUnhsN3M4MzJVcFliVEEzQllRaHIK
VkJKa3FoejVkaXFCMlk2NUwvZXc0Q1hmY0VXR1Y3L0h0cmpOUmxYTnNlcWVHa05EdEZVK1hwTUlk
ZTRJZEZzMjhXUmxhRk9ORUozbwpzZGZ4KzRlMGRVbytJWXR6U3A4MEk1UmZPRG5razh6Q0J3Wmdq
Mis0Qy9PSlBBUG12cXAzekNrY1ppUFVWNVNVaUJRNVhOSSt3KzZNCmtWYStYeG5pY0gxazNCdEFM
eCtERXZ5VkJPZlFwS01ucG1SeWR1b09VOTc2MUZlRFc0ZStBUmdvV3BOYUtzVmtlQ0Z4RVlUOEhm
OFcKZGNOZlp3WFdQd1N5YllZSEJFTm92elhTRUIxOTdUalJQb1Q2TFE9PTwvZHM6U2lnbmF0dXJl
VmFsdWU+PGRzOktleUluZm8gSWQ9Il8xNjNjZGEwZi0yOWJkLTQwM2UtYjkyYS05ZWNkNzcwMDQ0
NTUiPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZPekNDQkNPZ0F3SUJBZ0ln
THJBYmV2b2FlNTJ5M2Y2QzJ0QjBTbjNwN1hKbTBUMDJGb2d4S0NmTmhaY3dEUVlKS29aSWh2Y04K
QVFFTEJRQXdmREVMTUFrR0ExVUVCaE1DVlZNeFBEQTZCZ05WQkFvVE0wbHVkR1Z5Ym1WMElFTnZj
bkJ2Y21GMGFXOXVJR1p2Y2lCQgpjM05wWjI1bFpDQk9ZVzFsY3lCaGJtUWdUblZ0WW1WeWN6RXZN
QzBHQTFVRUF4TW1TVU5CVGs0Z1ZISmhaR1Z0WVhKcklFTnNaV0Z5CmFXNW5hRzkxYzJVZ1VHbHNi
M1FnUTBFd0hoY05NVGd3TWpJNE1EQXdNREF3V2hjTk1qTXdNekF4TWpNMU9UVTVXakNCanpFTE1B
a0cKQTFVRUJoTUNRa1V4SURBZUJnTlZCQWdURjBKeWRYTnpaV3h6TFVOaGNHbDBZV3dnVW1WbmFX
OXVNUkV3RHdZRFZRUUhFd2hDY25WegpjMlZzY3pFUk1BOEdBMVVFQ2hNSVJHVnNiMmwwZEdVeE9E
QTJCZ05WQkFNVEwwbERRVTVPSUZSTlEwZ2dRWFYwYUc5eWFYcGxaQ0JVCmNtRmtaVzFoY21zZ1VH
bHNiM1FnVm1Gc2FXUmhkRzl5TUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dL
Q0FRRUEKeGxwM0twWUhYM1d5QXNGaFNrM0x3V2ZuR2x4blVERnFGWkEzVW91TVlqL1hpZ2JNa05l
RVhJamxrUk9LVDRPUEdmUngvTEF5UmxRUQpqQ012NHFoYmtjWDFwN2FyNjNmbHE0U1pOVmNsMTVs
N2gwdVQ1OEZ6U2ZubHowdTVya0hmSkltRDQzK21hUC84Z3YzNkZSMjdqVzhSCjl3WTRoaytXczRJ
QjBpRlNkOFNYdjFLcjh3L0ptTVFTRGtpdUcrUmZJaXVid1EvZnk3RWtqNVFXaFBadyttTXhOS25I
VUx5M3hZejIKTHdWZmZ0andVdWVhY3ZxTlJDa01YbENsT0FEcWZUOG9TWm9lRFhlaEh2bFBzTENl
bUdCb1RLdXJza0lTNjlGMHlQRUg1Z3plMEgrZgo4RlJPc0lvS1NzVlEzNEI0Uy9qb0U2N25wc0pQ
VGRLc05QSlR5UUlEQVFBQm80SUJrekNDQVk4d0RBWURWUjBUQVFIL0JBSXdBREFkCkJnTlZIUTRF
RmdRVW9GcFk3NnA1eW9ORFJHdFFwelZ1UjgxVVdRMHdnY1lHQTFVZEl3U0J2akNCdTRBVXc2MCtw
dFlSQUVXQVhEcFgKU29wdDNERU5ubkdoZ1lDa2ZqQjhNUXN3Q1FZRFZRUUdFd0pWVXpFOE1Eb0dB
MVVFQ2hNelNXNTBaWEp1WlhRZ1EyOXljRzl5WVhScApiMjRnWm05eUlFRnpjMmxuYm1Wa0lFNWhi
V1Z6SUdGdVpDQk9kVzFpWlhKek1TOHdMUVlEVlFRREV5WkpRMEZPVGlCVWNtRmtaVzFoCmNtc2dR
MnhsWVhKcGJtZG9iM1Z6WlNCUWFXeHZkQ0JEUVlJZ0xyQWJldm9hZTUyeTNmNkMydEIwU24zcDdY
Sm0wVDAyRm9neEtDZk4KaFhrd0RnWURWUjBQQVFIL0JBUURBZ2VBTURRR0ExVWRId1F0TUNzd0th
QW5vQ1dHSTJoMGRIQTZMeTlqY213dWFXTmhibTR1YjNKbgpMM1J0WTJoZmNHbHNiM1F1WTNKc01G
RUdBMVVkSUFSS01FZ3dFQVlPS3dZQkJBR0N5UnNCQllNN0RBb3dOQVlJS3dZQkJRVUhBZ0V3CktE
QW1CZ2dyQmdFRkJRY0NBUllhYUhSMGNITTZMeTlqWVM1cFkyRnViaTV2Y21jdmNHbHNiM1F3RFFZ
SktvWklodmNOQVFFTEJRQUQKZ2dFQkFBdWpaMkljUjJEVnJ0YVJyQTU5ZU5ZQ2w0eGNzSk11OERR
Q0h2MjhmVGZpL0JpWlk0SXI3RjlrRnk5NkQ3T1o4b0xZNXpqZgo0ZEh4RndIUHFIOERoNkpXc3pY
dUhXMVphM1htbDBQYUh4Q1dSUzBYb2w4V3NISHBOeWdqTUJZZkowb2RWTTg4NVRaMUVsOVNpdUVI
Cm55bkZCZ1NtaUZjOTl1UWQvWURSWnVHdi9BMEh5djd5Ujl0a0xFZEQzQTF1TkpCVzRQK0hKR3Bk
S2tZTDFRNXJVNytvSFZQdE1LS0kKM2lGa1VFc2JPNDVBVmQ3dlAvai83SnRBWlBiNmtvT1Y1bFpp
MkgxUkxjY0d3emRlem5oSmdkME45b2JiMHZuRTQxL1VTV2FmZFdSWgpWR2t3UHVxVGhsN3NDdHpy
Skg4WFkweGN1bStjZkx4MkVBSXdVbk9jYWI0PTwvZHM6WDUwOUNlcnRpZmljYXRlPjwvZHM6WDUw
OURhdGE+PC9kczpLZXlJbmZvPjwvZHM6U2lnbmF0dXJlPjwvc21kOnNpZ25lZE1hcms+
</smd:encodedSignedMark>
EOF
chomp $enc;
$lp = { type => 'application', phase => 'open', 'encoded_signed_marks'=>[ $enc ] };
$rc=$dri->eps_create(\@labels, {product_type => ("plus"), duration => DateTime::Duration->new(years=>1), registrant => ("lm39"), auth=>{pw=>"abcd1234"}, lp => $lp});
is_string($R1,$E1.'<command><create><eps:create xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd" type="plus"><eps:labels><eps:label>test-andvalidate</eps:label><eps:label>test-validate</eps:label></eps:labels><eps:period>1</eps:period><eps:registrant>lm39</eps:registrant><eps:authInfo><eps:pw>abcd1234</eps:pw></eps:authInfo></eps:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="application"><launch:phase>open</launch:phase>'.$enc.'</launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'eps_create build with SMD file validation');
is($rc->is_success(),1,'eps_create is_success with SMD file validation');
is($dri->get_info('action'),'create','eps_create get_info(action) with SMD file validation');
is($dri->get_info('type'),'eps','eps_create get_info(type) with SMD file validation');
is($dri->get_info('roid'),'EP_e726f81a44c5c4bd00d160973808825c-UR','eps_create get_info(roid) with SMD file validation');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','eps_create get_info(crDate) with SMD file validation');
is("".$d,'2019-02-22T14:14:10','eps_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','eps_create get_info(exDate) with SMD file validation');
is("".$d,'2020-02-22T14:14:10','eps_create get_info(exDate) value');

exit 0;