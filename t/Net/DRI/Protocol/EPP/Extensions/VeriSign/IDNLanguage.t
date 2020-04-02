#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 2;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('VeriSign::COM_NET');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['-VeriSign::NameStore']});
my ($rc);

#########################################################################################################
## Example taken from EPP-IDN-Lang-Mapping.pdf
$rc=$dri->domain_create('xn--example2.com',{pure_create => 1, auth => { pw => '2fooBAR' }, language => 'en'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>xn--example2.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><idnLang:tag xmlns:idnLang="http://www.verisign.com/epp/idnLang-1.0">en</idnLang:tag></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');

$rc=$dri->domain_create('xn--example3.com',{pure_create => 1, auth => { pw => '2fooBAR' }, 'idn' => $dri->local_object('idn')->autodetect('','de') }); # will convert to iso_639-2
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>xn--example3.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><idnLang:tag xmlns:idnLang="http://www.verisign.com/epp/idnLang-1.0">ger</idnLang:tag></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');

exit 0;
