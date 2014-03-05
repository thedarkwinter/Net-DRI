#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;

use Test::More skip_all => 'Email handling is now obsolete at AFNIC';

eval { require MIME::Entity; MIME::Entity->import(); };
if ($@)
{
 plan skip_all => 'Module MIME::Entity is needed to test AFNIC email handling';
} else
{
 plan tests => 8;
}

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $R1='';
sub mysend
{
 my ($transport,$count,$msg)=@_;
 $R1=$msg->as_string();
 return 1;
}

sub munge_xmailer
{
 my $in=shift;
 $in=~s!MIME-tools \d\.\d+ \(Entity \d\.\d+\)!MIME-tools!;
 return $in;
}

my $dri=Net::DRI::TrapExceptions->new({cache_ttl=>10});
$dri->{trid_factory}=sub { return 'TRID-12345'; };

$dri->add_registry('AFNIC');
$dri->target('AFNIC')->add_current_profile('profile1','email',{f_send=>\&mysend, f_recv=> sub {}},{username=>'CLIENTID',password=>'CLIENTPW',email_from=>'test@localhost'});
$dri->transport->is_sync(0);


my $cs=$dri->local_object('contactset');
my $co=$dri->local_object('contact');
my $ns=$dri->local_object('hosts');

my $rc;

####################################################################################################

## FULL PM
$co->name('MyORG');
$co->street(['Whatever street 35','éçp àô']);
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
$co->srid('TEST');
$cs->set($co,'tech');

$ns->add('ns.toto.fr',['123.45.67.89']);
$ns->add('ns.toto.com');

$rc=$dri->domain_create('toto.fr',{pure_create=>1, contact => $cs, maintainer => 'ABCD', ns => $ns, auth => { pw=> 'nowmandatory!'} });

is($rc->code(),1001,'domain_create PM code');
is($rc->is_success(),1,'domain_create PM is_success');
is($rc->is_pending(),1,'domain_create PM is_pending');

my $E1=<<'EOF';
Content-Type: text/plain; charset="iso-8859-15"
Content-Disposition: inline
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0
X-Mailer: Net::DRI/0.96_05 via MIME-tools 5.428 (Entity 5.428)
From: test@localhost
To: domain@nic.fr
Subject: CLIENTID domain_create [TRID-12345]

1a..: C
1b..: CLIENTID
1c..: CLIENTPW
1e..: TRID-12345
1f..: 2.5.0
2a..: toto.fr
2z..: nowmandatory!
3a..: MyORG
3b..: Whatever street 35
3c..: éçp àô
3e..: Alphaville
3f..: 99999
3g..: FR
3h..: S
3j..: 111222333
3t..: +33 1 23 45 67 89
3v..: test@example.com
3w..: PM
3y..: ABCD
3z..: N
5a..: TEST-FRNIC
6a..: ns.toto.fr
6b..: 123.45.67.89
7a..: ns.toto.com
8a..: A
9a..: E
EOF

is_string(munge_xmailer($R1),munge_xmailer($E1),'domain_create build');

## REDUCED PP
$co=$dri->local_object('contact');
$co->srid('JOHN');
$co->disclose('N');
$co->key('ABCDEFGH-100');
$cs->set($co,'registrant');

$rc=$dri->domain_create('toto.fr',{pure_create=>1, contact => $cs, maintainer => 'ABCD', ns => $ns, auth => { pw => 'nowmandatory!'} });
is($rc->code(),1001,'domain_create PPreduced code');
is($rc->is_success(),1,'domain_create PPreduced is_success');
is($rc->is_pending(),1,'domain_create PPreduced is_pending');

my $E2=<<'EOF';
Content-Type: text/plain; charset="iso-8859-15"
Content-Disposition: inline
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0
X-Mailer: Net::DRI/0.96_05 via MIME-tools 5.428 (Entity 5.428)
From: test@localhost
To: domain@nic.fr
Subject: CLIENTID domain_create [TRID-12345]

1a..: C
1b..: CLIENTID
1c..: CLIENTPW
1e..: TRID-12345
1f..: 2.5.0
2a..: toto.fr
2z..: nowmandatory!
3q..: ABCDEFGH-100
3w..: PP
3x..: JOHN-FRNIC
5a..: TEST-FRNIC
6a..: ns.toto.fr
6b..: 123.45.67.89
7a..: ns.toto.com
8a..: A
9a..: E
EOF

is_string(munge_xmailer($R1),munge_xmailer($E2),'domain_create PPreduced build');

exit 0;
