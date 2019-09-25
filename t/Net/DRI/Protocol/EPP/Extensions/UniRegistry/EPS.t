#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper; # TODO: remove me

use Test::More tests => 53;
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
my ($d,$e);

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
exit 0;

# eps exempt - multi (they don't have a sample but let create one based on their doc specs)
$R2=$E1.'<response>'.r().'<resData><eps:empData xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:ed><eps:label>test-validate</eps:label><eps:exemptions><eps:exemption><eps:iprID>3111246</eps:iprID><eps:labels><eps:label>test-andvalidate</eps:label><eps:label>test-validate</eps:label></eps:labels></eps:exemption></eps:exemptions></eps:ed><eps:ed><eps:label>foobar-validate</eps:label><eps:exemptions><eps:exemption><eps:iprID>20190925</eps:iprID><eps:labels><eps:label>foobar-andvalidate</eps:label><eps:label>foobar-validate</eps:label></eps:labels></eps:exemption></eps:exemptions></eps:ed>
</eps:empData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->eps_exempt(qw/test-validate foobar-validate/);
is_string($R1,$E1.'<command><check><eps:exempt xmlns:eps="http://ns.uniregistry.net/eps-1.0" xsi:schemaLocation="http://ns.uniregistry.net/eps-1.0 eps-1.0.xsd"><eps:label>test-validate</eps:label><eps:label>foobar-validate</eps:label></eps:exempt></check><clTRID>ABC-12345</clTRID></command>'.$E2,'eps_exempt build (single label)');
is($rc->is_success(),1,'eps_exempt multi is_success');
is($dri->get_info('action'),'exempt_multi','eps_exempt multi get_info(action)');
is($dri->get_info('type'),'eps','eps_exempt multi get_info(type)');
is($dri->get_info('label'),'test-validate','eps_exempt multi get_info(label)');
$e=$dri->get_info('exemptions');
is($e->{iprID},'3111246','eps_exempt multi get_exemptions(iprID)');
is_deeply($e->{labels},['test-andvalidate','test-validate'],'eps_exempt multi get_exemptions(labels)');


exit 0;