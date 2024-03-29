#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 126;
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
$dri->add_current_registry('GoDaddy::MZB');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my ($d,$e,$enc,$lp,$todo,@exemptions);
my (@labels);

##########################################
## mzb - EPP Query Commands

### mzb check - single
$R2=$E1.'<response>'.r().'<resData><mzb:chkData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0"><mzb:cd><mzb:label>test-validate</mzb:label><mzb:roids><mzb:roid>EP_ad755e69ce0af2c8b565acb6d98fc6b0-UR</mzb:roid></mzb:roids></mzb:cd></mzb:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->mzb_check('test-validate');
is_string($R1,$E1.'<command><check><mzb:check xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:label>test-validate</mzb:label></mzb:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_check build (single)');
is($rc->is_success(),1,'mzb_check single is_success');
is_deeply(shift @{$dri->get_info('roids','mzb','test-validate')},'EP_ad755e69ce0af2c8b565acb6d98fc6b0-UR','mzb_check get_info(roids) test-validate');

### mzb check - multi
$R2=$E1.'<response>'.r().'<resData><mzb:chkData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0"><mzb:cd><mzb:label>test-validate</mzb:label><mzb:roids><mzb:roid>EP_ad755e69ce0af2c8b565acb6d98fc6b0-UR</mzb:roid></mzb:roids></mzb:cd><mzb:cd><mzb:label>foobar-validate</mzb:label><mzb:roids><mzb:roid>EP_ad755e69ce0af2c8b565acb6d98fc6b1-UR</mzb:roid><mzb:roid>EP_ad755e69ce0af2c8b565acb6d98fc6b2-UR</mzb:roid></mzb:roids></mzb:cd></mzb:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->mzb_check(qw/test-validate foobar-validate/);
is_string($R1,$E1.'<command><check><mzb:check xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:label>test-validate</mzb:label><mzb:label>foobar-validate</mzb:label></mzb:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_check build (multi)');
is($rc->is_success(),1,'mzb_check multi is_success');
is_deeply(shift @{$dri->get_info('roids','mzb','test-validate')},'EP_ad755e69ce0af2c8b565acb6d98fc6b0-UR','mzb_check multi get_info(roids) test-validate');
is_deeply($dri->get_info('roids','mzb','foobar-validate'),['EP_ad755e69ce0af2c8b565acb6d98fc6b1-UR','EP_ad755e69ce0af2c8b565acb6d98fc6b2-UR'],'mzb_check multi get_info(roids) foobar-validate');

