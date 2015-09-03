#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;

use Data::Dumper;

use Test::More tests => 99;
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
$dri->add_registry('AE');
$dri->target('AE')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->{registries}->{AE}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP',{}],'AE - epp transport_protocol_default');
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');

#####################################################################################################
######### Domain Commands ########

###################### Question 2 ###########################
## Creating a Contact Set...
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('C00012‐UAE'),'registrant');
$cs->add($dri->local_object('contact')->srid('C00014‐UAE'),'tech');

## Creating a Host Object...
$dh=$dri->local_object('hosts');
$dh->add('ns1.hosting.ae');
$dh->add('ns2.hosting.ae');
$dh->add('ns3.hosting.ae');
$dh->add('ns4.hosting.ae');
$dh->add('ns5.hosting.ae');
$dh->add('ns6.hosting.ae');
$dh->add('ns7.hosting.ae');
$dh->add('ns8.hosting.ae');
$dh->add('ns9.hosting.ae');
$dh->add('ns10.hosting.ae');
$dh->add('ns11.hosting.ae');
$dh->add('ns12.hosting.ae');
$dh->add('ns13.hosting.ae');
#
## Registering Domain...
$rc=$dri->domain_create('transportationlogistics.net.ae',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,ns=>$dh,auth=>{pw=>'FooBar21!@'}});
is($rc->is_success(),1,'epp_test - question 2');

###################### Question 4 ###########################
## Creating a Contact Set...
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('C00012‐UAE'),'registrant');
$cs->add($dri->local_object('contact')->srid('C00014‐UAE'),'tech');

## Creating a Host Object...
$dh=$dri->local_object('hosts');
$dh->add('ns1.hosting.ae');
$dh->add('ns2.hosting.ae');
#
## Registering Domain...
$rc=$dri->domain_create('in--valid.ae',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,ns=>$dh,auth=>{pw=>''}});
is($rc->is_success(),1,'epp_test - question 4');

#####################################################################################################
######### Closing Commands ########

$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

exit 0;
