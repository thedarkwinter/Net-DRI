#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;


use Test::More tests => 36;
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

#### Shared Registry
# MAM Clients
$rc = $dri->add_registry('NGTLD',{provider => 'mamclient'});
is($rc->{last_registry},'mamclient','mamclient: add_registry');
$rc = $dri->target('mamclient')->add_current_profile('p1-mamclient','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
is($rc->is_success(),1,'mamclient: add_current_profile');
is($dri->name(),'mamclient','mamclient: name');
is_deeply([$dri->tlds()],['bible','gop','kiwi','broadway','casino','poker','radio','tickets','tube'],'mamclient: tlds');
@periods = $dri->periods();
is($#periods,9,'mamclient: periods');
is_deeply( [$dri->object_types()],['domain','contact','ns'],'mamclient: object_types');
is_deeply( [$dri->profile_types()],['epp'],'mamclient: profile_types');
$drd = $dri->{registries}->{mamclient}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{}],'mamclient: epp transport_protocol_default');
is($drd->{bep}->{bep_type},2,'mamclient: bep_type');
is($drd->{info}->{check_limit},13,'mamclient: check_limit');

# Donuts
$rc = $dri->add_registry('NGTLD',{provider => 'donuts'});
is($rc->{last_registry},'donuts','donuts: add_registry');
$rc = $dri->target('donuts')->add_current_profile('p1-donuts','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$drd = $dri->{registries}->{donuts}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UNITEDTLD',{}],'donuts: epp transport_protocol_default');
is($drd->{bep}->{bep_type},2,'donuts: bep_type');
is($drd->{info}->{check_limit},5,'donuts: check_limit');
is($drd->{info}->{host_check_limit},5,'donuts: host_check_limit');
is($dri->info('contact_check_limit'),5,'donuts: contact_check_limit');
is($drd->{info}->{domain_check_limit},5,'donuts: domain_check_limit');


#### Dedicated Registry
# Neustar
$rc = $dri->add_registry('NGTLD',{provider => 'neustar','name'=>'buzz'});
is($rc->{last_registry},'buzz','neustar: add_registry');
$rc = $dri->target('buzz')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
is($rc->is_success(),1,'neustar: add_current_profile');
is($dri->name(),'buzz','neustar: name');
is_deeply([$dri->tlds()],['buzz'],'neustar: tlds');
@periods = $dri->periods();
is($#periods,9,'neustar: periods');
is_deeply( [$dri->object_types()],['domain','contact','ns'],'neustar: object_types');
is_deeply( [$dri->profile_types()],['epp'],'neustar: profile_types');
$drd = $dri->{registries}->{mamclient}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{}],'neustar: epp transport_protocol_default');
is($drd->{bep}->{bep_type},2,'neustar: bep_type');


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
$rc = $dri->target('buzz');
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase name="landrush">claims</launch:phase><launch:cd><launch:name exists="1">test.buzz</launch:name><launch:claimKey validatorID="sample">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_check_claims('test.buzz',{phase=>'landrush'});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.buzz</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase name="landrush">claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check_claims build_xml');
$lpres = $dri->get_info('lp');
is($lpres->{'exist'},1,'domain_check_claims get_info(exist)');
is($lpres->{'phase'},'claims','domain_check_claims get_info(phase)');
is($lpres->{'claim_key'},'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','domain_check_claims get_info(claim_key)');
is($lpres->{'validator_id'},'sample','domain_check_claims get_info(validator_id)');




exit 0;