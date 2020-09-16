#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;


use Test::More tests => 108;
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

my ($rc,$drd,@periods);

####################################################################################################
#### Loading DRD

# Core module lists for testing loaded_modules
my @core_modules = map { 'Net::DRI::Protocol::EPP::Core::'.$_ } qw/Session RegistryMessage Domain Contact Host/;
my @core_modules_no_host = map { 'Net::DRI::Protocol::EPP::Core::'.$_ } qw/Session RegistryMessage Domain Contact/; # e.g. ZACR

# DNSBelgium
$rc = $dri->add_registry('NGTLD',{provider => 'dnsbelgium'});
is($rc->{last_registry},'dnsbelgium','dnsbelgium: add_registry');
$rc = $dri->target('dnsbelgium')->add_current_profile('p1-dnsbelgium','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{dnsbelgium}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{}],'dnsbelgium: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules_no_host, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN/],'dnsbelgium: loaded_modules');
is($drd->{bep}->{bep_type},1,'dnsbelgium: bep_type');
is($drd->{info}->{check_limit},13,'dnsbelgium: check_limit');
is_deeply([$dri->tlds()],['brussels','dnsbelgium','vlaanderen'],'dnsbelgium: tlds');

# Donuts
$rc = $dri->add_registry('NGTLD',{provider => 'donuts'});
is($rc->{last_registry},'donuts','donuts: add_registry');
$rc = $dri->target('donuts')->add_current_profile('p1-donuts','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{donuts}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UnitedTLD',{}],'donuts: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN AllocationToken UnitedTLD::Charge UnitedTLD::Finance/],'donuts: loaded_modules');
is($drd->{bep}->{bep_type},2,'donuts: bep_type');
is($drd->{info}->{check_limit},5,'donuts: check_limit');
is($drd->{info}->{host_check_limit},5,'donuts: host_check_limit');
is($dri->info('contact_check_limit'),5,'donuts: contact_check_limit');
is($drd->{info}->{domain_check_limit},5,'donuts: domain_check_limit');

# Afilias
$rc = $dri->add_registry('NGTLD',{provider => 'afilias'});
is($rc->{last_registry},'afilias','afilias add_registry');
$rc = $dri->target('afilias')->add_current_profile('p1-afilias','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{afilias}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{'brown_fee_version' => '0.8'}],'afilias: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase Afilias::IPR Afilias::IDNLanguage Afilias::Message Afilias::Registrar Afilias::JSONMessage CentralNic::Fee/],'afilias: loaded_modules');
is($drd->{bep}->{bep_type},2,'aflias: bep_type');
is($drd->{info}->{check_limit},13,'afilias: check_limit');
is($drd->{info}->{host_check_limit},13,'afilias: host_check_limit');
is($dri->info('contact_check_limit'),13,'afilias: contact_check_limit');
is($drd->{info}->{domain_check_limit},13,'afilias: domain_check_limit');

# TangRS / CORENIC - ruhr
$rc = $dri->add_registry('NGTLD',{provider => 'tangors', name=>'ruhr'});
is($rc->{last_registry},'ruhr','tangors (ruhr) add_registry');
$rc = $dri->target('ruhr')->add_current_profile('p1-ruhr','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{ruhr}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::TangoRS',{fee_version=>undef}],'tangors (ruhr): epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase TangoRS::IDN TangoRS::Auction/],'tangors (ruhr): loaded_modules');
is($drd->{bep}->{bep_type},1,'ruhr: bep_type');

# TangRS / CORENIC - nrw (fee-1.0)
$rc = $dri->add_registry('NGTLD',{provider => 'tangors', name=>'nrw'});
is($rc->{last_registry},'nrw','tangors (nrw) add_registry');
$rc = $dri->target('nrw')->add_current_profile('p1-nrw','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{nrw}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::TangoRS',{fee_version=>'1.0'}],'tangors (nrw): epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase TangoRS::IDN TangoRS::Auction Fee/],'tangors (nrw): loaded_modules');
is($drd->{bep}->{bep_type},1,'nrw: bep_type');

# TangRS / CORENIC - radio (fee-0.21)
$rc = $dri->add_registry('NGTLD',{provider => 'corenic', name=>'radio'});
is($rc->{last_registry},'radio','corenc (radio) add_registry');
$rc = $dri->target('radio')->add_current_profile('p1-radio','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{radio}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CORE',{fee_version=>'0.21'}],'corenic (radio): epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS TangoRS::IDN TangoRS::Auction TangoRS::LaunchPhase TangoRS::ContactEligibility TangoRS::Promotion Fee/],'corenic (radio): loaded_modules');
is($drd->{bep}->{bep_type},1,'radio: bep_type');

# Fury
$rc = $dri->add_registry('NGTLD',{provider => 'fury', 'name' => 'kiwi'});
is($rc->{last_registry},'kiwi','fury: add_registry');
$rc = $dri->target('kiwi')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
is($rc->is_success(),1,'fury: add_current_profile');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN CentralNic::Fee/],'fury: loaded_modules');
$drd = $dri->{registries}->{kiwi}->{driver};
is($drd->{bep}->{bep_type},1,'fury: bep_type');
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee'],'brown_fee_version' => '0.11'}],'crr: epp transport_protocol_default');

