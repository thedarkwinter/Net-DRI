#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 77;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context = 50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1 = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2 = '</epp>';
our $TRID = '<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our $R1;
sub mysend
{
	my ($transport, $count, $msg) = @_;
	$R1 = $msg->as_string();
	return 1;
}

our $R2;
sub myrecv
{
	return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 :
		$E1 . '<response>' . r() . $TRID . '</response>' . $E2);
}

my $dri = Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory} = sub { return 'ABC-12345'; };
$dri->add_registry('SWITCH');
$dri->target('SWITCH')->add_current_profile('p1', 'epp', {f_send => \&mysend, f_recv => \&myrecv});

my $rc;
my $s;
my $d;
my ($dh, @c);
my ($lastid,$data,$secdns);

$R2 = $E1 . '<greeting><svID>SWITCH_EPP_Server</svID><svDate>2019-01-03T13:18:53+01:00</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:changePoll-1.0</extURI></svcExtension></svcMenu><dcp><access><personalAndOther/></access><statement><purpose><admin/><other/><prov/></purpose><recipient><ours/><public/></recipient><retention><legal/></retention></statement></dcp></greeting>' . $E2;
$rc = $dri->process('session', 'noop', []);
is($R1, $E1 . '<hello/>' . $E2, 'session noop build (hello command)');
is($rc->is_success(), 1, 'session noop is_success');
is($rc->get_data('session','server','server_id'),'SWITCH_EPP_Server','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date')->strftime('%FT%T%z'),'2019-01-03T13:18:53+0100','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:contact-1.0','urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:host-1.0'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:changePoll-1.0'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:changePoll-1.0'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><personalAndOther/></access><statement><purpose><admin/><other/><prov/></purpose><recipient><ours/><public/></recipient><retention><legal/></retention></statement>','session noop get_data(session,server,dcp_string)');


####################################################################################################
# Based on "SWITCH_CDS_Manual_en.pdf"
# 5.4 Annex: Examples of EPP poll messages

# Example of Bootstrap poll response with the following extensions configured at Login: secDNS-1.1 => yes, changePoll-1.0 => yes
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="46533741"><qDate>2018-11-20T15:01:01+01:00</qDate></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>polltest-cds-bootstrap.ch</domain:name><domain:roid>D123456-SWITCH</domain:roid><domain:status s="inactive" lang="en" /><domain:registrant>D1234567-SWITCH</domain:registrant><domain:clID>D1234568-SWITCH</domain:clID><domain:upDate>2018-11-20T15:01:01+01:00</domain:upDate></domain:infData></resData><extension><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0" state="after"><changePoll:operation>update</changePoll:operation><changePoll:date>2018-11-20T15:01:01+01:00</changePoll:date><changePoll:svTRID>20181120.123456</changePoll:svTRID><changePoll:who>SWITCH CDS: see https://www.nic.ch/faqs/dnssec/cds/</changePoll:who><changePoll:reason>DNSSEC initialized</changePoll:reason></changePoll:changeData><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>4</secDNS:digestType><secDNS:digest>AAAA54840FBBB6F4270F8B6D8C06C6A2B3152E55D2E9F81132130E507829B6D24FA56A4E074B4692DDC46F512B048AAC</secDNS:digest></secDNS:dsData><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>AAAA9AB3E7D203FF7923B8773599E248717F1DC79A9BEF09D8981B13AB7A049E</secDNS:digest></secDNS:dsData></secDNS:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('id','message','46533741'),'46533741','message get_info id');
is(''.$dri->get_info('qdate','message','46533741'),'2018-11-20T15:01:01','message get_info qdate');
is($dri->get_info('object_type','message','46533741'),'domain','message get_info object_type');
is($dri->get_info('object_id','message','46533741'),'polltest-cds-bootstrap.ch','message get_info id');
is($dri->get_info('action','message','46533741'),'info','message get_info action');
is($dri->get_info('name','message','46533741'),'polltest-cds-bootstrap.ch','message get_info name');
is($dri->get_info('roid','message','46533741'),'D123456-SWITCH','message get_info roid');
is($dri->get_info('clID','message','46533741'),'D1234568-SWITCH','message get_info clID');
is($dri->get_info('upDate','message','46533741'),'2018-11-20T15:01:01','message get_info upDate');
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'change');
is($data->{state},'after','example 1 state');
is($data->{operation},'update','example 1 operation');
is($data->{date}->iso8601(),'2018-11-20T15:01:01','example 1 date');
is($data->{svTRID},'20181120.123456','example 1 svtrid');
is($data->{who},'SWITCH CDS: see https://www.nic.ch/faqs/dnssec/cds/','example 1 who');
is($data->{reason},'DNSSEC initialized','example 1 reason');