### mzb info
$R2=$E1.'<response>'.r().'<resData><mzb:infData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:labels><mzb:label>test-andvalidate</mzb:label><mzb:label>test-validate</mzb:label></mzb:labels><mzb:registrant>lm39</mzb:registrant><mzb:clID>registry_a</mzb:clID><mzb:crID>registry_a</mzb:crID><mzb:crDate>2019-02-22T14:14:10</mzb:crDate><mzb:exDate>2020-02-22T14:14:10</mzb:exDate><mzb:releases><mzb:release><mzb:name>test-andvalidate.isc</mzb:name><mzb:authInfo><mzb:pw>uniregistry</mzb:pw></mzb:authInfo><mzb:crDate>2019-02-22T14:14:10.697Z</mzb:crDate></mzb:release></mzb:releases><mzb:authInfo><mzb:pw>abcd1234</mzb:pw></mzb:authInfo></mzb:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->mzb_info('EP_e726f81a44c5c4bd00d160973808825c-UR');
is_string($R1,$E1.'<command><info><mzb:info xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid></mzb:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_info build');
is($rc->is_success(),1,'mzb_info is_success');
$rc=$dri->mzb_info('EP_e726f81a44c5c4bd00d160973808825c-UR',{auth=>{pw=>'abcd1234'}});
is_string($R1,$E1.'<command><info><mzb:info xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:authInfo><mzb:pw>abcd1234</mzb:pw></mzb:authInfo></mzb:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_info build (with auth)');
is($rc->is_success(),1,'mzb_info (with auth) is_success');
is($dri->get_info('action'),'info','mzb_info get_info(action)');
is($dri->get_info('type'),'mzb','mzb_info get_info(type)');
is($dri->get_info('roid'),'EP_e726f81a44c5c4bd00d160973808825c-UR','mzb_info get_info(roid)');
is_deeply($dri->get_info('labels'),['test-andvalidate','test-validate'],'mzb_info get_info(labels)');
is($dri->get_info('registrant'),'lm39','mzb_info get_info(registrant)');
is($dri->get_info('clID'),'registry_a','mzb_info get_info(clID)');
is($dri->get_info('crID'),'registry_a','mzb_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','mzb_info get_info(crDate)');
is("".$d,'2019-02-22T14:14:10','mzb_info get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','mzb_info get_info(exDate)');
is("".$d,'2020-02-22T14:14:10','mzb_info get_info(exDate) value');
$e=shift @{$dri->get_info('releases')->{'release'}};
is($e->{name},'test-andvalidate.isc','mzb_info get_info(releases) first release name value');
is_deeply($e->{auth},{pw=>'uniregistry'},'mzb_info get_info(releases) first release auth value');
is($e->{crDate},'2019-02-22T14:14:10.697Z','mzb_info get_info(releases) first release crDate value');
is_deeply($dri->get_info('auth'),{pw=>'abcd1234'},'mzb_info get_info(auth)');

# test multiple release elements!
$R2='';
$R2=$E1.'<response>'.r().'<resData><mzb:infData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:labels><mzb:label>test-andvalidate</mzb:label><mzb:label>test-validate</mzb:label></mzb:labels><mzb:registrant>lm39</mzb:registrant><mzb:clID>registry_a</mzb:clID><mzb:crID>registry_a</mzb:crID><mzb:crDate>2019-02-22T14:14:10</mzb:crDate><mzb:exDate>2020-02-22T14:14:10</mzb:exDate><mzb:releases><mzb:release><mzb:name>test-andvalidate.isc</mzb:name><mzb:authInfo><mzb:pw>uniregistry</mzb:pw></mzb:authInfo><mzb:crDate>2019-02-22T14:14:10.697Z</mzb:crDate></mzb:release><mzb:release><mzb:name>foobar.isc</mzb:name><mzb:authInfo><mzb:pw>foobar</mzb:pw></mzb:authInfo><mzb:crDate>2019-09-24T14:14:10.697Z</mzb:crDate></mzb:release></mzb:releases><mzb:authInfo><mzb:pw>abcd1234</mzb:pw></mzb:authInfo></mzb:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->mzb_info('EP_e726f81a44c5c4bd00d160973808825c-UR');
is($rc->is_success(),1,'mzb_info is_success');
$e=$dri->get_info('releases')->{'release'};
is($e->[0]->{name},'test-andvalidate.isc','mzb_info get_info(releases) first release name value');
is_deeply($e->[0]->{auth},{pw=>'uniregistry'},'mzb_info get_info(releases) first release auth value');
is($e->[0]->{crDate},'2019-02-22T14:14:10.697Z','mzb_info get_info(releases) first release crDate value');
is($e->[1]->{name},'foobar.isc','mzb_info get_info(releases) second release name value');
is_deeply($e->[1]->{auth},{pw=>'foobar'},'mzb_info get_info(releases) second release auth value');
is($e->[1]->{crDate},'2019-09-24T14:14:10.697Z','mzb_info get_info(releases) second release crDate value');

