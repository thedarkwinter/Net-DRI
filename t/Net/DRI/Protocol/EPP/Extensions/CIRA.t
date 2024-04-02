#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 17;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('CIRA::CA');
$dri->target('CIRA::CA')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$co,$co2,$h,$toc);

####################################################################################################
## Contacts

$R2='';
$co=$dri->local_object('contact');
$co->srid('furycontact');
$co->name('Fury Contact');
$co->street(['123 Main Street']);
$co->city('Ottawa');
$co->sp('ON');
$co->pc('K1S5K5');
$co->cc('CA');
$co->voice('+1.6121221222');
$co->email('furycontact@fury.ca');
$co->auth({ pw => 'password' });
$co->lang('en');
$co->legal_form('CCT');
$co->agreement({version => 'default', signed => 1});
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>furycontact</contact:id><contact:postalInfo type="loc"><contact:name>Fury Contact</contact:name><contact:addr><contact:street>123 Main Street</contact:street><contact:city>Ottawa</contact:city><contact:sp>ON</contact:sp><contact:pc>K1S5K5</contact:pc><contact:cc>CA</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.6121221222</contact:voice><contact:email>furycontact@fury.ca</contact:email><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:create></create><extension><fury:create xmlns:fury="urn:ietf:params:xml:ns:fury-2.1" xsi:schemaLocation="urn:ietf:params:xml:ns:fury-2.1 fury-2.1.xsd"><fury:properties><fury:property><fury:key>AGREEMENT_VERSION</fury:key><fury:value default="true"/></fury:property><fury:property><fury:key>CPR</fury:key><fury:value>CCT</fury:value></fury:property><fury:property><fury:key>LANGUAGE</fury:key><fury:value>EN</fury:value></fury:property></fury:properties></fury:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');


$R2=$E1.'<response>'.r().'
<resData>
<contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0">
<contact:id>furycontact</contact:id>
<contact:roid>105-CIRA</contact:roid>
<contact:status s="ok"/>
<contact:postalInfo type="loc">
<contact:name>Fury Contact</contact:name>
<contact:addr>
<contact:street>123 Main Street</contact:street>
<contact:city>Ottawa</contact:city>
<contact:sp>ON</contact:sp>
<contact:pc>K1S5K5</contact:pc>
<contact:cc>CA</contact:cc>
</contact:addr>
</contact:postalInfo>
<contact:voice>+1.6121221222</contact:voice>
<contact:email>furycontact@fury.ca</contact:email>
<contact:clID>ca_fury</contact:clID>
<contact:crID>ca_fury</contact:crID>
<contact:crDate>2018-03-21T12:52:12.064Z</contact:crDate>
<contact:upID>ca_fury</contact:upID>
<contact:upDate>2018-03-21T12:53:30.867Z</contact:upDate>
<contact:authInfo>
<contact:pw>password</contact:pw>
</contact:authInfo>
</contact:infData>
</resData>
<extension>
<fury:info xmlns:fury="urn:ietf:params:xml:ns:fury-2.1">
<fury:properties>
<fury:property>
<fury:key>LANGUAGE</fury:key>
<fury:value>en</fury:value>
</fury:property>
<fury:property>
<fury:key>CPR</fury:key>
<fury:value>CCT</fury:value>
</fury:property>
<fury:property>
<fury:key>AGREEMENT_TIMESTAMP</fury:key>
<fury:value>2018-03-21T12:52:12.064Z</fury:value>
</fury:property>
<fury:property>
<fury:key>AGREEMENT_VERSION</fury:key>
<fury:value>2.0</fury:value>
</fury:property>
</fury:properties>
</fury:info>
</extension>
'.$TRID.'</response>'.$E2;
$rc=$dri->contact_info($dri->local_object('contact')->srid('furycontact'));
$co=$rc->get_data('contact','furycontact','self');
is($co->lang(),'en','contact_info lang');
is($co->legal_form(),'CCT','contact_info legal_form');
is_deeply($co->agreement(),{signed=>1,version=>'2.0',timestamp=>'2018-03-21T12:52:12'},'contact_info agreement');

