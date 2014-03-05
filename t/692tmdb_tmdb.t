#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use MIME::Base64;
use DateTime;
use DateTime::Duration;

use Test::More tests => 30;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='';
our $E2='';
our $TRID='';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-123456'}, logging => 'null' });
$dri->add_registry('TMDB');

# Example OTE credentials
my $cnis_data = { server=>'test.tmcnis.org', realm=>'CNIS OT&E Service', username=>'cnisNUM', password=>'ABC123' };
my $smdrl_data = { server=>'test.ry.marksdb.org', realm=>'marksdb -OT&E service', username=>'smdrlNUM', password=>'ABC123' };

$dri->target('TMDB')->add_current_profile('p1','tmdb',{f_send=>\&mysend,f_recv=>\&myrecv},{cnis_dats => $cnis_data, smdrl_data => $smdrl_data });
#$dri->target('TMDB')->add_current_profile('p1','tmdb',{clid=>123,remote_url=>'http://localhost/'}, {cnis_dats => $cnis_data, smdrl_data => $smdrl_data });

my $rc;
my ($dh,@c);
my ($s,$d,$smark,$mark,$cs,$holder,$holder2,$agent,$tparty,$l1,$l2,$d1,$chg,@docs,@labels);

## Session commands

=cut
$R2='<?xml version="1.0" encoding="utf-8"?><tmch xmlns="urn:ietf:params:xml:ns:tmch-1.0"><greeting><svID>TMCH server</svID><svDate>2013-01-15T12:01:02Z</svDate></greeting></tmch>';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
=cut

####################################################################################################
## SMD-RL Commands

my $PGPSIG=<<'EOF';
-----BEGIN PGP SIGNATURE-----
Version: Crypt::OpenPGP 1.06

iQEcBAABAgAGBQJSXH57AAoJELjE6ZtM/TdMXlIIAKf7qz9IuAYKVEYQcZTcZYXU
GJ9TjwBN33W/BLPQsjJDaPMOXL3n8mqD1Ilz1Qw+R4nxaR/KnrCiew1WRf69IL58
AqiX0+EziHKfRqNyovbz9kMczsCXHgxVY0F/iky7SOLmlv3JdbL7ONcrvMOh90Y8
eHb4PYP2MrBVtBaoDKd+vRzfWkB4QlYzAqs3tK0alltHrIP89gZmeAnE9lDR4iSL
bys2TTulY0JmsbGVVHwu8dN/iJcxxpwNDoPCZQoO9Fkpcte1w5nKKi8Uit4FZuzJ
ipiYdg3ibY5qg04qMl6iiCSXmkVSBL0p2i/Co/OOR08E+kXzV/Wqc8JR3Li5Uss=
=gaxy
-----END PGP SIGNATURE-----
EOF