### mzb info response for an unauthorized client
$R2='';
$R2=$E1.'<response>'.r().'<resData><mzb:infData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:labels><mzb:label>test-andvalidate</mzb:label><mzb:label>test-validate</mzb:label></mzb:labels><mzb:registrant>lm39</mzb:registrant><mzb:clID>registry_a</mzb:clID><mzb:crID>registry_a</mzb:crID><mzb:crDate>2019-02-22T14:14:10</mzb:crDate><mzb:exDate>2020-02-22T14:14:10</mzb:exDate></mzb:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->mzb_info('EP_e726f81a44c5c4bd00d160973808825c-UR');
is_string($R1,$E1.'<command><info><mzb:info xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid></mzb:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_info build for an unauthorized client');
is($rc->is_success(),1,'mzb_info is_success for an unauthorized client');
is($dri->get_info('action'),'info','mzb_info get_info(action) for an unauthorized client');
is($dri->get_info('type'),'mzb','mzb_info get_info(type) for an unauthorized client');
is($dri->get_info('roid'),'EP_e726f81a44c5c4bd00d160973808825c-UR','mzb_info get_info(roid) for an unauthorized client');
is_deeply($dri->get_info('labels'),['test-andvalidate','test-validate'],'mzb_info get_info(labels) for an unauthorized client');
is($dri->get_info('registrant'),'lm39','mzb_info get_info(registrant) for an unauthorized client');
is($dri->get_info('clID'),'registry_a','mzb_info get_info(clID) for an unauthorized client');
is($dri->get_info('crID'),'registry_a','mzb_info get_info(crID) for an unauthorized client');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','mzb_info get_info(crDate)');
is("".$d,'2019-02-22T14:14:10','mzb_info get_info(crDate) value for an unauthorized client');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','mzb_info get_info(exDate) for an unauthorized client');
is("".$d,'2020-02-22T14:14:10','mzb_info get_info(exDate) value for an unauthorized client');

# mzb exempt with multiple exemptions in response
$R2=$E1.'<response>'.r().'<resData><mzb:empData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:ed><mzb:label>test-validate</mzb:label><mzb:exemptions><mzb:exemption><mzb:iprID>3111246</mzb:iprID><mzb:labels><mzb:label>test-andvalidate</mzb:label><mzb:label>test-validate</mzb:label></mzb:labels></mzb:exemption><mzb:exemption><mzb:iprID>3111777</mzb:iprID><mzb:labels><mzb:label>test-validate</mzb:label></mzb:labels></mzb:exemption></mzb:exemptions></mzb:ed></mzb:empData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->mzb_exempt('test-validate');
is_string($R1,$E1.'<command><check><mzb:exempt xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:label>test-validate</mzb:label></mzb:exempt></check><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_exempt build (single label)');
is($rc->is_success(),1,'mzb_exempt single label is_success');
is($dri->get_info('action'),'exempt','mzb_exempt get_info(action)');
is($dri->get_info('type'),'mzb','mzb_exempt get_info(type)');
is($dri->get_info('label'),'test-validate','mzb_exempt get_info(label)');
@exemptions=@{$dri->get_info('exemptions')};
$e=shift @exemptions;
is($e->{iprID},'3111246','mzb_exempt get_exemptions(iprID)');
is_deeply($e->{labels},['test-andvalidate','test-validate'],'mzb_exempt get_exemptions(labels)');
$e = shift @exemptions;
is($e->{iprID},'3111777','mzb_exempt get_exemptions(iprID)');
is_deeply($e->{labels},['test-validate'],'mzb_exempt get_exemptions(labels)');

# FIXME - this test fails is the previous test is removed, suggesting that its only passing due to caching.
# Verified by running cache_clear. Only the second (last?) label is being returned by get_info. Will raise separately.
#$dri->cache_clear();

