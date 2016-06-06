#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 6;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('IN');
$dri->target('IN')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->{registries}->{IN}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::IN',{}],'IN - epp transport_protocol_default');
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');

####################################################################################################
######## Domain Commands ########

# Domain Create
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('test1106-27'),'registrant');
$cs->add($dri->local_object('contact')->srid('huma1106-28'),'admin');
$cs->add($dri->local_object('contact')->srid('pass1236-FA'),'tech');
$cs->add($dri->local_object('contact')->srid('pass1236-FA'),'billing');
$dh=$dri->local_object('hosts');
$dh->add('ns1.example.in');
$dh->add('ns2.example.in',['1.2.3.4'],[],1);
$rc=$dri->domain_create('example.in',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,auth=>{pw=>'opqrstuv'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.in</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.example.in</domain:hostObj><domain:hostObj>ns2.example.in</domain:hostObj></domain:ns><domain:registrant>test1106-27</domain:registrant><domain:contact type="admin">huma1106-28</domain:contact><domain:contact type="billing">pass1236-FA</domain:contact><domain:contact type="tech">pass1236-FA</domain:contact><domain:authInfo><domain:pw>opqrstuv</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($rc->is_success(),1,'domain_create is_success');

# Domain Create /w Trademark
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('test1106-27'),'registrant');
$cs->add($dri->local_object('contact')->srid('huma1106-28'),'admin');
$cs->add($dri->local_object('contact')->srid('pass1236-FA'),'tech');
$cs->add($dri->local_object('contact')->srid('pass1236-FA'),'billing');
$dh=$dri->local_object('hosts');
$dh->add('ns1.example.in');
$dh->add('ns2.example.in',['1.2.3.4'],[],1);
my $tm = {
	name => 'Test Trademark',
  date => DateTime->new(year=>2016,month=>07,day=>01),
  number => '998877',
  country => 'CA',
  ownerCountry => 'CA'
};
$rc=$dri->domain_create('example.in',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,auth=>{pw=>'opqrstuv'},trademark=>$tm});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.in</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.example.in</domain:hostObj><domain:hostObj>ns2.example.in</domain:hostObj></domain:ns><domain:registrant>test1106-27</domain:registrant><domain:contact type="admin">huma1106-28</domain:contact><domain:contact type="billing">pass1236-FA</domain:contact><domain:contact type="tech">pass1236-FA</domain:contact><domain:authInfo><domain:pw>opqrstuv</domain:pw></domain:authInfo></domain:create></create><extension><trademark:create xmlns:trademark="urn:afilias:params:xml:ns:trademark-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:trademark-1.0 trademark-1.0.xsd"><trademark:name>Test Trademark</trademark:name><trademark:country>CA</trademark:country><trademark:number>998877</trademark:number><trademark:date>2016-07-01</trademark:date><trademark:ownerCountry>CA</trademark:ownerCountry></trademark:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create trademark build_xml');
is($rc->is_success(),1,'domain_create trademark is_success');

# Domain Update ADD 'Trademark'
my $changes = $dri->local_object('changes');
$changes->set('trademark',{
	name => 'Test Trademark',
  date => DateTime->new(year=>2016,month=>07,day=>01),
  number => '998877',
  country => 'CA',
  ownerCountry => 'CA'
});
$rc = $dri->domain_update('example.in', $changes);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.in</domain:name></domain:update></update><extension><trademark:update xmlns:trademark="urn:afilias:params:xml:ns:trademark-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:trademark-1.0 trademark-1.0.xsd"><trademark:name>Test Trademark</trademark:name><trademark:number>998877</trademark:number><trademark:country>CA</trademark:country><trademark:ownerCountry>CA</trademark:ownerCountry><trademark:date>2016-07-01</trademark:date></trademark:update></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain_update add_trademark build');
is($rc->is_success(),1,'domain_update add_trademark is_success');

# Domain Update REM 'Trademark'
$changes = $dri->local_object('changes');
$changes->del('trademark',{
	name => 'Test Trademark',
  date => DateTime->new(year=>2016,month=>07,day=>01),
  number => '998877',
  country => 'CA',
  ownerCountry => 'CA'
});
$rc = $dri->domain_update('example.in', $changes);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.in</domain:name></domain:update></update><extension><trademark:update xmlns:trademark="urn:afilias:params:xml:ns:trademark-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:trademark-1.0 trademark-1.0.xsd"><trademark:rem><trademark:name>Test Trademark</trademark:name><trademark:number>998877</trademark:number><trademark:country>CA</trademark:country><trademark:ownerCountry>CA</trademark:ownerCountry><trademark:date>2016-07-01</trademark:date></trademark:rem></trademark:update></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain_update remove_trademark build');
is($rc->is_success(),1,'domain_update remove_trademark is_success');

#####################################################################################################
######### Closing Commands ########

$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

exit 0;
