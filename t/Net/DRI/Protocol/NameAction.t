#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::NameAction::Connection;
use DateTime::Duration;
use DateTime;
use Test::More tests => 45;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }


our ($R1,$R2);
our (@R1,@R2); #FIXME

sub mysend { my ($transport,$count,$msg,$ctx)=@_;
  *{Net::DRI::Transport::Dummy::transport_data} = sub { return {remote_url       => 'https://ncktest.nameaction.com/interface',
  	                                                            client_login     => 'ncktest',
  	                                                            client_password  => 'ncktest'}};
  $R1 = Net::DRI::Protocol::NameAction::Connection->build_url($transport,$msg);
  return 1;
}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2); }
sub munge { my $in=shift; $in=~s/>\s*</></sg; chomp($in); return $in; }

my $RESELLERID=''; #'LOGIN';

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->add_registry('NameAction');
$dri->target('NameAction')->add_current_profile('p1','nameaction',{f_send=>\&mysend,f_recv=>\&myrecv});#,client_login=>'LOGIN',client_password=>'PASSWORD',remote_url=>'http://localhost/'});

my ($r,$rc,$rd,$ns,$cs);


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

$r=<<'EOF';
EOF
$rc=$dri->domain_check('nameaction.cl');
is($R1,'https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Check&SLD=nameaction&TLD=cl','domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','nameaction.cl'),0,'domain_check get_info(exist) from cache');

exit 1;

#===Test registration with default name servers===================================

push @R2,<<'EOF';
<nck>
  <response>
    <command>create</command>
  <response>1000</response>
  <message>
    Request to Create the domain nameaction.cl was successfully received for 2 year(s). (Cost USD$95.0)
  </message>
</nck>
EOF

$cs=$dri->local_object('contactset');
my $co=$dri->local_object('contact');
$co->srid('daniel'); # Portfolio user name for OpenSRS?
$co->auth('daniel'); # Portfolio password for OpenSRS?
$co->name('Admin'); # Should be firstname, name => lastname.
$co->firstname('John');
$co->lastname('Doe');
$co->org('Catmas Inc.');
$co->street(['32 Catmas Street','Suite 100','Admin']);
$co->city('SomeCity');
$co->sp('CA');
$co->pc('90210');
$co->cc('US');
$co->voice('+1.4165550123x1812');
$co->fax('+1.4165550125');
$co->email('admin@example.com');
$co->url('http://www.catmas.com');

$cs->set($co,'registrant');
$cs->set($co,'admin');
$cs->set($co,'billing');

$r=<<"EOF";
https://ncktest.nameaction.com/interface?User=ncktest&Pass=ncktest&Command=Create&SLD=nameaction&TLD=cl&Year=1&RegistrantName=JohnDoe&RegistrantOrganization=NameAction DomainLA&RegistrantAddress=1156 HighStreet&RegistrantCity=California&RegistrantCountryCode=US&RegistrantPostalCode=95064&RegistrantPhone=1.1234567&RegistrantEmail=j.doenameaction.com&AdminName=John Doe&AdminOrganization=NameAction DomainLA&AdminAddress=1156 HighStreet&AdminCity=California&AdminCountryCode=US&AdminPostalCode=95064&AdminPhone=1.1234567&AdminEmail=j.doenameaction.com&TechName=JohnDoe&TechOrganization=NameAction Domain LA&TechAddress=1156 HighStreet&TechCity=California&TechCountryCode=US&TechPostalCode=95064&TechPhone=1.1234567&TechEmail=j.doenameaction.com&NS1=ns1.nameaction.com&NS2=ns2.nameaction.com&IP1=200.27.54.210&IP2=200.27.54.211&InfoPL=55555555-5
EOF

