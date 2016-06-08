#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 10;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend  { my ($transport, $count, $msg) = @_; $R1 = $msg->as_string(); return 1; }
sub myrecv  { return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r       { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('INFO',{clid => 'ClientX'});
$dri->target('INFO')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$ok,$cs,$st,$p);

####################################################################################################
## IDN Extension

# Old method
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.info</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.info',{'language'=>'zh'});
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.info</domain:name></domain:check></check><extension><idn:check xmlns:idn="urn:afilias:params:xml:ns:idn-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:idn-1.0 idn-1.0.xsd"><idn:script>zh</idn:script></idn:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check idn old build');
is($rc->is_success(),1,'domain_check idn old is_success');

# New method (with IDN Object)
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.info</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.info',{'idn' => $dri->local_object('idn')->autodetect('','zh') });
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.info</domain:name></domain:check></check><extension><idn:check xmlns:idn="urn:afilias:params:xml:ns:idn-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:idn-1.0 idn-1.0.xsd"><idn:script>zh</idn:script></idn:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check idn new build');
is($rc->is_success(),1,'domain_check idn new is_success');

# New method (with IDN Object and extlang)
$dri->cache_clear();
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.info</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.info',{'idn' => $dri->local_object('idn')->autodetect('','zh-tw') });
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.info</domain:name></domain:check></check><extension><idn:check xmlns:idn="urn:afilias:params:xml:ns:idn-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:idn-1.0 idn-1.0.xsd"><idn:script>zh-tw</idn:script></idn:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check idn new with extlang build');
is($rc->is_success(),1,'domain_check idn new with extlang is_success');

# Check Multi - New method (with IDN Object and extlang)
$dri->cache_clear();
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example4.info</domain:name></domain:cd><domain:cd><domain:name avail="1">example5.info</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example4.info','example5.info',{'idn' => $dri->local_object('idn')->autodetect('','zh-tw') });
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.info</domain:name><domain:name>example5.info</domain:name></domain:check></check><extension><idn:check xmlns:idn="urn:afilias:params:xml:ns:idn-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:idn-1.0 idn-1.0.xsd"><idn:script>zh-tw</idn:script></idn:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi idn new with extlang build');
is($rc->is_success(),1,'domain_check multi idn new with extlang is_success');

# Check Multi - Old method
$dri->cache_clear();
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example4.info</domain:name></domain:cd><domain:cd><domain:name avail="1">example5.info</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example4.info','example5.info',{'language'=>'zh-tw'});
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.info</domain:name><domain:name>example5.info</domain:name></domain:check></check><extension><idn:check xmlns:idn="urn:afilias:params:xml:ns:idn-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:idn-1.0 idn-1.0.xsd"><idn:script>zh-tw</idn:script></idn:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi idn new with extlang build');
is($rc->is_success(),1,'domain_check multi idn old is_success');

exit 0;