# ZACR (Durban)
$rc = $dri->add_registry('NGTLD',{provider => 'zacr','name'=>'joburg'});
is($rc->{last_registry},'joburg','zacr: add_registry');
$rc = $dri->target('joburg')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
is($rc->is_success(),1,'zacr: add_current_profile');
is($dri->name(),'joburg','zacr: name');
is_deeply([$dri->tlds()],['joburg'],'zacr: tlds');
@periods = $dri->periods();
is($#periods,9,'zacr: periods');
is_deeply( [$dri->object_types()],['domain','contact'],'zacr: object_types');
is_deeply( [$dri->profile_types()],['epp','whois'],'zacr: profile_types');
$drd = $dri->{registries}->{joburg}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ZACR',{}],'zacr: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules_no_host, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase ZACR::Domain ZACR::Contact UnitedTLD::Charge/],'zacr: loaded_modules');
is($drd->{bep}->{bep_type},1,'zacr: bep_type');

# CRR
$rc = $dri->add_registry('NGTLD',{provider => 'crr'});
is($rc->{last_registry},'crr','crr: add_registry');
$rc = $dri->target('crr')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{crr}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee','AllocationToken'],disable_idn=>1,'brown_fee_version' => '0.6'}],'crr: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase CentralNic::Fee AllocationToken/],'crr: loaded_modules');
is($drd->{bep}->{bep_type},2,'crr: bep_type');
is($drd->{info}->{check_limit},13,'crr: check_limit');

# NICBR
$rc = $dri->add_registry('NGTLD',{provider => 'nicbr'});
is($rc->{last_registry},'nicbr','nicbr add_registry');
$rc = $dri->target('nicbr')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{nicbr}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{disable_idn=>1}],'nicbr: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules_no_host, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase/],'nicbr: loaded_modules');
is($drd->{bep}->{bep_type},2,'nicbr: bep_type');
is($drd->{info}->{check_limit},13,'nicbr: check_limit');
is_deeply([$dri->tlds()],['bom','final','rio'],'nicbr: tlds');

# Verisign
$rc = $dri->add_registry('NGTLD',{provider => 'verisign'});
is($rc->{last_registry},'verisign','verisign add_registry');
$rc = $dri->target('verisign')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{verisign}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{disable_idn=>1,custom=>['VeriSign::Sync', 'VeriSign::PollLowBalance', 'VeriSign::PollRGP', 'VeriSign::IDNLanguage', 'VeriSign::WhoWas', 'VeriSign::Suggestion', 'VeriSign::ClientAttributes', 'VeriSign::TwoFactorAuth', 'VeriSign::ZoneManagement', 'VeriSign::Balance', 'VeriSign::NameStore', 'VeriSign::PremiumDomain', 'CentralNic::Fee', 'Fee'], fee_version => '0.9'}],'verisign: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase VeriSign::Sync VeriSign::PollLowBalance VeriSign::PollRGP VeriSign::IDNLanguage VeriSign::WhoWas VeriSign::Suggestion VeriSign::ClientAttributes VeriSign::TwoFactorAuth VeriSign::ZoneManagement VeriSign::Balance VeriSign::NameStore VeriSign::PremiumDomain CentralNic::Fee Fee/],'verisign: loaded_modules');
is($drd->{bep}->{bep_type},2,'verisign: bep_type');
is($drd->{info}->{check_limit},13,'verisign: check_limit');
is_deeply([$dri->tlds()],['com','net','cc','tv','name','jobs','xn--pssy2u','xn--c1yn36f','xn--11b4c3d','xn--t60b56a','xn--c2br7g','xn--42c2d9a','xn--j1aef','xn--3pxu8k','xn--hdb9cza1b','xn--mk1bu44c','xn--fhbei','xn--tckwe','xn--9dbq2a','azure','bing','broker','career','cfd','crs','forex','hotmail','java','maif','makeup','markets','microsoft','oracle','pictet','realestate','realtor','sca','shell','sky','spreadbetting','trading','xbox','windows'],'verisign: tlds');

# CoCCA
$rc = $dri->add_registry('NGTLD',{provider => 'cocca'});
is($rc->{last_registry},'cocca','cocca: add_registry');
$rc = $dri->target('cocca')->add_current_profile('p1-cocca','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{cocca}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CoCCA::Notifications','CentralNic::Fee'],'brown_fee_version' => '0.8'}],'cocca: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN CoCCA::Notifications CentralNic::Fee/],'cocca: loaded_modules');
is($drd->{info}->{check_limit},13,'cocca: check_limit');
is($drd->{info}->{host_check_limit},13,'cocca: host_check_limit');
is($dri->info('contact_check_limit'),13,'cocca: contact_check_limit');
is($drd->{info}->{domain_check_limit},13,'cocca: domain_check_limit');

# Nominet regional
$rc = $dri->add_registry('NGTLD',{provider => 'nominet',name=>'wales'});
is($rc->{last_registry},'wales','nominet regional: add_registry');
$rc = $dri->target('wales')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
is($rc->is_success(),1,'nominet regional: add_current_profile');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase CentralNic::Fee AllocationToken/],'nominet regional: loaded_modules');