# Example of Bootstrap poll response with the following extensions configured at Login: secDNS-1.1 => no, changePoll-1.0 => no
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg><extValue><value><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>4</secDNS:digestType><secDNS:digest>AAAA54840FBBB6F4270F8B6D8C06C6A2B3152E55D2E9F81132130E507829B6D24FA56A4E074B4692DDC46F512B048AAC</secDNS:digest></secDNS:dsData><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>AAAA9AB3E7D203FF7923B8773599E248717F1DC79A9BEF09D8981B13AB7A049E</secDNS:digest></secDNS:dsData></secDNS:infData></value><reason lang="en">urn:ietf:params:xml:ns:secDNS-1.1 not in login services</reason></extValue><extValue><value><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0"><changePoll:operation>update</changePoll:operation><changePoll:date>2018-11-20T15:01:01+01:00</changePoll:date><changePoll:svTRID>20181120.123456</changePoll:svTRID><changePoll:who>SWITCH CDS: see https://www.nic.ch/faqs/dnssec/cds/</changePoll:who><changePoll:reason>DNSSEC initialized</changePoll:reason></changePoll:changeData></value><reason lang="en">urn:ietf:params:xml:ns:changePoll-1.0 not in login services</reason></extValue></result><msgQ count="1" id="46533741"><qDate>2018-11-20T15:01:01+01:00</qDate></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>polltest-cds-bootstrap.ch</domain:name><domain:roid>D123456-SWITCH</domain:roid><domain:status s="inactive"/><domain:registrant>D1234567-SWITCH</domain:registrant><domain:clID>D1234568-SWITCH</domain:clID><domain:upDate>2018-11-20T15:01:01+01:00</domain:upDate></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('id','message','46533741'),'46533741','message 2 get_info id');
is_deeply([$rc->get_extended_results()],
[
	{
		from=>'eppcom:extValue',
		type=>'rawxml',
		message=>'<secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>4</secDNS:digestType><secDNS:digest>AAAA54840FBBB6F4270F8B6D8C06C6A2B3152E55D2E9F81132130E507829B6D24FA56A4E074B4692DDC46F512B048AAC</secDNS:digest></secDNS:dsData><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>AAAA9AB3E7D203FF7923B8773599E248717F1DC79A9BEF09D8981B13AB7A049E</secDNS:digest></secDNS:dsData></secDNS:infData>',
		reason=>'urn:ietf:params:xml:ns:secDNS-1.1 not in login services',
		lang=>'en'
	},
	{
		from=>'eppcom:extValue',
		type=>'rawxml',
		message=>'<changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0"><changePoll:operation>update</changePoll:operation><changePoll:date>2018-11-20T15:01:01+01:00</changePoll:date><changePoll:svTRID>20181120.123456</changePoll:svTRID><changePoll:who>SWITCH CDS: see https://www.nic.ch/faqs/dnssec/cds/</changePoll:who><changePoll:reason>DNSSEC initialized</changePoll:reason></changePoll:changeData>',
		reason=>'urn:ietf:params:xml:ns:changePoll-1.0 not in login services',
		lang=>'en'
	}
],'message 2 extra info');
is(''.$dri->get_info('qdate','message','46533741'),'2018-11-20T15:01:01','message 2 get_info qdate');
is($dri->get_info('object_type','message','46533741'),'domain','message 2 get_info object_type');
is($dri->get_info('object_id','message','46533741'),'polltest-cds-bootstrap.ch','message 2 get_info id');
is($dri->get_info('action','message','46533741'),'info','message 2 get_info action');
is($dri->get_info('name','message','46533741'),'polltest-cds-bootstrap.ch','message 2 get_info name');
is($dri->get_info('roid','message','46533741'),'D123456-SWITCH','message 2 get_info roid');
is($dri->get_info('clID','message','46533741'),'D1234568-SWITCH','message 2 get_info clID');
is($dri->get_info('upDate','message','46533741'),'2018-11-20T15:01:01','message 2 get_info upDate');

