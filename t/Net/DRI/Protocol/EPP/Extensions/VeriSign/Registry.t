#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 175; # TODO: change when finished!!!
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['VeriSign::Registry']});

my ($rc,$d,$related,$phase,$services,$slainfo,$domainname);

####################################################################################################

##
# Tests based on: http://www.verisigninc.com/assets/epp-sdk/verisign_epp-extension_registry_v00.html
##

## 3.1 EPP Query Commands

# 3.1.1 EPP <check> Command
# Check single registry zone
$R2=$E1.'<response>'.r().'<resData><registry:chkData xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:cd><registry:name avail="0">zone1</registry:name><registry:reason>Client not authorized</registry:reason></registry:cd></registry:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registry_check('zone1');
is_string($R1,$E1.'<command><check><registry:check xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:name>zone1</registry:name></registry:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'registry_check build (single)');
is($rc->is_success(),1,'registry_check is_success');
is($dri->get_info('action'),'check','registry_check get_info(action)');
is($dri->get_info('exist'),1,'registry_check get_info(exist)');
is($dri->get_info('reason'),'Client not authorized','registry_check get_info(reason)');

# Check multiple registry zones
$R2=$E1.'<response>'.r().'<resData><registry:chkData xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:cd><registry:name avail="0">zone1</registry:name><registry:reason>Client not authorized</registry:reason></registry:cd><registry:cd><registry:name avail="0">zone2</registry:name><registry:reason>Already supported</registry:reason></registry:cd><registry:cd><registry:name avail="1">zone3</registry:name></registry:cd></registry:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registry_check(qw/zone1 zone2 zone3/);
is_string($R1,$E1.'<command><check><registry:check xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:name>zone1</registry:name><registry:name>zone2</registry:name><registry:name>zone3</registry:name></registry:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'registry check: registry_check build (multi)');
is($rc->is_success(),1,'registry_check multi is_success');
is($rc->get_data('registry','zone1','action'),'check','registry_check multi get_data(action,registry1/3)');
is($rc->get_data('registry','zone1','exist'),1,'registry_check multi get_data(exist,registry1/3)');
is($rc->get_data('registry','zone1','reason'),'Client not authorized','registry_check multi get_data(reason,registry1/3)');
is($rc->get_data('registry','zone2','action'),'check','registry_check multi get_data(action,registry2/3)');
is($rc->get_data('registry','zone2','exist'),1,'registry_check multi get_data(exist,registry2/3)');
is($rc->get_data('registry','zone2','reason'),'Already supported','registry_check multi get_data(reason,registry2/3)');
is($rc->get_data('registry','zone3','exist'),0,'registry_check multi get_data(exist,registry3/3)');


# 3.1.2 EPP <info> Command

# <registry:all>
# All: return a summary information (name,crDate,upDate) of all the zone objects
$R2=$E1.'<response>'.r().'<resData><registry:infData xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:zoneList><registry:zone><registry:name>EXAMPLE1</registry:name><registry:crDate>2012-10-01T00:00:00.0Z</registry:crDate><registry:upDate>2012-10-15T00:00:00.0Z</registry:upDate></registry:zone><registry:zone><registry:name>EXAMPLE2</registry:name><registry:crDate>2012-09-01T00:00:00.0Z</registry:crDate><registry:upDate>2012-09-19T00:00:00.0Z</registry:upDate></registry:zone></registry:zoneList></registry:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registry_info();
is_string($R1,$E1.'<command><info><registry:info xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:all/></registry:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'registry info: registry_info build (all zones)');
is($rc->is_success(),1,'registry_info all zones is success');
is($rc->get_data('registry','EXAMPLE1','name'),'EXAMPLE1','registry_info_all get_data(name,registry zone 1/2)');
is($rc->get_data('registry','EXAMPLE1','crDate'),'2012-10-01T00:00:00','registry_info_all get_data(crDate,registry zone 1/2)');
is($rc->get_data('registry','EXAMPLE1','upDate'),'2012-10-15T00:00:00','registry_info_all get_data(upDate,registry zone 1/2)');
is($rc->get_data('registry','EXAMPLE2','name'),'EXAMPLE2','registry_info_all get_data(name,registry zone 2/2)');
is($rc->get_data('registry','EXAMPLE2','crDate'),'2012-09-01T00:00:00','registry_info_all get_data(crDate,registry zone 2/2)');
is($rc->get_data('registry','EXAMPLE2','upDate'),'2012-09-19T00:00:00','registry_info_all get_data(upDate,registry zone 2/2)');

# <registry:name>
# Individual: return full registry zone object information (Section 2.3 of the documentation)
# simple
$R2=$E1.'<response>'.r().'<resData><registry:infData xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:zone><registry:name>zone1</registry:name><registry:crDate>2012-10-01T00:00:00.0Z</registry:crDate><registry:upDate>2012-10-15T00:00:00.0Z</registry:upDate></registry:zone></registry:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registry_info('zone1');
is_string($R1,$E1.'<command><info><registry:info xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:name>zone1</registry:name></registry:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'registry info: registry_info build (one zone object)');
is($rc->is_success(),1,'registry_info (one zone object) is success');
is($dri->get_info('name'),'zone1','registry_info get_info(name)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','registry_info get_info(crDate)');
is($d,'2012-10-01T00:00:00','registry_info get_info(crDate)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','registry_info get_info(upDate)');
is($d,'2012-10-15T00:00:00','registry_info get_info(upDate)');
# extended
$R2=$E1.'<response>'.r().
'<resData>
<registry:infData xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd">
<registry:zone>
  <registry:name>zone1</registry:name>  
  <registry:group>STANDARD</registry:group>
  <registry:subProduct>EXAMPLE</registry:subProduct>
  <registry:related>
    <registry:fields type="sync">
      <registry:field>clID</registry:field>
      <registry:field>registrant</registry:field>
      <registry:field>ns</registry:field>
    </registry:fields>
    <registry:zoneMember type="equal">EXAMPLE</registry:zoneMember>
    <registry:zoneMember type="equal">EXAMPLE2</registry:zoneMember>
    <registry:zoneMember type="equal">EXAMPLE3</registry:zoneMember>
  </registry:related>
  <registry:phase type="sunrise">
    <registry:startDate>2012-11-01T00:00:00.0Z</registry:startDate>
    <registry:endDate>2012-12-01T00:00:00.0Z</registry:endDate>
  </registry:phase>
  <registry:phase type="claims" name="landrush">
    <registry:startDate>2012-12-01T00:00:00.0Z</registry:startDate>
    <registry:endDate>2012-12-08T00:00:00.0Z</registry:endDate>
  </registry:phase>
  <registry:phase type="claims" name="open">
    <registry:startDate>2012-12-08T00:00:00.0Z</registry:startDate>
    <registry:endDate>2013-02-01T00:00:00.0Z</registry:endDate>
  </registry:phase>
  <registry:phase type="open">
    <registry:startDate>2013-02-01T00:00:00.0Z</registry:startDate>
  </registry:phase>
  <registry:services>
    <registry:objURI required="true">urn:ietf:params:xml:ns:domain-1.0</registry:objURI>
    <registry:objURI required="true">urn:ietf:params:xml:ns:host-1.0</registry:objURI>
    <registry:objURI required="true">urn:ietf:params:xml:ns:contact-1.0</registry:objURI>
    <registry:svcExtension>
      <registry:extURI required="true">urn:ietf:params:xml:ns:rgp-1.0</registry:extURI>
      <registry:extURI required="true">urn:ietf:params:xml:ns:secDNS-1.1</registry:extURI>
      <registry:extURI required="true">http://www.verisign-grs.com/epp/namestoreExt-1.1</registry:extURI>
      <registry:extURI required="false">http://www.verisign.com/epp/idnLang-1.0</registry:extURI>
    </registry:svcExtension>
  </registry:services>
  <registry:slaInfo>
    <registry:sla type="downtime" unit="min">864</registry:sla>
    <registry:sla type="rtt" command="domain:check" unit="ms">2000</registry:sla>
    <registry:sla type="rtt" command="domain:info" unit="ms">2000</registry:sla>
    <registry:sla type="rtt" command="domain:create" unit="ms">4000</registry:sla>
    <registry:sla type="rtt" command="domain:update" unit="ms">4000</registry:sla>
    <registry:sla type="rtt" command="domain:renew" unit="ms">4000</registry:sla>
    <registry:sla type="rtt" command="domain:delete" unit="ms">4000</registry:sla>
    <registry:sla type="rtt" command="domain:transfer" unit="ms">4000</registry:sla>
  </registry:slaInfo>
  <registry:crID>clientX</registry:crID>
  <registry:crDate>2012-10-01T00:00:00.0Z</registry:crDate>
  <registry:upID>clientY</registry:upID>
  <registry:upDate>2012-10-15T00:00:00.0Z</registry:upDate>
  <registry:domain>
    <registry:domainName level="2">
      <registry:minLength>5</registry:minLength>
      <registry:maxLength>50</registry:maxLength>
      <registry:alphaNumStart>true</registry:alphaNumStart>
      <registry:alphaNumEnd>false</registry:alphaNumEnd>
      <registry:onlyDnsChars>true</registry:onlyDnsChars>
      <registry:regex>
        <registry:expression>^\w+.*$</registry:expression>
        <registry:explanation>Alphanumeric</registry:explanation>
      </registry:regex>
      <registry:regex>
        <registry:expression>^\d+.*$</registry:expression>
      </registry:regex>
      <registry:reservedNames>
        <registry:reservedName>reserved1</registry:reservedName>
      </registry:reservedNames>
    </registry:domainName>
    <registry:idn>
      <registry:idnVersion>4.1</registry:idnVersion>
      <registry:idnaVersion>2008</registry:idnaVersion>
      <registry:unicodeVersion>6.0</registry:unicodeVersion>
      <registry:encoding>Punycode</registry:encoding>
      <registry:commingleAllowed>false</registry:commingleAllowed>
      <registry:language code="LANG-1">
        <registry:table>http://www.iana.org/idn-tables/test_tab1_1.1.txt</registry:table>
        <registry:variantStrategy>blocked</registry:variantStrategy>
      </registry:language>
    </registry:idn>
    <registry:premiumSupport>false</registry:premiumSupport>
    <registry:contact type="admin">
      <registry:min>1</registry:min>
      <registry:max>4</registry:max>
    </registry:contact>
    <registry:contact type="tech">
      <registry:min>1</registry:min>
      <registry:max>2</registry:max>
    </registry:contact>
    <registry:ns>
      <registry:min>0</registry:min>
      <registry:max>13</registry:max>
    </registry:ns>
    <registry:childHost>
      <registry:min>0</registry:min>
    </registry:childHost>
    <registry:period command="create">
      <registry:length>
        <registry:min unit="y">1</registry:min>
        <registry:max unit="y">10</registry:max>
        <registry:default unit="y">1</registry:default>
      </registry:length>
    </registry:period>
    <registry:period command="renew">
      <registry:length>
        <registry:min unit="y">2</registry:min>
        <registry:max unit="y">5</registry:max>
        <registry:default unit="y">2</registry:default>
      </registry:length>
    </registry:period>
    <registry:transferHoldPeriod unit="d">5</registry:transferHoldPeriod>
    <registry:gracePeriod command="create" unit="d">5</registry:gracePeriod>
    <registry:gracePeriod command="renew" unit="d">5</registry:gracePeriod>
    <registry:gracePeriod command="transfer" unit="d">5</registry:gracePeriod>
    <registry:gracePeriod command="autoRenew" unit="d">45</registry:gracePeriod>
    <registry:rgp>
      <registry:redemptionPeriod unit="d">30</registry:redemptionPeriod>
      <registry:pendingRestore unit="d">7</registry:pendingRestore>
      <registry:pendingDelete unit="d">5</registry:pendingDelete>
    </registry:rgp>
    <registry:dnssec>
      <registry:dsDataInterface>
       <registry:min>0</registry:min>
       <registry:max>13</registry:max>
       <registry:alg>3</registry:alg>
       <registry:digestType>1</registry:digestType>
      </registry:dsDataInterface>
      <registry:maxSigLife>
        <registry:clientDefined>false</registry:clientDefined>
      </registry:maxSigLife>
    </registry:dnssec>
    <registry:maxCheckDomain>5</registry:maxCheckDomain>
    <registry:supportedStatus>
      <registry:status>ok</registry:status>
      <registry:status>clientDeleteProhibited</registry:status>
      <registry:status>serverDeleteProhibited</registry:status>
      <registry:status>clientHold</registry:status>
      <registry:status>serverHold</registry:status>
      <registry:status>clientRenewProhibited</registry:status>
      <registry:status>serverRenewProhibited</registry:status>
      <registry:status>clientTransferProhibited</registry:status>
      <registry:status>serverTransferProhibited</registry:status>
      <registry:status>clientUpdateProhibited</registry:status>
      <registry:status>serverUpdateProhibited</registry:status>
      <registry:status>inactive</registry:status>
      <registry:status>pendingDelete</registry:status>
      <registry:status>pendingTransfer</registry:status>
    </registry:supportedStatus>
    <registry:authInfoRegex>
      <registry:expression>^.*$</registry:expression>
    </registry:authInfoRegex>
  </registry:domain>
  <registry:host>
    <registry:internal>
      <registry:minIP>1</registry:minIP>
      <registry:maxIP>13</registry:maxIP>
      <registry:sharePolicy>perZone</registry:sharePolicy>
    </registry:internal>
    <registry:external>
      <registry:minIP>0</registry:minIP>
      <registry:maxIP>0</registry:maxIP>
      <registry:sharePolicy>perZone</registry:sharePolicy>
    </registry:external>
    <registry:nameRegex>
      <registry:expression>^.*$</registry:expression>
    </registry:nameRegex>
    <registry:maxCheckHost>5</registry:maxCheckHost>
    <registry:supportedStatus>
      <registry:status>ok</registry:status>
      <registry:status>clientDeleteProhibited</registry:status>
      <registry:status>serverDeleteProhibited</registry:status>
      <registry:status>clientUpdateProhibited</registry:status>
      <registry:status>serverUpdateProhibited</registry:status>
      <registry:status>linked</registry:status>
      <registry:status>pendingDelete</registry:status>
      <registry:status>pendingTransfer</registry:status>
    </registry:supportedStatus>
  </registry:host>
  <registry:contact>
    <registry:contactIdRegex>
      <registry:expression>^.*$</registry:expression>
    </registry:contactIdRegex>
    <registry:sharePolicy>perZone</registry:sharePolicy>
    <registry:intSupport>true</registry:intSupport>
    <registry:locSupport>false</registry:locSupport>
    <registry:postalInfo>
      <registry:name>
        <registry:minLength>5</registry:minLength>
        <registry:maxLength>15</registry:maxLength>
      </registry:name>
      <registry:org>
        <registry:minLength>2</registry:minLength>
        <registry:maxLength>40</registry:maxLength>
      </registry:org>
      <registry:address>
        <registry:street>
          <registry:minLength>1</registry:minLength>
          <registry:maxLength>40</registry:maxLength>
          <registry:minEntry>1</registry:minEntry>
          <registry:maxEntry>3</registry:maxEntry>
        </registry:street>
        <registry:city>
          <registry:minLength>1</registry:minLength>
          <registry:maxLength>40</registry:maxLength>
        </registry:city>
        <registry:sp>
          <registry:minLength>1</registry:minLength>
          <registry:maxLength>40</registry:maxLength>
        </registry:sp>
        <registry:pc>
          <registry:minLength>1</registry:minLength>
          <registry:maxLength>40</registry:maxLength>
        </registry:pc>
      </registry:address>
      <registry:voiceRequired>false</registry:voiceRequired>
      <registry:voiceExt>
        <registry:minLength>1</registry:minLength>
        <registry:maxLength>40</registry:maxLength>
      </registry:voiceExt>
      <registry:faxExt>
        <registry:minLength>1</registry:minLength>
        <registry:maxLength>40</registry:maxLength>
      </registry:faxExt>
      <registry:emailRegex>
        <registry:expression>^.+\..+$</registry:expression>
      </registry:emailRegex>
    </registry:postalInfo>
    <registry:maxCheckContact>5</registry:maxCheckContact>
    <registry:authInfoRegex>
      <registry:expression>^.*$</registry:expression>
    </registry:authInfoRegex>
    <registry:clientDisclosureSupported>false</registry:clientDisclosureSupported>
    <registry:supportedStatus>
      <registry:status>ok</registry:status>
      <registry:status>clientDeleteProhibited</registry:status>
      <registry:status>serverDeleteProhibited</registry:status>
      <registry:status>clientTransferProhibited</registry:status>
      <registry:status>serverTransferProhibited</registry:status>
      <registry:status>clientUpdateProhibited</registry:status>
      <registry:status>serverUpdateProhibited</registry:status>
      <registry:status>linked</registry:status>
      <registry:status>pendingDelete</registry:status>
      <registry:status>pendingTransfer</registry:status>
    </registry:supportedStatus>
    <registry:transferHoldPeriod unit="d">5</registry:transferHoldPeriod>
  </registry:contact>
</registry:zone>
</registry:infData>
</resData>'.$TRID.'</response>'.$E2;

$rc=$dri->registry_info('zone1');
is_string($R1,$E1.'<command><info><registry:info xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:name>zone1</registry:name></registry:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'registry info: registry_info build (one zone object)');
is($rc->is_success(),1,'registry_info (one zone object) is success');
is($dri->get_info('name'),'zone1','registry_info get_info(name)');
is($dri->get_info('group'),'STANDARD','registry_info get_info(group)');
is($dri->get_info('subProduct'),'EXAMPLE','registry_info get_info(subProduct)');
$related = $dri->get_info('related');
is($related->{'fields_type'},'sync','registry_info get_info(related) fields type attribute');
is($related->{'fields'}->[0],'clID','registry_info get_info(fields) - 1/3');
is($related->{'fields'}->[1],'registrant','registry_info get_info(fields) - 2/3');
is($related->{'fields'}->[2],'ns','registry_info get_info(fields) - 3/3');
my $fields=$related->{'fields'};
is_deeply($fields,['clID','registrant','ns'],'registry_info get_info(related) fields');
my $zones_name=$related->{'zone_member_name'};
is_deeply($zones_name,['EXAMPLE','EXAMPLE2','EXAMPLE3'],'registry_info get_info(related) zoneMember');
my $zones_type=$related->{'zone_member_type'};
is_deeply($zones_type,['equal','equal','equal'],'registry_info get_info(related) zoneMember type attribute');

# TODO: tests for get_info(phase) - find a friendly way to perform the test. array values keep changing... 
#my $phase=$dri->get_info('phase');
#print Dumper($phase);
#my @values = values @{$phase}[0];
#is_deeply(\@values,['sunrise','2012-11-01T00:00:00.0Z','2012-12-01T00:00:00.0Z'],'registry_info get_info(phase1)');
#@values = values @{$phase}[1];
#is_deeply(\@values,['2012-11-01T00:00:00.0Z','2012-12-01T00:00:00.0Z'],'registry_info get_info(phase2)');
#@values = values @{$phase}[2];
#is_deeply(\@values,['2012-11-01T00:00:00.0Z','2012-12-01T00:00:00.0Z'],'registry_info get_info(phase3)');
#@values = values @{$phase}[3];
#is_deeply(\@values,['2012-11-01T00:00:00.0Z','2012-12-01T00:00:00.0Z'],'registry_info get_info(phase4)');

$services=$dri->get_info('services');
my $objuri_attr=$services->{'objuri_required'};
is_deeply($objuri_attr,['true','true','true'],'registry_info get_info(services) required objURI attributes');
my $objuri_name=$services->{'objuri_name'};
is_deeply($objuri_name,['urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:host-1.0','urn:ietf:params:xml:ns:contact-1.0'],'registry_info get_info(services) objURI names');
my $exturi_attr=$services->{'exturi_required'};
is_deeply($exturi_attr,['true','true','true','false'],'registry_info get_info(services) required extURI attributes');
my $exturi_name=$services->{'exturi_name'};
is_deeply($exturi_name,['urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:secDNS-1.1','http://www.verisign-grs.com/epp/namestoreExt-1.1','http://www.verisign.com/epp/idnLang-1.0'],'registry_info get_info(services) extURI names');

$slainfo=$dri->get_info('slaInfo');
my $sla_type_attr=$slainfo->{'sla_type'};
is_deeply($sla_type_attr,['downtime','rtt','rtt','rtt','rtt','rtt','rtt','rtt'],'registry_info get_info(slaInfo) type attributes');
my $sla_unit_attr=$slainfo->{'sla_unit'};
is_deeply($sla_unit_attr,['min','ms','ms','ms','ms','ms','ms','ms'],'registry_info get_info(slaInfo) unit attributes');
my $sla_command_attr=$slainfo->{'sla_command'};
is_deeply($sla_command_attr,['domain:check','domain:info','domain:create','domain:update','domain:renew','domain:delete','domain:transfer'],'registry_info get_info(slaInfo) command attributes');
my $sla_time=$slainfo->{'sla_time'};
is_deeply($sla_time,['864','2000','2000','4000','4000','4000','4000','4000'],'registry_info get_info(slaInfo) time');

is($dri->get_info('crID'),'clientX','registry_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','registry_info get_info(crDate)');
is($d,'2012-10-01T00:00:00','registry_info get_info(crDate)');
is($dri->get_info('upID'),'clientY','registry_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','registry_info get_info(upDate)');
is($d,'2012-10-15T00:00:00','registry_info get_info(upDate)');

$domainname=$dri->get_info('domain');
is($domainname->{'dom_level_attr'},'2','registry_info get_info(domain) domainName level attr');
is($domainname->{'dom_min_len'},'5','registry_info get_info(domain) domainName minLength');
is($domainname->{'dom_max_len'},'50','registry_info get_info(domain) domainName maxLength');
is($domainname->{'dom_alp_start'},'true','registry_info get_info(domain) domainName alphaNumStart');
is($domainname->{'dom_alp_end'},'false','registry_info get_info(domain) domainName alphaNumEnd');
is($domainname->{'dom_dns_chars'},'true','registry_info get_info(domain) domainName onlyDnsChars');
my $dom_regex=$domainname->{regex};
is($dom_regex->[0]->{expression},'^\w+.*$','registry_info get_info(domain) domainName regex1(expression)');
is($dom_regex->[0]->{explanation},'Alphanumeric','registry_info get_info(domain) domainName regex1(explanation)');
is($dom_regex->[1]->{expression},'^\d+.*$','registry_info get_info(domain) domainName regex2(expression)');
is($domainname->{reserved_names}->{reservedName},'reserved1','registry_info get_info(domain) domainName reservedNames(reservedName)');
is($domainname->{idn_idnversion},'4.1','registry_info get_info(domain) IDN idnVersion');
is($domainname->{idn_idnaversion},'2008','registry_info get_info(domain) IDN idnaVersion');
is($domainname->{idn_unicodeversion},'6.0','registry_info get_info(domain) IDN unicodeVersion');
is($domainname->{idn_encoding},'Punycode','registry_info get_info(domain) IDN encoding');
is($domainname->{idn_commingleallowed},'false','registry_info get_info(domain) IDN commingleAllowed');
my $dom_idn_lang=$domainname->{idn_language};
is($domainname->{idn_language_attr},'LANG-1','registry_info get_info(domain) IDN language (code attr)');
is($dom_idn_lang->[0]->{table},'http://www.iana.org/idn-tables/test_tab1_1.1.txt','registry_info get_info(domain) IDN language (table)');
is($dom_idn_lang->[0]->{variant_strategy},'blocked','registry_info get_info(domain) IDN language (variantStrategy)');
is($domainname->{premium_support},'false','registry_info get_info(domain) premiumSupport');
my $dom_contacts=$domainname->{contact};
is($dom_contacts->[0]->{contact_type_attr},'admin','registry_info get_info(domain) contact1(type attribute)');
is($dom_contacts->[0]->{min},'1','registry_info get_info(domain) contact1(min)');
is($dom_contacts->[0]->{max},'4','registry_info get_info(domain) contact1(max)');
is($dom_contacts->[1]->{contact_type_attr},'tech','registry_info get_info(domain) contact2 type attribute)');
is($dom_contacts->[1]->{min},'1','registry_info get_info(domain) contact2(min)');
is($dom_contacts->[1]->{max},'2','registry_info get_info(domain) contact2(max)');
is($domainname->{ns}->{min},'0','registry_info get_info(domain) ns(min)');
is($domainname->{ns}->{max},'13','registry_info get_info(domain) ns(max)');
is($domainname->{child_host}->{min},'0','registry_info get_info(domain) childHost(min)');
my $dom_period=$domainname->{period}[0];
is($dom_period->[0]->{period_command_attr},'create','registry_info get_info(domain) period1(command attribute)');
$dom_period=shift $dom_period->[1];
is($dom_period->{unit_attr},'y','registry_info get_info(domain) period1(unit)');
is($dom_period->{min},'1','registry_info get_info(domain) period1(min)');
is($dom_period->{max},'10','registry_info get_info(domain) period1(max)');
is($dom_period->{default},'1','registry_info get_info(domain) period1(default)');
$dom_period=$domainname->{period}[1];
is($dom_period->[0]->{period_command_attr},'renew','registry_info get_info(domain) period2(command attribute)');
$dom_period=shift $dom_period->[1];
is($dom_period->{unit_attr},'y','registry_info get_info(domain) period2(unit)');
is($dom_period->{min},'2','registry_info get_info(domain) period2(min)');
is($dom_period->{max},'5','registry_info get_info(domain) period2(max)');
is($dom_period->{default},'2','registry_info get_info(domain) period2(default)');
is($domainname->{transfer_hold_period_attr},'d','registry_info get_info(domain) transferHoldPeriod attribute');
is($domainname->{transfer_hold_period},'5','registry_info get_info(domain) transferHoldPeriod');
my $dom_grace_period=shift $domainname->{grace_period}[0];
is($dom_grace_period->{grace_period_command_attr},'create','registry_info get_info(domain) gracePeriod1(command attribute)');
is($dom_grace_period->{grace_period_unit_attr},'d','registry_info get_info(domain) gracePeriod1(unit attribute)');
is($dom_grace_period->{grace_period},'5','registry_info get_info(domain) gracePeriod1');
$dom_grace_period=shift $domainname->{grace_period}[1];
is($dom_grace_period->{grace_period_command_attr},'renew','registry_info get_info(domain) gracePeriod2(command attribute)');
is($dom_grace_period->{grace_period_unit_attr},'d','registry_info get_info(domain) gracePeriod2(unit attribute)');
is($dom_grace_period->{grace_period},'5','registry_info get_info(domain) gracePeriod2');
$dom_grace_period=shift$domainname->{grace_period}[2];
is($dom_grace_period->{grace_period_command_attr},'transfer','registry_info get_info(domain) gracePeriod3(command attribute)');
is($dom_grace_period->{grace_period_unit_attr},'d','registry_info get_info(domain) gracePeriod3(unit attribute)');
is($dom_grace_period->{grace_period},'5','registry_info get_info(domain) gracePeriod3');
$dom_grace_period=shift $domainname->{grace_period}[3];
is($dom_grace_period->{grace_period_command_attr},'autoRenew','registry_info get_info(domain) gracePeriod4(command attribute)');
is($dom_grace_period->{grace_period_unit_attr},'d','registry_info get_info(domain) gracePeriod4(unit attribute)');
is($dom_grace_period->{grace_period},'45','registry_info get_info(domain) gracePeriod4');
my $dom_rgp=$domainname->{rgp};
is($dom_rgp->{redemption_period_attr},'d','registry_info get_info(domain) rgp(redemptionPeriod attribute)');
is($dom_rgp->{redemption_period},'30','registry_info get_info(domain) rgp(redemptionPeriod)');
is($dom_rgp->{pending_restore_attr},'d','registry_info get_info(domain) rgp(pendingRestore attribute)');
is($dom_rgp->{pending_restore},'7','registry_info get_info(domain) rgp(pendingRestore)');
is($dom_rgp->{pending_delete_attr},'d','registry_info get_info(domain) rgp(pendingDelete attribute)');
is($dom_rgp->{pending_delete},'5','registry_info get_info(domain) rgp(pendingDelete)');
my $dom_dnssec=$domainname->{dnssec};
is($dom_dnssec->{ds_data_interface}->{min},'0','registry_info get_info(domain) dnssec(dsDataInterface(min))');
is($dom_dnssec->{ds_data_interface}->{max},'13','registry_info get_info(domain) dnssec(dsDataInterface(max))');
is($dom_dnssec->{ds_data_interface}->{alg},'3','registry_info get_info(alg) dnssec(dsDataInterface(alg))');
is($dom_dnssec->{ds_data_interface}->{digest_type},'1','registry_info get_info(digestType) dnssec(dsDataInterface(digestType))');
is($dom_dnssec->{max_sig_life}->{client_defined},'false','registry_info get_info(domain) dnssec(maxSigLife(clientDefined))');
is($domainname->{max_check_domain},'5','registry_info get_info(domain) maxCheckDomain');
my $dom_supported_status=$domainname->{supported_status};
is_string(values @{$dom_supported_status}[0],'ok','registry_info get_info(domain) supportedStatus(1)');
is_string(values @{$dom_supported_status}[1],'clientDeleteProhibited','registry_info get_info(domain) supportedStatus(2)');
is_string(values @{$dom_supported_status}[5],'clientRenewProhibited','registry_info get_info(domain) supportedStatus(6)');
is_string(values @{$dom_supported_status}[13],'pendingTransfer','registry_info get_info(domain) supportedStatus(14)');
is($domainname->{auth_info_regex}->{expression},'^.*$','registry_info get_info(domain) authInfoRegex');

my $host=$dri->get_info('host');
is_string($host->{internal}->{min_ip},'1','registry_info get_info(host) internal(min_ip)');
is_string($host->{internal}->{max_ip},'13','registry_info get_info(host) internal(max_ip)');
is_string($host->{internal}->{share_policy},'perZone','registry_info get_info(host) internal(sharePolicy)');
is_string($host->{external}->{min_ip},'0','registry_info get_info(host) external(min_ip)');
is_string($host->{external}->{max_ip},'0','registry_info get_info(host) external(max_ip)');
is_string($host->{external}->{share_policy},'perZone','registry_info get_info(host) external(sharePolicy)');
is_string($host->{name_regex}->{expression}[0],'^.*$','registry_info get_info(host) nameRegex(expression1)');
my $host_supported_status=$host->{supported_status};
is_string(values @{$host_supported_status}[0],'ok','registry_info get_info(host) supportedStatus(1)');
is_string(values @{$host_supported_status}[1],'clientDeleteProhibited','registry_info get_info(host) supportedStatus(2)');
is_string(values @{$host_supported_status}[7],'pendingTransfer','registry_info get_info(host) supportedStatus(8)');

my $contact=$dri->get_info('contact');
is_string($contact->{contact_id_regex}->{expression},'^.*$','registry_info get_info(contact) contactIdRegex');
is_string($contact->{share_policy},'perZone','registry_info get_info(contact) sharePolicy');
is_string($contact->{int_support},'true','registry_info get_info(contact) intSupport');
is_string($contact->{loc_support},'false','registry_info get_info(contact) locSupport');
my $contact_postal=$contact->{postal_info};
is_string($contact_postal->{name}->{min_length},'5','registry_info get_info(contact) postalInfo(name->minLength)');
is_string($contact_postal->{name}->{max_length},'15','registry_info get_info(contact) postalInfo(name->maxLength)');
is_string($contact_postal->{org}->{min_length},'2','registry_info get_info(contact) postalInfo(org->minLength)');
is_string($contact_postal->{org}->{max_length},'40','registry_info get_info(contact) postalInfo(org->maxLength)');
my $contact_address=$contact_postal->{address};
is_string($contact_address->{street}->{min_length},'1','registry_info get_info(contact) postalInfo(address->street->minLength)');
is_string($contact_address->{street}->{max_length},'40','registry_info get_info(contact) postalInfo(address->street->maxLength)');
is_string($contact_address->{street}->{min_entry},'1','registry_info get_info(contact) postalInfo(address->street->minEntry)');
is_string($contact_address->{street}->{max_entry},'3','registry_info get_info(contact) postalInfo(address->street->maxEntry)');
is_string($contact_address->{city}->{min_length},'1','registry_info get_info(contact) postalInfo(address->city->minLength)');
is_string($contact_address->{city}->{max_length},'40','registry_info get_info(contact) postalInfo(address->city->maxLength)');
is_string($contact_address->{sp}->{min_length},'1','registry_info get_info(contact) postalInfo(address->sp->minLength)');
is_string($contact_address->{sp}->{max_length},'40','registry_info get_info(contact) postalInfo(address->sp->maxLength)');
is_string($contact_address->{pc}->{min_length},'1','registry_info get_info(contact) postalInfo(address->pc->minLength)');
is_string($contact_address->{pc}->{max_length},'40','registry_info get_info(contact) postalInfo(address->pc->maxLength)');
is_string($contact_postal->{voice_required},'false','registry_info get_info(contact) postalInfo(voiceRequired)');
is_string($contact_postal->{voice_ext}->{min_length},'1','registry_info get_info(contact) postalInfo(voiceExt->minLength)');
is_string($contact_postal->{voice_ext}->{max_length},'40','registry_info get_info(contact) postalInfo(voiceExt->maxLength)');
is_string($contact_postal->{fax_ext}->{min_length},'1','registry_info get_info(contact) postalInfo(faxExt->minLength)');
is_string($contact_postal->{fax_ext}->{max_length},'40','registry_info get_info(contact) postalInfo(faxExt->maxLength)');
my $contact_email_regex=$contact_postal->{email_regex};
is_string(values @{$contact_email_regex}[0],'^.+\..+$','registry_info get_info(contact) postalInfo(emailRegex)');
is_string($contact->{max_check_contact},'5','registry_info get_info(contact) maxCheckContact');
is_string($contact->{auth_info_regex}->{expression},'^.*$','registry_info get_info(contact) authInfoRegex');
is_string($contact->{client_disclosure_supported},'false','registry_info get_info(contact) clientDisclosureSupported');
my $contact_supported_status=$contact->{supported_status};
is_string(values @{$contact_supported_status}[2],'serverDeleteProhibited','registry_info get_info(contact) supportedStatus(3)');
is_string(values @{$contact_supported_status}[4],'serverTransferProhibited','registry_info get_info(contact) supportedStatus(5)');
is_string(values @{$contact_supported_status}[6],'serverUpdateProhibited','registry_info get_info(contact) supportedStatus(7)');
is_string($contact->{transfer_hold_period},'5','registry_info get_info(contact) transferHoldPeriod');
is_string($contact->{transfer_hold_period_attr},'d','registry_info get_info(contact) transferHoldPeriod(attribute)');

## 3.2 EPP Transform Commands

# Simple
# 3.2.1 EPP <create> Command
$R2=$E1.'<response>'.r().'<resData><registry:creData xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:name>zone1</registry:name><registry:crDate>2012-10-30T22:00:00.0Z</registry:crDate></registry:creData></resData>'.$TRID.'</response>'.$E2;
# related node
my $f1 = { fields => ['clID','registrant','ns'], fields_attr => 'sync'};
my @related_fields = ($f1);
my $m1 = { zone_member => 'EXAMPLE', zone_member_type_attr => 'equal' };
my $m2 = { zone_member => 'EXAMPLE2', zone_member_type_attr => 'equal' };
my $m3 = { zone_member => 'EXAMPLE3', zone_member_type_attr => 'equal' };
my @related_members = ($m1,$m2,$m3);
my @related_el = (\@related_fields,\@related_members);
# phase node
my $p1 = { p_type_attr=>'sunrise', start_date => '2012-11-01T00:00:00.0Z', end_date => '2012-12-01T00:00:00.0Z' };
my $p2 = { p_type_attr=>'claims', p_name_attr=>'landrush', start_date => '2012-12-01T00:00:00.0Z', end_date => '2012-12-08T00:00:00.0Z' };
my $p3 = { p_type_attr=>'claims', p_name_attr=>'open', start_date => '2012-12-08T00:00:00.0Z', end_date => '2013-02-01T00:00:00.0Z' };
my $p4 = { p_type_attr=>'open', start_date => '2013-02-01T00:00:00.0Z' };
my @phase_el = ($p1,$p2,$p3,$p4);
# service node
my $s1 = { obj_uri_attr=>"true", obj_uri=>'urn:ietf:params:xml:ns:domain-1.0' };
my $s2 = { obj_uri_attr=>'true', obj_uri=>'urn:ietf:params:xml:ns:host-1.0' };
my $s3 = { obj_uri_attr=>'true', obj_uri=>'urn:ietf:params:xml:ns:contact-1.0' };
my @service_obj_uri = ($s1,$s2,$s3);
my $svc1 = { ext_uri=>'urn:ietf:params:xml:ns:rgp-1.0', ext_uri_attr=>'true'};
my $svc2 = { ext_uri=>'urn:ietf:params:xml:ns:secDNS-1.1', ext_uri_attr=>'true'};
my $svc3 = { ext_uri=>'http://www.verisign-grs.com/epp/namestoreExt-1.1', ext_uri_attr=>'true'};
my $svc4 = { ext_uri=>'http://www.verisign.com/epp/idnLang-1.0', ext_uri_attr=>'false'};
my @service_svc_ext = ($svc1,$svc2,$svc3,$svc4);
my @service_el = (\@service_obj_uri,\@service_svc_ext);
# slainfo node
my $sla1 = { sla=>864, sla_type_attr=>'downtime', sla_unit_attr=>'min' };
my $sla2 = { sla=>2000, sla_type_attr=>'rtt', sla_command_attr=>'domain:check', sla_unit_attr=>'ms' };
my $sla3 = { sla=>2000, sla_type_attr=>'rtt', sla_command_attr=>'domain:info', sla_unit_attr=>'ms' };
my $sla4 = { sla=>4000, sla_type_attr=>'rtt', sla_command_attr=>'domain:create', sla_unit_attr=>'ms' };
my $sla5 = { sla=>4000, sla_type_attr=>'rtt', sla_command_attr=>'domain:update', sla_unit_attr=>'ms' };
my $sla6 = { sla=>4000, sla_type_attr=>'rtt', sla_command_attr=>'domain:renew', sla_unit_attr=>'ms' };
my $sla7 = { sla=>4000, sla_type_attr=>'rtt', sla_command_attr=>'domain:delete', sla_unit_attr=>'ms' };
my $sla8 = { sla=>4000, sla_type_attr=>'rtt', sla_command_attr=>'domain:transfer', sla_unit_attr=>'ms' };
my @slainfo_el = ($sla1,$sla2,$sla3,$sla4,$sla5,$sla6,$sla7,$sla8);

# domain node
## domain->domainName
my $regex1 = { expression=>'^\w+.*$', explanation=>'Alphanumeric' };
my $regex2 = { expression=>'^\d+.*$' };
my @domain_name_regex = ($regex1, $regex2);
my $n1 = { reserved_name=>'reserved1' };
#my $n2 = { reserved_name=>'reserved2' };
#my @domain_name_reserved_names = ( $n1,$n2, {reserved_name_uri=>'www.foo.com'} ); # confirming code is ok for other fields....
my @domain_name_reserved_names = ( $n1 );
my $domain_name = { dom_level_attr=>2, dom_min_len=>5, dom_max_len=>50, dom_alp_start=>'true', dom_alp_end=>'false', dom_dns_chars=>'true', dom_regex=>\@domain_name_regex, dom_reserved_names=>\@domain_name_reserved_names};
## domain->idn
my $lang1 = { idn_code_attr=>'LANG-1', idn_reg_table=>'http://www.iana.org/idn-tables/test_tab1_1.1.txt', idn_reg_variant_strategy=>'blocked' };
#my $lang2 = { idn_code_attr=>'LANG-2', idn_reg_table=>'http://www.iana.org/idn-tables/test_tab1_1.2.txt', idn_reg_variant_strategy=>'open' };
#my @domain_idn_language = ( $lang1, $lang2 ); # test adding multiple idn languages...
my @domain_idn_language = ( $lang1 );
my $domain_idn = { idn_version=>'4.1', idna_version=>'2008', unicode_version=>'6.0', encoding=>'Punycode', commingle_allowed=>'false', language=>\@domain_idn_language };
## domain->contact
my $c1 = { contact_type_attr=>'admin', contact_min=>'1', contact_max=>'4' };
#my $c2 = { contact_type_attr=>'tech', contact_min=>'1', contact_max=>'1' };
#my $c3 = { contact_type_attr=>'billing', contact_min=>'2', contact_max=>'3' };
#my @domain_contact = ( $c1,$c2,$c3 ); # test adding multiple contacts...
my @domain_contact = ( $c1 );
## domain->ns
my @domain_ns = ( {ns_min=>'0', ns_max=>'13'} );
## domain->childHost
my @domain_child_host = ( {child_host_min=>'0'} );
## domain->period
$p1= { period_command_attr=>'create', period_min=>'1', period_min_attr=>'y', period_max=>'10', period_max_attr=>'y', period_default=>'1', period_default_attr=>'y' };
#$p2= { period_command_attr=>'renew', period_min=>'1', period_min_attr=>'m', period_max=>'10', period_max_attr=>'m', period_default=>'1', period_default_attr=>'m' };
#my @domain_period = ($p1,$p2); # test adding multiple periods...
my @domain_period = ($p1);
## domain->transferHoldPeriod
my @domain_transfer_hold_period = ( { transfer_hold_period=>5 , transfer_hold_period_attr=>'d' } );
## domain->gracePeriod
my $g1 = { grace_period_command_attr=>'create', grace_period_unit_attr=>'d', grace_period=>5 };
my $g2 = { grace_period_command_attr=>'renew', grace_period_unit_attr=>'d', grace_period=>5 };
my $g3 = { grace_period_command_attr=>'transfer', grace_period_unit_attr=>'d', grace_period=>5 };
my $g4 = { grace_period_command_attr=>'autoRenew', grace_period_unit_attr=>'d', grace_period=>45 };
my @domain_grace_period = ($g1,$g2,$g3,$g4);
## domain->rgp
my @domain_rgp = ( { rgp_redemption_period=>30, rgp_redemption_period_attr=>'d', rgp_pending_restore=>7, rgp_pending_restore_attr=>'d', rgp_pending_delete=>5, rgp_pending_delete_attr=>'d' } );
## domain->dnssec
my @domain_dnssec = ( { dnssec_ds_data_min=>0, dnssec_ds_data_max=>13, dnssec_ds_data_alg=>[3], dnssec_ds_data_digest=>[1], dnssec_max_sig_client=>'false' } );
## domain->supportedStatus
my @domain_supported_status = ({ status=>['ok','clientDeleteProhibited','serverDeleteProhibited','clientHold','serverHold','clientRenewProhibited','serverRenewProhibited','clientTransferProhibited','serverTransferProhibited','clientUpdateProhibited','serverUpdateProhibited','inactive','pendingDelete','pendingTransfer'] });
## domain->authInfoRegex
my @domain_auth_info_regex = ({ regex_expression=>'^.*$' });
my @domain_el = ({ dom_name=>$domain_name, dom_idn=>$domain_idn, dom_premium_support=>'false', dom_contact=>\@domain_contact, dom_ns=>\@domain_ns,
	dom_child_host=>\@domain_child_host, dom_period=>\@domain_period, dom_transfer_hold_period=>\@domain_transfer_hold_period,
	dom_grace_period=>\@domain_grace_period, dom_rgp=>\@domain_rgp, dom_dnssec=>\@domain_dnssec,
	dom_max_check_domain=>5, dom_supported_status=>\@domain_supported_status ,dom_auth_info_regex=>\@domain_auth_info_regex
});
# END: domain node
# host node
my @host_supported_status = ({ status=>['ok','clientDeleteProhibited','serverDeleteProhibited','clientUpdateProhibited','serverUpdateProhibited','linked','pendingDelete','pendingTransfer'] });
my @host_el = (
  {
    host_internal=>{ min_ip=>1, max_ip=>13, share_policy=>'perZone' },
    host_external=>{ min_ip=>0, max_ip=>0, share_policy=>'perZone' },
    host_name_regex=>[{regex_expression=>'^.*$'}],
    host_max_check_host=>5,
    host_supported_status=>\@host_supported_status
  }
);
# END: host node

# contact node
my @contact_postal_info = (
  {
    contact_postal_info_name=>{ min_length=>5, max_length=>15 },
    contact_postal_info_org=>{ min_length=>2, max_length=>40 },
    contact_postal_info_address=>
    {
      street=>{ min_length=>1, max_length=>40, min_entry=>1, max_entry=>3 },
      city=>{ min_length=>1, max_length=>40 },
      sp=>{ min_length=>1, max_length=>40 },
      pc=>{ min_length=>1, max_length=>40 },
    },
    contact_postal_info_voice_required=>'false',
    contact_postal_info_voice_ext=>{ min_length=>1, max_length=>40 },
    contact_postal_info_fax_ext=>{ min_length=>1, max_length=>40 },
    contact_postal_info_email_regex=>[{regex_expression=>'^.+\..+$'}],
  }
);
my @contact_supported_status = ({ status=>['ok','clientDeleteProhibited','serverDeleteProhibited','clientTransferProhibited','serverTransferProhibited','clientUpdateProhibited','serverUpdateProhibited','linked','pendingDelete','pendingTransfer'] });
my @contact_el = (
  {
    contact_id_regex=>{regex_expression=>'^.*$'},
    contact_share_policy=>'perZone',
    contact_int_support=>'true',
    contact_loc_support=>'false',
    contact_postal_info=>\@contact_postal_info,
    contact_max_check_contact=>5,
    contact_auth_info_regex=>{regex_expression=>'^.*$'},
    contact_client_disclosure_supported=>'false',
    contact_supported_status=>\@contact_supported_status,
    contact_transfer_hold_period=>5,
    contact_transfer_hold_period_attr=>'d'
  }
);
# END: contact node

$rc=$dri->registry_create('EXAMPLE',{group=>'STANDARD',sub_product=>'EXAMPLE',related=>\@related_el,phase=>\@phase_el,service=>\@service_el,sla_info=>\@slainfo_el,cr_id=>'clientX',cr_date=>'2012-10-01T00:00:00.0Z',up_id=>'clientY',up_date=>'2012-10-15T00:00:00.0Z',domain=>\@domain_el,host=>\@host_el,contact=>\@contact_el});
#is_string($R1,$E1.'<command><create><registry:create xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:zone><registry:name>EXAMPLE</registry:name><registry:group>STANDARD</registry:group><registry:subProduct>EXAMPLE</registry:subProduct><registry:related><registry:fields type="sync"><registry:field>clID</registry:field><registry:field>registrant</registry:field><registry:field>ns</registry:field></registry:fields><registry:zoneMember type="equal">EXAMPLE</registry:zoneMember><registry:zoneMember type="equal">EXAMPLE2</registry:zoneMember><registry:zoneMember type="equal">EXAMPLE3</registry:zoneMember></registry:related><registry:phase type="sunrise"><registry:startDate>2012-11-01T00:00:00.0Z</registry:startDate><registry:endDate>2012-12-01T00:00:00.0Z</registry:endDate></registry:phase><registry:phase name="landrush" type="claims"><registry:startDate>2012-12-01T00:00:00.0Z</registry:startDate><registry:endDate>2012-12-08T00:00:00.0Z</registry:endDate></registry:phase><registry:phase name="open" type="claims"><registry:startDate>2012-12-08T00:00:00.0Z</registry:startDate><registry:endDate>2013-02-01T00:00:00.0Z</registry:endDate></registry:phase><registry:phase type="open"><registry:startDate>2013-02-01T00:00:00.0Z</registry:startDate></registry:phase><registry:services><registry:objURI required="true">urn:ietf:params:xml:ns:domain-1.0</registry:objURI><registry:objURI required="true">urn:ietf:params:xml:ns:host-1.0</registry:objURI><registry:objURI required="true">urn:ietf:params:xml:ns:contact-1.0</registry:objURI><registry:svcExtension><registry:extURI required="true">urn:ietf:params:xml:ns:rgp-1.0</registry:extURI><registry:extURI required="true">urn:ietf:params:xml:ns:secDNS-1.1</registry:extURI><registry:extURI required="true">http://www.verisign-grs.com/epp/namestoreExt-1.1</registry:extURI><registry:extURI required="false">http://www.verisign.com/epp/idnLang-1.0</registry:extURI></registry:svcExtension></registry:services><registry:slaInfo><registry:sla type="downtime" unit="min">864</registry:sla><registry:sla type="rtt" command="domain:check" unit="ms">2000</registry:sla><registry:sla type="rtt" command="domain:info" unit="ms">2000</registry:sla><registry:sla type="rtt" command="domain:create" unit="ms">4000</registry:sla><registry:sla type="rtt" command="domain:update" unit="ms">4000</registry:sla><registry:sla type="rtt" command="domain:renew" unit="ms">4000</registry:sla><registry:sla type="rtt" command="domain:delete" unit="ms">4000</registry:sla><registry:sla type="rtt" command="domain:transfer" unit="ms">4000</registry:sla></registry:slaInfo><registry:crID>clientX</registry:crID><registry:crDate>2012-10-01T00:00:00.0Z</registry:crDate></registry:zone></registry:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'registry_create build');
# README: faking original attributes order (registry:phase type and and name attr, registry:slainfo (all attributes)) because of the array swapping on Perl 5.xx
is_string($R1,$E1.'<command><create><registry:create xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:zone><registry:name>EXAMPLE</registry:name><registry:group>STANDARD</registry:group><registry:subProduct>EXAMPLE</registry:subProduct><registry:related><registry:fields type="sync"><registry:field>clID</registry:field><registry:field>registrant</registry:field><registry:field>ns</registry:field></registry:fields><registry:zoneMember type="equal">EXAMPLE</registry:zoneMember><registry:zoneMember type="equal">EXAMPLE2</registry:zoneMember><registry:zoneMember type="equal">EXAMPLE3</registry:zoneMember></registry:related><registry:phase type="sunrise"><registry:startDate>2012-11-01T00:00:00.0Z</registry:startDate><registry:endDate>2012-12-01T00:00:00.0Z</registry:endDate></registry:phase><registry:phase name="landrush" type="claims"><registry:startDate>2012-12-01T00:00:00.0Z</registry:startDate><registry:endDate>2012-12-08T00:00:00.0Z</registry:endDate></registry:phase><registry:phase name="open" type="claims"><registry:startDate>2012-12-08T00:00:00.0Z</registry:startDate><registry:endDate>2013-02-01T00:00:00.0Z</registry:endDate></registry:phase><registry:phase type="open"><registry:startDate>2013-02-01T00:00:00.0Z</registry:startDate></registry:phase><registry:services><registry:objURI required="true">urn:ietf:params:xml:ns:domain-1.0</registry:objURI><registry:objURI required="true">urn:ietf:params:xml:ns:host-1.0</registry:objURI><registry:objURI required="true">urn:ietf:params:xml:ns:contact-1.0</registry:objURI><registry:svcExtension><registry:extURI required="true">urn:ietf:params:xml:ns:rgp-1.0</registry:extURI><registry:extURI required="true">urn:ietf:params:xml:ns:secDNS-1.1</registry:extURI><registry:extURI required="true">http://www.verisign-grs.com/epp/namestoreExt-1.1</registry:extURI><registry:extURI required="false">http://www.verisign.com/epp/idnLang-1.0</registry:extURI></registry:svcExtension></registry:services><registry:slaInfo><registry:sla type="downtime" unit="min">864</registry:sla><registry:sla command="domain:check" type="rtt" unit="ms">2000</registry:sla><registry:sla command="domain:info" type="rtt" unit="ms">2000</registry:sla><registry:sla command="domain:create" type="rtt" unit="ms">4000</registry:sla><registry:sla command="domain:update" type="rtt" unit="ms">4000</registry:sla><registry:sla command="domain:renew" type="rtt" unit="ms">4000</registry:sla><registry:sla command="domain:delete" type="rtt" unit="ms">4000</registry:sla><registry:sla command="domain:transfer" type="rtt" unit="ms">4000</registry:sla></registry:slaInfo><registry:crID>clientX</registry:crID><registry:crDate>2012-10-01T00:00:00.0Z</registry:crDate><registry:upID>clientY</registry:upID><registry:upDate>2012-10-15T00:00:00.0Z</registry:upDate><registry:domain><registry:domainName level="2"><registry:minLength>5</registry:minLength><registry:maxLength>50</registry:maxLength><registry:alphaNumStart>true</registry:alphaNumStart><registry:alphaNumEnd>false</registry:alphaNumEnd><registry:onlyDnsChars>true</registry:onlyDnsChars><registry:regex><registry:expression>^\w+.*$</registry:expression><registry:explanation>Alphanumeric</registry:explanation></registry:regex><registry:regex><registry:expression>^\d+.*$</registry:expression></registry:regex><registry:reservedNames><registry:reservedName>reserved1</registry:reservedName></registry:reservedNames></registry:domainName><registry:idn><registry:idnVersion>4.1</registry:idnVersion><registry:idnaVersion>2008</registry:idnaVersion><registry:unicodeVersion>6.0</registry:unicodeVersion><registry:encoding>Punycode</registry:encoding><registry:commingleAllowed>false</registry:commingleAllowed><registry:language code="LANG-1"><registry:table>http://www.iana.org/idn-tables/test_tab1_1.1.txt</registry:table><registry:variantStrategy>blocked</registry:variantStrategy></registry:language></registry:idn><registry:premiumSupport>false</registry:premiumSupport><registry:contact type="admin"><registry:min>1</registry:min><registry:max>4</registry:max></registry:contact><registry:ns><registry:min>0</registry:min><registry:max>13</registry:max></registry:ns><registry:childHost><registry:min>0</registry:min></registry:childHost><registry:period command="create"><registry:length><registry:min unit="y">1</registry:min><registry:max unit="y">10</registry:max><registry:default unit="y">1</registry:default></registry:length></registry:period><registry:transferHoldPeriod unit="d">5</registry:transferHoldPeriod><registry:gracePeriod command="create" unit="d">5</registry:gracePeriod><registry:gracePeriod command="renew" unit="d">5</registry:gracePeriod><registry:gracePeriod command="transfer" unit="d">5</registry:gracePeriod><registry:gracePeriod command="autoRenew" unit="d">45</registry:gracePeriod><registry:rgp><registry:redemptionPeriod unit="d">30</registry:redemptionPeriod><registry:pendingRestore unit="d">7</registry:pendingRestore><registry:pendingDelete unit="d">5</registry:pendingDelete></registry:rgp><registry:dnssec><registry:dsDataInterface><registry:min>0</registry:min><registry:max>13</registry:max><registry:alg>3</registry:alg><registry:digestType>1</registry:digestType></registry:dsDataInterface><registry:maxSigLife><registry:clientDefined>false</registry:clientDefined></registry:maxSigLife></registry:dnssec><registry:maxCheckDomain>5</registry:maxCheckDomain><registry:supportedStatus><registry:status>ok</registry:status><registry:status>clientDeleteProhibited</registry:status><registry:status>serverDeleteProhibited</registry:status><registry:status>clientHold</registry:status><registry:status>serverHold</registry:status><registry:status>clientRenewProhibited</registry:status><registry:status>serverRenewProhibited</registry:status><registry:status>clientTransferProhibited</registry:status><registry:status>serverTransferProhibited</registry:status><registry:status>clientUpdateProhibited</registry:status><registry:status>serverUpdateProhibited</registry:status><registry:status>inactive</registry:status><registry:status>pendingDelete</registry:status><registry:status>pendingTransfer</registry:status></registry:supportedStatus><registry:authInfoRegex><registry:expression>^.*$</registry:expression></registry:authInfoRegex></registry:domain><registry:host><registry:internal><registry:minIP>1</registry:minIP><registry:maxIP>13</registry:maxIP><registry:sharePolicy>perZone</registry:sharePolicy></registry:internal><registry:external><registry:minIP>0</registry:minIP><registry:maxIP>0</registry:maxIP><registry:sharePolicy>perZone</registry:sharePolicy></registry:external><registry:nameRegex><registry:expression>^.*$</registry:expression></registry:nameRegex><registry:maxCheckHost>5</registry:maxCheckHost><registry:supportedStatus><registry:status>ok</registry:status><registry:status>clientDeleteProhibited</registry:status><registry:status>serverDeleteProhibited</registry:status><registry:status>clientUpdateProhibited</registry:status><registry:status>serverUpdateProhibited</registry:status><registry:status>linked</registry:status><registry:status>pendingDelete</registry:status><registry:status>pendingTransfer</registry:status></registry:supportedStatus></registry:host><registry:contact><registry:contactIdRegex><registry:expression>^.*$</registry:expression></registry:contactIdRegex><registry:sharePolicy>perZone</registry:sharePolicy><registry:intSupport>true</registry:intSupport><registry:locSupport>false</registry:locSupport><registry:postalInfo><registry:name><registry:minLength>5</registry:minLength><registry:maxLength>15</registry:maxLength></registry:name><registry:org><registry:minLength>2</registry:minLength><registry:maxLength>40</registry:maxLength></registry:org><registry:address><registry:street><registry:minLength>1</registry:minLength><registry:maxLength>40</registry:maxLength><registry:minEntry>1</registry:minEntry><registry:maxEntry>3</registry:maxEntry></registry:street><registry:city><registry:minLength>1</registry:minLength><registry:maxLength>40</registry:maxLength></registry:city><registry:sp><registry:minLength>1</registry:minLength><registry:maxLength>40</registry:maxLength></registry:sp><registry:pc><registry:minLength>1</registry:minLength><registry:maxLength>40</registry:maxLength></registry:pc></registry:address><registry:voiceRequired>false</registry:voiceRequired><registry:voiceExt><registry:minLength>1</registry:minLength><registry:maxLength>40</registry:maxLength></registry:voiceExt><registry:faxExt><registry:minLength>1</registry:minLength><registry:maxLength>40</registry:maxLength></registry:faxExt><registry:emailRegex><registry:expression>^.+\..+$</registry:expression></registry:emailRegex></registry:postalInfo><registry:maxCheckContact>5</registry:maxCheckContact><registry:authInfoRegex><registry:expression>^.*$</registry:expression></registry:authInfoRegex><registry:clientDisclosureSupported>false</registry:clientDisclosureSupported><registry:supportedStatus><registry:status>ok</registry:status><registry:status>clientDeleteProhibited</registry:status><registry:status>serverDeleteProhibited</registry:status><registry:status>clientTransferProhibited</registry:status><registry:status>serverTransferProhibited</registry:status><registry:status>clientUpdateProhibited</registry:status><registry:status>serverUpdateProhibited</registry:status><registry:status>linked</registry:status><registry:status>pendingDelete</registry:status><registry:status>pendingTransfer</registry:status></registry:supportedStatus><registry:transferHoldPeriod unit="d">5</registry:transferHoldPeriod></registry:contact></registry:zone></registry:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'registry_create build');
is($rc->is_success(),1,'registry_create is_success');
is($dri->get_info('name'),'zone1','registry_create get_info(name)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','registry_create get_info(crDate)');
is($d,'2012-10-30T22:00:00','registry_create get_info(crDate)');


# 3.2.2 EPP <delete> Command
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->registry_delete('EXAMPLE');
is_string($R1,$E1.'<command><delete><registry:delete xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:name>EXAMPLE</registry:name></registry:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'registry_delete build');
is($rc->is_success(),1,'registry_delete is_success');


# 3.2.5 EPP <update> Command
# FIXME???: they mention "The update completely replaces the prior version of the zone". So it makes no sense using the standard update: add, del and chg???
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->registry_update('EXAMPLE',{group=>'STANDARD',sub_product=>'EXAMPLE'});
is_string($R1,$E1.'<command><update><registry:update xmlns:registry="http://www.verisign.com/epp/registry-1.0" xsi:schemaLocation="http://www.verisign.com/epp/registry-1.0 registry-1.0.xsd"><registry:zone><registry:name>EXAMPLE</registry:name><registry:group>STANDARD</registry:group><registry:subProduct>EXAMPLE</registry:subProduct></registry:zone></registry:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'registry_update build');
is($rc->is_success(),1,'registry_update is_success');


####################################################################################################
exit 0;
