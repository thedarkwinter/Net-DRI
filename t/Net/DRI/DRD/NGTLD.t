#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;


use Test::More tests => 124;
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


#### Shared Registry
# MAM Clients
$rc = $dri->add_registry('NGTLD',{provider => 'mamclient'});
is($rc->{last_registry},'mamclient','mamclient: add_registry');
$rc = $dri->target('mamclient')->add_current_profile('p1-mamclient','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
is($rc->is_success(),1,'mamclient: add_current_profile');
is($dri->name(),'mamclient','mamclient: name');
is_deeply([$dri->tlds()],['radio'],'mamclient: tlds');
@periods = $dri->periods();
is($#periods,9,'mamclient: periods');
is_deeply( [$dri->object_types()],['domain','contact','ns'],'mamclient: object_types');
is_deeply( [$dri->profile_types()],['epp','whois'],'mamclient: profile_types');
$drd = $dri->{registries}->{mamclient}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee']}],'mamclient: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN CentralNic::Fee/],'mamclient: loaded_modules');
is($drd->{bep}->{bep_type},2,'mamclient: bep_type');
is($drd->{info}->{check_limit},13,'mamclient: check_limit');

# Donuts
$rc = $dri->add_registry('NGTLD',{provider => 'donuts'});
is($rc->{last_registry},'donuts','donuts: add_registry');
$rc = $dri->target('donuts')->add_current_profile('p1-donuts','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{donuts}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{ssl_version => 'TLSv12'},'Net::DRI::Protocol::EPP::Extensions::UNITEDTLD',{}],'donuts: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN AllocationToken UNITEDTLD::Charge UNITEDTLD::Finance/],'donuts: loaded_modules');
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
# test for migration from StartingDot to Afilias - .bio
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">foobar.bio</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('foobar.bio');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>foobar.bio</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build afilias - ngtld (StartingDot to Afilias migration)');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','foobar.bio'),0,'domain_check get_info(exist) from cache');

#### Dedicated Registry
# Neustar (pharmacy)
$rc = $dri->add_registry('NGTLD',{provider => 'neustar','name'=>'pharmacy'});
is($rc->{last_registry},'pharmacy','neustar: add_registry');
$rc = $dri->target('pharmacy')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
is($rc->is_success(),1,'neustar: add_current_profile');
is($dri->name(),'pharmacy','neustar: name');
is_deeply([$dri->tlds()],['pharmacy'],'neustar: tlds');
@periods = $dri->periods();
is($#periods,9,'neustar: periods');
is_deeply( [$dri->object_types()],['domain','contact','ns'],'neustar: object_types');
is_deeply( [$dri->profile_types()],['epp','whois'],'neustar: profile_types');
$drd = $dri->{registries}->{pharmacy}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{custom=>'NeuLevel::Fee'}],'neustar: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN NeuLevel::Message AllocationToken NeuLevel::Fee/],'neustar: loaded_modules');
is($drd->{bep}->{bep_type},1,'neustar: bep_type');

# FFM (Neustar + CentralNic::Fee )
$rc = $dri->add_registry('NGTLD',{provider => 'ffm'});
is($rc->{last_registry},'ffm','ffm: add_registry');
$rc = $dri->target('ffm')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
is($rc->is_success(),1,'neustar ffm: add_current_profile');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN NeuLevel::Message AllocationToken CentralNic::Fee/],'ffm: loaded_modules');

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
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules_no_host, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase COZA::Domain COZA::Contact UNITEDTLD::Charge/],'zacr: loaded_modules');

is($drd->{bep}->{bep_type},1,'zacr: bep_type');


# CRR
$rc = $dri->add_registry('NGTLD',{provider => 'crr'});
is($rc->{last_registry},'crr','crr: add_registry');
$rc = $dri->target('crr')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{crr}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee'],disable_idn=>1,'brown_fee_version' => '0.6'}],'crr: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase CentralNic::Fee/],'crr: loaded_modules');
is($drd->{bep}->{bep_type},2,'crr: bep_type');
is($drd->{info}->{check_limit},13,'crr: check_limit');

