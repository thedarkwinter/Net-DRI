#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 5;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['VeriSign::PremiumDomain']});
$dri->protocol->default_parameters()->{premium_domain}=1;


$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example.tv</domain:name></domain:cd></domain:chkData></resData><extension><premiumdomain:chkData xmlns:premiumdomain="http://www.verisign.com/epp/premiumdomain-1.0" xsi:schemaLocation="http://www.verisign.com/epp/premiumdomain-1.0 premiumdomain-1.0.xsd"><premiumdomain:cd><premiumdomain:name premium="1">example.tv</premiumdomain:name><premiumdomain:price unit="USD">125.00</premiumdomain:price><premiumdomain:renewalPrice unit="USD">75.00</premiumdomain:renewalPrice></premiumdomain:cd></premiumdomain:chkData></extension>'.$TRID.'</response>'.$E2;
my $rc=$dri->domain_check('example.tv');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.tv</domain:name></domain:check></check><extension><premiumdomain:check xmlns:premiumdomain="http://www.verisign.com/epp/premiumdomain-1.0" xsi:schemaLocation="http://www.verisign.com/epp/premiumdomain-1.0 premiumdomain-1.0.xsd"><premiumdomain:flag>1</premiumdomain:flag></premiumdomain:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build premium_domain=1');

is($rc->get_data('is_premium'),1,'domain_check premium=1 get_data(is_premium)');
is_deeply($rc->get_data('price'),{unit=>'USD',amount=>125.00},'domain_check premium=1 get_data(price)');
is_deeply($rc->get_data('renewal_price'),{unit=>'USD',amount=>75.00},'domain_check premium=1 get_data(renewal_price)');

$R2='';
$rc=$dri->domain_update('premium.tv',$dri->local_object('changes')->set('premium_short_name','testregistrar'));
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.tv</domain:name></domain:update></update><extension><premiumdomain:reassign xmlns:premiumdomain="http://www.verisign.com/epp/premiumdomain-1.0" xsi:schemaLocation="http://www.verisign.com/epp/premiumdomain-1.0 premiumdomain-1.0.xsd"><premiumdomain:shortName>testregistrar</premiumdomain:shortName></premiumdomain:reassign></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build premium_domain=1');

exit 0;