# mzb exempt - multi (they don't have a sample but let create one based on their doc specs)
$R2=$E1.'<response>'.r().'<resData><mzb:empData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:ed><mzb:label>test-validate</mzb:label><mzb:exemptions><mzb:exemption><mzb:iprID>3111246</mzb:iprID><mzb:labels><mzb:label>test-andvalidate</mzb:label><mzb:label>test-validate</mzb:label></mzb:labels></mzb:exemption></mzb:exemptions></mzb:ed><mzb:ed><mzb:label>foobar-validate</mzb:label><mzb:exemptions><mzb:exemption><mzb:iprID>20190925</mzb:iprID><mzb:labels><mzb:label>foobar-andvalidate</mzb:label><mzb:label>foobar-validate</mzb:label></mzb:labels></mzb:exemption></mzb:exemptions></mzb:ed></mzb:empData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->mzb_exempt(qw/test-validate foobar-validate/);
is_string($R1,$E1.'<command><check><mzb:exempt xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:label>test-validate</mzb:label><mzb:label>foobar-validate</mzb:label></mzb:exempt></check><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_exempt build (multi label)');
is($rc->is_success(),1,'mzb_exempt multi is_success');
is($dri->get_info('action'),'exempt_multi','mzb_exempt multi get_info(action)');
is($dri->get_info('type'),'mzb','mzb_exempt multi get_info(type)');
@exemptions=@{$dri->get_info('exemptions','mzb','test-validate')};
$e=shift @exemptions;
is($e->{iprID},'3111246','mzb_exempt multi get_exemptions(iprID) - test-validate label');
is_deeply($e->{labels},['test-andvalidate','test-validate'],'mzb_exempt multi get_exemptions(labels) - test-validate label');
@exemptions=@{$dri->get_info('exemptions','mzb','foobar-validate')};
$e=shift @exemptions;
is($e->{iprID},'20190925','mzb_exempt multi get_exemptions(iprID) - foobar-validate label');
is_deeply($e->{labels},['foobar-andvalidate','foobar-validate'],'mzb_exempt multi get_exemptions(labels) - foobar-validate label');

# mzb create
$R2=$E1.'<response>'.r().'<resData><mzb:creData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:crDate>2019-02-22T14:14:10</mzb:crDate><mzb:exDate>2020-02-22T14:14:10</mzb:exDate></mzb:creData></resData>'.$TRID.'</response>'.$E2;
@labels = qw/test-andvalidate test-validate/;
$rc=$dri->mzb_create(\@labels, {product_type => "standard", duration => DateTime::Duration->new(years=>1), registrant => ("lm39"), auth=>{pw=>"abcd1234"}});
is_string($R1,$E1.'<command><create><mzb:create xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd" type="standard"><mzb:labels><mzb:label>test-andvalidate</mzb:label><mzb:label>test-validate</mzb:label></mzb:labels><mzb:period>1</mzb:period><mzb:registrant>lm39</mzb:registrant><mzb:authInfo><mzb:pw>abcd1234</mzb:pw></mzb:authInfo></mzb:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_create build');
is($rc->is_success(),1,'mzb_create is_success');
is($dri->get_info('action'),'create','mzb_create get_info(action)');
is($dri->get_info('type'),'mzb','mzb_create get_info(type)');
is($dri->get_info('roid'),'EP_e726f81a44c5c4bd00d160973808825c-UR','mzb_create get_info(roid)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','mzb_create get_info(crDate)');
is("".$d,'2019-02-22T14:14:10','mzb_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','mzb_create get_info(exDate)');
is("".$d,'2020-02-22T14:14:10','mzb_create get_info(exDate) value');
# test mandatory fields
throws_ok { $dri->mzb_create(\@labels, {registrant => ("lm39"), auth=>{pw=>"abcd1234"}}) } qr/type must be standard or plus/, 'mzb_create build error check - no product_type';
throws_ok { $dri->mzb_create(\@labels, {product_type => "standard", registrant => ("lm39"), auth=>{pw=>"abcd1234"}}) } qr/period\/duration is mandatory/, 'mzb_create build error check - no period/duration';
throws_ok { $dri->mzb_create(\@labels, {product_type => "standard", duration => DateTime::Duration->new(years=>1), auth=>{pw=>"abcd1234"}}) } qr/registrant is mandatory/, 'mzb_create build error check - no registrant';
throws_ok { $dri->mzb_create(\@labels, {product_type => "standard", duration => DateTime::Duration->new(years=>1), registrant => ("lm39")}) } qr/authInfo is mandatory/, 'mzb_create build error check - no authInfo';