# Nominet-MMX
$rc = $dri->add_registry('NGTLD',{provider => 'nominet-mmx',name=>'broadway'});
is($rc->{last_registry},'broadway','nominet mmx: add_registry');
$rc = $dri->target('broadway')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{broadway}->{driver};
is($rc->is_success(),1,'nominet mmx: add_current_profile');
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee','AllocationToken'], 'brown_fee_version' => '0.5' }],'nominet mmx: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN CentralNic::Fee AllocationToken/],'nominet mmx: loaded_modules');

# Teleinfo (CentralNic::Fee)
$rc = $dri->add_registry('NGTLD',{provider => 'teleinfo'});
is($rc->{last_registry},'teleinfo','teleinfo: add_registry');
$rc = $dri->target('teleinfo')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{teleinfo}->{driver};
is($rc->is_success(),1,'teleinfo: add_current_profile');
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee'], 'disable_idn' => 1, 'brown_fee_version' => '0.9'}],'teleinfo: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase CentralNic::Fee/],'teleinfo: loaded_modules');

# Neustar Legacy (hotels)
$rc = $dri->add_registry('NGTLD',{provider => 'neustar','name'=>'hotels'});
is($rc->{last_registry},'hotels','neustar: add_registry');
$rc = $dri->target('hotels')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
is($rc->is_success(),1,'neustar: add_current_profile');
is($dri->name(),'hotels','neustar: name');
is_deeply([$dri->tlds()],['hotels'],'neustar: tlds');
@periods = $dri->periods();
is($#periods,9,'neustar: periods');
is_deeply( [$dri->object_types()],['domain','contact','ns'],'neustar: object_types');
is_deeply( [$dri->profile_types()],['epp','whois'],'neustar: profile_types');
$drd = $dri->{registries}->{hotels}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::Neustar',{extensions => ['-NeuLevel::WhoisType','-ARI::KeyValue','-NeuLevel::EXTContact'], 'brown_fee_version' => '0.6' }],'neustar: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN AllocationToken NeuLevel::CO NeuLevel::Message CentralNic::Fee/],'neustar: loaded_modules');
is($drd->{bep}->{bep_type},1,'neustar: bep_type');

# Neustar-Narwhal Using ARI extensions
$rc = $dri->add_registry('NGTLD',{provider => 'ari'});
is($rc->{last_registry},'ari','neustar-ari: add_registry');
$rc = $dri->target('ari')->add_current_profile('ari','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{ari}->{driver};
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS AllocationToken ARI::IDNVariant ARI::KeyValue ARI::ExAvail ARI::Price ARI::TMCHApplication ARI::Block  NeuLevel::CO NeuLevel::Message NeuLevel::WhoisType NeuLevel::EXTContact/],'neustar-ari: loaded_modules');

# Neustar-Narwhal Using Starndard extensions
$rc = $dri->add_registry('NGTLD',{provider => 'narwhal'});
is($rc->{last_registry},'narwhal','neustar-narwhal: add_registry');
$rc = $dri->target('narwhal')->add_current_profile('narwhal','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{'narwhal'}->{driver};
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN AllocationToken NeuLevel::CO NeuLevel::Message NeuLevel::EXTContact NeuLevel::WhoisType ARI::KeyValue CentralNic::Fee/],'neustar-narwhal: loaded_modules');

####################################################################################################
#### ngTLD Methods
my ($lpres,$ch1);

#### domain_check_claims
# donuts no subphase (or subphase discarded)
$rc = $dri->target('donuts');
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>claims</launch:phase><launch:cd><launch:name exists="1">test.clothing</launch:name><launch:claimKey validatorID="sample">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_check_claims('test.clothing',{phase=>'ignoreme'}); ## PHASE IS DISCARDED AS NOT REQUIRED
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.clothing</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase>claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check_claims build_xml');
$lpres = $dri->get_info('lp');
is($lpres->{'exist'},1,'domain_check_claims get_info(exist)');
is($lpres->{'phase'},'claims','domain_check_claims get_info(phase)');
is($lpres->{'claim_key'},'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','domain_check_claims get_info(claim_key)');
is($lpres->{'validator_id'},'sample','domain_check_claims get_info(validator_id)');

# neustar subphase = landrush (required)
$rc = $dri->target('hotels');
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase name="landrush">claims</launch:phase><launch:cd><launch:name exists="1">test.hotels</launch:name><launch:claimKey validatorID="sample">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_check_claims('test.hotels',{phase=>'landrush'});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.hotels</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase name="landrush">claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check_claims build_xml');
$lpres = $dri->get_info('lp');
is($lpres->{'exist'},1,'domain_check_claims get_info(exist)');
is($lpres->{'phase'},'claims','domain_check_claims get_info(phase)');
is($lpres->{'claim_key'},'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','domain_check_claims get_info(claim_key)');
is($lpres->{'validator_id'},'sample','domain_check_claims get_info(validator_id)');

exit 0;
