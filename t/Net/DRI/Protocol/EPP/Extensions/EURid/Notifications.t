#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 53;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$co,$toc,$cs,$h,$dh,@c);

########################################################################################################

# 1. Poll request command (case of 2 messages in queue). First message is a "TRANSFER AWAY" event.
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="b023fc6a-aa54-422e-b61c-445ca1d8f48a"><qDate>2014-09-14T11:36:16.882Z</qDate><msg>Domain name transferred away: transfer-away.eu</msg></msgQ><resData><poll:pollData xmlns:poll="http://www.eurid.eu/xml/epp/poll-1.2"><poll:context>TRANSFER</poll:context><poll:objectType>DOMAIN</poll:objectType><poll:object>transfer-away.eu</poll:object><poll:objectUnicode>transfer-away.eu</poll:objectUnicode><poll:action>AWAY</poll:action><poll:code>2306</poll:code><poll:registrar>test_registrar</poll:registrar></poll:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_restrieve build_xml');
is($rc->is_success(), 1, 'message_retrieve is_success');
is($dri->get_info('last_id'),'b023fc6a-aa54-422e-b61c-445ca1d8f48a','message_retrieve get_info(last_id)');
is($dri->get_info('context','message','b023fc6a-aa54-422e-b61c-445ca1d8f48a'),'TRANSFER','message_retrieve get_info context');
is($dri->get_info('notification_code','message','b023fc6a-aa54-422e-b61c-445ca1d8f48a'),'2306','message_retrieve get_info notification_code');
is($dri->get_info('action','message','b023fc6a-aa54-422e-b61c-445ca1d8f48a'),'AWAY','message_retrieve get_info action');
is($dri->get_info('detail','message','b023fc6a-aa54-422e-b61c-445ca1d8f48a'),undef,'message_retrieve get_info detail');
is($dri->get_info('object_type','message','b023fc6a-aa54-422e-b61c-445ca1d8f48a'),'DOMAIN','message_retrieve get_info object_type');
is($dri->get_info('object_unicode','message','b023fc6a-aa54-422e-b61c-445ca1d8f48a'),'transfer-away.eu','message_retrieve get_info object_unicode');
is($dri->get_info('exist','message','b023fc6a-aa54-422e-b61c-445ca1d8f48a'),'1','message_retrieve get_info exist');
# poll-1.2 adds the registar element. I have no example so this is just thrown in as a guess!
is($dri->get_info('registrar','message','b023fc6a-aa54-422e-b61c-445ca1d8f48a'),'test_registrar','message_retrieve get_info registrar');

# 2. Poll acknowledgement command (9 message remaining in queue).
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><msgQ count="9" id="c8ef9775-8ca3-4c04-8ce4-d201baf86ab0"/>'.$TRID.'</response>'.$E2;
$rc=$dri->message_delete('b023fc6a-aa54-422e-b61c-445ca1d8f48a');
is($R1,$E1.'<command><poll msgID="b023fc6a-aa54-422e-b61c-445ca1d8f48a" op="ack"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_restrieve build_xml');
is($rc->is_success(), 1, 'message_delete is_success');
is($dri->message_count(), 9, 'message_delete get_info message_count');

# 3. Poll request command (case of 1 message in queue). First message is a “DOMAIN QUARANTINED” event.
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4"><qDate>2014-09-14T14:59:16.901Z</qDate><msg>Domain name quarantined: domain-poll-quarantine-02.eu</msg></msgQ><resData><poll:pollData xmlns:poll="http://www.eurid.eu/xml/epp/poll-1.2"><poll:context>DOMAIN</poll:context><poll:objectType>DOMAIN</poll:objectType><poll:object>domain-poll-quarantine-02.eu</poll:object><poll:objectUnicode>domain-poll-quarantine-02.eu</poll:objectUnicode><poll:action>QUARANTINED</poll:action><poll:code>1700</poll:code></poll:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_restrieve build_xml');
is($rc->is_success(), 1, 'message_retrieve is_success');
is($dri->get_info('last_id'),'e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4','message_retrieve get_info(last_id)');
is($dri->get_info('context','message','e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4'),'DOMAIN','message_retrieve get_info context');
is($dri->get_info('notification_code','message','e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4'),'1700','message_retrieve get_info notification_code');
is($dri->get_info('action','message','e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4'),'QUARANTINED','message_retrieve get_info action');
is($dri->get_info('detail','message','e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4'),undef,'message_retrieve get_info detail');
is($dri->get_info('object_type','message','e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4'),'DOMAIN','message_retrieve get_info object_type');
is($dri->get_info('object_unicode','message','e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4'),'domain-poll-quarantine-02.eu','message_retrieve get_info object_unicode');
is($dri->get_info('exist','message','e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4'),'1','message_retrieve get_info exist');

