#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::NameAction::Connection;
use DateTime::Duration;
use DateTime;
use Test::More tests => 36;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our ($R1,$R2);

sub mysend { my ($transport,$count,$msg,$ctx)=@_;
  *{Net::DRI::Transport::Dummy::transport_data} = sub { return {remote_url       => 'https://ncktest.nameaction.com/interface',
  	                                                            client_login     => 'ncktest',
  	                                                            client_password  => 'ncktest'}};
  $R1 = Net::DRI::Protocol::NameAction::Connection->build_url($transport,$msg);
  return 1;
}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->add_registry('NameAction');
$dri->target('NameAction')->add_current_profile('p1','nameaction',{f_send=>\&mysend,f_recv=>\&myrecv});;

my ($r,$rc,$rd,$ns,$cs);

$r = "https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Check&SLD=nameaction&TLD=cl";

$R2 = <<'EOF';
<nck>
  <response>
    <command>check</command>
    <value>1</value>
  </response>
  <message>
   Domain nameaction.cl is available
  </message>
</nck>
EOF

$rc=$dri->domain_check('nameaction.cl');
is($R1,$r,'domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');


### Create

$r='https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Create&SLD=nameaction&TLD=cl&Year=2&RegistrantName=JohnDoe&RegistrantOrganization=NameAction+DomainLA&RegistrantAddress=1156+HighStreet&RegistrantCity=California&RegistrantCountryCode=US&RegistrantPostalCode=95064&RegistrantPhone=1.1234567&RegistrantEmail=j.doe%40nameaction.com&AdminName=JohnDoe&AdminOrganization=NameAction+DomainLA&AdminAddress=1156+HighStreet&AdminCity=California&AdminCountryCode=US&AdminPostalCode=95064&AdminPhone=1.1234567&AdminEmail=j.doe%40nameaction.com&TechName=JohnDoe&TechOrganization=NameAction+DomainLA&TechAddress=1156+HighStreet&TechCity=California&TechCountryCode=US&TechPostalCode=95064&TechPhone=1.1234567&TechEmail=j.doe%40nameaction.com&NS1=ns1.nameaction.com&NS2=ns2.nameaction.com&IP1=200.27.54.210&IP2=200.27.54.211&InfoPL=55555555-5';

$R2 = <<'EOF';
<nck>
  <response>
    <command>create</command>
    <value>1000</value>
  </response>
  <message>
    Request to Create the domain nameaction.cl was successfully received for 2 year(s). (Cost USD$95.0)
  </message>
</nck>
EOF

$cs=$dri->local_object('contactset');
my $co=$dri->local_object('contact');
isa_ok($co,'Net::DRI::Data::Contact::NameAction','local_object(contact)');

$co->name('JohnDoe');
$co->org('NameAction DomainLA');
$co->street(['1156 HighStreet','','']);
$co->city('California');
$co->pc('95064');
$co->cc('US');
$co->voice('1.1234567');
$co->email('j.doe@nameaction.com');

$cs->set($co,'registrant');
$cs->set($co,'admin');
$cs->set($co,'tech');

$ns = $dri->local_object('hosts')->set(['ns1.nameaction.com','200.27.54.210'],['ns2.nameaction.com','200.27.54.211']);

$rc = $dri->domain_create('nameaction.cl',{ pure_create =>1, 
                                            duration    => DateTime::Duration->new(years=>2),
                                            ns          => $ns,
                                            contact     => $cs,
                                            info_pl     => '55555555-5'
                                           });

is_string($R1,$r,'domain_create build');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');

### Renew

$r="https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Renew&SLD=nameaction&TLD=cl&Year=2";

$R2 = <<'EOF';
<nck>
  <response>
    <command>renew</command>
    <value>1000</value>
  </response>
  <message>
    Request to Renew the domain nameaction.cl was successfully received for 2 year(s). (Cost USD$80.0)
  </message>
</nck>
EOF