# Example of Bootstrap poll response with the following extensions configured at Login: secDNS-1.1 => no, changePoll-1.0 => yes
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg><extValue><value><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>4</secDNS:digestType><secDNS:digest>AAAA54840FBBB6F4270F8B6D8C06C6A2B3152E55D2E9F81132130E507829B6D24FA56A4E074B4692DDC46F512B048AAC</secDNS:digest></secDNS:dsData><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>AAAA9AB3E7D203FF7923B8773599E248717F1DC79A9BEF09D8981B13AB7A049E</secDNS:digest></secDNS:dsData></secDNS:infData></value><reason lang="en">urn:ietf:params:xml:ns:secDNS-1.1 not in login services</reason></extValue></result><msgQ count="1" id="46533741"><qDate>2018-11-20T15:01:01+01:00</qDate></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>polltest-cds-bootstrap.ch</domain:name><domain:roid>D123456-SWITCH</domain:roid><domain:status s="inactive" lang="en"/><domain:registrant>D1234567-SWITCH</domain:registrant><domain:clID>D1234568-SWITCH</domain:clID><domain:upDate>2018-11-20T15:01:01+01:00</domain:upDate></domain:infData></resData><extension><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0" state="after"><changePoll:operation>update</changePoll:operation><changePoll:date>2018-11-20T15:01:01+01:00</changePoll:date><changePoll:svTRID>20181120.123456</changePoll:svTRID><changePoll:who>SWITCH CDS: see https://www.nic.ch/faqs/dnssec/cds/</changePoll:who><changePoll:reason>DNSSEC initialized</changePoll:reason></changePoll:changeData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('id','message','46533741'),'46533741','message 3 get_info id');
is_deeply([$rc->get_extended_results()],
[
	{
		from=>'eppcom:extValue',
		type=>'rawxml',
		message=>'<secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>4</secDNS:digestType><secDNS:digest>AAAA54840FBBB6F4270F8B6D8C06C6A2B3152E55D2E9F81132130E507829B6D24FA56A4E074B4692DDC46F512B048AAC</secDNS:digest></secDNS:dsData><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>AAAA9AB3E7D203FF7923B8773599E248717F1DC79A9BEF09D8981B13AB7A049E</secDNS:digest></secDNS:dsData></secDNS:infData>',
		reason=>'urn:ietf:params:xml:ns:secDNS-1.1 not in login services',
		lang=>'en'
	}
],'message 3 extra info');
is(''.$dri->get_info('qdate','message','46533741'),'2018-11-20T15:01:01','message 3 get_info qdate');
is($dri->get_info('object_type','message','46533741'),'domain','message 3 get_info object_type');
is($dri->get_info('object_id','message','46533741'),'polltest-cds-bootstrap.ch','message 3 get_info id');
is($dri->get_info('action','message','46533741'),'info','message 3 get_info action');
is($dri->get_info('name','message','46533741'),'polltest-cds-bootstrap.ch','message 3 get_info name');
is($dri->get_info('roid','message','46533741'),'D123456-SWITCH','message 3 get_info roid');
is($dri->get_info('clID','message','46533741'),'D1234568-SWITCH','message 3 get_info clID');
is($dri->get_info('upDate','message','46533741'),'2018-11-20T15:01:01','message 3 get_info upDate');
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'change');
is($data->{state},'after','example 3 state');
is($data->{operation},'update','example 3 operation');
is($data->{date}->iso8601(),'2018-11-20T15:01:01','example 3 date');
is($data->{svTRID},'20181120.123456','example 3 svtrid');
is($data->{who},'SWITCH CDS: see https://www.nic.ch/faqs/dnssec/cds/','example 3 who');
is($data->{reason},'DNSSEC initialized','example 3 reason');

