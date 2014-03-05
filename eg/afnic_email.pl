#!/usr/bin/perl

use encoding "iso-8859-15";
use strict;
use warnings;

use Net::DRI;

my $dri=Net::DRI->new();

my $ok=eval {
############################################################################################################

## You need to modify the following information to make this script work :
## Cc & Bcc are added to all outgoing messages, you can remove them if not needed
## smtphost is the server to connect to by SMTP to send emails
## CLIENTID/CLIENTPW are your AFNIC credentials
## test@localhost is the address that will be put in the From: field of all outgoing messages.

$dri->add_registry('AFNIC', { clid => 'CLIENTID' } );
$dri->target('AFNIC')->add_current_profile('profile1','email',{cc=>'testcc@localhost',bcc=>'testbcc@localhost',smtphost=>'localhost'},['CLIENTID','CLIENTPW','test@localhost']);

my $cs=$dri->local_object('contactset');
my $co=$dri->local_object('contact');
$co->org('MyORG');
$co->street(['Whatever street 35','יחp אפ']);
$co->city('Alphaville');
$co->pc('99999');
$co->cc('FR');
$co->legal_form('S');
$co->legal_id('111222333');
$co->voice('+33.123456789');
$co->email('test@example.com');
$co->disclose('N');

$cs->set($co,'registrant');
$co=$dri->local_object('contact');
$co->roid('TEST-FRNIC');
$cs->set($co,'tech');

my $ns=$dri->local_object('hosts');
$ns->add('ns.toto.fr',['123.45.67.89']);
$ns->add('ns.toto.com');

my $rc=$dri->domain_create('toto1.fr',{pure_create => 1, contact => $cs, maintainer => 'ABCD', ns => $ns});
print "Mail successfully sent.\n" if $rc->is_success() && $rc->is_pending();

$co=$dri->local_object('contact');
$co->roid('JOHN-FRNIC');
$co->name('John, Doe'); ## Warning : AFNIC requires a , 
$co->street(['Whatever street 35','יחp אפ']);
$co->city('Alphaville');
$co->pc('99999');
$co->cc('FR');
$co->voice('+33.123456789');
$co->email('test@example.com');
$co->disclose('N');
$co->key('ABCDEFGH-100');
$cs->set($co,'registrant');

$rc=$dri->domain_create('toto2.fr',{pure_create => 1, contact => $cs, maintainer => 'ABCD', ns => $ns});
print "Mail successfully sent.\n" if $rc->is_success() && $rc->is_pending();

############################################################################################################
1;
};

if (! $ok)
{ 
 my $err=$@;
 print "AN ERROR happened !!!\n";
 if (ref $err)
 {
  $err->print();
 } else
 {
  print $err;
 }
} else
{
 print "No error";
}

print "\n";

exit 0;
