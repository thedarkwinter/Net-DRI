#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 9;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
my ($dri,$rc,$s,$d,$dh,@c,$idn);

sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

$dri=Net::DRI::TrapExceptions->new({cache_ttl => -1, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
# $rc = $dri->add_registry('NGTLD',{provider => 'ari'});
# To use ARI extensions instead
$rc = $dri->add_current_registry('Neustar::Narwhal');
$dri->add_current_profile('p2','epp_ari',{f_send=>\&mysend,f_recv=>\&myrecv});

#####################
## exAvail Extension

# domain check
$R2=$E1.'<response>'.r().'<extension><exAvail:chkData xmlns:exAvail="urn:ar:params:xml:ns:exAvail-1.0"><exAvail:cd><exAvail:name>example6.menu</exAvail:name><exAvail:state s="application"><exAvail:phase>sunrise</exAvail:phase><exAvail:date>2012-10-20T00:00:00Z</exAvail:date><exAvail:reason>some reason</exAvail:reason><exAvail:primaryDomainName>example.menu</exAvail:primaryDomainName></exAvail:state></exAvail:cd></exAvail:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example6.menu',{ex_avail=>1});
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example6.menu</domain:name></domain:check></check><extension><exAvail:check xmlns:exAvail="urn:ar:params:xml:ns:exAvail-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:exAvail-1.0 exAvail-1.0.xsd"/></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check ex_avail build_xml');
is($dri->get_info('action'),'check','domain_check get_info(check)');
is($dri->get_info('name'),'example6.menu','domain_check get_info name');
is($dri->get_info('exist'),'1','domain_check get_info exists');
my $ea = $dri->get_info('ex_avail');
is($ea->{'state'},'application','domain_check get_info ex_avail state');
is($ea->{'phase'},'sunrise','domain_check get_info ex_avail phase');
is($ea->{'reason'},'some reason','domain_check get_info ex_avail reason');
is($ea->{'date'},'2012-10-20T00:00:00','domain_check get_info ex_avail date');
is($ea->{'primary_domain_name'},'example.menu','domain_check get_info ex_avail primary_domain_name');

exit 0;