$rc=$dri->domain_create('example-nsi.net',{username => 'daniel', password => 'daniel', contact => $cs, registrant_ip => '10.0.10.19', pure_create => 1, duration => DateTime::Duration->new(years =>10)});
is_string(munge(shift(@R1)),munge($r),'domain_create (default name servers)');
is($rc->is_success(),1,'domain_create is_success (default name servers)');
#is($rc->native_code(),200,'domain_create native_code (default name servers)');
is($rc->code(),1000,'domain_create code (default name servers)');
is($dri->get_info('id'),3735281,'domain_create id');
#is($dri->get_info_keys(),'admin_email','domain_create response keys');
#is($dri->get_info('registration_code'),200,'domain_create get_info(registration_code)');
#is($dri->get_info('domain','example-nsi.net','admin_email'),'jsmith@catmas.com','domain_create get_info(admin_email)');
is($dri->get_info('admin_email'),'jsmith@catmas.com','domain_create get_info(admin_email)');

#===Test registration with default name servers===================================

push @R2,<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
   <header>
      <version>0.9</version>
   </header>
   <body>
      <data_block>
         <dt_assoc>
            <item key="protocol">XCP</item>
            <item key="action">REPLY</item>
            <item key="object">DOMAIN</item>
            <item key="is_success">0</item>
            <item key="response_code">435</item>
            <item key="response_text">
               Request failed validation: Name server
               'dns1.example.com' is not found at the registry. Please double check
               the nameserver and re-submit.
               Name server 'dns2.example.com' is not found at the
               registry. Please double check the nameserver and re-submit.
            </item>
            <item key="attributes">
               <dt_assoc>
                  <item key="registration_text">
                        Request failed validation: Name server
                     'dns1.example.com' is not found at the registry. Please double check
                     the nameserver and re-submit.
                     Name server 'dns2.example.com' is not found at the
                     registry. Please double check the nameserver and re-submit.
                  </item>
                  <item key="registration_code">435</item>
                  <item key="id">3735283</item>
                  <item key="forced_pending">3735283</item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF

$r=<<"EOF";
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
	<header>
		<version>0.9</version>
	</header>
	<body>
		<data_block>
			<dt_assoc>
				<item key="action">sw_register</item>
				<item key="object">domain</item>
				<item key="protocol">XCP</item>
				<item key="registrant_ip">216.40.46.115</item>
				<item key="attributes">
				<dt_assoc>
<item key="contact_set">
   <dt_assoc>
      <item key="admin">
      admin_co
      </item>
      <item key="billing">
      admin_co
      </item>
      <item key="owner">
      admin_co
      </item>
   </dt_assoc>
</item>
					<item key="custom_nameservers">1</item>
					<item key="custom_tech_contact">0</item>
					<item key="domain">yahoo.com</item>
                  <item key="nameserver_list">
                     <dt_array>
                        <item key="0">
                           <dt_assoc>
                              <item key="name">ns1.domaindirect.com</item>
                              <item key="sortorder">1</item>
                           </dt_assoc>
                        </item>
                        <item key="1">
                           <dt_assoc>
                              <item key="name">ns2.domaindirect.com</item>
                              <item key="sortorder">2</item>
                           </dt_assoc>
                        </item>
		</dt_array>
		</item>
					<item key="period">7</item>
					<item key="reg_password">daniel</item>
					<item key="reg_type">new</item>
					<item key="reg_username">daniel</item>
				</dt_assoc>
				</item>
			</dt_assoc>
		</data_block>
	</body>
</OPS_envelope>
EOF

$ns=$dri->local_object('hosts');
$ns->add('ns1.domaindirect.com',['123.45.67.89']);
$ns->add('ns2.domaindirect.com');

#SKIP: {
#	skip 'dt_array bug', 3;
$rc=$dri->domain_create('yahoo.com',{username => 'daniel', password => 'daniel', contact => $cs, registrant_ip => '216.40.46.115', pure_create => 1, duration => DateTime::Duration->new(years =>7), ns => $ns});
is_string(munge(shift(@R1)),munge($r),'domain_create (custom name servers)');
is($rc->is_success(),0,'domain_create is_success (custom name servers)');
#is($dri->get_info('response_code'),435,'domain_create get_info(response_code)');
#is($dri->get_info('registration_code'),435,'domain_create get_info(registration_code)');
#};