# CRR
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
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{disable_idn=>1,custom=>['VeriSign::Sync', 'VeriSign::PollLowBalance', 'VeriSign::PollRGP', 'VeriSign::IDNLanguage', 'VeriSign::WhoWas', 'VeriSign::Suggestion', 'VeriSign::ClientAttributes', 'VeriSign::TwoFactorAuth', 'VeriSign::ZoneManagement', 'VeriSign::Balance', 'VeriSign::NameStore', 'VeriSign::PremiumDomain', 'CentralNic::Fee'], brown_fee_version => '0.9'}],'verisign: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase VeriSign::Sync VeriSign::PollLowBalance VeriSign::PollRGP VeriSign::IDNLanguage VeriSign::WhoWas VeriSign::Suggestion VeriSign::ClientAttributes VeriSign::TwoFactorAuth VeriSign::ZoneManagement VeriSign::Balance VeriSign::NameStore VeriSign::PremiumDomain CentralNic::Fee/],'verisign: loaded_modules');
is($drd->{bep}->{bep_type},2,'verisign: bep_type');
is($drd->{info}->{check_limit},13,'verisign: check_limit');
is_deeply([$dri->tlds()],['com','net','cc','tv','jobs','xn--pssy2u','xn--c1yn36f','xn--11b4c3d','xn--t60b56a','xn--c2br7g','xn--42c2d9a','xn--j1aef','xn--3pxu8k','xn--hdb9cza1b','xn--mk1bu44c','xn--fhbei','xn--tckwe','azure','bank','bing','broker','career','cfd','crs','forex','hotmail','insurance','java','maif','makeup','markets','microsoft','ooo','oracle','pictet','realtor','sca','shell','sky','spreadbetting','trading','xbox','windows'],'verisign: tlds');

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
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase/],'nominet regional: loaded_modules');

# Nominet-MMX
$rc = $dri->add_registry('NGTLD',{provider => 'nominet-mmx',name=>'blog'});
is($rc->{last_registry},'blog','nominet mmx: add_registry');
$rc = $dri->target('blog')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{blog}->{driver};
is($rc->is_success(),1,'nominet mmx: add_current_profile');
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{ssl_version => 'TLSv12'},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee','AllocationToken','MAM::QualifiedLawyer'], 'brown_fee_version' => '0.5' }],'nominet mmx: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase IDN CentralNic::Fee AllocationToken MAM::QualifiedLawyer/],'nominet mmx: loaded_modules');

# Teleinfo (CentralNic::Fee)
$rc = $dri->add_registry('NGTLD',{provider => 'teleinfo'});
is($rc->{last_registry},'teleinfo','teleinfo: add_registry');
$rc = $dri->target('teleinfo')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{teleinfo}->{driver};
is($rc->is_success(),1,'teleinfo: add_current_profile');
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee'], 'disable_idn' => 1, 'brown_fee_version' => '0.9'}],'teleinfo: epp transport_protocol_default');
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS LaunchPhase CentralNic::Fee/],'teleinfo: loaded_modules');

