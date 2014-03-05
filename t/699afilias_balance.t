#!/usr/bin/perl -w 

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Data::Dumper;

use Test::More tests => 19;
eval { no warnings; require::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
*{'main::is_string'}=\&main::is if $@;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';

our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our $R1;
sub mysend { my ($transport,$count,$msg) = @_; $R1 = $msg->as_string(); return 1; }

our $R2;
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

sub r{my ($c,$m)=@_;return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';}

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('ORG',{ 'clid'=>'ClientX'});
eval { $dri->target('ORG')->add_current_profile('p1','epp', { f_send=> \&mysend, f_recv=> \&myrecv });
};
print Dumper $@ if $@;  #DEBUG!!!

my ($rc,$s,$d,$dh,@c);
my ($c,$cs,$st,$p);

####################################################################################################
## Registrar Command
$R2=$E1.'<response>'.r().'<resData><registrar:infData xmlns:registrar="urn:ietf:params:xml:ns:registrar-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:registrar-1.0 registrar-1.0.xsd">
  <registrar:id>ClientX</registrar:id>
  <registrar:roid>R3003-LRMS</registrar:roid>
  <registrar:user>ClientX</registrar:user>
  <registrar:ctID>ClientX-R</registrar:ctID>
  <registrar:contact type="admin">ClientX-Ra</registrar:contact>
  <registrar:contact type="billing">ClientX-Rb</registrar:contact>
  <registrar:contact type="tech">ClientX-Rt</registrar:contact>
  <registrar:crID>admin</registrar:crID>
  <registrar:crDate>2012-04-13T20:29:31.0Z</registrar:crDate>
  <registrar:status s="ok"/>
  <registrar:portfolio name="afilias">
    <registrar:balance>100</registrar:balance>
    <registrar:threshold>1.00</registrar:threshold>
  </registrar:portfolio>
  <registrar:category>A</registrar:category>
  </registrar:infData>
  </resData>'.$TRID.'</response>'.$E2;

# basic / plain text info
#$rc = $dri->registrar_info("ClientX");
$rc = $dri->registrar_info(); # uses current clid from add_registry

is($R1,$E1.'<command><info><registrar:info xmlns:registrar="urn:ietf:params:xml:ns:registrar-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:registrar-1.0 registrar-1.0.xsd"><registrar:id>ClientX</registrar:id></registrar:info></info><clTRID>ABC-12345</clTRID></command></epp>','registrar_info build_xml');
is($dri->get_info('id'),'ClientX','registrar_info({id => "ClientX"})');
is($dri->get_info('roid'),'R3003-LRMS','registrar_info({roid => "R3003-LRMS"})');
is($dri->get_info('user'),'ClientX','registrar_info({user => "ClientX"})');
is($dri->get_info('ctID'),'ClientX-R','registrar_info({ctID => "ClientX-R"})');
is($dri->get_info('crID'),'admin','registrar_info({crID => "admin"})');
is($dri->get_info('crDate'),'2012-04-13T20:29:31','registrar_info({crDate => "2012-04-13T20:29:31"})');
is($dri->get_info('category'),'A','registrar_info({category => "A"})');

# contacts
$cs = $dri->get_info('contact');
isa_ok($cs,'Net::DRI::Data::ContactSet','registrar_info get_info(contact)');
is ($cs->contact_admin()->id(),'ClientX-Ra','registrar_info({contact type=admin => "ClientX-Ra"})');
is ($cs->contact_billing()->id(),'ClientX-Rb','registrar_info({contact type=billing => "ClientX-Rb"})');
is ($cs->contact_tech()->id(),'ClientX-Rt','registrar_info({contact type=tech => "ClientX-Rt"})');

# status - either ok / lock
$st = $dri->get_info('status');
isa_ok($st,'Net::DRI::Protocol::EPP::Core::Status','registrar_info get_info(status)');
is_deeply([$st->list_status()],['ok'],'registrar_info({status s="ok"}');

# portfolio
$p = shift $dri->get_info('portfolio'); # first array element
is($p->{name},'afilias','registrar_info({portfolio name="afilias"})');
is($p->{'balance'},'100','registrar_info({balance => "100"})');
is($p->{'threshold'},'1.00','registrar_info({threshold => "1.00"})');

# plain balance/threshold
is($dri->get_info('balance'),'100','registrar_info({balance => "100"})');
is($dri->get_info('threshold'),'1.00','registrar_info({threshold => "1.00"})');

exit 0;                                                                                                                       