# mzb create with SMD file validation
$R2=$E1.'<response>'.r().'<resData><mzb:creData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:crDate>2019-02-22T14:14:10</mzb:crDate><mzb:exDate>2020-02-22T14:14:10</mzb:exDate></mzb:creData></resData>'.$TRID.'</response>'.$E2;
@labels = qw/test-andvalidate test-validate/;
# Encoded signed mark validation model
$enc=<<'EOF';
<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWduZWRNYXJrIHht
bG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRNYXJrLTEuMCIgaWQ9Il85M2Yz
Y2M5Yy1mOTNlLTQ5ZDgtYmU2Yi04NmJlOWQ4ZDQ1ODkiPjxzbWQ6aWQ+MDAwMDAwODUxNTI2MDc2
ODYwMjM0LTY1NTM1PC9zbWQ6aWQ+PHNtZDppc3N1ZXJJbmZvIGlzc3VlcklmzbI2NTUzNSI+PHNt
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
$rc=$dri->mzb_create(\@labels, {product_type => ("plus"), duration => DateTime::Duration->new(years=>1), registrant => ("lm39"), auth=>{pw=>"abcd1234"}, lp => $lp});
is_string($R1,$E1.'<command><create><mzb:create xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd" type="plus"><mzb:labels><mzb:label>test-andvalidate</mzb:label><mzb:label>test-validate</mzb:label></mzb:labels><mzb:period>1</mzb:period><mzb:registrant>lm39</mzb:registrant><mzb:authInfo><mzb:pw>abcd1234</mzb:pw></mzb:authInfo></mzb:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="application"><launch:phase>open</launch:phase>'.$enc.'</launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_create build with SMD file validation');
is($rc->is_success(),1,'mzb_create is_success with SMD file validation');
is($dri->get_info('action'),'create','mzb_create get_info(action) with SMD file validation');
is($dri->get_info('type'),'mzb','mzb_create get_info(type) with SMD file validation');
is($dri->get_info('roid'),'EP_e726f81a44c5c4bd00d160973808825c-UR','mzb_create get_info(roid) with SMD file validation');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','mzb_create get_info(crDate) with SMD file validation');
is("".$d,'2019-02-22T14:14:10','mzb_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','mzb_create get_info(exDate) with SMD file validation');
is("".$d,'2020-02-22T14:14:10','mzb_create get_info(exDate) value');

# same command with single label in array
@labels = qw/test-and-validate/;
$rc=$dri->mzb_create(\@labels, {product_type => ("plus"), duration => DateTime::Duration->new(years=>1), registrant => ("lm39"), auth=>{pw=>"abcd1234"}, lp => $lp});
is_string($R1,$E1.'<command><create><mzb:create xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd" type="plus"><mzb:labels><mzb:label>test-and-validate</mzb:label></mzb:labels><mzb:period>1</mzb:period><mzb:registrant>lm39</mzb:registrant><mzb:authInfo><mzb:pw>abcd1234</mzb:pw></mzb:authInfo></mzb:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="application"><launch:phase>open</launch:phase>'.$enc.'</launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_create build with SMD file validation');
is($rc->is_success(),1,'mzb_create is_success with SMD file validation');
is($dri->get_info('action'),'create','mzb_create get_info(action) with SMD file validation');

