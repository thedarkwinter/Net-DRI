#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 3;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport, $count, $msg) = @_; $R1 = $msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('CO',{clid => 'ClientX'});
$dri->target('CO')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$ok,$cs,$st,$p);

####################################################################################################
## CO Extension
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns="urn:ietf:params:xml:ns:domain-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>EXAMPLE1.CO</domain:name><domain:roid>D20342671-US</domain:roid><domain:status s="clientHold"/><domain:registrant>COUS-7135</domain:registrant><domain:contact type="admin">TEST123</domain:contact><domain:contact type="billing">TEST123</domain:contact><domain:contact type="tech">TEST123</domain:contact><domain:ns><domain:hostObj>NS1.TEST.CO</domain:hostObj><domain:hostObj>NS2.TEST.CO</domain:hostObj><domain:hostObj>NS3.TEST.CO</domain:hostObj></domain:ns><domain:clID>NEUSTAR</domain:clID><domain:crID>NEUSTAR</domain:crID><domain:crDate>2009-06-09T15:55:37.0Z</domain:crDate><domain:upID>NEUSTAR</domain:upID><domain:upDate>2009-09-16T12:51:30.0Z</domain:upDate><domain:exDate>2014-06-08T23:59:59.0Z</domain:exDate><domain:authInfo><domain:pw>abcdef123</domain:pw></domain:authInfo></domain:infData></resData><extension><neulevel:extension xmlns="urn:ietf:params:xml:ns:neulevel-1.0" xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>DomainSuspendedIndicator=expired</neulevel:unspec></neulevel:extension></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_info('example1.co');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('domain_suspended_indicator'),'expired','domain_info get_info (domain_suspended_indicator)');

exit(0);