$rc = $dri->domain_renew('nameaction.cl',{duration => DateTime::Duration->new(years=>2)});
is($rc->is_success(),1,'domain_renew is_success');
is($R1,$r,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');

### Update 

$r="https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Modify&SLD=nameaction&TLD=cl&RegistrantName=JohnDoe&RegistrantOrganization=NameAction+DomainLA&RegistrantAddress=1156+HighStreet&RegistrantCity=California&RegistrantCountryCode=US&RegistrantPostalCode=95064&RegistrantPhone=1.1234567&RegistrantEmail=j.doe%40nameaction.com&AdminName=JohnDoe&AdminOrganization=NameAction+DomainLA&AdminAddress=1156+HighStreet&AdminCity=California&AdminCountryCode=US&AdminPostalCode=95064&AdminPhone=1.1234567&AdminEmail=j.doe%40nameaction.com&NS1=ns1.nameaction.com&NS2=ns2.nameaction.com&IP1=200.27.54.210&IP2=200.27.54.211";

$R2 = <<'EOF';
<nck>
  <response>
    <command>modify</command>
    <value>1000</value>
  </response>
  <message>
    Domain nameaction.cl successfully modified
  </message>
</nck>
EOF

$cs=$dri->local_object('contactset');
$co=$dri->local_object('contact');
$co->name('JohnDoe');
$co->org('NameAction DomainLA');
$co->street(['1156 HighStreet','','']);
$co->city('California');
$co->pc('95064');
$co->cc('US');
$co->voice('1.1234567');
$co->email('j.doe@nameaction.com');

$cs->set($co,'registrant');
$cs->set($co,'admin');

my $toc=$dri->local_object('changes');
$toc->set('ns',$ns);
$toc->set('contact',$cs);

$rc = $dri->domain_update('nameaction.cl',$toc);
is_string($R1,$r,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');
is($dri->get_info('action'),'update','domain_update get_info(action)');
is($dri->get_info('exist'),1,'domain_update get_info(exist)');

### Domain Info Error

$r= "https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Info&SLD=nameaction&TLD=cl";

$R2 = <<'EOF';
<nck>
  <response>
    <error>
      <code>2311</code>
      <message>Domains are not associated with this account</message>
    </error>
  </response>
</nck>
EOF

$rc = $dri->domain_info('nameaction.cl');
is_string($R1,$r,'domain_info build');
is($rc->is_success(),0,'domain_info error');

### Domain Specific Info 

$r= "https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Info&SLD=nameaction&TLD=cl";

$R2 = <<'EOF';
<nck>
  <response>
    <command>Info</command>
    <value>1000</value> 
  </response>
  <message>
    <details>
      <domain>nameaction.cl</domain>
      <contacts>
        <registrant>NameAction Domain LA</registrant>
        <admin>John Doe</admin> 
        <tech>John Doe</tech>
      </contacts>
      <hosts>
        <ns1>ns1.nameaction.com</ns1> 
        <ip1>200.27.54.210</ip1>
        <ns2>ns2.nameaction.com</ns2>
        <ip2>200.27.54.211</ip2>
      </hosts>
      <expirydate>2012-02-13 00:00:00</expirydate>
      <status>Registred</status>
    </details>
  </message>
</nck> 
EOF

$rc = $dri->domain_info('nameaction.cl');
is_string($R1,$r,'domain_info build');
is($rc->is_success(),1,'domain_info is_success');
my $s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','registrant','tech'],'domain_info get_info(contact) types');
isa_ok($co,'Net::DRI::Data::Contact::NameAction','domain_info get_info(contact)');
is($s->get('registrant')->name(),'NameAction Domain LA','domain_info get_info(contact) registrant name');
is($s->get('admin')->name(),'John Doe','domain_info get_info(contact) admin name');
is($s->get('tech')->name(),'John Doe','domain_info get_info(contact) tech name');
my $dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(subordinate_hosts)');
my @c=$dh->get_names();
is_deeply(\@c,['ns1.nameaction.com','ns2.nameaction.com'],'domain_info get_info(host) get_names');
my $d=$dri->get_info('expirydate');
is($d,'2012-02-13 00:00:00','domain_info get_info(expirydate) value');

### Domain Info Error

$r= "https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Delete&SLD=nameaction&TLD=cl";

$R2 = <<'EOF';
<nck>
  <response>
    <command>delete</command>
    <value>1000</value>
  </response>
  <message>
    Request to Delete the domain nameaction.cl successfully received
  </message>
</nck>
EOF

$rc = $dri->domain_delete('nameaction.cl', { pure_delete => 1 });
is_string($R1,$r,'domain_delete build');
is($rc->is_success(),1,'domain_delete is_success');

### Transfer 

$r= 'https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Transfer&Type=Management&SLD=nameaction&TLD=cl&AuthCode=ABC1234';

$R2 = <<'EOF';
<nck>
  <response>
    <command>transfer</command>
    <value>1000</value>
  </response>
  <message>
    Request to Transfer the domain nameaction.cl successfully received
  </message>
</nck>
EOF

$rc = $dri->domain_transfer_start('nameaction.cl', {auth=>{pw=>'ABC1234'}});
is_string($R1,$r,'domain_transfer build');
is($rc->is_success(),1,'domain_transfer is_success');

### Trade

$r= 'https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Transfer&Type=Owner&SLD=nameaction&TLD=cl&RegistrantName=John+Doe&RegistrantOrganization=NameAction+Domain+LA&RegistrantAddress=1156+High+Street&RegistrantCity=California&RegistrantCountryCode=US&RegistrantPostalCode=95064&RegistrantPhone=1.1234567&RegistrantEmail=j.doe%40nameaction.com';

$R2 = <<'EOF';
<nck>
  <response>
    <command>transfer</command>
    <value>1000</value>
  </response>
  <message>
    Request to Transfer the domain nameaction.cl successfully received
  </message>
</nck>
EOF

$cs=$dri->local_object('contactset');
$co=$dri->local_object('contact');
$co->name('John Doe');
$co->org('NameAction Domain LA');
$co->street(['1156 High Street','','']);
$co->city('California');
$co->pc('95064');
$co->cc('US');
$co->voice('1.1234567');
$co->email('j.doe@nameaction.com');

$cs->set($co,'registrant');

$rc = $dri->domain_trade_start('nameaction.cl', { contact => $cs });
is_string($R1,$r,'domain_trade build');
is($rc->is_success(),1,'domain_trade is_success');

exit 0;