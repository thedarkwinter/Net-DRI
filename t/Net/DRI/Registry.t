#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 7;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

####################################################################################################

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging=>'null'});
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send => \&mysend, f_recv => \&myrecv});

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">toto.com</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;

my $rc1=$dri->domain_check('toto.com');
is($dri->get_info('result_from_cache'),0,'dri->get_info(result_from_cache) 1st call');
is($dri->get_info('result_from_cache','session','exchange'),0,'dri->get_info(result_from_cache,session,exchange) 1st call');
is($rc1->get_data('session','exchange','result_from_cache'),0,'rc->get_data(result_from_cache) 1st call');

my $rc2=$dri->domain_check('toto.com');
is($dri->get_info('result_from_cache'),1,'dri->get_info(result_from_cache) 2nd call');
is($dri->get_info('result_from_cache','session','exchange'),1,'dri->get_info(result_from_cache,session,exchange) 2nd call');
is($rc2->get_data('session','exchange','result_from_cache'),1,'rc->get_data(result_from_cache) 2nd call');

my $rc3=$dri->domain_check('toto.com');
is_deeply($rc2,$rc3,'with cache, 3rd call results = 2nd call results');

####################################################################################################

exit 0;