$co=$dri->local_object('contact')->srid('agreed2');
$co2=$dri->local_object('contact');
$co2->email('noprops@domain.fr');
$toc=$dri->local_object('changes');
$toc->set('info',$co2);
$toc->add('lang','fr');
$toc->del('lang','en');
$rc=$dri->contact_update($co, $toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>agreed2</contact:id><contact:chg><contact:email>noprops@domain.fr</contact:email></contact:chg></contact:update></update><extension><fury:update xmlns:fury="urn:ietf:params:xml:ns:fury-2.1" xsi:schemaLocation="urn:ietf:params:xml:ns:fury-2.1 fury-2.1.xsd"><fury:add><fury:properties><fury:property><fury:key>LANGUAGE</fury:key><fury:value>FR</fury:value></fury:property></fury:properties></fury:add><fury:rem><fury:properties><fury:property><fury:key>LANGUAGE</fury:key><fury:value>EN</fury:value></fury:property></fury:properties></fury:rem></fury:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2, 'contact_update build');

# ####################################################################################################
## Domain commands

my $cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('furycontact'),'registrant');
$cs->add($dri->local_object('contact')->srid('furycontact'),'admin');
$rc=$dri->domain_create('xn--test-dmain-wbb.ca',{pure_create=>1, auth=>{pw=>'password'},contact=>$cs,privacy=>1});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--test-dmain-wbb.ca</domain:name><domain:registrant>furycontact</domain:registrant><domain:contact type="admin">furycontact</domain:contact><domain:authInfo><domain:pw>password</domain:pw></domain:authInfo></domain:create></create><extension><fury:create xmlns:fury="urn:ietf:params:xml:ns:fury-2.1" xsi:schemaLocation="urn:ietf:params:xml:ns:fury-2.1 fury-2.1.xsd"><fury:properties><fury:property><fury:key>PRIVACY</fury:key><fury:value>PRIVATE</fury:value></fury:property></fury:properties></fury:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2, 'domain_create build');

$R2=$E1.'<response>'.r().'
<resData>
<domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
<domain:name>xn--test-dmain-wbb.ca</domain:name>
<domain:roid>106-CIRA</domain:roid>
<domain:status s="inactive"/>
<domain:registrant>furycontact</domain:registrant>
<domain:contact type="admin">furycontact</domain:contact>
<domain:clID>ca_fury</domain:clID>
<domain:crID>ca_fury</domain:crID>
<domain:crDate>2018-03-21T12:52:37.823Z</domain:crDate>
<domain:upID>CIRA_RAR_1</domain:upID>
<domain:upDate>2018-03-26T12:56:17.473Z</domain:upDate>
<domain:exDate>2019-03-21T12:52:37.823Z</domain:exDate>
<domain:authInfo>
<domain:pw>password</domain:pw>
</domain:authInfo>
</domain:infData>
</resData>
<extension>
<idn:data xmlns:idn="urn:ietf:params:xml:ns:idn-1.0">
<idn:table>fr</idn:table>
<idn:uname>test-dômain.ca</idn:uname>
</idn:data>
<fury:info xmlns:fury="urn:ietf:params:xml:ns:fury-2.1">
<fury:properties>
<fury:property>
<fury:key>PRIVACY</fury:key>
<fury:value>PRIVATE</fury:value>
</fury:property>
</fury:properties>
<fury:bundle>
<fury:name>test-domain.ca</fury:name>
<fury:domains>
<fury:name>xn--tst-domin-w1a6g.ca</fury:name>
<fury:name>xn--tst-dmain-b4a9j.ca</fury:name>
</fury:domains>
</fury:bundle>
</fury:info>
<fury-rgp:rgpInfo xmlns:fury-rgp="urn:ietf:params:xml:ns:fury-rgp-1.0">
<fury-rgp:rgpStatusEnd>2018-11-03T19:22:29.273Z
</fury-rgp:rgpStatusEnd>
</fury-rgp:rgpInfo>
</extension>
'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('xn--test-dmain-wbb.ca');
is($rc->get_data('domain','xn--test-dmain-wbb.ca','privacy'), 1, 'domain_info parse privacy');
is($rc->get_data('domain','xn--test-dmain-wbb.ca','contact')->get('registrant')->whois_display(), 'PRIVATE', 'domain_info parse registrant whois_display');
is_deeply($rc->get_data('domain','xn--test-dmain-wbb.ca','variants'), ['test-domain.ca', 'xn--tst-domin-w1a6g.ca', 'xn--tst-dmain-b4a9j.ca'], 'domain_info parse variants');
is($rc->get_data('domain','xn--test-dmain-wbb.ca','rgp_status_end'), '2018-11-03T19:22:29', 'domain_info parse rgp_status_end');


