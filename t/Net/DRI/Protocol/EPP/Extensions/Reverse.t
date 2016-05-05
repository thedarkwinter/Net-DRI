#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 6;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['Reverse','-VeriSign::NameStore']});



my $cmd = $dri->remote_object('command', '54321-XYZ');
my $rc = $cmd->reverse({ reason => 'Reversing an accidental double renewal.', trid => 'ABC-10001'});
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><extension><reverse:reverse xmlns:reverse="urn:ietf:params:xml:ns:reverse-0.1" xsi:schemaLocation="urn:ietf:params:xml:ns:reverse-0.1 reverse-0.1.xsd"><reverse:reason>Reversing an accidental double renewal.</reverse:reason><reverse:trID><reverse:clTRID>ABC-10001</reverse:clTRID><reverse:svTRID>54321-XYZ</reverse:svTRID></reverse:trID><reverse:clTRID>ABC-12345</reverse:clTRID></reverse:reverse></extension></epp>', 'coommand reverse build');


$R2='<?xml version="1.0" encoding="utf-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="5" id="12345"><qDate>2016-04-04T22:01:00.0Z</qDate><msg>Pending action completed successfully.</msg></msgQ><resData><reverse:panData xmlns:reverse="urn:ietf:params:xml:ns:reverse-0.1"><reverse:paTRID paResult="1"><reverse:clTRID>ABC-12345</reverse:clTRID><reverse:svTRID>54321-XYZ</reverse:svTRID></reverse:paTRID><reverse:paDate>2016-04-04T22:00:00.0Z</reverse:paDate></reverse:panData></resData><trID><clTRID>BCD-23456</clTRID><svTRID>65432-WXY</svTRID></trID></response></epp>';
$rc = $dri->message_retrieve();
is($rc->get_data('action'), 'review_reverse', 'get_data action');
is($rc->get_data('result'), 1, 'get_data result');
is($rc->get_data('trid'), 'ABC-12345', 'get_data trid');
is($rc->get_data('svtrid'), '54321-XYZ', 'get_data svtrid');
is(''.$rc->get_data('date'), '2016-04-04T22:00:00', 'get_data date');


exit 0;
