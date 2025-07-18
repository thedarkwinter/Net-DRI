#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 67;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };

$dri->add_current_registry('VeriSign::COM_NET');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['LaunchPhase','-VeriSign::NameStore']});

# for the mark processing
my $po=$dri->{registries}->{'VeriSign::COM_NET'}->{profiles}->{p1}->{protocol};
eval { Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::setup(undef,$po,undef);};
my $parser=XML::LibXML->new();
my ($doc,$root,$rh);


my ($rc,$e,$toc);
my ($lp,$lpres);

#########################################################################################################
## CHECK

# 3.1.1.  Claims Check Form
$lp = {type=>'claims'} ;
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>claims</launch:phase><launch:cd><launch:name exists="1">example2.com</launch:name><launch:claimKey validatorID="sample">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example2.com',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.com</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase>claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');
$lpres = $dri->get_info('lp');
is($lpres->{'exist'},1,'domain_check get_info(exist)');
is($lpres->{'phase'},'claims','domain_check get_info(phase) ');
is($lpres->{'claim_key'},'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','domain_check get_info(claim_key) ');
is($lpres->{'validator_id'},'sample','domain_check get_info(validator_id) ');

# using a custom phase name with custom (autodetected)
$lp = {type=>'claims','phase'=>'foobar'} ;
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase name="foobar">custom</launch:phase><launch:cd><launch:name exists="1">examplef.com</launch:name><launch:claimKey validatorID="sample">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('examplef.com',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>examplef.com</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase name="foobar">custom</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');

# using a claims phase with custom sub_phase
$lp = { type=>'claims','phase'=>'claims', 'sub_phase'=>'barfoo' } ;
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase name="barfoo">claims</launch:phase><launch:cd><launch:name exists="1">examplef2.com</launch:name><launch:claimKey validatorID="sample">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('examplef2.com',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>examplef2.com</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase name="barfoo">claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');

# With multiple claims (launchphase-02), claim_key became 1 or more, so we need to make room for this without breaking backwards compatibility
$lp = {type=>'claims'} ;
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>claims</launch:phase><launch:cd><launch:name exists="1">exampleg2.com</launch:name><launch:claimKey validatorID="tmch">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey><launch:claimKey validatorID="custom-tmch">20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('exampleg2.com',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exampleg2.com</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase>claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');
$lpres = $dri->get_info('lp');
is($lpres->{'exist'},1,'domain_check get_info(exist)');
is($lpres->{'phase'},'claims','domain_check get_info(phase)');
# pre launchphase-02 method will only get the last claim, but its safe if there is only one claim
is($lpres->{'claim_key'},'20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002','domain_check get_info(claim_key) ');
is($lpres->{'validator_id'},'custom-tmch','domain_check get_info(validator_id) ');
# added claims_count and claims in launchphase-02
is($lpres->{'claims_count'},'2','domain_check get_info(claims_count)');
is_deeply($lpres->{'claims'},[{claim_key=>'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','validator_id'=>'tmch'},{claim_key=>'20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002','validator_id'=>'custom-tmch'}],'domain_check get_info(claims_count)');

# 3.1.1.  Claims Check Form Multi
$lp = {type=>'claims'} ;
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>claims</launch:phase><launch:cd><launch:name exists="0">examplea.com</launch:name></launch:cd><launch:cd><launch:name exists="1">exampleb.com</launch:name><launch:claimKey>2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('examplea.com','exampleb.com',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>examplea.com</domain:name><domain:name>exampleb.com</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase>claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check_multi build_xml');
is($dri->get_info('exist','domain','examplea.com'),0,'domain_check_multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','exampleb.com'),1,'domain_check_multi get_info(exist) 2/2');
$lpres = $dri->get_info('lp','domain','exampleb.com');
is($lpres->{'claim_key'},'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','domain_check_multi get_info(claim_key) ');

# With multiple claims (launchphase-02), claim_key became 1 or more, so we need to make room for this without breaking backwards compatibility
$lp = {type=>'claims'} ;
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>claims</launch:phase><launch:cd><launch:name exists="0">examplea1.com</launch:name></launch:cd><launch:cd><launch:name exists="1">exampleb1.com</launch:name><launch:claimKey>2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd><launch:cd><launch:name exists="1">examplec1.com</launch:name><launch:claimKey validatorID="tmch">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey><launch:claimKey validatorID="custom-tmch">20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('examplea1.com','exampleb1.com','examplec1.com',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>examplea1.com</domain:name><domain:name>exampleb1.com</domain:name><domain:name>examplec1.com</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase>claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check_multi build_xml');
is($dri->get_info('exist','domain','examplea1.com'),0,'domain_check_multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','exampleb1.com'),1,'domain_check_multi get_info(exist) 2/2');
is($dri->get_info('exist','domain','examplec1.com'),1,'domain_check_multi get_info(exist) 2/2');
$lpres = $dri->get_info('lp','domain','exampleb1.com');
is($lpres->{'claim_key'},'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','domain_check_multi get_info(claim_key)');

$lpres = $dri->get_info('lp','domain','examplec1.com');
# pre launchphase-02 method will only get the last claim, but its safe if there is only one claim
is($lpres->{'claim_key'},'20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002','domain_check get_info(claim_key) ');
is($lpres->{'validator_id'},'custom-tmch','domain_check get_info(validator_id) ');
# added claims_count and claims in launchphase-02
is($lpres->{'claims_count'},'2','domain_check get_info(claims_count)');
is_deeply($lpres->{'claims'},[{claim_key=>'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','validator_id'=>'tmch'},{claim_key=>'20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002','validator_id'=>'custom-tmch'}],'domain_check get_info(claims_count)');

#3.1.2.  Availability Check Form
$lp = {phase=>'idn-release',type=>'avail'};
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.com</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.com',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.com</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="avail"><launch:phase name="idn-release">custom</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');

#3.1.2.  Availability Check Form
$lp = {phase=>'idn-release',type=>'avail'};
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.com</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.com',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.com</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="avail"><launch:phase name="idn-release">custom</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');

#2.3  Availability Check Using Phase 'claims' and subphase 'landrush'
$lp = {phase=>'claims',sub_phase=>'landrush',type=>'avail'};
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example4.com</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example4.com',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="avail"><launch:phase name="landrush">claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check with subphase build_xml');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');

