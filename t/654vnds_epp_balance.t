#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 11;
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
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['VeriSign::Balance']});

####################################################################################################


$R2=$E1.'<response>'.r().'<resData><balance:infData xmlns:balance="http://www.verisign.com/epp/balance-1.0"><balance:creditLimit>1000.00</balance:creditLimit><balance:balance>200.00</balance:balance><balance:availableCredit>800.00</balance:availableCredit><balance:creditThreshold><balance:fixed>500.00</balance:fixed></balance:creditThreshold></balance:infData></resData>'.$TRID.'</response>'.$E2;
my $rc=$dri->balance_info();
is_string($R1,$E1.'<command><info><balance:info xmlns:balance="http://www.verisign.com/epp/balance-1.0" xsi:schemaLocation="http://www.verisign.com/epp/balance-1.0 balance-1.0.xsd"/></info><clTRID>ABC-12345</clTRID></command>'.$E2,'balance_info build');
is($rc->get_data('session','balance','credit_limit'),1000,'balance_info get_data(credit_limit) 1');
is($rc->get_data('session','balance','balance'),200,'balance_info get_data(balance) 1');
is($rc->get_data('session','balance','available_credit'),800,'balance_info get_data(available_credit) 1');
is($rc->get_data('session','balance','credit_threshold'),500,'balance_info get_data(credit_threshold) 1');
is($rc->get_data('session','balance','credit_threshold_type'),'FIXED','balance_info get_data(credit_threshold_type) 1');

$R2=$E1.'<response>'.r().'<resData><balance:infData xmlns:balance="http://www.verisign.com/epp/balance-1.0"><balance:creditLimit>1000.00</balance:creditLimit><balance:balance>200.00</balance:balance><balance:availableCredit>800.00</balance:availableCredit><balance:creditThreshold><balance:percent>50</balance:percent></balance:creditThreshold></balance:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->balance_info();
is($rc->get_data('session','balance','credit_limit'),1000,'balance_info get_data(credit_limit) 2');
is($rc->get_data('session','balance','balance'),200,'balance_info get_data(balance) 2');
is($rc->get_data('session','balance','available_credit'),800,'balance_info get_data(available_credit) 2');
is($rc->get_data('session','balance','credit_threshold'),50,'balance_info get_data(credit_threshold) 2');
is($rc->get_data('session','balance','credit_threshold_type'),'PERCENT','balance_info get_data(credit_threshold_type) 2');



exit 0;