my $SMDRL=<<'EOF';
1,2013-10-14T23:30:02.3Z
smd-id,insertion-datetime
0000001681375789102250-65535,2013-08-09T12:00:00.0Z
0000001691375789102379-65535,2013-08-09T12:00:00.0Z
0000001701375789102455-65535,2013-08-09T12:00:00.0Z
0000001711375789102531-65535,2013-08-09T12:00:00.0Z
0000001721375789102646-65535,2013-08-09T12:00:00.0Z
0000001731375789103073-65535,2013-08-09T12:00:00.0Z
0000001741375789103526-65535,2013-08-09T12:00:00.0Z
0000001751375789103645-65535,2013-08-10T00:00:00.0Z
0000001761375789103896-65535,2013-08-09T12:00:00.0Z
0000001771375789104608-65535,2013-08-10T00:00:00.0Z
0000001781375789104683-65535,2013-08-09T12:00:00.0Z
0000001791375789104761-65535,2013-08-10T00:00:00.0Z
0000001801375789104829-65535,2013-08-09T12:00:00.0Z
0000001811375789104899-65535,2013-08-10T00:00:00.0Z
0000001821375789105364-65535,2013-08-09T12:00:00.0Z
0000001831375789105609-65535,2013-08-09T12:00:00.0Z
0000001841375789105951-65535,2013-08-09T12:00:00.0Z
0000001861375789106207-65535,2013-08-09T12:00:00.0Z
0000001871375789106415-65535,2013-08-09T12:00:00.0Z
0000001881375789106727-65535,2013-08-10T00:00:00.0Z
0000001891375789106801-65535,2013-08-09T12:00:00.0Z
0000001901375789106867-65535,2013-08-09T12:00:00.0Z
0000001911375789106930-65535,2013-08-09T12:00:00.0Z
0000001921375789107127-65535,2013-08-09T12:00:00.0Z
0000001931375789107419-65535,2013-08-09T12:00:00.0Z
0000001941375789107764-65535,2013-08-09T12:00:00.0Z
0000001951375789107828-65535,2013-08-09T12:00:00.0Z
0000001961375789108243-65535,2013-08-09T12:00:00.0Z
0000001971375789108423-65535,2013-08-09T12:00:00.0Z
0000001981375789108707-65535,2013-08-09T12:00:00.0Z
0000001991375789108768-65535,2013-08-09T12:00:00.0Z
0000002001375789108838-65535,2013-08-09T12:00:00.0Z
0000002011375789109167-65535,2013-08-09T12:00:00.0Z
0000002021375789109490-65535,2013-08-09T12:00:00.0Z
0000002031375789109556-65535,2013-08-09T12:00:00.0Z
0000002041375789109612-65535,2013-08-09T12:00:00.0Z
0000002051375789109669-65535,2013-08-09T12:00:00.0Z
0000002061375789109951-65535,2013-08-09T12:00:00.0Z
0000002071375789110528-65535,2013-08-09T12:00:00.0Z
0000002081375789110588-65535,2013-08-09T12:00:00.0Z
0000002091375789110915-65535,2013-08-09T12:00:00.0Z
0000002101375789110972-65535,2013-08-09T12:00:00.0Z
0000002111375789111443-65535,2013-08-09T12:00:00.0Z
0000002121375789111594-65535,2013-08-09T12:00:00.0Z
0000002131375789111654-65535,2013-08-09T12:00:00.0Z
0000002141375789111712-65535,2013-08-09T12:00:00.0Z
0000002151375789111768-65535,2013-08-09T12:00:00.0Z
0000002161375789111823-65535,2013-08-09T12:00:00.0Z
0000002171375789112267-65535,2013-08-09T12:00:00.0Z
0000002181375789112723-65535,2013-08-09T12:00:00.0Z
0000002191375789112871-65535,2013-08-09T12:00:00.0Z
0000002201375789113183-65535,2013-08-09T12:00:00.0Z
0000002211375789113504-65535,2013-08-09T12:00:00.0Z
0000002221375789113751-65535,2013-08-09T12:00:00.0Z
0000002231375789113815-65535,2013-08-09T12:00:00.0Z
0000002241375789113879-65535,2013-08-09T12:00:00.0Z
0000002251375789114171-65535,2013-08-09T12:00:00.0Z
0000002261375789114687-65535,2013-08-09T12:00:00.0Z
0000002291375789114812-65535,2013-08-09T12:00:00.0Z
0000002301375789114865-65535,2013-08-09T12:00:00.0Z
0000001891373633633430-65535,2013-08-09T12:00:00.0Z
0000002201373633640894-65535,2013-08-09T12:00:00.0Z
0000001911373633633994-65535,2013-08-09T12:00:00.0Z
0000002221373633641502-65535,2013-08-09T12:00:00.0Z
0000001931373633634379-65535,2013-08-09T12:00:00.0Z
0000002291373633642550-65535,2013-08-09T12:00:00.0Z
0000001921373633634098-65535,2013-08-09T12:00:00.0Z
0000002261373633642458-65535,2013-08-09T12:00:00.0Z
0000001941373633634727-65535,2013-08-09T12:00:00.0Z
0000002301373633642818-65535,2013-08-09T12:00:00.0Z
0000001861376042761179-65535,2013-08-10T00:00:00.0Z
0000002001376042764293-65535,2013-08-10T00:00:00.0Z
0000002011376042764485-65535,2013-08-10T00:00:00.0Z
0000002021376042764750-65535,2013-08-10T00:00:00.0Z
0000002031376042765014-65535,2013-08-10T00:00:00.0Z
0000002041376042765085-65535,2013-08-10T00:00:00.0Z
0000002051376042765277-65535,2013-08-10T00:00:00.0Z
0000002061376042765341-65535,2013-08-10T00:00:00.0Z
0000002071376042765408-65535,2013-08-10T00:00:00.0Z
0000002081376042765470-65535,2013-08-10T00:00:00.0Z
0000002091376042765779-65535,2013-08-10T00:00:00.0Z
0000002101376042766438-65535,2013-08-10T00:00:00.0Z
0000002111376042766714-65535,2013-08-10T00:00:00.0Z
0000002121376042767302-65535,2013-08-10T00:00:00.0Z
0000002131376042767364-65535,2013-08-10T00:00:00.0Z
0000002141376042767572-65535,2013-08-10T00:00:00.0Z
0000002151376042767642-65535,2013-08-10T00:00:00.0Z
0000002161376042767705-65535,2013-08-10T00:00:00.0Z
0000002171376042767771-65535,2013-08-10T00:00:00.0Z
0000002181376042767994-65535,2013-08-10T00:00:00.0Z
0000002191376042768370-65535,2013-08-10T00:00:00.0Z
0000002201376042768432-65535,2013-08-10T00:00:00.0Z
0000002211376042768492-65535,2013-08-10T00:00:00.0Z
0000002221376042768552-65535,2013-08-10T00:00:00.0Z
0000002231376042769036-65535,2013-08-10T00:00:00.0Z
0000002241376042769508-65535,2013-08-10T00:00:00.0Z
0000002251376042769746-65535,2013-08-10T00:00:00.0Z
0000002261376042770009-65535,2013-08-10T00:00:00.0Z
0000002291376042770068-65535,2013-08-10T00:00:00.0Z
0000002301376042770286-65535,2013-08-10T00:00:00.0Z
0000001991373633636222-65535,2013-08-09T12:00:00.0Z
0000001731373633629261-65535,2013-08-09T12:00:00.0Z
0000001861373633632586-65535,2013-08-09T12:00:00.0Z
0000002011373633636590-65535,2013-08-09T12:00:00.0Z
0000002001373633636321-65535,2013-08-09T12:00:00.0Z
0000001741373633629635-65535,2013-08-09T12:00:00.0Z
0000001871373633632796-65535,2013-08-09T12:00:00.0Z
0000002061373633637623-65535,2013-08-09T12:00:00.0Z
0000001681373633626622-65535,2013-08-09T12:00:00.0Z
0000002051373633637534-65535,2013-08-09T12:00:00.0Z
0000001881373633633247-65535,2013-08-09T12:00:00.0Z
0000002071373633638027-65535,2013-08-09T12:00:00.0Z
0000001761373633630141-65535,2013-08-09T12:00:00.0Z
0000002121373633638842-65535,2013-08-09T12:00:00.0Z
0000001751373633629780-65535,2013-08-09T12:00:00.0Z
0000002111373633638619-65535,2013-08-09T12:00:00.0Z
0000001771373633630713-65535,2013-08-09T12:00:00.0Z
0000002131373633638939-65535,2013-08-09T12:00:00.0Z
0000001791373633631082-65535,2013-08-09T12:00:00.0Z
0000002181373633640467-65535,2013-08-09T12:00:00.0Z
0000001781373633630933-65535,2013-08-09T12:00:00.0Z
0000002171373633640151-65535,2013-08-09T12:00:00.0Z
0000001801373633631189-65535,2013-08-09T12:00:00.0Z
0000002191373633640690-65535,2013-08-09T12:00:00.0Z
0000001821373633631931-65535,2013-08-09T12:00:00.0Z
0000002241373633641784-65535,2013-08-09T12:00:00.0Z
0000001811373633631599-65535,2013-08-09T12:00:00.0Z
0000002231373633641702-65535,2013-08-09T12:00:00.0Z
0000001831373633632193-65535,2013-08-09T12:00:00.0Z
0000002251373633642257-65535,2013-08-09T12:00:00.0Z
0000001951373633634829-65535,2013-08-09T12:00:00.0Z
0000002031373633637350-65535,2013-08-09T12:00:00.0Z
0000001841373633632347-65535,2013-08-09T12:00:00.0Z
0000002021373633637151-65535,2013-08-09T12:00:00.0Z
0000001961373633635119-65535,2013-08-09T12:00:00.0Z
0000002041373633637442-65535,2013-08-09T12:00:00.0Z
0000001971373633635580-65535,2013-08-09T12:00:00.0Z
0000002091373633638246-65535,2013-08-09T12:00:00.0Z
0000001691373633627900-65535,2013-08-09T12:00:00.0Z
0000002081373633638160-65535,2013-08-09T12:00:00.0Z
0000001981373633635962-65535,2013-08-09T12:00:00.0Z
0000002101373633638337-65535,2013-08-09T12:00:00.0Z
0000001711373633628408-65535,2013-08-09T12:00:00.0Z
0000002151373633639447-65535,2013-08-09T12:00:00.0Z
0000001701373633628125-65535,2013-08-09T12:00:00.0Z
0000002141373633639034-65535,2013-08-09T12:00:00.0Z
0000001721373633628952-65535,2013-08-09T12:00:00.0Z
0000002161373633639717-65535,2013-08-09T12:00:00.0Z
0000001901373633633646-65535,2013-08-09T12:00:00.0Z
0000002211373633641407-65535,2013-08-09T12:00:00.0Z
EOF