#3.1.3.  Trademark Check Form => draft-ietf-eppext-launchphase-03
$dri->cache_clear();
$lp = {type=>'trademark'};
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:cd><launch:name exists="0">example1.com</launch:name></launch:cd><launch:cd><launch:name exists="1">example2.com</launch:name><launch:claimKey validatorID="tmch">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd><launch:cd><launch:name exists="1">example3.com</launch:name><launch:claimKey validatorID="tmch">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey><launch:claimKey validatorID="custom-tmch">20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example1.com','example2.com','example3.com',{lp => $lp});
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1.com</domain:name><domain:name>example2.com</domain:name><domain:name>example3.com</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="trademark"/></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check_multi build_xml');
is($dri->get_info('exist','domain','example1.com'),0,'domain_check_multi get_info(exist) 1/3');
is($dri->get_info('exist','domain','example2.com'),1,'domain_check_multi get_info(exist) 2/3');
is($dri->get_info('exist','domain','example3.com'),1,'domain_check_multi get_info(exist) 3/3');
$lpres = $dri->get_info('lp','domain','example1.com');
is($lpres->{'claim_key'},undef,'domain_check_multi get_info(claim_key) 1/3');
$lpres = $dri->get_info('lp','domain','example2.com');
is($lpres->{'claim_key'},'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','domain_check_multi get_info(claim_key) 2/3');
$lpres = $dri->get_info('lp','domain','example3.com');
is($lpres->{'claims_count'},'2','domain_check get_info(claims_count)');
is_deeply($lpres->{'claims'},[{claim_key=>'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','validator_id'=>'tmch'},{claim_key=>'20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002','validator_id'=>'custom-tmch'}],'domain_check get_info(claims_count)');

