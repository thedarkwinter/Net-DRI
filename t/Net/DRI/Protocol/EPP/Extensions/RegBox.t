#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;


use Test::More tests => 8;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }


my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };

$dri->add_current_registry('NicAT::RegBox');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$c1,$c2);


####################################################################################################
## Service Message Extension
## https://tools.ietf.org/html/draft-mayrhofer-eppext-servicemessage-00

## 1.1 version of it is active so we need to test loading from greeting
## FIXME: Server does not currently return extension in greeting, so skipping this for now, but it will probably need to select version
SKIP: {
  skip 'Skipping 3 greeting tests',3;
$R2=$E1.'<greeting><greeting><svID>epp1-brussels.rb.ipcom.at</svID><svDate>2014-11-11T14:39:53.576230Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:signedMark-1.0</extURI><extURI>urn:ietf:params:xml:ns:mark-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'http://tld-box.at/xmlns/resdata-1.1','Service Message resdata-1.1 loaded correctly');
}

# random message
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="123"><qDate>2014-02-01T16:00:00.000Z</qDate><msg>Some message</msg></msgQ><resData><message xmlns="http://tld-box.at/xmlns/resdata-1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" type="MessageType"><desc>Descriptive message</desc><data><entry name="sample">stuff</entry></data></message></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'123','message_retrieve get_info(last_id)');
is($dri->get_info('content','message',123),'Some message','message_retrieve get_info(message)');
is($dri->get_info('message_type','message',123),'MessageType','message_retrieve get_info(message_type)');
is($dri->get_info('description','message',123),'Descriptive message','message_retrieve get_info(description)');
is_deeply($dri->get_info('entries','message',123),[{key=>'sample','value'=>'stuff'}],'message_retrieve get_info(entries)');

####################################################################################################



exit 0;