# 4. Poll acknowledgement command (no more messages in queue).
$R2=$E1.'<response><result code="1300"><msg>Command completed successfully; no messages</msg></result>'.$TRID.'</response>'.$E2;
$rc=$dri->message_delete('e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4');
is($R1,$E1.'<command><poll msgID="e0ade1eb-8dd2-42cc-a46b-fd02bab54ce4" op="ack"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_restrieve build_xml');
is($rc->is_success(), 1, 'message_delete is_success');
is($dri->message_count(), 0, 'message_delete get_info message_count');

# 5. Poll request command (case of an empty queue).
$R2=$E1.'<response><result code="1300"><msg>Command completed successfully; no messages</msg></result>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_restrieve build_xml');
is($rc->is_success(), 1, 'message_retrieve is_success');
is($dri->get_info('last_id'),undef,'message_retrieve get_info(last_id) undef');
is($dri->message_count(), 0, 'message_retrive get_info message_count');

# 6. Poll request command. Watermark reached
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="11" id="735501cd-653c-4953-971e-9f1488d0c885"><qDate>2014-09-13T11:25:38.671Z</qDate><msg>Watermark level reached: 10000</msg></msgQ><resData><poll:pollData xmlns:poll="http://www.eurid.eu/xml/epp/poll-1.2"><poll:context>WATERMARK</poll:context><poll:objectType>WATERMARK</poll:objectType><poll:object>10000</poll:object><poll:objectUnicode>10000</poll:objectUnicode><poll:action>REACHED</poll:action><poll:code>2600</poll:code></poll:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_restrieve build_xml');
is($rc->is_success(), 1, 'message_retrieve is_success');
is($dri->get_info('last_id'),'735501cd-653c-4953-971e-9f1488d0c885','message_retrieve get_info(last_id)');
is($dri->get_info('context','message','735501cd-653c-4953-971e-9f1488d0c885'),'WATERMARK','message_retrieve get_info context');
is($dri->get_info('notification_code','message','735501cd-653c-4953-971e-9f1488d0c885'),undef,'message_retrieve get_info notification_code');
is($dri->get_info('action','message','735501cd-653c-4953-971e-9f1488d0c885'),'REACHED','message_retrieve get_info action');
is($dri->get_info('detail','message','735501cd-653c-4953-971e-9f1488d0c885'),undef,'message_retrieve get_info detail');
is($dri->get_info('object_type','message','735501cd-653c-4953-971e-9f1488d0c885'),'session','message_retrieve get_info object_type');
is($dri->get_info('object_unicode','message','735501cd-653c-4953-971e-9f1488d0c885'),undef,'message_retrieve get_info object_unicode');
is($dri->get_info('exist','message','735501cd-653c-4953-971e-9f1488d0c885'),undef,'message_retrieve get_info exist');
# it used to be called level
is($dri->get_info('level','message','735501cd-653c-4953-971e-9f1488d0c885'),10000.00,'message_retrieve get_info level');
# old test used this method
is($rc->get_data('message','735501cd-653c-4953-971e-9f1488d0c885','level'),10000.00,'notification !domain get_data(level)');

# 7 .Poll request command. Dynamic Update completed
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="9938" id="e535d011-baa1-42d8-b0e6-5aec5edaa49e"><qDate>2014-09-14T08:24:55.726Z</qDate><msg>DynUpdate completed for domain name: secure-domain.eu</msg></msgQ><resData><poll:pollData xmlns:poll="http://www.eurid.eu/xml/epp/poll-1.2"><poll:context>DYNUPDATE</poll:context><poll:objectType>DOMAIN</poll:objectType><poll:object>secure-domain.eu</poll:object><poll:objectUnicode>secure-domain.eu</poll:objectUnicode><poll:action>DONE_TEST</poll:action><poll:code>1000</poll:code></poll:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_restrieve build_xml');
is($rc->is_success(), 1, 'message_retrieve is_success');
is($dri->get_info('last_id'),'e535d011-baa1-42d8-b0e6-5aec5edaa49e','message_retrieve get_info(last_id)');
is($dri->get_info('context','message','e535d011-baa1-42d8-b0e6-5aec5edaa49e'),'DYNUPDATE','message_retrieve get_info context');
is($dri->get_info('notification_code','message','e535d011-baa1-42d8-b0e6-5aec5edaa49e'),'1000','message_retrieve get_info notification_code');
is($dri->get_info('action','message','e535d011-baa1-42d8-b0e6-5aec5edaa49e'),'DONE_TEST','message_retrieve get_info action');
is($dri->get_info('detail','message','e535d011-baa1-42d8-b0e6-5aec5edaa49e'),undef,'message_retrieve get_info detail');
is($dri->get_info('object_type','message','e535d011-baa1-42d8-b0e6-5aec5edaa49e'),'DOMAIN','message_retrieve get_info object_type');
is($dri->get_info('object_unicode','message','e535d011-baa1-42d8-b0e6-5aec5edaa49e'),'secure-domain.eu','message_retrieve get_info object_unicode');
is($dri->get_info('exist','message','e535d011-baa1-42d8-b0e6-5aec5edaa49e'),'1','message_retrieve get_info exist');

exit 0;
