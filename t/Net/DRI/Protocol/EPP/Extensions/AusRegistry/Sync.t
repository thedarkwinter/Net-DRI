#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 1;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}});
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['AusRegistry::Sync','-VeriSign::Sync', '-VeriSign::NameStore','-VeriSign::IDNLanguage']});

####################################################################################################

my $toc=$dri->local_object('changes');
$toc->set('sync', $dri->local_object('datetime', year => 2010, month => 4, day => 3, hour => 22));
my $rc=$dri->domain_update('example.com',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com</domain:name></domain:update></update><extension><sync:update xmlns:sync="urn:X-ar:params:xml:ns:sync-1.0" xsi:schemaLocation="urn:X-ar:params:xml:ns:sync-1.0 sync-1.0.xsd"><sync:exDate>2010-04-03T22:00:00.000000Z</sync:exDate></sync:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');

exit 0;