# ARI
$rc = $dri->add_registry('NGTLD',{provider => 'ari'});
is($rc->{last_registry},'ari','ari: add_registry');
$rc = $dri->target('ari')->add_current_profile('ari','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{ari}->{driver};
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS NeuLevel::Message AllocationToken ARI::IDNVariant ARI::KeyValue ARI::ExAvail ARI::Price ARI::TMCHApplication ARI::Block NeuLevel::EXTContact/],'ari: loaded_modules');
is_deeply([$dri->tlds()],['xn--1ck2e1b','xn--bck1b9a5dre4c','xn--cck2b3b','xn--eckvdtc9d','xn--fct429k','xn--g2xx48c','xn--gckr3f0f','xn--gk3at1e','xn--jvr189m','xn--kcrx77d1x4a','xn--kpu716f','xn--mgba7c0bbn0a','xn--ngbc5azd','xn--nyqy26a','xn--pbt977c','xn--rhqv96g','xn--rovu88b','aaa','able','afl','americanexpress','amex','analytics','anz','athleta','audible','author','aws','baby','banamex','bananarepublic','barclaycard','barclays','baseball','best','bible','bond','book','booking','boots','bot','bridgestone','build','buy','buzz','call','cancerresearch','cartier','cba','cbn','ceo','chase','chintai','chloe','circle','citadel','citi','cloud','club','commbank','compare','coupon','courses','cuisinella','deal','dealer','dell','discover','doha','duns','dupont','earth','farmers','fast','ferrero','film','fire','firestone','flickr','ford','fox','free','ftr','gap','giving','got','grainger','gucci','health','homegoods','homesense','honeywell','hot','hsbc','hyatt','ibm','icu','ieee','iinet','imdb','intel','intuit','iselect','iwc','jlc','jmp','jnj','jot','joy','jpmorgan','kinder','kindle','kpmg','krd','kred','latrobe','like','lilly','lincoln','luxury','marshalls','mcd','mcdonalds','melbourne','men','menu','mint','mlb','moe','moi','monash','montblanc','mtn','mutual','netbank','nfl','nyc','now','olayan','olayangroup','oldnavy','one','open','panerai','pay','pharmacy','philips','physio','piaget','pin','ping','playstation','praxi','prime','qpon','quest','qvc','read','rocher','room','safe','safety','sandvik','sandvikcoromant','sas','save','saxo','schmidt','scor','secure','seek','select','seven','silk','smile','song','sony','spot','starhub','statefarm','study','sucks','swiftcover','sydney','tab','taipei','talk','tdk','teva','tjmaxx','tjx','tkmaxx','trust','tube','tunes','tushu','uno','virgin','vista','vistaprint','vivo','walter','wanggou','watches','weather','weatherchannel','whoswho','winners','woodside','wow','wtc','yahoo','yamaxun','yandex','you','zappos','zero','zippo'],'ari: tlds');

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
$rc = $dri->target('pharmacy');
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase name="landrush">claims</launch:phase><launch:cd><launch:name exists="1">test.pharmacy</launch:name><launch:claimKey validatorID="sample">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_check_claims('test.pharmacy',{phase=>'landrush'});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.pharmacy</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase name="landrush">claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check_claims build_xml');
$lpres = $dri->get_info('lp');
is($lpres->{'exist'},1,'domain_check_claims get_info(exist)');
is($lpres->{'phase'},'claims','domain_check_claims get_info(phase)');
is($lpres->{'claim_key'},'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','domain_check_claims get_info(claim_key)');
is($lpres->{'validator_id'},'sample','domain_check_claims get_info(validator_id)');

#### afiliassrs migration tests
$rc = $dri->add_registry('NGTLD',{provider => 'afiliassrs'});
is($rc->{last_registry},'afiliassrs','afiliassrs add_registry');
$rc = $dri->target('afiliassrs')->add_current_profile('p1-afiliassrs','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
# afiliassrs - @ngtlds
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">foobar.global</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('foobar.global');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>foobar.global</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build afiliassrs - ngtld');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','foobar.global'),0,'domain_check get_info(exist) from cache');
# afiliassrs - @gtlds
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">foobar.xxx</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('foobar.xxx');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>foobar.xxx</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build afiliassrs - gtld');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','foobar.xxx'),0,'domain_check get_info(exist) from cache');
# afiliassrs - @cctlds
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">foobar.com.vc</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('foobar.com.vc');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>foobar.com.vc</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build afiliassrs - cctld');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','foobar.com.vc'),0,'domain_check get_info(exist) from cache');

exit 0;
