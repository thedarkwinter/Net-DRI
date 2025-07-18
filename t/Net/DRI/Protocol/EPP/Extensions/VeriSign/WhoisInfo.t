#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 3;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('VeriSign::COM_NET');
# To test the WhoisInfo extension, we must load it (not in use by any Registry by default).
$dri->add_current_profile('p1','epp',
    { f_send=>\&mysend, f_recv=>\&myrecv },
    { extensions => ['-VeriSign::NameStore', 'VeriSign::WhoisInfo'] }
);

#########################################################################################################
## Example taken from EPP-Whois-Info-Ext.pdf

$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.com</domain:name><domain:roid>EXAMPLE1-VRSN</domain:roid><domain:status s="ok"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2005-11-11T18:09:52.0354Z</domain:crDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><whoisInf:whoisInfData xmlns:whoisInf="http://www.verisign.com/epp/whoisInf-1.0" xsi:schemaLocation="http://www.verisign.com/epp/whoisInf-1.0 whoisInf-1.0.xsd"><whoisInf:registrar>Example Registrar Inc.</whoisInf:registrar><whoisInf:whoisServer>whois.example.com</whoisInf:whoisServer><whoisInf:url>http://www.example.com</whoisInf:url><whoisInf:irisServer>iris.example.com</whoisInf:irisServer></whoisInf:whoisInfData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></trID></response></epp>';
my $rc=$dri->domain_info('example2.com',{whois_info => 1});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example2.com</domain:name></domain:info></info><extension><whoisInf:whoisInf xmlns:whoisInf="http://www.verisign.com/epp/whoisInf-1.0" xsi:schemaLocation="http://www.verisign.com/epp/whoisInf-1.0 whoisInf-1.0.xsd"><whoisInf:flag>1</whoisInf:flag></whoisInf:whoisInf></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build');
is($rc->is_success(),1,'domain_info is_success');
my $w=$dri->get_info('whois_info');
is_deeply($w,{ registrar => 'Example Registrar Inc.', whois_server => 'whois.example.com', url => 'http://www.example.com', iris_server => 'iris.example.com' },'domain_info get_info(whois_info)');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
