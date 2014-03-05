#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 1;

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
$dri->add_registry('INFO');
$dri->target('INFO')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});


$R2=$E1."<response><result code='2005'><msg lang='en-US'>Parameter value syntax error</msg><value xmlns:oxrs='urn:afilias:params:xml:ns:oxrs-1.0'><oxrs:xcp>2005:Parameter value syntax error (ContactAuthInfoType:AUTHT range (6-16))</oxrs:xcp></value></result>".$TRID."</response>".$E2;

my $rc=$dri->domain_check('toto.info');
is_deeply([$rc->get_extended_results()],[{from=>'oxrs',type=>'text',message=>'2005:Parameter value syntax error (ContactAuthInfoType:AUTHT range (6-16))'}],'oxrs error message parsing');

exit 0;