#===Test renew===================================

#pop @R2;

push @R2,<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no'?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
<header>
<version>0.9</version>
</header>
<body>
<data_block>
<dt_assoc>
<item key="protocol">XCP</item>
<item key="action">REPLY</item>
<item key="object">DOMAIN</item>
<item key="attributes">
<dt_assoc>
<item key="registration expiration date">2006-01-08 15:35:00</item>
<item key="auto_renew">1</item>
<item key="admin_email">admin1@example.com</item>
<item key="id">3212624</item>
<item key="order_id">3511417</item>
</dt_assoc>
</item>
<item key="response_text">Command completed successfully</item>
<item key="is_success">1</item>
<item key="response_code">200</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$r=<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
<header>
<version>0.9</version>
</header>
<body>
<data_block>
<dt_assoc>
<item key="action">renew</item>
<item key="object">domain</item>
<item key="protocol">XCP</item>
<item key="registrant_ip">216.40.46.115</item>
<item key="attributes">
<dt_assoc>
<item key="auto_renew">1</item>
<item key="currentexpirationyear">2009</item>
<item key="domain">example.com</item>
<item key="handle">process</item>
<item key="period">5</item>
</dt_assoc>
</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$rc=$dri->domain_renew('example.com',{username => 'daniel', password => 'guessthis', registrant_ip => '216.40.46.115', auto_renew => 1, duration => DateTime::Duration->new(years =>5), current_expiration => DateTime->new( year => 2009, month => 06, day => 27)});
is_string(munge(shift(@R1)),munge($r),'domain_renew');
is($rc->is_success(),1,'domain_renew is_success');
is($dri->get_info('admin_email'),'admin1@example.com','domain_renew get_info(admin_email)');
is(''.$dri->get_info('exDate'),'2006-01-08T15:35:00','domain_info get_info(exDate)');
#is($dri->get_info('registration expiration date'),'2006-12-07 00:00:00','domain_renew get_info(expiration date)');

#===Test revoke===================================

push @R2,<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no'?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
<header>
<version>0.9</version>
</header>
<body>
<data_block>
<dt_assoc>
<item key="protocol">XCP</item>
<item key="action">REPLY</item>
<item key="object">DOMAIN</item>
<item key="is_success">1</item>
<item key="attributes">
<dt_assoc>
<item key="charge">0</item>
<item key="price">undef</item>
</dt_assoc>
</item>
<item key="response_text">Domain test.com revoked successfully.</item>
<item key="response_code">200</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$r=<<"EOF";
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
<header>
<version>0.9</version>
</header>
<body>
<data_block>
<dt_assoc>
<item key="action">revoke</item>
<item key="object">domain</item>
<item key="protocol">XCP</item>
<item key="registrant_ip">216.40.46.115</item>
<item key="attributes">
<dt_assoc>
<item key="domain">example.com</item>
<item key="reseller">$RESELLERID</item>
</dt_assoc>
</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$rc=$dri->domain_delete('example.com',{pure_delete => 1, username => 'daniel', password => 'guessthis', registrant_ip => '216.40.46.115', reseller_id => $RESELLERID});
is_string(munge(shift(@R1)),munge($r),'domain_delete');
is($rc->is_success(),1,'domain_delete is_success');
is($dri->get_info('charge'),0,'domain_renew get_info(charge)');

#===Test transfer initiation===================================

push @R2,<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
<header>
<version>0.9</version>
</header>
<body>
<data_block>
<dt_assoc>
<item key="protocol">XCP</item>
<item key="action">REPLY</item>
<item key="object">DOMAIN</item>
<item key="response_code">200</item>
<item key="response_text">Transfer request has been successfully sent</item>
<item key="is_success">1</item>
<item key="attributes">
<dt_assoc>
<item key="registration_text">Transfer request has been successfully sent</item>
<item key="registration_code">200</item>
<item key="id">3735288</item>
</dt_assoc>
</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$r=<<"EOF";
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
<header>
<version>0.9</version>
</header>
<body>
<data_block>
<dt_assoc>
<item key="action">sw_register</item>
<item key="object">domain</item>
<item key="protocol">XCP</item>
<item key="registrant_ip">10.0.10.19</item>
<item key="attributes">
<dt_assoc>
<item key="contact_set">
   <dt_assoc>
      <item key="admin">
      admin_co
      </item>
      <item key="billing">
      admin_co
      </item>
      <item key="owner">
      admin_co
      </item>
   </dt_assoc>