# smdrd_fetch_php
$R2=$PGPSIG;
$rc = $dri->smdrl_fetch_sig();
is($dri->get_info('action'),'fetch_sig','smdrl_fetch_sig get_info (action)');
my $sig = $dri->get_info('sig');
is($sig,$PGPSIG,'smdrl_fetch_sig get_info (sig)');

# smdrl_fetch
$R2=$SMDRL;
$rc = $dri->smdrl_fetch();
is($dri->get_info('action'),'fetch','smdrl_fetch get_info (fetch)');
my $smdrl = $dri->get_info('self');
is ($smdrl->{generated},'2013-10-14T23:30:02','smdrl_fetch get_info self (generated)');
my $smdid = $smdrl->{smdlist}->[0];
is ($smdid,'0000001681375789102250-65535','smdrl_fetch get_info self (first smd)');
is ($smdrl->{$smdid},'2013-08-09T12:00:00','smdrl_fetch get_info self (first smd insert date)');
my $raw = $dri->get_info('raw');
is ($raw,$SMDRL,'smdrl_fetch get_info self (raw)');

##############################################
## CNIS Commands

my $CNIS=<<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<tmNotice:notice xmlns:tmNotice="urn:ietf:params:xml:ns:tmNotice-1.0">
  <tmNotice:id>370d0b7c9223372036854775807</tmNotice:id>
  <tmNotice:notBefore>2010-08-14T09:00:00.0Z</tmNotice:notBefore>
  <tmNotice:notAfter>2010-08-16T09:00:00.0Z</tmNotice:notAfter>
  <tmNotice:label>example-one</tmNotice:label>
  <tmNotice:claim>
    <tmNotice:markName>Example One</tmNotice:markName>
    <tmNotice:holder entitlement="owner">
      <tmNotice:org>Example Inc.</tmNotice:org>
      <tmNotice:addr>
        <tmNotice:street>123 Example Dr.</tmNotice:street>
        <tmNotice:street>Suite 100</tmNotice:street>
        <tmNotice:city>Reston</tmNotice:city>
        <tmNotice:sp>VA</tmNotice:sp>
        <tmNotice:pc>20190</tmNotice:pc>
        <tmNotice:cc>US</tmNotice:cc>
      </tmNotice:addr>
    </tmNotice:holder>
    <tmNotice:contact type="owner">
      <tmNotice:name>Joe Doe</tmNotice:name>
      <tmNotice:org>Example Inc.</tmNotice:org>
      <tmNotice:addr>
        <tmNotice:street>123 Example Dr.</tmNotice:street>
        <tmNotice:street>Suite 100</tmNotice:street>
        <tmNotice:city>Reston</tmNotice:city>
        <tmNotice:sp>VA</tmNotice:sp>
        <tmNotice:pc>20190</tmNotice:pc>
        <tmNotice:cc>US</tmNotice:cc>
      </tmNotice:addr>
      <tmNotice:voice x="4321">+1.7035555555</tmNotice:voice>
      <tmNotice:email>jdoe@example.com</tmNotice:email>
    </tmNotice:contact>
    <tmNotice:jurDesc jurCC="US">UNITED STATES OF AMERICA</tmNotice:jurDesc>
    <tmNotice:classDesc classNum="35">Advertising; business management; business administration.</tmNotice:classDesc>
    <tmNotice:classDesc classNum="36">Insurance; financial affairs; monetary affairs; real estate.</tmNotice:classDesc>
    <tmNotice:goodsAndServices>Bardus populorum circumdabit se cum captiosus populum. Smert populorum circumdabit se cum captiosus populum qui eis differimus.</tmNotice:goodsAndServices>
  </tmNotice:claim>
  <tmNotice:claim>
    <tmNotice:markName>Example-One</tmNotice:markName>
    <tmNotice:holder entitlement="owner">
      <tmNotice:org>Example S.A. de C.V.</tmNotice:org>
      <tmNotice:addr>
        <tmNotice:street>Calle conocida #343</tmNotice:street>
        <tmNotice:city>Conocida</tmNotice:city>
        <tmNotice:sp>SP</tmNotice:sp>
        <tmNotice:pc>82140</tmNotice:pc>
        <tmNotice:cc>BR</tmNotice:cc>
      </tmNotice:addr>
    </tmNotice:holder>
    <tmNotice:jurDesc jurCC="BR">BRAZIL</tmNotice:jurDesc>
    <tmNotice:goodsAndServices>Bardus populorum circumdabit se cum captiosus populum. Smert populorum circumdabit se cum captiosus populum qui eis differimus.</tmNotice:goodsAndServices>
  </tmNotice:claim>
  <tmNotice:claim>
    <tmNotice:markName>One</tmNotice:markName>
    <tmNotice:holder entitlement="owner">
      <tmNotice:org>One Corporation</tmNotice:org>
      <tmNotice:addr>
        <tmNotice:street>Otra calle</tmNotice:street>
        <tmNotice:city>Otra ciudad</tmNotice:city>
        <tmNotice:sp>OT</tmNotice:sp>
        <tmNotice:pc>383742</tmNotice:pc>
        <tmNotice:cc>CR</tmNotice:cc>
      </tmNotice:addr>
    </tmNotice:holder>
    <tmNotice:jurDesc jurCC="CR">COSTA RICA</tmNotice:jurDesc>
    <tmNotice:goodsAndServices>Bardus populorum circumdabit se cum captiosus populum. Smert populorum circumdabit se cum captiosus populum qui eis differimus.</tmNotice:goodsAndServices>
    <tmNotice:notExactMatch>
      <tmNotice:court>
        <tmNotice:refNum>234235</tmNotice:refNum>
        <tmNotice:cc>CR</tmNotice:cc>
        <tmNotice:courtName>Supreme Court of Justice of Costa Rica</tmNotice:courtName>
      </tmNotice:court>
    </tmNotice:notExactMatch>
  </tmNotice:claim>
  <tmNotice:claim>
    <tmNotice:markName>One Inc</tmNotice:markName>
    <tmNotice:holder entitlement="owner">
      <tmNotice:org>One SA de CV</tmNotice:org>
      <tmNotice:addr>
        <tmNotice:street>La calle</tmNotice:street>
        <tmNotice:city>La ciudad</tmNotice:city>
        <tmNotice:sp>CD</tmNotice:sp>
        <tmNotice:pc>34323</tmNotice:pc>
        <tmNotice:cc>AR</tmNotice:cc>
      </tmNotice:addr>
    </tmNotice:holder>
    <tmNotice:jurDesc jurCC="AR">ARGENTINA</tmNotice:jurDesc>
    <tmNotice:goodsAndServices>Bardus populorum circumdabit se cum captiosus populum. Smert populorum circumdabit se cum captiosus populum qui eis differimus.</tmNotice:goodsAndServices>
    <tmNotice:notExactMatch>
      <tmNotice:udrp>
        <tmNotice:caseNo>D2003-0499</tmNotice:caseNo>
        <tmNotice:udrpProvider>WIPO</tmNotice:udrpProvider>
      </tmNotice:udrp>
    </tmNotice:notExactMatch>
  </tmNotice:claim>
