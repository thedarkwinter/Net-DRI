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
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('VeriSign::NameStore');
# To test the WhoWas extension, we must load it (not in use by any Registry by default).
$dri->add_current_profile('p1','epp',
    { f_send=>\&mysend, f_recv=>\&myrecv },
    { extensions => ['VeriSign::WhoWas'] }
);

$R2=$E1.'<response>'.r().'<resData><whowas:infData xmlns:whowas="http://www.verisign.com/epp/whowas-1.0" xsi:schemaLocation="http://www.verisign.com/epp/whowas-1.0 whowas-1.0.xsd"><whowas:type>domain</whowas:type><whowas:name>test.tv</whowas:name><whowas:history><whowas:rec><whowas:date>2002-04-02T12:00:00</whowas:date><whowas:name>test.tv</whowas:name><whowas:roid>EXAMPLE1-REP</whowas:roid><whowas:op>SERVER TRANSFER</whowas:op><whowas:clID>ClientY</whowas:clID><whowas:clName>Client Y Corporation</whowas:clName></whowas:rec><whowas:rec><whowas:date>2002-02-02T12:00:00</whowas:date><whowas:name>test.tv</whowas:name><whowas:roid>EXAMPLE1-REP</whowas:roid><whowas:op>TRANSFER</whowas:op><whowas:clID>ClientZ</whowas:clID><whowas:clName>Client Z Corporation</whowas:clName></whowas:rec></whowas:history></whowas:infData></resData>'.$TRID.'</response>'.$E2;

my $rc=$dri->domain_whowas('test.tv');
is_string($R1,$E1.'<command><info><whowas:info xmlns:whowas="http://www.verisign.com/epp/whowas-1.0" xsi:schemaLocation="http://www.verisign.com/epp/whowas-1.0 whowas-1.0.xsd"><whowas:type>domain</whowas:type><whowas:name>test.tv</whowas:name></whowas:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_whowas build');

is($rc->get_data('type'),'domain','domain_whowas get_data type');
is_deeply($rc->get_data('history'),[{date=>'2002-04-02T12:00:00',name=>'test.tv',roid=>'EXAMPLE1-REP',op=>'SERVER TRANSFER',clID=>'ClientY',clName=>'Client Y Corporation'},{date=>'2002-02-02T12:00:00',name=>'test.tv',roid=>'EXAMPLE1-REP',op=>'TRANSFER',clID=>'ClientZ',clName=>'Client Z Corporation'}],'domain_whowas get_data history');

exit 0;