# Example of Bootstrap poll response with the following extensions configured at Login: secDNS-1.1 => yes, changePoll-1.0 => no
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg><extValue><value><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0"><changePoll:operation>update</changePoll:operation><changePoll:date>2018-11-20T15:55:16+01:00</changePoll:date><changePoll:svTRID>20181120.123456</changePoll:svTRID><changePoll:who>SWITCH CDS: see https://www.nic.ch/faqs/dnssec/cds/</changePoll:who><changePoll:reason>Rollover of DNSSEC Digest</changePoll:reason></changePoll:changeData></value><reason lang="en">urn:ietf:params:xml:ns:changePoll-1.0 not in login services</reason></extValue></result><msgQ count="1" id="46533743"><qDate>2018-11-20T15:55:16+01:00</qDate></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>polltest-cds-rollover.ch</domain:name><domain:roid>D123456-SWITCH</domain:roid><domain:status s="inactive" lang="en"/><domain:registrant>D1234567-SWITCH</domain:registrant><domain:clID>D1234568-SWITCH</domain:clID><domain:upDate>2018-11-20T15:55:16+01:00</domain:upDate></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>4</secDNS:digestType><secDNS:digest>AAAA54840FBBB6F4270F8B6D8C06C6A2B3152E55D2E9F81132130E507829B6D24FA56A4E074B4692DDC46F512B048AAC</secDNS:digest></secDNS:dsData><secDNS:dsData><secDNS:keyTag>1337</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>AAAA9AB3E7D203FF7923B8773599E248717F1DC79A9BEF09D8981B13AB7A049E</secDNS:digest></secDNS:dsData></secDNS:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('id','message','46533743'),'46533743','message 4 get_info id');
is_deeply([$rc->get_extended_results()],
[
	{
		from=>'eppcom:extValue',
		type=>'rawxml',
		message=>'<changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0"><changePoll:operation>update</changePoll:operation><changePoll:date>2018-11-20T15:55:16+01:00</changePoll:date><changePoll:svTRID>20181120.123456</changePoll:svTRID><changePoll:who>SWITCH CDS: see https://www.nic.ch/faqs/dnssec/cds/</changePoll:who><changePoll:reason>Rollover of DNSSEC Digest</changePoll:reason></changePoll:changeData>',
		reason=>'urn:ietf:params:xml:ns:changePoll-1.0 not in login services',
		lang=>'en'
	}
],'message 4 extra info');
is(''.$dri->get_info('qdate','message','46533743'),'2018-11-20T15:55:16','message 4 get_info qdate');
is($dri->get_info('object_type','message','46533743'),'domain','message 3 get_info object_type');
is($dri->get_info('object_id','message','46533743'),'polltest-cds-rollover.ch','message 4 get_info id');
is($dri->get_info('action','message','46533743'),'info','message 4 get_info action');
is($dri->get_info('name','message','46533743'),'polltest-cds-rollover.ch','message 4 get_info name');
is($dri->get_info('roid','message','46533743'),'D123456-SWITCH','message 4 get_info roid');
is($dri->get_info('clID','message','46533743'),'D1234568-SWITCH','message 4 get_info clID');
is($dri->get_info('upDate','message','46533743'),'2018-11-20T15:55:16','message 4 get_info upDate');
is_deeply($rc->get_data('message','46533743','secdns'),
[
    {
        'alg' => '13',
        'digest' => 'AAAA54840FBBB6F4270F8B6D8C06C6A2B3152E55D2E9F81132130E507829B6D24FA56A4E074B4692DDC46F512B048AAC',
        'digestType' => '4',
        'keyTag' => '1337'
    },
    {
        'alg' => '13',
        'digest' => 'AAAA9AB3E7D203FF7923B8773599E248717F1DC79A9BEF09D8981B13AB7A049E',
        'keyTag' => '1337',
        'digestType' => '2'
    }
],'message 4 secdns');

# Example of Delete poll response with the following extensions configured at Login: secDNS-1.1 => yes, changePoll-1.0 => no
$R2=$E1.'<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="46533742"><qDate>2018-11-20T15:12:41+01:00</qDate></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>polltest-cds-delete.ch</domain:name><domain:roid>D123456-SWITCH</domain:roid><domain:status s="inactive" lang="en"/><domain:registrant>D1234567-SWITCH</domain:registrant><domain:clID>D1234568-SWITCH</domain:clID><domain:upDate>2018-11-20T15:12:41+01:00</domain:upDate></domain:infData></resData><extension><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0" state="after"><changePoll:operation>update</changePoll:operation><changePoll:date>2018-11-20T15:12:41+01:00</changePoll:date><changePoll:svTRID>20181120.123456</changePoll:svTRID><changePoll:who>SWITCH CDS: see https://www.nic.ch/faqs/dnssec/cds/</changePoll:who><changePoll:reason>DNSSEC deactivated</changePoll:reason></changePoll:changeData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('id','message','46533742'),'46533742','message 5 get_info id');
is(''.$dri->get_info('qdate','message','46533742'),'2018-11-20T15:12:41','message 5 get_info qdate');
is($dri->get_info('object_type','message','46533742'),'domain','message 5 get_info object_type');
is($dri->get_info('object_id','message','46533742'),'polltest-cds-delete.ch','message 5 get_info id');
is($dri->get_info('action','message','46533742'),'info','message 5 get_info action');
is($dri->get_info('name','message','46533742'),'polltest-cds-delete.ch','message 5 get_info name');
is($dri->get_info('roid','message','46533742'),'D123456-SWITCH','message 5 get_info roid');
is($dri->get_info('clID','message','46533742'),'D1234568-SWITCH','message 5 get_info clID');
is($dri->get_info('upDate','message','46533742'),'2018-11-20T15:12:41','message 5 get_info upDate');
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'change');
is($data->{state},'after','example 5 state');
is($data->{operation},'update','example 5 operation');
is($data->{date}->iso8601(),'2018-11-20T15:12:41','example 5 date');
is($data->{svTRID},'20181120.123456','example 5 svtrid');
is($data->{who},'SWITCH CDS: see https://www.nic.ch/faqs/dnssec/cds/','example 5 who');
is($data->{reason},'DNSSEC deactivated','example 5 reason');


# END: Based on "SWITCH_CDS_Manual_en.pdf"
####################################################################################################


exit 0;

sub r
{
	my ($c, $m) = @_;
	return '<result code="' . ($c || 1000) . '"><msg>' .
		($m || 'Command completed successfully') .
		'</msg></result>';
}