</tmNotice:notice>
EOF

# cnis_lookup
$R2=$CNIS;
$rc = $dri->cnis_lookup('abc123');
is($dri->get_info('action'),'lookup','cnis_lookup get_info (lookup)');
is($dri->get_info('id'),'370d0b7c9223372036854775807','cnis_lookup get_info (id)');
is($dri->get_info('not_before'),'2010-08-14T09:00:00','cnis_lookup get_info (not_before)');
is($dri->get_info('not_after'),'2010-08-16T09:00:00','cnis_lookup get_info (not_after)');
is($dri->get_info('label'),'example-one','cnis_lookup get_info (label)');
my @claims = @{$dri->get_info('claim')};
my $c1 = $claims[0];
is($c1->{mark_name},'Example One','cnis lookup claim1 (mark_name)');
is($c1->{goods_services},'Bardus populorum circumdabit se cum captiosus populum. Smert populorum circumdabit se cum captiosus populum qui eis differimus.','cnis lookup claim1 (goods_services)');
is($c1->{jurisdiction_cc},'US','cnis lookup claim1 (jurisdiction_cc)');
is($c1->{jurisdiction},'UNITED STATES OF AMERICA','cnis lookup claim1 (jurisdiction)');
is_deeply($c1->{class}->[0],{'number'=>'35','description'=>'Advertising; business management; business administration.'} ,'cnis lookup claim1 (class)');
isa_ok($c1->{contact},'Net::DRI::Data::ContactSet','cnis lookup claim1 (contact_set)');
$holder = $c1->{contact}->get('holder_owner');
isa_ok($holder,'Net::DRI::Data::Contact','cnis lookup claim1 (holder_owner)');
is($holder->org(),'Example Inc.','cnis lookup claim1 (holder_owner org)');

my $c3 = $claims[2];
is($c3->{mark_name},'One','cnis lookup claim3 (mark_name)');
is($c3->{jurisdiction},'COSTA RICA','cnis lookup claim3 (jurisdiction)');
my @nem = @{$c3->{not_exact_match}};
my $n1 = $nem[0];
is($n1->{type},'court','cnis lookup claim3 not_exact_match1 court (type)');
is($n1->{ref_num},'234235','cnis lookup claim3 not_exact_match1 court (ref_num)');
is($n1->{cc},'CR','cnis lookup claim3 not_exact_match1 court (cc)');
is($n1->{court_name},'Supreme Court of Justice of Costa Rica','cnis lookup claim3 not_exact_match1 court (court_name)');

my $c4 = $claims[3];
is($c4->{mark_name},'One Inc','cnis lookup claim3 (mark_name)');
@nem = @{$c4->{not_exact_match}};
$n1 = $nem[0];
is($n1->{type},'udrp','cnis lookup claim3 not_exact_match1 udrp (type)');
is($n1->{case_no},'D2003-0499','cnis lookup claim4 not_exact_match1 udrp (case_no)');
is($n1->{udrp_provider},'WIPO','cnis lookup claim4 not_exact_match1 udrp (udrp_provider)');

exit 0;