#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

#use Test::More tests => 30;
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
$dri->add_registry('LV');
$dri->target('LV')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });
 
print Dumper($dri);
exit 0;

eval {
  $dri->add_registry('LV');
  $dri->target('LV')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });
};

#if ($@) { # if error
#  print Dumper $@;
#  exit 1;
#}

#print Dumper($dri); exit 0;

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
## Contacts

####################################################################################################
## Domains

# 2.0 Domain Update - http://www.nic.lv/eppdoc/html/extensions/lvdomain.html
my $changes = $dri->local_object('changes'); exit 0;
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('51249'), 'admin');
$changes->add('contact', $cs);
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('78496'), 'tech');
$changes->del('contact', $cs);
$changes->add('ns',$dri->local_object('hosts')->set(['ns3.example.info']));
$rc = $dri->domain_update('example-lvnic.lv', $changes);

print Dumper($R1);
exit 0;

is_string($R1,$E1.'<command><update><domain:update xmlns:domain="http://www.dns.pl/nask-epp-schema/domain-2.0" xsi:schemaLocation="http://www.dns.pl/nask-epp-schema/domain-2.0 domain-2.0.xsd"><domain:name>uptest.pl</domain:name><domain:add><domain:ns>ns3.example.info</domain:ns><domain:contact type="tech">98765</domain:contact></domain:add><domain:rem><domain:contact type="tech">12347</domain:contact></domain:rem></domain:update></update><clTRID>ABC-12345</clTRID></command></epp>', 'domain_update build');
is($rc->is_success(), 1, 'domain_update is success');