</item>
<item key="custom_nameservers">0</item>
<item key="custom_tech_contact">0</item>
<item key="domain">yahoo.com</item>
<item key="reg_password">example</item>
<item key="reg_type">transfer</item>
<item key="reg_username">example</item>
</dt_assoc>
</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$rc=$dri->domain_transfer_start('yahoo.com',{username => 'example', password => 'example', contact => $cs, registrant_ip => '10.0.10.19'});
is_string(munge(shift(@R1)),munge($r),'domain_transfer_start');
is($rc->is_success(),1,'domain_transfer_start is_success');
is($dri->get_info('id'),3735288,'domain_transfer_start get_info(id)');

#===Test transfer check===================================

push @R2,<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
<header>
<version>0.9</version>
</header>
<body>
<data_block>
<dt_assoc>
<item key="protocol">XCP</item>
<item key="action">REPLY</item>
<item key="object">DOMAIN</item>
<item key="is_success">1</item>
<item key="response_text">Query successful</item>
<item key="response_code">200</item>
<item key="attributes">
<dt_assoc>
<item key="status">pending_owner</item>
<item key="transferrable">0</item>
<item key="reason">Transfer in progress</item>
<item key="request_address"/>
<item key="unixtime">1115213766</item>
<item key="timestamp">Wed May 4 09:36:06 2005</item>
</dt_assoc>
</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$r=<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
<header>
<version>0.9</version>
</header>
<body>
<data_block>
<dt_assoc>
<item key="action">check_transfer</item>
<item key="object">domain</item>
<item key="protocol">XCP</item>
<item key="registrant_ip">216.40.46.115</item>
<item key="attributes">
<dt_assoc>
<item key="check_status">1</item>
<item key="domain">catmas.com</item>
<item key="get_request_address">1</item>
</dt_assoc>
</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$rc=$dri->domain_transfer_query('catmas.com',{username => 'daniel', password => 'guessthis', registrant_ip => '216.40.46.115'});
is_string(munge(shift(@R1)),munge($r),'domain_transfer_query');
is($rc->is_success(),1,'domain_transfer_query is_success');
is($dri->get_info('transferrable'),0,'domain_transfer_query get_info(transferrable)');
is($dri->get_info('reason'),'Transfer in progress','domain_transfer_query get_info(reason)');
is($dri->get_info('unixtime'),1115213766,'domain_transfer_query get_info(reason)');

#===Test transfer cancel===================================

push @R2,<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
<header>
<version>0.9</version>
</header>
<body>
<data_block>
<dt_assoc>
<item key="protocol">XCP</item>
<item key="action">REPLY</item>
<item key="object">TRANSFER</item>
<item key="response_text">Transfer with order id: 3533098 has been canceled.</item>
<item key="is_success">1</item>
<item key="response_code">200</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$r=<<"EOF";
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
<header>
<version>0.9</version>
</header>
<body>
<data_block>
<dt_assoc>
<item key="action">cancel_transfer</item>
<item key="object">transfer</item>
<item key="protocol">XCP</item>
<item key="registrant_ip">216.40.46.115</item>
<item key="attributes">
<dt_assoc>
<item key="domain">example.com</item>
<item key="reseller">$RESELLERID</item>
</dt_assoc>
</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$rc=$dri->domain_transfer_stop('example.com',{username => 'daniel', password => 'guessthis', registrant_ip => '216.40.46.115', reseller_id => $RESELLERID});
is_string(munge(shift(@R1)),munge($r),'domain_transfer_stop');
is($rc->is_success(),1,'domain_transfer_stop is_success');

exit 0;