$toc=$dri->local_object('changes');
$toc->set('auth', { pw => 'password2' });
$toc->set('privacy', 0);
$rc=$dri->domain_update('xn--nwtst-bsac.ca', $toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--nwtst-bsac.ca</domain:name><domain:chg><domain:authInfo><domain:pw>password2</domain:pw></domain:authInfo></domain:chg></domain:update></update><extension><fury:update xmlns:fury="urn:ietf:params:xml:ns:fury-2.1" xsi:schemaLocation="urn:ietf:params:xml:ns:fury-2.1 fury-2.1.xsd"><fury:add><fury:properties><fury:property><fury:key>PRIVACY</fury:key><fury:value>PUBLIC</fury:value></fury:property></fury:properties></fury:add><fury:rem><fury:properties><fury:property><fury:key>PRIVACY</fury:key><fury:value>PRIVATE</fury:value></fury:property></fury:properties></fury:rem></fury:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2, 'domain_update build');

####################################################################################################
## Agreement

$R2=$E1.'<response>'.r().'
<extension>
<fury:response xmlns:fury="urn:ietf:params:xml:ns:fury-2.1">
<fury:infData>
<fury:language>en</fury:language>
<fury:properties>
<fury:property>
<fury:key>AGREEMENT_VERSION</fury:key>
<fury:localizedKey>Agreement Version</fury:localizedKey>
<fury:propertyValues>
<fury:propertyValue>
<fury:value default="true">2.0</fury:value>
<fury:localizedValue>2.0</fury:localizedValue>
<fury:localizedDetail>
&lt;html>
&lt;head>
&lt;title>Registrant Agreement: Version 2.0&lt;/title>
&lt;/head>
&lt;body>
&lt;h3>Registrant Agreement&lt;br />
Version 2.0, October 12, 2010
&lt;/h3>
&lt;p>This agreement (the "Agreement") is between you (the "Registrant") and the
Canadian Internet Registration Authority ("CIRA").
&lt;/p>
&lt;p>In consideration of the registration by CIRA of the Domain Name applied for by
the Registrant in the name of the Registrant, and other good and valuable
consideration,
the receipt and adequacy of which are hereby acknowledged, CIRA and the Registrant
agree as follows:
&lt;/p>
&lt;h3>ARTICLE 1&lt;br />
... (remaining agreement displays here)
</fury:localizedDetail>
<fury:propertyValueAttributes>
<fury:propertyValueAttribute>
<fury:key>expiry_date</fury:key>
<fury:value>3000-01-01T00:00:00.000Z</fury:value>
</fury:propertyValueAttribute>
<fury:propertyValueAttribute>
<fury:key>effective_date</fury:key>
<fury:value>2018-03-14T20:04:10.618Z</fury:value>
</fury:propertyValueAttribute>
<fury:propertyValueAttribute>
<fury:key>enabled</fury:key>
<fury:value>true</fury:value>
</fury:propertyValueAttribute>
</fury:propertyValueAttributes>
</fury:propertyValue>
</fury:propertyValues>
<fury:propertyAttributes>
<fury:propertyAttribute>
<fury:key>entitytype</fury:key>
<fury:value>contact</fury:value>
</fury:propertyAttribute>
<fury:propertyAttribute>
<fury:key>removable</fury:key>
<fury:value>false</fury:value>
</fury:propertyAttribute>
<fury:propertyAttribute>
<fury:key>propertytype</fury:key>
<fury:value>SINGLEENUM</fury:value>
</fury:propertyAttribute>
<fury:propertyAttribute>
<fury:key>updatable</fury:key>
<fury:value>true</fury:value>
</fury:propertyAttribute>
</fury:propertyAttributes>
</fury:property>
</fury:properties>
</fury:infData>
</fury:response>
</extension>'.$TRID.'</response>'.$E2;
$rc=$dri->agreement_info('en');
is_string($R1,$E1.'<extension><fury:command xmlns:fury="urn:ietf:params:xml:ns:fury-2.1" xsi:schemaLocation="urn:ietf:params:xml:ns:fury-2.1 fury-2.1.xsd"><fury:info><fury:language>en</fury:language><fury:properties><fury:property><fury:key>AGREEMENT_VERSION</fury:key><fury:value default="true"/></fury:property></fury:properties></fury:info></fury:command></extension>'.$E2, 'agreement_info build');
is($rc->get_data('agreement', 'cira', 'language'), 'en', 'agreement_info parse language');
is($rc->get_data('agreement', 'cira', 'version'), '2.0', 'agreement_info parse version');
like($rc->get_data('agreement', 'cira', 'content'), qr/Registrant Agreement: Version 2.0/, 'agreement_info parse content');