# same command with single label in scalar
$rc=$dri->mzb_create('test-et-validate', {product_type => ("plus"), duration => DateTime::Duration->new(years=>1), registrant => ("lm39"), auth=>{pw=>"abcd1234"}, lp => $lp});
is_string($R1,$E1.'<command><create><mzb:create xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd" type="plus"><mzb:labels><mzb:label>test-et-validate</mzb:label></mzb:labels><mzb:period>1</mzb:period><mzb:registrant>lm39</mzb:registrant><mzb:authInfo><mzb:pw>abcd1234</mzb:pw></mzb:authInfo></mzb:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="application"><launch:phase>open</launch:phase>'.$enc.'</launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_create build with SMD file validation');
is($rc->is_success(),1,'mzb_create is_success with SMD file validation');
is($dri->get_info('action'),'create','mzb_create get_info(action) with SMD file validation');


# mzb delete
$R2=$E1.'<response>'.r().'<msgQ count="2" id="1"/>'.$TRID.'</response>'.$E2;
$rc=$dri->mzb_delete('EP_e726f81a44c5c4bd00d160973808825c-UR');
is_string($R1,$E1.'<command><delete><mzb:delete xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid></mzb:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_delete build');
is($rc->is_success(),1,'mzb_delete is_success');

# mzb renew
$R2=$E1.'<response>'.r().'<resData><mzb:renData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:exDate>2022-02-22T14:14:10</mzb:exDate></mzb:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->mzb_renew('EP_e726f81a44c5c4bd00d160973808825c-UR',{duration => DateTime::Duration->new(years=>2), current_expiration => DateTime->new(year=>2020,month=>2,day=>22)});
is($R1,$E1.'<command><renew><mzb:renew xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:curExpDate>2020-02-22</mzb:curExpDate><mzb:period>2</mzb:period></mzb:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_renew build');
is($dri->get_info('action'),'renew','mzb_renew get_info(action)');
is($dri->get_info('type'),'mzb','mzb_renew get_info(type)');
is($dri->get_info('roid'),'EP_e726f81a44c5c4bd00d160973808825c-UR','mzb_renew get_info(roid)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','mzb_renew get_info(exDate)');
is("".$d,'2022-02-22T14:14:10','mzb_renew get_info(exDate) value');
# test mandatory fields
throws_ok { $dri->mzb_renew('',{duration => DateTime::Duration->new(years=>2), current_expiration => DateTime->new(year=>2020,month=>2,day=>22)}) } qr/roid missing/, 'mzb_renew build error check - no roid';
throws_ok { $dri->mzb_renew('EP_e726f81a44c5c4bd00d160973808825c-UR',{current_expiration => DateTime->new(year=>2020,month=>2,day=>22)}) } qr/period\/duration is mandatory/, 'mzb_renew build error check - no period';
throws_ok { $dri->mzb_renew('EP_e726f81a44c5c4bd00d160973808825c-UR',{duration => DateTime::Duration->new(years=>2)}) } qr/current expiration date/, 'mzb_renew build error check - no current_expiration';
throws_ok { $dri->mzb_renew('EP_e726f81a44c5c4bd00d160973808825c-UR',{duration => DateTime::Duration->new(years=>2), current_expiration => "2022-02-22T14:14:10"}) } qr/current expiration date must be YYYY-MM-DD/, 'mzb_renew build error check - incorrect date format';

