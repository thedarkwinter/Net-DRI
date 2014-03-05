#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use DateTime;
use Test::More tests => 45;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }


our (@R1,@R2);
sub mysend { my ($transport,$count,$msg)=@_; push @R1,$msg->get_body(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string(shift(@R2)); }
sub munge { my $in=shift; $in=~s/>\s*</></sg; chomp($in); return $in; }

my $RESELLERID=''; #'LOGIN';

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->add_registry('OpenSRS');
$dri->target('OpenSRS')->add_current_profile('p1','xcp',{f_send=>\&mysend,f_recv=>\&myrecv,client_login=>'LOGIN',client_password=>'PASSWORD',remote_url=>'http://localhost/'});

my ($r,$rc,$rd,$ns,$cs);

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
            <item key="response_text">Command successful</item>
            <item key="response_code">200</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="page">1</item>
                  <item key="total">2</item>
                  <item key="remainder">0</item>
                  <item key="exp_domains">
                     <dt_array>
                        <item key="0">
                           <dt_assoc>
                              <item key="f_let_expire">N</item>
                              <item key="name">katarina.biz</item>
                              <item key="expiredate">2007-12-18 23:59:59</item>
                              <item key="f_auto_renew">N</item>
                           </dt_assoc>
                        </item>
                        <item key="1">
                           <dt_assoc>
                              <item key="name">kristina.cn</item>
                              <item key="expiredate">2007-12-18 23:59:59</item>
                              <item key="f_let_expire">N</item>
                              <item key="f_auto_renew">N</item>
                           </dt_assoc>
                        </item>
                     </dt_array>
                  </item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF

my $yday=DateTime->from_epoch(epoch => time()-60*60*24)->strftime('%F');
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
            <item key="action">get_domains_by_expiredate</item>
            <item key="object">domain</item>
            <item key="protocol">XCP</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="exp_from">$yday</item>
                  <item key="exp_to">2030-01-01</item>
                  <item key="limit">1000000</item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF
$rc=$dri->account_list_domains();
is_string(munge(shift(@R1)),munge($r),'account_list_domains build');
is($rc->is_success(),1,'account_list_domains is_success');
$rd=$dri->get_info('list','account','domains');
is_deeply($rd,['katarina.biz','kristina.cn'],'account_list_domains get_info(list,account,domains)');

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
            <item key="object">COOKIE</item>
            <item key="response_text">Command Successful</item>
            <item key="is_success">1</item>
            <item key="response_code">200</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="waiting_requests_no">0</item>
                  <item key="permission"/>
                  <item key="cookie">24128866:3210384</item>
                  <item key="domain_count">131</item>
                  <item key="f_owner">1</item>
                  <item key="last_access_time">1082751795</item>
                  <item key="encoding_type"/>
                  <item key="last_ip">10.0.11.215</item>
                  <item key="expiredate">2007-11-25 00:00:00</item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF

push @R2,<<'EOF';
<?xml version='1.0' encoding="UTF-8" standalone="no" ?>
<!DOCTYPE OPS_envelope SYSTEM "ops.dtd">
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
            <item key="response_code">200</item>
            <item key="response_text">Query Successful</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="auto_renew">0</item>
                  <item key="registry_createdate">2006-12-12 21:27:25</item>
                  <item key="registry_expiredate">2007-12-12 21:27:25</item>
                  <item key="registry_updatedate">2006-12-12 21:27:25</item>
                  <item key="sponsoring_rsp">1</item>
                  <item key="expiredate">2007-12-12 21:27:25</item>
                  <item key="let_expire">0</item>
                  <item key="contact_set">
<dt_assoc>
  <item key="owner">
    <dt_assoc>
      <item key="first_name">Owen</item>
      <item key="last_name">Owner</item>
      <item key="phone">+1.4165550123x1902</item>
      <item key="fax">+1.4165550124</item>
      <item key="email">owner@catmas.com</item>
      <item key="org_name">Catmas Inc.</item>
      <item key="address1">32 Catmas Street</item>
      <item key="address2">Suite 500</item>
      <item key="address3">Owner</item>
      <item key="city">SomeCity</item>
      <item key="state">CA</item>
      <item key="country">US</item>
      <item key="postal_code">90210</item>
      <item key="url">http://www.catmas.com</item>
    </dt_assoc>
  </item>
  <item key="admin">
    <dt_assoc>
      <item key="first_name">Adler</item>
      <item key="last_name">Admin</item>
      <item key="phone">+1.4165550123x1812</item>
      <item key="fax">+1.4165550125</item>
      <item key="email">admin@catmas.com</item>
      <item key="org_name">Catmas Inc.</item>
      <item key="address1">32 Catmas Street</item>
      <item key="address2">Suite 100</item>
      <item key="address3">Admin</item>
      <item key="city">SomeCity</item>
      <item key="state">CA</item>
      <item key="country">US</item>
      <item key="postal_code">90210</item>
      <item key="url">http://www.catmas.com</item>
    </dt_assoc>
  </item>
  <item key="billing">
      <dt_assoc>
        <item key="first_name">Bill</item>
        <item key="last_name">Billing</item>
        <item key="phone">+1.4165550123x1248</item>
        <item key="fax">+1.4165550136</item>
        <item key="email">billing@catmas.com</item>
        <item key="org_name">Catmas Inc.</item>
        <item key="address1">32 Catmas Street</item>
        <item key="address2">Suite 200</item>
        <item key="address3">Billing</item>
        <item key="city">SomeCity</item>
        <item key="state">CA</item>
        <item key="country">US</item>
        <item key="postal_code">90210</item>
        <item key="url">http://www.catmas.com</item>
      </dt_assoc>
    </item>
    <item key="tech">
      <dt_assoc>
        <item key="first_name">Tim</item>
        <item key="last_name">Tech</item>
        <item key="phone">+1.4165550123x1243</item>
        <item key="fax">+1.4165550125</item>
        <item key="email">techie@catmas.com</item>
        <item key="org_name">Catmas Inc.</item>
        <item key="address1">32 Catmas Street</item>
        <item key="address2">Suite 100</item>
        <item key="address3">Tech</item>
        <item key="city">SomeCity</item>
        <item key="state">CA</item>
        <item key="country">US</item>
        <item key="postal_code">90210</item>
        <item key="url">http://www.catmas.com</item>
      </dt_assoc>
    </item>
  </dt_assoc>
                  </item>
                  <item key="nameserver_list">
                     <dt_array>
                        <item key="0">
                           <dt_assoc>
                              <item key="ipaddress">21.40.33.21</item>
                              <item key="sortorder">1</item>
                              <item key="name">ns1.domaindirect.com</item>
                           </dt_assoc>
                        </item>
                        <item key="1">
                           <dt_assoc>
                              <item key="ipaddress">207.136.100.142</item>
                              <item key="sortorder">2</item>
                              <item key="name">ns2.domaindirect.com</item>
                           </dt_assoc>
                        </item>
                        <item key="2">
                           <dt_assoc>
                              <item key="ipaddress">24.22.23.28</item>
                              <item key="sortorder">3</item>
                              <item key="name">patrick.mytestingprofile.com</item>
                           </dt_assoc>
                        </item>
                        <item key="3">
                           <dt_assoc>
                              <item key="ipaddress">24.22.23.24</item>
                              <item key="sortorder">4</item>
                              <item key="name">qa1.mytestingprofile.com</item>
                           </dt_assoc>
                        </item>
                        <item key="4">
                           <dt_assoc>
                              <item key="ipaddress">24.22.23.25</item>
                              <item key="sortorder">5</item>
                              <item key="name">qa2.mytestingprofile.com</item>
                           </dt_assoc>
                        </item>
                     </dt_array>
                  </item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF

$rc=$dri->domain_info('whatever.com',{username => 'aaaa', password => 'aaaa', registrant_ip => '216.40.46.115'});
is($rc->is_success(),1,'domain_info is_success');
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
            <item key="action">set</item>
            <item key="object">cookie</item>
            <item key="protocol">XCP</item>
            <item key="registrant_ip">216.40.46.115</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="domain">whatever.com</item>
                  <item key="reg_password">aaaa</item>
                  <item key="reg_username">aaaa</item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF

is_string(munge(shift(@R1)),munge($r),'domain_info build 1/2');
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
            <item key="action">get</item>
            <item key="cookie">24128866:3210384</item>
            <item key="object">domain</item>
            <item key="protocol">XCP</item>
            <item key="registrant_ip">216.40.46.115</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="type">all_info</item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF
is_string(munge(shift(@R1)),munge($r),'domain_info build 2/2');
is($dri->get_info('value','session','cookie'),'24128866:3210384','domain_info set_cookie value');
is($dri->get_info('auto_renew'),0,'domain_info get_info(auto_renew)');
is($dri->get_info('sponsoring_rsp'),1,'domain_info get_info(sponsoring_rsp)');
is($dri->get_info('let_expire'),0,'domain_info get_info(let_expire)');
is(''.$dri->get_info('crDate'),'2006-12-12T21:27:25','domain_info get_info(crDate)');
is(''.$dri->get_info('exDate'),'2007-12-12T21:27:25','domain_info get_info(exDate)');
is(''.$dri->get_info('upDate'),'2006-12-12T21:27:25','domain_info get_info(upDate)');
is(''.$dri->get_info('exDateLocal'),'2007-12-12T21:27:25','domain_info get_info(exDateLocal)');
$ns=$dri->get_info('ns');
is($ns->count(),5,'domain_info get_info(ns) count');
is_deeply([$ns->get_names()],[qw/ns1.domaindirect.com ns2.domaindirect.com patrick.mytestingprofile.com qa1.mytestingprofile.com qa2.mytestingprofile.com/],'domain_info get_info(ns) get_names');
$cs=$dri->get_info('contact');
is($cs->get('registrant')->firstname(),'Owen','domain_info get_info(contact) get(registrant) firstname');
is($cs->get('registrant')->name(),'Owner','domain_info get_info(contact) get(registrant) name');
is($cs->get('admin')->email(),'admin@catmas.com','domain_info get_info(contact) get(admin) email');
is($cs->get('billing')->cc(),'US','domain_info get_info(contact) get(billing) cc');
is($cs->get('tech')->city(),'SomeCity','domain_info get_info(contact) get(tech) city');

#===Contact sets to test registration===================================

my $admin_co=<<'EOF';
<dt_assoc>
   <item key="address1">32 Catmas Street</item>
   <item key="address2">Suite 100</item>
   <item key="address3">Admin</item>
   <item key="city">SomeCity</item>
   <item key="country">US</item>
   <item key="email">admin@example.com</item>
   <item key="fax">+1.4165550125</item>
   <item key="first_name">Adler</item>
   <item key="last_name">Admin</item>
   <item key="org_name">Catmas Inc.</item>
   <item key="phone">+1.4165550123x1812</item>
   <item key="postal_code">90210</item>
   <item key="state">CA</item>
   <item key="url">http://www.catmas.com</item>
</dt_assoc>
EOF

my $defcs=<<"EOF";
<item key="contact_set">
   <dt_assoc>
      <item key="admin">
      $admin_co
      </item>
      <item key="billing">
         <dt_assoc>
            <item key="first_name">Bill</item>
            <item key="last_name">Billing</item>
            <item key="phone">+1.4165550123x1248</item>
            <item key="fax">+1.4165550136</item>
            <item key="email">billing\@example.com</item>
            <item key="org_name">Catmas Inc.</item>
            <item key="address1">32 Catmas Street</item>
            <item key="address2">Suite 200</item>
            <item key="address3">Billing</item>
            <item key="city">SomeCity</item>
            <item key="state">CA</item>
            <item key="country">US</item>
            <item key="postal_code">90210</item>
            <item key="url">http://www.catmas.com</item>
         </dt_assoc>
      </item>
      <item key="owner">
         <dt_assoc>
            <item key="first_name">Owen</item>
            <item key="last_name">Owner</item>
            <item key="phone">+1.4165550123x1902</item>
            <item key="fax">+1.4165550124</item>
            <item key="email">owner\@example.com</item>
            <item key="org_name">Catmas Inc.</item>
            <item key="address1">32 Catmas Street</item>
            <item key="address2">Suite 500</item>
            <item key="address3">Owner</item>
            <item key="city">SomeCity</item>
            <item key="state">CA</item>
            <item key="country">US</item>
            <item key="postal_code">90210</item>
            <item key="url">http://www.catmas.com</item>
         </dt_assoc>
      </item>
      <item key="tech">
         <dt_assoc>
            <item key="first_name">Tim</item>
            <item key="last_name">Tech</item>
            <item key="phone">+1.4165550123x1243</item>
            <item key="fax">+1.4165550125</item>
            <item key="email">techie\@example.com</item>
            <item key="org_name">Catmas Inc.</item>
            <item key="address1">32 Catmas Street</item>
            <item key="address2">Suite 100</item>
            <item key="address3">Tech</item>
            <item key="city">SomeCity</item>
            <item key="state">CA</item>
            <item key="country">US</item>
            <item key="postal_code">90210</item>
            <item key="url">http://www.catmas.com</item>
          </dt_assoc>
      </item>
   </dt_assoc>
</item>
EOF

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
<item key="is_success">1</item>
<item key="response_code">200</item>
<item key="response_text">
Domain registration successfully completed.
WHOIS Privacy service cannot be applied to your account.
Please contact X for more information.
Domain successfully locked.
</item>
<item key="attributes">
<dt_assoc>
<item key="registration_text">Domain registration
successfully completed. WHOIS Privacy service cannot be applied to your
account. Please contact X for more
information. Domain successfully locked.</item>
<item key="registration_code">200</item>
<item key="id">3735281</item>
<item key="cancelled_orders">
<dt_array>
<item key="0">3764860</item>
<item key="1">3764861</item>
</dt_array>
</item>
<item key="admin_email">jsmith@catmas.com</item>
<item key="whois_privacy">
<dt_assoc>
<item key="response_text">WHOIS_Privacy service
cannot be applied to your account. Please contact X
for more information.</item>
<item key="order_id"/>
<item key="response_code">300</item>
<item key="is_success">0</item>
</dt_assoc>
</item>
</dt_assoc>
</item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
EOF

$cs=$dri->local_object('contactset');
my $co=$dri->local_object('contact');
$co->srid('daniel'); # Portfolio user name for OpenSRS?
$co->auth('daniel'); # Portfolio password for OpenSRS?
$co->name('Admin'); # Should be firstname, name => lastname.
$co->firstname('Adler');
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
      $admin_co
      </item>
      <item key="billing">
      $admin_co
      </item>
      <item key="owner">
      $admin_co
      </item>
   </dt_assoc>
</item>
					<item key="custom_nameservers">0</item>
					<item key="custom_tech_contact">0</item>
					<item key="domain">example-nsi.net</item>
					<item key="period">10</item>
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
      $admin_co
      </item>
      <item key="billing">
      $admin_co
      </item>
      <item key="owner">
      $admin_co
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
      $admin_co
      </item>
      <item key="billing">
      $admin_co
      </item>
      <item key="owner">
      $admin_co
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