####################################################################################################
## Notifications

# $R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ id="1901" count="108"><qDate>2010-01-20T16:58:17.0Z</qDate><msg lang="en">omain example.ca has been transferred to another Registrar</msg></msgQ><resData><poll:extData xmlns:poll="urn:ietf:params:xml:ns:poll-1.0"><msgID>3027</msgID><domainName>example.ca</domainName></poll:extData></resData>'.$TRID.'</response>'.$E2;
# $rc=$dri->message_retrieve();
# is($rc->get_data('message',1901,'msg_id'),'3027','notification parsing msg_id');
# is($rc->get_data('message',1901,'domain_name'),'example.ca','notification parsing domain_name');

########################
### Cira Fury eco Domain
$dri->add_registry('NGTLD',{provider=>'fury'});
$dri->target('fury')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

$R2='';
$co=$dri->local_object('contact');
$co->srid('furycontact2');
$co->name('Fury Contact2');
$co->street(['123 Main Street']);
$co->city('Ottawa');
$co->sp('ON');
$co->pc('K1S5K5');
$co->cc('CA');
$co->voice('+1.6121221222');
$co->email('furycontact@fury.eco');
$co->auth({ pw => 'password' });
$co->lang('en');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>furycontact2</contact:id><contact:postalInfo type="loc"><contact:name>Fury Contact2</contact:name><contact:addr><contact:street>123 Main Street</contact:street><contact:city>Ottawa</contact:city><contact:sp>ON</contact:sp><contact:pc>K1S5K5</contact:pc><contact:cc>CA</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>Fury Contact2</contact:name><contact:addr><contact:street>123 Main Street</contact:street><contact:city>Ottawa</contact:city><contact:sp>ON</contact:sp><contact:pc>K1S5K5</contact:pc><contact:cc>CA</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.6121221222</contact:voice><contact:email>furycontact@fury.eco</contact:email><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');

$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('furycontact2'),'registrant');
$cs->add($dri->local_object('contact')->srid('furycontact2'),'admin');
$rc=$dri->domain_create('test.eco',{pure_create=>1, auth=>{pw=>'password'},contact=>$cs});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.eco</domain:name><domain:registrant>furycontact2</domain:registrant><domain:contact type="admin">furycontact2</domain:contact><domain:authInfo><domain:pw>password</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2, 'domain_create build');


exit 0;