# mzb transfer (only op="request" is supported for mzb objects)
$R2=$E1.'<response>'.r().'<resData><mzb:trnData xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:trStatus>serverApproved</mzb:trStatus><mzb:reID>registry_a</mzb:reID><mzb:reDate>2019-02-22T14:15:00</mzb:reDate><mzb:acID>uniregistry</mzb:acID><mzb:acDate>2019-02-22T14:15:00</mzb:acDate></mzb:trnData></resData>'.$TRID.'</response>'.$E2;
$rc = $dri->mzb_transfer_request('EP_e726f81a44c5c4bd00d160973808825c-UR', {auth=>{pw=>'abc1234'}});
is($R1,$E1.'<command><transfer op="request"><mzb:transfer xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:authInfo><mzb:pw>abc1234</mzb:pw></mzb:authInfo></mzb:transfer></transfer><clTRID>ABC-12345</clTRID></command></epp>', 'mzb_transfer_request build');
is($rc->is_success(),1,'mzb_transfer_request is_success');
is($dri->get_info('action'),'transfer_request','mzb_transfer_request get_info(action)');
is($dri->get_info('type'),'mzb','mzb_transfer_request get_info(type)');
is($dri->get_info('roid'),'EP_e726f81a44c5c4bd00d160973808825c-UR','mzb_transfer_request get_info(roid)');
is($dri->get_info('trStatus'),'serverApproved','mzb_transfer_request get_info(trStatus)');
is($dri->get_info('reID'),'registry_a','mzb_transfer_request get_info(reID)');
is($dri->get_info('acID'),'uniregistry','mzb_transfer_request get_info(acID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','mzb_transfer_request get_info(reDate)');
is($d,'2019-02-22T14:15:00','mzb_transfer_request get_info(reDate) value=>"2019-02-22T14:15:00"');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','mzb_transfer_request get_info(acDate)');
is($d,'2019-02-22T14:15:00','mzb_transfer_request get_info(acDate) value=>"2019-02-22T14:15:00"');

# mzb update
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$todo = $dri->local_object('changes');
$todo->set('registrant',$dri->local_object('contact')->srid('reg_a_cntct'));
$todo->set('auth',{pw=>'password'});
$rc=$dri->mzb_update('EP_e726f81a44c5c4bd00d160973808825c-UR', $todo);
is_string($R1,$E1.'<command><update><mzb:update xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:chg><mzb:registrant>reg_a_cntct</mzb:registrant><mzb:authInfo><mzb:pw>password</mzb:pw></mzb:authInfo></mzb:chg></mzb:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_update build');
is($rc->is_success(),1,'mzb_update is_success');

# mzb release create
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->mzb_release_create('EP_e726f81a44c5c4bd00d160973808825c-UR', { name=>("test-andvalidate.isc"), auth=>{pw=>"uniregistry"} });
is_string($R1,$E1.'<command><create><mzb:release xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:name>test-andvalidate.isc</mzb:name><mzb:authInfo><mzb:pw>uniregistry</mzb:pw></mzb:authInfo></mzb:release></create><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_release_create build');
is($rc->is_success(),1,'mzb_release_create is_success');

# mzb release delete
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->mzb_release_delete('EP_e726f81a44c5c4bd00d160973808825c-UR', { name=>("test-andvalidate.isc") });
is_string($R1,$E1.'<command><delete><mzb:release xmlns:mzb="urn:gdreg:params:xml:ns:mzb-1.0" xsi:schemaLocation="urn:gdreg:params:xml:ns:mzb-1.0 mzb-1.0.xsd"><mzb:roid>EP_e726f81a44c5c4bd00d160973808825c-UR</mzb:roid><mzb:name>test-andvalidate.isc</mzb:name></mzb:release></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'mzb_release_delete build');
is($rc->is_success(),1,'mzb_release_delete is_success');



#####################
## Notifications - mzb poll message
# EPP poll message when an mzb object expires: that's the only EPP poll message for mzb and is basically a generic poll message
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ id="16" count="2"><qDate>2019-09-25T21:36:25.615Z</qDate><msg>Uni mzb block \'EP_663bcf1d1cd7cade5d164727156d916f-UR\' has expired and will be auto-renewed in 45 days.</msg></msgQ>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'16','message_retrieve get_info(last_id)');
is($dri->message_count(),2,'message_count (pure text message)');
is(''.$dri->get_info('qdate','message','16'),'2019-09-25T21:36:25','message get_info qdate');
is($dri->get_info('content','message','16'),"Uni mzb block \'EP_663bcf1d1cd7cade5d164727156d916f-UR\' has expired and will be auto-renewed in 45 days.",'message get_info msg');
is($dri->get_info('lang','message','16'),'en','message get_info lang');



exit 0;