## INFO
#3.2.  EPP <info> Command
$lp = {phase => 'sunrise','application_id'=>'abc123','include_mark'=>'true'};
my $markxml = '<mark:mark xmlns:mark="urn:ietf:params:xml:ns:mark-1.0"><mark:trademark><mark:id>1234-2</mark:id><mark:markName>Example One</mark:markName><mark:holder entitlement="owner"><mark:org>Example Inc.</mark:org><mark:addr><mark:street>123 Example Dr.</mark:street><mark:street>Suite 100</mark:street><mark:city>Reston</mark:city><mark:sp>VA</mark:sp><mark:pc>20190</mark:pc><mark:cc>US</mark:cc></mark:addr></mark:holder><mark:jurisdiction>US</mark:jurisdiction><mark:class>35</mark:class><mark:class>36</mark:class><mark:label>example-one</mark:label><mark:label>exampleone</mark:label><mark:goodsAndServices>Dirigendas et eiusmodifeaturing infringo in airfare et cartam servicia.</mark:goodsAndServices><mark:regNum>234235</mark:regNum><mark:regDate>2009-08-16T09:00:00.0Z</mark:regDate><mark:exDate>2015-08-16T09:00:00.0Z</mark:exDate></mark:trademark></mark:mark>';
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:host>ns1.example.com</domain:host><domain:host>ns2.example.com</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><launch:infData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>sunrise</launch:phase><launch:applicationID>abc123</launch:applicationID><launch:status s="pendingAllocation"/>'.$markxml.'</launch:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example2.com',{lp => $lp});
is ($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example2.com</domain:name></domain:info></info><extension><launch:info xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" includeMark="true"><launch:phase>sunrise</launch:phase><launch:applicationID>abc123</launch:applicationID></launch:info></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info build_xml');
$lpres = $dri->get_info('lp');
is($lpres->{'phase'},'sunrise','domain_info get_info(phase) ');
is($lpres->{'application_id'},'abc123','domain_info get_info(application_id) ');
is($lpres->{'status'},'pendingAllocation','domain_info get_info(launch_status) ');
my @marks = @{$lpres->{'marks'}};
my $m = $marks[0];
is ($m->{mark_name},'Example One','domain_info get_info(mark name)');

$doc=$parser->parse_string('<?xml version="1.0" encoding="UTF-8"?>'.$markxml);
$root=$doc->getDocumentElement();
my $m2=Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_mark($po,$root);
is_deeply($m, @{$m2}[0], 'data structures should be the same');

## CREATE
# 3.3.1.  Sunrise Create Form

# Code validation model
$lp = {phase => 'sunrise','code_marks'=>[ {code=>'123', validator_id => 'sample'},{code=>456}] }; # CAREFUL how you build the list, these are two separate codes
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.tld</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData><extension><launch:creData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>sunrise</launch:phase><launch:applicationID>2393-9323-E08C-03B1</launch:applicationID></launch:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><launch:codeMark><launch:code validatorID="sample">123</launch:code></launch:codeMark><launch:codeMark><launch:code>456</launch:code></launch:codeMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [code validation model]');
$lpres = $dri->get_info('lp');
is($lpres->{'phase'},'sunrise','domain_create get_info(phase) ');
is($lpres->{'application_id'},'2393-9323-E08C-03B1','domain_create get_info(application_id)');

# Mark validation model
$lp = {phase => 'sunrise','code_marks'=>[ {mark=>$m} ] };
$R2='';
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><launch:codeMark><mark:mark xmlns:mark="urn:ietf:params:xml:ns:mark-1.0"><mark:trademark><mark:id>1234-2</mark:id><mark:markName>Example One</mark:markName><mark:holder entitlement="owner"><mark:org>Example Inc.</mark:org><mark:addr><mark:street>123 Example Dr.</mark:street><mark:street>Suite 100</mark:street><mark:city>Reston</mark:city><mark:sp>VA</mark:sp><mark:pc>20190</mark:pc><mark:cc>US</mark:cc></mark:addr></mark:holder><mark:jurisdiction>US</mark:jurisdiction><mark:class>35</mark:class><mark:class>36</mark:class><mark:label>example-one</mark:label><mark:label>exampleone</mark:label><mark:goodsAndServices>Dirigendas et eiusmodifeaturing infringo in airfare et cartam servicia.</mark:goodsAndServices><mark:regNum>234235</mark:regNum><mark:regDate>2009-08-16T09:00:00Z</mark:regDate><mark:exDate>2015-08-16T09:00:00Z</mark:exDate></mark:trademark></mark:mark></launch:codeMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [mark validation model]');

# Code with Mark validation model
$lp = {phase => 'sunrise','code_marks'=>[ {code=>'49FD46E6C4B45C55D4AC',mark=>$m} ] }; # CAREFUL how you build the list, this is *single* code + mark
$R2='';
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><launch:codeMark><launch:code>49FD46E6C4B45C55D4AC</launch:code><mark:mark xmlns:mark="urn:ietf:params:xml:ns:mark-1.0"><mark:trademark><mark:id>1234-2</mark:id><mark:markName>Example One</mark:markName><mark:holder entitlement="owner"><mark:org>Example Inc.</mark:org><mark:addr><mark:street>123 Example Dr.</mark:street><mark:street>Suite 100</mark:street><mark:city>Reston</mark:city><mark:sp>VA</mark:sp><mark:pc>20190</mark:pc><mark:cc>US</mark:cc></mark:addr></mark:holder><mark:jurisdiction>US</mark:jurisdiction><mark:class>35</mark:class><mark:class>36</mark:class><mark:label>example-one</mark:label><mark:label>exampleone</mark:label><mark:goodsAndServices>Dirigendas et eiusmodifeaturing infringo in airfare et cartam servicia.</mark:goodsAndServices><mark:regNum>234235</mark:regNum><mark:regDate>2009-08-16T09:00:00Z</mark:regDate><mark:exDate>2015-08-16T09:00:00Z</mark:exDate></mark:trademark></mark:mark></launch:codeMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [code and mark validation model]');

# signed mark validation model
my $smd=<<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
  <smd:signedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0" id="signedMark">
   <smd:id>1-2</smd:id>
   <smd:issuerInfo issuerID="2">
    <smd:org>Example Inc.</smd:org>
    <smd:email>support@example.tld</smd:email>
    <smd:url>http://www.example.tld</smd:url>
    <smd:voice x="1234">+1.7035555555</smd:voice>
   </smd:issuerInfo>
   <smd:notBefore>2009-08-16T09:00:00.0Z</smd:notBefore>
   <smd:notAfter>2010-08-16T09:00:00.0Z</smd:notAfter>
   <mark:mark xmlns:mark="urn:ietf:params:xml:ns:mark-1.0">
    <mark:trademark>
     <mark:id>1234-2</mark:id>
     <mark:markName>Example One</mark:markName>
     <mark:holder entitlement="owner">
      <mark:org>Example Inc.</mark:org>
      <mark:addr>
       <mark:street>123 Example Dr.</mark:street>
       <mark:street>Suite 100</mark:street>
       <mark:city>Reston</mark:city>
       <mark:sp>VA</mark:sp>
       <mark:pc>20190</mark:pc>
       <mark:cc>US</mark:cc>
      </mark:addr>
     </mark:holder>
     <mark:jurisdiction>US</mark:jurisdiction>
     <mark:class>35</mark:class>
     <mark:class>36</mark:class>
     <mark:label>example-one</mark:label>
     <mark:label>exampleone</mark:label>
     <mark:goodsAndServices>Dirigendas et eiusmodi
      featuring infringo in airfare et cartam servicia.
     </mark:goodsAndServices>
     <mark:regNum>234235</mark:regNum>
     <mark:regDate>2009-08-16T09:00:00.0Z</mark:regDate>
     <mark:exDate>2015-08-16T09:00:00.0Z</mark:exDate>
    </mark:trademark>
   </mark:mark>
   <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
    <SignedInfo>
     <CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
     <SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
     <Reference URI="#signedMark">
      <Transforms>
       <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
      </Transforms>
      <DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
      <DigestValue>
       miF4M2aTd1Y3tKOzJtiyl2VpzAnVPnV1Hq7Zax+yzrA=
      </DigestValue>
     </Reference>
    </SignedInfo>
    <SignatureValue>
     MELpHTWEVfG1JcsG1/a//o54OnlJ5A864+X5JwfqgGBBeZSzGHNzwzTKFzIyyyfn
     lGxVwNMoBV5aSvkF7oEKMNVzfcl/P0czNQZ/LJ83p3Ol27/iUNsqgCaGf9Zupw+M
     XT4Q2lOrIw+qSx5g7q9T83siMLvkD5uEYlU5dPqgsObLTW8/doTQrA14RcxgY4kG
     a4+t5B1cT+5VaghTOPb8uUSEDKjnOsGdy8p24wgyK9n8h0CTSS2ZQ6Zq/RmQeT7D
     sbceUHheQ+mkQWIljpMQqsiBjw5XXh4jkEgfAzrb6gkYEF+X8ReuPZuOYC4QjIET
     yx8ifN4KE3GIbMXeF4LDsA==
    </SignatureValue>
    <KeyInfo>
     <KeyValue>
      <RSAKeyValue>
       <Modulus>
        o/cwvXhbVYl0RDWWvoyeZpETVZVVcMCovUVNg/swWinuMgEWgVQFrz0xA04pEhXC
        FVv4evbUpekJ5buqU1gmQyOsCKQlhOHTdPjvkC5upDqa51Flk0TMaMkIQjs7aUKC
        mA4RG4tTTGK/EjR1ix8/D0gHYVRldy1YPrMP+ou75bOVnIos+HifrAtrIv4qEqwL
        L4FTZAUpaCa2BmgXfy2CSRQbxD5Or1gcSa3vurh5sPMCNxqaXmIXmQipS+DuEBqM
        M8tldaN7RYojUEKrGVsNk5i9y2/7sjn1zyyUPf7vL4GgDYqhJYWV61DnXgx/Jd6C
        WxvsnDF6scscQzUTEl+hyw==
       </Modulus>
       <Exponent>
        AQAB
       </Exponent>
      </RSAKeyValue>
     </KeyValue>
     <X509Data>
      <X509Certificate>
       MIIESTCCAzGgAwIBAgIBAjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEL
       MAkGA1UECBMCQ0ExFDASBgNVBAcTC0xvcyBBbmdlbGVzMRMwEQYDVQQKEwpJQ0FO
       TiBUTUNIMRswGQYDVQQDExJJQ0FOTiBUTUNIIFRFU1QgQ0EwHhcNMTMwMjA4MDAw
       MDAwWhcNMTgwMjA3MjM1OTU5WjBsMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0Ex
       FDASBgNVBAcTC0xvcyBBbmdlbGVzMRcwFQYDVQQKEw5WYWxpZGF0b3IgVE1DSDEh
       MB8GA1UEAxMYVmFsaWRhdG9yIFRNQ0ggVEVTVCBDRVJUMIIBIjANBgkqhkiG9w0B
       AQEFAAOCAQ8AMIIBCgKCAQEAo/cwvXhbVYl0RDWWvoyeZpETVZVVcMCovUVNg/sw
       WinuMgEWgVQFrz0xA04pEhXCFVv4evbUpekJ5buqU1gmQyOsCKQlhOHTdPjvkC5u
       pDqa51Flk0TMaMkIQjs7aUKCmA4RG4tTTGK/EjR1ix8/D0gHYVRldy1YPrMP+ou7
       5bOVnIos+HifrAtrIv4qEqwLL4FTZAUpaCa2BmgXfy2CSRQbxD5Or1gcSa3vurh5
       sPMCNxqaXmIXmQipS+DuEBqMM8tldaN7RYojUEKrGVsNk5i9y2/7sjn1zyyUPf7v
       L4GgDYqhJYWV61DnXgx/Jd6CWxvsnDF6scscQzUTEl+hywIDAQABo4H/MIH8MAwG
       A1UdEwEB/wQCMAAwHQYDVR0OBBYEFPZEcIQcD/Bj2IFz/LERuo2ADJviMIGMBgNV
       HSMEgYQwgYGAFO0/7kEh3FuEKS+Q/kYHaD/W6wihoWakZDBiMQswCQYDVQQGEwJV
       UzELMAkGA1UECBMCQ0ExFDASBgNVBAcTC0xvcyBBbmdlbGVzMRMwEQYDVQQKEwpJ
       Q0FOTiBUTUNIMRswGQYDVQQDExJJQ0FOTiBUTUNIIFRFU1QgQ0GCAQEwDgYDVR0P
       AQH/BAQDAgeAMC4GA1UdHwQnMCUwI6AhoB+GHWh0dHA6Ly9jcmwuaWNhbm4ub3Jn
       L3RtY2guY3JsMA0GCSqGSIb3DQEBCwUAA4IBAQB2qSy7ui+43cebKUKwWPrzz9y/
       IkrMeJGKjo40n+9uekaw3DJ5EqiOf/qZ4pjBD++oR6BJCb6NQuQKwnoAz5lE4Ssu
       y5+i93oT3HfyVc4gNMIoHm1PS19l7DBKrbwbzAea/0jKWVzrvmV7TBfjxD3AQo1R
       bU5dBr6IjbdLFlnO5x0G0mrG7x5OUPuurihyiURpFDpwH8KAH1wMcCpXGXFRtGKk
       wydgyVYAty7otkl/z3bZkCVT34gPvF70sR6+QxUy8u0LzF5A/beYaZpxSYG31amL
       AdXitTWFipaIGea9lEGFM0L9+Bg7XzNn4nVLXokyEB3bgS4scG6QznX23FGk
      </X509Certificate>
     </X509Data>
    </KeyInfo>
   </Signature>
  </smd:signedMark>
EOF
chomp $smd;

$doc=$parser->parse_string($smd);
$root=$doc->getDocumentElement();
$smd =~ s|<?.*?>\s*||; # for test, remove the xml header is its not put into the xml
#$m=Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_signed_mark($po,$root);

$lp = {phase => 'sunrise','signed_marks'=>[ $root ] }; # CAREFUL how you build the list, this is *single* signed mark
$R2='';
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase>'.$smd.'</launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [signedMark validation model]');

# Encoded signed mark validation model
my $enc=<<'EOF';
<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWdu
ZWRNYXJrIHhtbG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRN
YXJrLTEuMCIgaWQ9InNpZ25lZE1hcmsiPgogIDxzbWQ6aWQ+MS0yPC9zbWQ6aWQ+
CiAgPHNtZDppc3N1ZXJJbmZvIGlzc3VlcklEPSIyIj4KICAgIDxzbWQ6b3JnPkV4
YW1wbGUgSW5jLjwvc21kOm9yZz4KICAgIDxzbWQ6ZW1haWw+c3VwcG9ydEBleGFt
cGxlLnRsZDwvc21kOmVtYWlsPgogICAgPHNtZDp1cmw+aHR0cDovL3d3dy5leGFt
cGxlLnRsZDwvc21kOnVybD4KICAgIDxzbWQ6dm9pY2UgeD0iMTIzNCI+KzEuNzAz
NTU1NTU1NTwvc21kOnZvaWNlPgogIDwvc21kOmlzc3VlckluZm8+CiAgPHNtZDpu
b3RCZWZvcmU+MjAwOS0wOC0xNlQwOTowMDowMC4wWjwvc21kOm5vdEJlZm9yZT4K
ICA8c21kOm5vdEFmdGVyPjIwMTAtMDgtMTZUMDk6MDA6MDAuMFo8L3NtZDpub3RB
ZnRlcj4KICA8bWFyazptYXJrIHhtbG5zOm1hcms9InVybjppZXRmOnBhcmFtczp4
bWw6bnM6bWFyay0xLjAiPgogICAgPG1hcms6dHJhZGVtYXJrPgogICAgICA8bWFy
azppZD4xMjM0LTI8L21hcms6aWQ+CiAgICAgIDxtYXJrOm1hcmtOYW1lPkV4YW1w
bGUgT25lPC9tYXJrOm1hcmtOYW1lPgogICAgICA8bWFyazpob2xkZXIgZW50aXRs
ZW1lbnQ9Im93bmVyIj4KICAgICAgICA8bWFyazpvcmc+RXhhbXBsZSBJbmMuPC9t
YXJrOm9yZz4KICAgICAgICA8bWFyazphZGRyPgogICAgICAgICAgPG1hcms6c3Ry
ZWV0PjEyMyBFeGFtcGxlIERyLjwvbWFyazpzdHJlZXQ+CiAgICAgICAgICA8bWFy
azpzdHJlZXQ+U3VpdGUgMTAwPC9tYXJrOnN0cmVldD4KICAgICAgICAgIDxtYXJr
OmNpdHk+UmVzdG9uPC9tYXJrOmNpdHk+CiAgICAgICAgICA8bWFyazpzcD5WQTwv
bWFyazpzcD4KICAgICAgICAgIDxtYXJrOnBjPjIwMTkwPC9tYXJrOnBjPgogICAg
ICAgICAgPG1hcms6Y2M+VVM8L21hcms6Y2M+CiAgICAgICAgPC9tYXJrOmFkZHI+
CiAgICAgIDwvbWFyazpob2xkZXI+CiAgICAgIDxtYXJrOmp1cmlzZGljdGlvbj5V
UzwvbWFyazpqdXJpc2RpY3Rpb24+CiAgICAgIDxtYXJrOmNsYXNzPjM1PC9tYXJr
OmNsYXNzPgogICAgICA8bWFyazpjbGFzcz4zNjwvbWFyazpjbGFzcz4KICAgICAg
PG1hcms6bGFiZWw+ZXhhbXBsZS1vbmU8L21hcms6bGFiZWw+CiAgICAgIDxtYXJr
OmxhYmVsPmV4YW1wbGVvbmU8L21hcms6bGFiZWw+CiAgICAgIDxtYXJrOmdvb2Rz
QW5kU2VydmljZXM+RGlyaWdlbmRhcyBldCBlaXVzbW9kaQogICAgICAgIGZlYXR1
cmluZyBpbmZyaW5nbyBpbiBhaXJmYXJlIGV0IGNhcnRhbSBzZXJ2aWNpYS4KICAg
ICAgPC9tYXJrOmdvb2RzQW5kU2VydmljZXM+IAogICAgICA8bWFyazpyZWdOdW0+
MjM0MjM1PC9tYXJrOnJlZ051bT4KICAgICAgPG1hcms6cmVnRGF0ZT4yMDA5LTA4
LTE2VDA5OjAwOjAwLjBaPC9tYXJrOnJlZ0RhdGU+CiAgICAgIDxtYXJrOmV4RGF0
ZT4yMDE1LTA4LTE2VDA5OjAwOjAwLjBaPC9tYXJrOmV4RGF0ZT4KICAgIDwvbWFy
azp0cmFkZW1hcms+CiAgPC9tYXJrOm1hcms+CiAgPFNpZ25hdHVyZSB4bWxucz0i
aHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+CiAgICA8U2lnbmVk
SW5mbz4KICAgICAgPENhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJo
dHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz4KICAgICAg
PFNpZ25hdHVyZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIw
MDEvMDQveG1sZHNpZy1tb3JlI3JzYS1zaGEyNTYiLz4KICAgICAgPFJlZmVyZW5j
ZSBVUkk9IiNzaWduZWRNYXJrIj4KICAgICAgICA8VHJhbnNmb3Jtcz4KICAgICAg
ICAgIDxUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAw
LzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPgogICAgICAgIDwvVHJh
bnNmb3Jtcz4KICAgICAgICA8RGlnZXN0TWV0aG9kIEFsZ29yaXRobT0iaHR0cDov
L3d3dy53My5vcmcvMjAwMS8wNC94bWxlbmMjc2hhMjU2Ii8+CiAgICAgICAgPERp
Z2VzdFZhbHVlPm1pRjRNMmFUZDFZM3RLT3pKdGl5bDJWcHpBblZQblYxSHE3WmF4
K3l6ckE9PC9EaWdlc3RWYWx1ZT4KICAgICAgPC9SZWZlcmVuY2U+CiAgICA8L1Np
Z25lZEluZm8+CiAgICA8U2lnbmF0dXJlVmFsdWU+TUVMcEhUV0VWZkcxSmNzRzEv
YS8vbzU0T25sSjVBODY0K1g1SndmcWdHQkJlWlN6R0hOend6VEtGekl5eXlmbgps
R3hWd05Nb0JWNWFTdmtGN29FS01OVnpmY2wvUDBjek5RWi9MSjgzcDNPbDI3L2lV
TnNxZ0NhR2Y5WnVwdytNClhUNFEybE9ySXcrcVN4NWc3cTlUODNzaU1MdmtENXVF
WWxVNWRQcWdzT2JMVFc4L2RvVFFyQTE0UmN4Z1k0a0cKYTQrdDVCMWNUKzVWYWdo
VE9QYjh1VVNFREtqbk9zR2R5OHAyNHdneUs5bjhoMENUU1MyWlE2WnEvUm1RZVQ3
RApzYmNlVUhoZVErbWtRV0lsanBNUXFzaUJqdzVYWGg0amtFZ2ZBenJiNmdrWUVG
K1g4UmV1UFp1T1lDNFFqSUVUCnl4OGlmTjRLRTNHSWJNWGVGNExEc0E9PTwvU2ln
bmF0dXJlVmFsdWU+CiAgICA8S2V5SW5mbz4KICAgICAgPEtleVZhbHVlPgo8UlNB
S2V5VmFsdWU+CjxNb2R1bHVzPgpvL2N3dlhoYlZZbDBSRFdXdm95ZVpwRVRWWlZW
Y01Db3ZVVk5nL3N3V2ludU1nRVdnVlFGcnoweEEwNHBFaFhDCkZWdjRldmJVcGVr
SjVidXFVMWdtUXlPc0NLUWxoT0hUZFBqdmtDNXVwRHFhNTFGbGswVE1hTWtJUWpz
N2FVS0MKbUE0Ukc0dFRUR0svRWpSMWl4OC9EMGdIWVZSbGR5MVlQck1QK291NzVi
T1ZuSW9zK0hpZnJBdHJJdjRxRXF3TApMNEZUWkFVcGFDYTJCbWdYZnkyQ1NSUWJ4
RDVPcjFnY1NhM3Z1cmg1c1BNQ054cWFYbUlYbVFpcFMrRHVFQnFNCk04dGxkYU43
UllvalVFS3JHVnNOazVpOXkyLzdzam4xenl5VVBmN3ZMNEdnRFlxaEpZV1Y2MURu
WGd4L0pkNkMKV3h2c25ERjZzY3NjUXpVVEVsK2h5dz09CjwvTW9kdWx1cz4KPEV4
cG9uZW50PgpBUUFCCjwvRXhwb25lbnQ+CjwvUlNBS2V5VmFsdWU+CjwvS2V5VmFs
dWU+CiAgICAgIDxYNTA5RGF0YT4KPFg1MDlDZXJ0aWZpY2F0ZT5NSUlFU1RDQ0F6
R2dBd0lCQWdJQkFqQU5CZ2txaGtpRzl3MEJBUXNGQURCaU1Rc3dDUVlEVlFRR0V3
SlZVekVMCk1Ba0dBMVVFQ0JNQ1EwRXhGREFTQmdOVkJBY1RDMHh2Y3lCQmJtZGxi
R1Z6TVJNd0VRWURWUVFLRXdwSlEwRk8KVGlCVVRVTklNUnN3R1FZRFZRUURFeEpK
UTBGT1RpQlVUVU5JSUZSRlUxUWdRMEV3SGhjTk1UTXdNakE0TURBdwpNREF3V2hj
Tk1UZ3dNakEzTWpNMU9UVTVXakJzTVFzd0NRWURWUVFHRXdKVlV6RUxNQWtHQTFV
RUNCTUNRMEV4CkZEQVNCZ05WQkFjVEMweHZjeUJCYm1kbGJHVnpNUmN3RlFZRFZR
UUtFdzVXWVd4cFpHRjBiM0lnVkUxRFNERWgKTUI4R0ExVUVBeE1ZVm1Gc2FXUmhk
Rzl5SUZSTlEwZ2dWRVZUVkNCRFJWSlVNSUlCSWpBTkJna3Foa2lHOXcwQgpBUUVG
QUFPQ0FROEFNSUlCQ2dLQ0FRRUFvL2N3dlhoYlZZbDBSRFdXdm95ZVpwRVRWWlZW
Y01Db3ZVVk5nL3N3CldpbnVNZ0VXZ1ZRRnJ6MHhBMDRwRWhYQ0ZWdjRldmJVcGVr
SjVidXFVMWdtUXlPc0NLUWxoT0hUZFBqdmtDNXUKcERxYTUxRmxrMFRNYU1rSVFq
czdhVUtDbUE0Ukc0dFRUR0svRWpSMWl4OC9EMGdIWVZSbGR5MVlQck1QK291Nwo1
Yk9WbklvcytIaWZyQXRySXY0cUVxd0xMNEZUWkFVcGFDYTJCbWdYZnkyQ1NSUWJ4
RDVPcjFnY1NhM3Z1cmg1CnNQTUNOeHFhWG1JWG1RaXBTK0R1RUJxTU04dGxkYU43
UllvalVFS3JHVnNOazVpOXkyLzdzam4xenl5VVBmN3YKTDRHZ0RZcWhKWVdWNjFE
blhneC9KZDZDV3h2c25ERjZzY3NjUXpVVEVsK2h5d0lEQVFBQm80SC9NSUg4TUF3
RwpBMVVkRXdFQi93UUNNQUF3SFFZRFZSME9CQllFRlBaRWNJUWNEL0JqMklGei9M
RVJ1bzJBREp2aU1JR01CZ05WCkhTTUVnWVF3Z1lHQUZPMC83a0VoM0Z1RUtTK1Ev
a1lIYUQvVzZ3aWhvV2FrWkRCaU1Rc3dDUVlEVlFRR0V3SlYKVXpFTE1Ba0dBMVVF
Q0JNQ1EwRXhGREFTQmdOVkJBY1RDMHh2Y3lCQmJtZGxiR1Z6TVJNd0VRWURWUVFL
RXdwSgpRMEZPVGlCVVRVTklNUnN3R1FZRFZRUURFeEpKUTBGT1RpQlVUVU5JSUZS
RlUxUWdRMEdDQVFFd0RnWURWUjBQCkFRSC9CQVFEQWdlQU1DNEdBMVVkSHdRbk1D
VXdJNkFob0IrR0hXaDBkSEE2THk5amNtd3VhV05oYm00dWIzSm4KTDNSdFkyZ3VZ
M0pzTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFCMnFTeTd1aSs0M2NlYktVS3dX
UHJ6ejl5LwpJa3JNZUpHS2pvNDBuKzl1ZWthdzNESjVFcWlPZi9xWjRwakJEKytv
UjZCSkNiNk5RdVFLd25vQXo1bEU0U3N1Cnk1K2k5M29UM0hmeVZjNGdOTUlvSG0x
UFMxOWw3REJLcmJ3YnpBZWEvMGpLV1Z6cnZtVjdUQmZqeEQzQVFvMVIKYlU1ZEJy
NklqYmRMRmxuTzV4MEcwbXJHN3g1T1VQdXVyaWh5aVVScEZEcHdIOEtBSDF3TWND
cFhHWEZSdEdLawp3eWRneVZZQXR5N290a2wvejNiWmtDVlQzNGdQdkY3MHNSNitR
eFV5OHUwTHpGNUEvYmVZYVpweFNZRzMxYW1MCkFkWGl0VFdGaXBhSUdlYTlsRUdG
TTBMOStCZzdYek5uNG5WTFhva3lFQjNiZ1M0c2NHNlF6blgyM0ZHazwvWDUwOUNl
cnRpZmljYXRlPgo8L1g1MDlEYXRhPgogICAgPC9LZXlJbmZvPgogIDwvU2lnbmF0
dXJlPgo8L3NtZDpzaWduZWRNYXJrPgo=
</smd:encodedSignedMark>
EOF
chomp $enc;
$doc=$parser->parse_string($enc);
$root=$doc->getDocumentElement();

$lp = {phase => 'sunrise','encoded_signed_marks'=>[ $enc ] }; # CAREFUL how you build the list, this is *single* encoded signed mark
$R2='';
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase>'.$enc.'</launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [encoded_signed_mark validation model - using padded string]');

$lp = {phase => 'sunrise','encoded_signed_marks'=>[ 'ABC123=' ] }; # CAREFUL how you build the list, this is *single* encoded signed mark
$R2='';
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">ABC123=</smd:encodedSignedMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [encoded_signed_mark validation model - using unpadded string]');

$lp = {phase => 'sunrise','encoded_signed_marks'=>[ $root ] }; # CAREFUL how you build the list, this is *single* encoded signed mark
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase>'.$enc.'</launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [encoded_signed_mark validation model - using xml root element]');


#3.3.2.  Claims Create Form
$lp = {phase => 'claims', notices => [ {id=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ] }; # notices = array of hashes
$R2='';
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>claims</launch:phase><launch:notice><launch:noticeID>abc123</launch:noticeID><launch:notAfter>2008-12-01T00:00:00Z</launch:notAfter><launch:acceptedDate>2009-10-01T00:00:00Z</launch:acceptedDate></launch:notice></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [claims create]');

# create with multiple notices (launchphase-02 example although this was supported before anyway)
$lp = {phase => 'claims', notices => [
   {id=>'370d0b7c9223372036854775807',  validator_id=>'tmch',        not_after_date=>DateTime->new({year=>2014,month=>06,day=>19,hour=>10}),  accepted_date=>DateTime->new({year=>2014,month=>06,day=>19,hour=>9}) },
   {id=>'470d0b7c9223654313275808',     validator_id=>'custom-tmch', not_after_date=>DateTime->new({year=>2014,month=>06,day=>19,hour=>10}),  accepted_date=>DateTime->new({year=>2014,month=>06,day=>19,hour=>9,second=>30}) }
 ] };
$R2='';
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>claims</launch:phase><launch:notice><launch:noticeID validatorID="tmch">370d0b7c9223372036854775807</launch:noticeID><launch:notAfter>2014-06-19T10:00:00Z</launch:notAfter><launch:acceptedDate>2014-06-19T09:00:00Z</launch:acceptedDate></launch:notice><launch:notice><launch:noticeID validatorID="custom-tmch">470d0b7c9223654313275808</launch:noticeID><launch:notAfter>2014-06-19T10:00:00Z</launch:notAfter><launch:acceptedDate>2014-06-19T09:00:30Z</launch:acceptedDate></launch:notice></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [claims create]');

#3.3.3.  General Create Form
$lp = {phase => 'landrush','type' =>'application'};
$R2='';
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="application"><launch:phase>landrush</launch:phase></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [general create]');

#3.3.4.  Mixed Create Form
$lp = {type=>'registration', phase => 'non-tmch-sunrise','code_marks'=>[ {code=>'123'}], notices => [ {'id'=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ]  };
$R2='';
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="registration"><launch:phase name="non-tmch-sunrise">custom</launch:phase><launch:codeMark><launch:code>123</launch:code></launch:codeMark><launch:notice><launch:noticeID>abc123</launch:noticeID><launch:notAfter>2008-12-01T00:00:00Z</launch:notAfter><launch:acceptedDate>2009-10-01T00:00:00Z</launch:acceptedDate></launch:notice></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [mixed create]');

# Create using Multiple Launch items. E.G. Donuts DPML + Claims
my $lp1 = {phase => 'landrush','type' =>'application' };
my $lp2 = {type=>'registration', phase => 'claims',notices => [ {'id'=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ]  };
$rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>[$lp1,$lp2]});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="application"><launch:phase>landrush</launch:phase></launch:create><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="registration"><launch:phase>claims</launch:phase><launch:notice><launch:noticeID>abc123</launch:noticeID><launch:notAfter>2008-12-01T00:00:00Z</launch:notAfter><launch:acceptedDate>2009-10-01T00:00:00Z</launch:acceptedDate></launch:notice></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml [general create]');

# UPDATE
$lp = {phase => 'sunrise','application_id'=>'abc321'};
$R2='';
$toc=$dri->local_object('changes');
$toc->set('lp',$lp);
$rc=$dri->domain_update('example10.com',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example10.com</domain:name></domain:update></update><extension><launch:update xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><launch:applicationID>abc321</launch:applicationID></launch:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build_xml');


# DELETE
$lp = {phase => 'sunrise','application_id'=>'abc321'};
$R2='';
$rc=$dri->domain_delete('example10.com',{pure_delete=>1,lp=>$lp});
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example10.com</domain:name></domain:delete></delete><extension><launch:delete xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><launch:applicationID>abc321</launch:applicationID></launch:delete></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build_xml');


#########################################################################################################
## POLL MESSAGE

# *withOut* domain:infData
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="3" id="123"><qDate>2013-12-13T13:55:40.547Z</qDate><msg>Application created.  Status validated</msg></msgQ><extension><launch:infData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>sunrise</launch:phase><launch:applicationID>123456</launch:applicationID><launch:status s="validated" /></launch:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'123','message_retrieve get_info(last_id)');
$lp = $dri->get_info('lp','message',123);
is($lp->{'application_id'},'123456','message_retrieve get_info lp->{application_id}');

# *with* domain:infData
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="2" id="124"><qDate>2013-12-13T13:55:40.547Z</qDate><msg>Application created.  Status validated</msg></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>test.tld</domain:name></domain:infData></resData><extension><launch:infData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>sunrise</launch:phase><launch:applicationID>123456</launch:applicationID><launch:status s="validated" /></launch:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'124','message_retrieve get_info(last_id)');
$lp = $dri->get_info('lp','message',124);
is($lp->{'application_id'},'123456','message_retrieve get_info lp->{application_id}');

exit 0;
