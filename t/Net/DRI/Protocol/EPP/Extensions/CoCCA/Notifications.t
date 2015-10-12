#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;
use Test::More tests => 29;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('PH');
$dri->target('PH')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->{registries}->{PH}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::PH',{}],'PH - epp transport_protocol_default');
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');
$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

####################################################################################################
####### Polling Commands ########

### poll message id: 207
$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="331" id="207"><qDate>2015-07-09T07:20:15.186Z</qDate><msg lang="en"><![CDATA[<offlineUpdate><domain><name>domain1.com.ph</name><change>UNKNOWN</change><details></details></domain></offlineUpdate>]]></msg></msgQ>' . $TRID . '</response>' . $E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success [207]');
my $last_id = $dri->get_info('last_id');
is($last_id,'207','message_retrieve get_info(last_id) - 207');
is($dri->get_info('action'),'offline_update','message_poll get_info(action)');
is($dri->get_info('name'),'domain1.com.ph','message_poll get_info(name)');
is($dri->get_info('change'),'UNKNOWN','message_poll get_info(change)');
is($dri->get_info('details'),'','message_poll get_info(details)');

### poll message id: 520
$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="72" id="520"><qDate>2015-07-13T13:48:36.124Z</qDate><msg lang="en"><![CDATA[<offlineUpdate><domain><name>domain2.ph</name><change>NAMESERVERS_CHANGED</change><details>Domain Nameservers Updated</details></domain></offlineUpdate>]]></msg></msgQ>' . $TRID . '</response>' . $E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success [520]');
$last_id = $dri->get_info('last_id');
is($last_id,'520','message_retrieve get_info(last_id) - 520');
is($dri->get_info('action'),'offline_update','message_poll get_info(action)');
is($dri->get_info('name'),'domain2.ph','message_poll get_info(name)');
is($dri->get_info('change'),'NAMESERVERS_CHANGED','message_poll get_info(change)');
is($dri->get_info('details'),'Domain Nameservers Updated','message_poll get_info(details)');

### poll message id: 594
$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="594"><qDate>2015-08-24T16:16:13.559Z</qDate><msg lang="en"><![CDATA[<offlineUpdate><domain><name>domain3.com.ph</name><change>RENEWAL</change><details>Domain renewed for 1y</details></domain></offlineUpdate>]]></msg></msgQ>' . $TRID . '</response>' . $E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success [594]');
$last_id = $dri->get_info('last_id');
is($last_id,'594','message_retrieve get_info(last_id) - 594');
is($dri->get_info('action'),'offline_update','message_poll get_info(action)');
is($dri->get_info('name'),'domain3.com.ph','message_poll get_info(name)');
is($dri->get_info('change'),'RENEWAL','message_poll get_info(change)');
is($dri->get_info('details'),'Domain renewed for 1y','message_poll get_info(details)');

### poll message id: 595
$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="595"><qDate>2015-10-01T04:05:07.812Z</qDate><msg lang="en"><![CDATA[<offlineUpdate><domain><name>domain4.ph</name><change>DELETION</change><details>Domain deleted</details></domain></offlineUpdate>]]></msg></msgQ>' . $TRID . '</response>' . $E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success [595]');
$last_id = $dri->get_info('last_id');
is($last_id,'595','message_retrieve get_info(last_id) - 595');
is($dri->get_info('action'),'offline_update','message_poll get_info(action)');
is($dri->get_info('name'),'domain4.ph','message_poll get_info(name)');
is($dri->get_info('change'),'DELETION','message_poll get_info(change)');
is($dri->get_info('details'),'Domain deleted','message_poll get_info(details)');

exit 0;
