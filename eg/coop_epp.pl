#!/usr/bin/perl
#
#
# A Net::DRI example for .COOP : creation of contacts, hosts, domains, and deleting domain

use utf8;
use strict;
use warnings;

use Net::DRI;

## Fill these variables : your registrar id, password, and contact prefix
my $CLID='';
my $PASS='';
my $CID_PREFIX=''; ## The registry mandates all contacts ID to start with a specific prefix, tied to your account


my $dri=Net::DRI->new({cache_ttl=>10,logging=>'files'});

my $ok=eval {
############################################################################################################
$dri->add_registry('COOP',{clid=>$CLID});

## This connects to .COOP server for tests : make sure you have local files key.pem and cert.pem
my $rc=$dri->target('COOP')->add_current_profile('profile1','epp',{ssl_key_file=>'./key.pem',ssl_cert_file=>'./cert.pem',ssl_ca_file=>'./cert.pem',client_login=>$CLID,client_password=>$PASS});

die($rc) unless $rc->is_success(); ## Here we catch all errors during setup of transport, such as authentication errors

my $t1=time()%100;
my $c1=new_contact($dri); ## sponsor 1
$c1->srid($CID_PREFIX.'1s'.$t1);
my $c2=new_contact($dri); ## sponsor 2
$c2->srid($CID_PREFIX.'s'.($t1+1));
my $c3=new_contact($dri);
$c3->srid($CID_PREFIX.'r'.($t1+2));
$c3->sponsors([$c1->srid(),$c2->srid()]); ## $c3 will be used as registrant, hence it needs 2 sponsors !
$c3->mailing_list(1);
my $c4=new_contact($dri);
$c4->srid($CID_PREFIX.'c'.($t1+3)); ## will be  used as billing/technical/admin
$c4->mailing_list(0);

$rc=$dri->contact_create($c1);
die($rc) unless $rc->is_success();
my $id=$dri->get_info('id');
print "Contact1 created, id=$id\n";
$rc=$dri->contact_create($c2);
die($rc) unless $rc->is_success();
$id=$dri->get_info('id');
print "Contact2 created, id=$id\n";
$rc=$dri->contact_create($c3);
die($rc) unless $rc->is_success();
$id=$dri->get_info('id');
print "Contact3 created, id=$id\n";
$rc=$dri->contact_create($c4);
die($rc) unless $rc->is_success();
$id=$dri->get_info('id');
print "Contact3 created, id=$id\n";


my $nso=$dri->local_object('hosts');
foreach my $ns (qw/ns1.example.com ns2.example.com/)
{
 print "Attempting to create host $ns ";
 my $e=$dri->host_exist($ns);
 if ($e==0)
 {
  $rc=$dri->host_create($ns);
  print $rc->is_success()? "OK\n" : "KO\n";
 } else
 {
  print "EXIST already\n";
 }
 $nso->add($ns);
}

my $dom='toto-'.time().'.coop';
$rc=$dri->domain_check($dom);
print "$dom exists: ".($dri->get_info('exist')? 'YES' : 'NO')."\n";
my $cs=$dri->local_object('contactset');
$cs->set($c3,'registrant');
$cs->set($c4,'billing');
$cs->set($c4,'tech');
$cs->set($c4,'admin');
print "Attempting to create domain $dom\n";
$rc=$dri->domain_create($dom,{pure_create=>1,duration=>$dri->local_object('duration',years => 2),ns=>$nso,contact=>$cs,auth=>{pw=>'whatever'}});
print "$dom created successfully:".($rc->is_success()? 'YES' : 'NO')."\n";

$rc=$dri->domain_check($dom);
print "$dom does exists now: ".($dri->get_info('exist')? 'YES' : 'NO')."\n";
$rc=$dri->domain_info($dom);
print "$dom domain_info: ".($rc->is_success()? 'YES' : 'NO')."\n";

$rc=$dri->domain_delete($dom,{pure_delete => 1});
print "$dom domain_delete: ".($rc->is_success()? 'YES' : 'NO')."\n";

$rc=$dri->contact_delete($c3);
print 'Contact3 deleted successfully: '.($rc->is_success()? 'YES' : 'NO')."\n";
$rc=$dri->contact_delete($c1);
print 'Contact1 deleted successfully: '.($rc->is_success()? 'YES' : 'NO')."\n";
$rc=$dri->contact_delete($c2);
print 'Contact2 deleted successfully: '.($rc->is_success()? 'YES' : 'NO')."\n";
$rc=$dri->contact_delete($c4);
print 'Contact4 deleted successfully: '.($rc->is_success()? 'YES' : 'NO')."\n";


$dri->end();
};

if (! $ok)
{ 
 my $err=$@;
 print "\n\nAn EXCEPTION happened !\n";
 if (ref $err)
 {
  $err->print();
 } else
 {
  print $err;
 }
} else
{
 print "\n\nNo exception happened, everything seems OK !";
}

print "\n";
exit 0;

######################################################

sub new_contact
{
 my ($dri)=@_;
 my $c=$dri->local_object('contact');
 $c->name('My Name');
 $c->org('My Organisation àé æ'.time());
 $c->street(['My Address']);
 $c->city('My city');
 $c->pc(11111);
 $c->cc('FR');
 $c->email('test@example.com');
 $c->voice('+33.1111111');
 $c->fax('+33.2222222');
 $c->auth({pw => 'whatever'});
 $c->lang('fr');
 $c->loc2int(); ## registry operator needs internationalized & localized forms (not just internationalized alone)
 return $c;
}
