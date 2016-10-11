#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use DateTime;
use DateTime::Duration;

use Test::More tests => 121;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1 = '<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2 = '</epp>';
our $TRID = '<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
my ($dri, $rc, $s, $d, $dh, @c);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $ok=eval {
  $dri = Net::DRI->new({cache_ttl => 10});
  $dri->{trid_factory} = sub { return 'ABC-12345'; };
  $dri->add_registry('CZ');
  $dri->target('CZ')->add_current_profile('p1', 'epp', {f_send => \&mysend, f_recv => \&myrecv});
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

####################################################################################################
###### Contact operations

## Contact check
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><contact:chkData xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:cd><contact:id avail="0">ID064561</contact:id><contact:reason>already registered.</contact:reason></contact:cd></contact:chkData></resData>' . $TRID . '</response>' . $E2;

my $c = $dri->local_object('contact');
$c->srid('ID064561');
$ok=eval {
  $rc = $dri->contact_check($c);
  1;
};

if (!$ok) {
  my $err=$@;
  if (ref $@ eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'contact check is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><contact:check xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:id>ID064561</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>' . $E2, 'contact check build xml');
is($dri->get_info('action'),'check','contact check action');
is($dri->get_info('exist'),1,'contact check exist');
is($dri->get_info('exist','contact','ID064561'),1,'contact check exist from cache');

## Contact delete
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><contact:chkData xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:cd><contact:id avail="0">ID064561</contact:id><contact:reason>already registered.</contact:reason></contact:cd></contact:chkData></resData>' . $TRID . '</response>' . $E2;

$c = $dri->local_object('contact');
$c->srid('ID064562');

$ok=eval {
  $rc = $dri->contact_delete($c);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $@ eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'contact delete is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><contact:delete xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:id>ID064562</contact:id></contact:delete></delete><clTRID>ABC-12345</clTRID></command>' . $E2, 'contact delete build xml');

## Contact create
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><contact:creData xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:id>TL1-CZ</contact:id><contact:crDate>2008-04-25T18:20:51+02:00</contact:crDate></contact:creData></resData>' . $TRID . '</response>' . $E2;

$c = $dri->local_object('contact');
$c->srid('TL1-CZ');
$c->name('Tonnerre Lombard');
$c->org('SyGroup GmbH');
$c->street(['Gueterstrasse 86']);
$c->city('Basel');
$c->sp('BS');
$c->pc('4053');
$c->cc('CH');
$c->voice('+41.61338033');
$c->fax('+41.613831467');
$c->email('tonnerre.lombard@sygroup.ch');
$c->auth({pw => 'blablabla'});

$ok=eval {
  $rc = $dri->contact_create($c);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $@ eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'contact create is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:id>TL1-CZ</contact:id><contact:postalInfo><contact:name>Tonnerre Lombard</contact:name><contact:org>SyGroup GmbH</contact:org><contact:addr><contact:street>Gueterstrasse 86</contact:street><contact:city>Basel</contact:city><contact:sp>BS</contact:sp><contact:pc>4053</contact:pc><contact:cc>CH</contact:cc></contact:addr></contact:postalInfo><contact:voice>+41.61338033</contact:voice><contact:fax>+41.613831467</contact:fax><contact:email>tonnerre.lombard@sygroup.ch</contact:email></contact:create></create><clTRID>ABC-12345</clTRID></command>' . $E2, 'contact create build xml');
is($dri->get_info('crDate', 'contact', 'TL1-CZ'), '2008-04-25T18:20:51', 'contact create crdate');

## Contact create disclose + (vat + ident)
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><contact:creData xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:id>ID0561</contact:id><contact:crDate>2016-07-25T11:47:47+02:00</contact:crDate></contact:creData></resData>' . $TRID . '</response>' . $E2;

$c = $dri->local_object('contact');
$c->srid('ID064561');
$c->name('Jan Novak');
$c->org('Firma s.r.o.');
$c->street(['Narodni trida 1230/12']);
$c->city('Praha');
$c->pc('12000');
$c->cc('CZ');
$c->voice('+420.222745111');
$c->fax('+420.222745111');
$c->email('info@mymail.cz');
$c->disclose({voice=>0,vat=>0,identity=>0,alt_email=>0});
$c->vat('7035555556'); # VAT Number of the legal entity
$c->identity({type=>'op', value=>'8888888856'}); # the identity of the legal entity
$c->alt_email('info@mymail.cz'); # the alternate notification email of the legal entity
$c->auth({pw => 'mypassword'});

$ok=eval {
  $rc = $dri->contact_create($c);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $@ eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'contact create disclose + (vat + ident) is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:id>ID064561</contact:id><contact:postalInfo><contact:name>Jan Novak</contact:name><contact:org>Firma s.r.o.</contact:org><contact:addr><contact:street>Narodni trida 1230/12</contact:street><contact:city>Praha</contact:city><contact:pc>12000</contact:pc><contact:cc>CZ</contact:cc></contact:addr></contact:postalInfo><contact:voice>+420.222745111</contact:voice><contact:fax>+420.222745111</contact:fax><contact:email>info@mymail.cz</contact:email><contact:vat>7035555556</contact:vat><contact:ident type="op">8888888856</contact:ident><contact:notifyEmail>info@mymail.cz</contact:notifyEmail><contact:disclose flag="0"><contact:voice/><contact:vat/><contact:ident/><contact:notifyEmail/></contact:disclose></contact:create></create><clTRID>ABC-12345</clTRID></command>' . $E2, 'contact create disclose + (vat + ident) build xml');
is($dri->get_info('crDate', 'contact', 'ID0561'), '2016-07-25T11:47:47', 'contact create disclose + (vat + ident) crdate');

## Contact info
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><contact:infData xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:id>TL2-CZ</contact:id><contact:roid>C0000146169-CZ</contact:roid><contact:status s="ok">Objekt is without restrictions</contact:status><contact:postalInfo><contact:name>Tonnerre Lombard</contact:name><contact:org>SyGroup GmbH</contact:org><contact:addr><contact:street>Gueterstrasse 86</contact:street><contact:city>Basel</contact:city><contact:sp>Basel-Stadt</contact:sp><contact:pc>4053</contact:pc><contact:cc>CH</contact:cc></contact:addr></contact:postalInfo><contact:voice>+41.61338033</contact:voice><contact:fax>+41.613831467</contact:fax><contact:email>tonnerre.lombard@sygroup.ch</contact:email><contact:clID>REG-FRED_A</contact:clID><contact:crID>REG-FRED_A</contact:crID><contact:crDate>2008-04-25T18:20:51+02:00</contact:crDate><contact:upID>REG-FRED_A</contact:upID><contact:upDate>2008-04-25T18:29:12+02:00</contact:upDate><contact:authInfo>blablabla</contact:authInfo></contact:infData></resData>' . $TRID . '</response>' . $E2;

$c = $dri->local_object('contact');
$c->srid('TL2-CZ');

$ok=eval {
  $rc = $dri->contact_info($c);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'contact info is_success');
$c = $dri->get_info('self', 'contact', 'TL2-CZ');
is(ref($c), 'Net::DRI::Data::Contact::CZ', 'contact info type');
is($c->srid(), 'TL2-CZ', 'contact info srid');
is($c->roid(), 'C0000146169-CZ', 'contact info roid');
is($c->name(), 'Tonnerre Lombard', 'contact info name');
is($c->org(), 'SyGroup GmbH', 'contact info org');
is_deeply(scalar $c->street(), ['Gueterstrasse 86'], 'contact info street');
is($c->city(), 'Basel', 'contact info city');
is($c->sp(), 'Basel-Stadt', 'contact info sp');
is($c->pc(), '4053', 'contact info pc');
is($c->voice(), '+41.61338033', 'contact info voice');
is($c->fax(), '+41.613831467', 'contact info fax');
is($c->email(), 'tonnerre.lombard@sygroup.ch', 'contact info email');
is($c->auth()->{pw}, 'blablabla', 'contact info authcode');

## Contact info + (vat + ident) + disclose
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><contact:infData xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:id>ID064561</contact:id><contact:roid>C0000842892-CZ</contact:roid><contact:status s="ok">Objekt is without restrictions</contact:status><contact:postalInfo><contact:name>Jan Novak</contact:name><contact:org>Firma s.r.o.</contact:org><contact:addr><contact:street>Narodni trida 1230/12</contact:street><contact:city>Praha</contact:city><contact:pc>12000</contact:pc><contact:cc>CZ</contact:cc></contact:addr></contact:postalInfo><contact:voice>+420.222745111</contact:voice><contact:fax>+420.222745111</contact:fax><contact:email>info@mymail.cz</contact:email><contact:clID>REG-FRED_A</contact:clID><contact:crID>REG-FRED_A</contact:crID><contact:crDate>2016-07-25T10:50:37+02:00</contact:crDate><contact:authInfo>mypassword</contact:authInfo><contact:disclose flag="0"><contact:voice /><contact:vat /><contact:ident /><contact:notifyEmail /></contact:disclose><contact:vat>7035555556</contact:vat><contact:ident type="op">8888888856</contact:ident><contact:notifyEmail>info@mymail.cz</contact:notifyEmail></contact:infData></resData>' . $TRID . '</response>' . $E2;

$c = $dri->local_object('contact');
$c->srid('ID064561');

$ok=eval {
  $rc = $dri->contact_info($c);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'contact info (vat + ident) is_success');
$c = $dri->get_info('self', 'contact', 'ID064561');
is(ref($c), 'Net::DRI::Data::Contact::CZ', 'contact info (vat + ident) type');
is($c->srid(), 'ID064561', 'contact info (vat + ident) srid');
is($c->roid(), 'C0000842892-CZ', 'contact info (vat + ident) roid');
is($c->name(), 'Jan Novak', 'contact info (vat + ident) name');
is($c->org(), 'Firma s.r.o.', 'contact info (vat + ident) org');
is_deeply(scalar $c->street(), ['Narodni trida 1230/12'], 'contact info (vat + ident) street');
is($c->city(), 'Praha', 'contact info (vat + ident) city');
is($c->pc(), '12000', 'contact info (vat + ident) pc');
is($c->voice(), '+420.222745111', 'contact info (vat + ident) voice');
is($c->fax(), '+420.222745111', 'contact info (vat + ident) fax');
is($c->email(), 'info@mymail.cz', 'contact info (vat + ident) email');
is($c->vat(), '7035555556', 'contact info (vat + ident) vat number');
is($c->identity()->{type}, 'op', 'contact info (vat + ident) identity type');
is($c->identity()->{value}, '8888888856', 'contact info (vat + ident) identity value');

## Contact update
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

my $todo = $dri->local_object('changes');
$c = $dri->local_object('contact');
$c->srid('TL2-CZ');
$c->street(['Gueterstrasse 86']);
$c->city('Basel');
$c->sp('BS');
$c->fax(undef);
$c->auth({pw => 'bliblablu'});
$todo->set('info', $c);

$ok=eval {
  $rc = $dri->contact_update($c, $todo);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'contact update is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:id>TL2-CZ</contact:id><contact:chg><contact:postalInfo><contact:addr><contact:street>Gueterstrasse 86</contact:street><contact:city>Basel</contact:city><contact:sp>BS</contact:sp></contact:addr></contact:postalInfo></contact:chg></contact:update></update><clTRID>ABC-12345</clTRID></command></epp>', 'contact update build xml');

## Contact update vat + ident
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

$todo = $dri->local_object('changes');
$c = $dri->local_object('contact');
$c->srid('TL2-CZ');
$c->street(['Gueterstrasse 86']);
$c->city('Basel');
$c->sp('BS');
$c->fax(undef);
$c->auth({pw => 'bliblablu'});
$c->vat('7035555556'); # VAT Number of the legal entity
$c->identity({type=>'op', value=>'8888888856'}); # the identity of the legal entity
$c->alt_email('info@mymail.cz'); # the alternate notification email of the legal entity
$todo->set('info', $c);

$ok=eval {
  $rc = $dri->contact_update($c, $todo);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'contact update (vat + ident) is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="http://www.nic.cz/xml/epp/contact-1.6" xsi:schemaLocation="http://www.nic.cz/xml/epp/contact-1.6 contact-1.6.1.xsd"><contact:id>TL2-CZ</contact:id><contact:chg><contact:postalInfo><contact:addr><contact:street>Gueterstrasse 86</contact:street><contact:city>Basel</contact:city><contact:sp>BS</contact:sp></contact:addr></contact:postalInfo><contact:vat>7035555556</contact:vat><contact:ident type="op">8888888856</contact:ident><contact:notifyEmail>info@mymail.cz</contact:notifyEmail></contact:chg></contact:update></update><clTRID>ABC-12345</clTRID></command></epp>', 'contact update (vat + ident) build xml');

####################################################################################################
######### Domain operations

## Domain create
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:creData xmlns:domain="http://www.nic.cz/xml/epp/domain-1.4" xsi:schemaLocation="http://www.nic.cz/xml/epp/domain-1.4 domain-1.4.xsd"><domain:name>sygroup.cz</domain:name><domain:crDate>2008-05-07T14:31:26+02:00</domain:crDate><domain:exDate>2009-05-07</domain:exDate></domain:creData></resData>' . $TRID . '</response>' . $E2;

my $cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('SG1-CZ'), 'registrant');
$cs->add($dri->local_object('contact')->srid('SK1-CZ'), 'admin');
$cs->add($dri->local_object('contact')->srid('SL1-CZ'), 'tech');

$ok=eval {
  $rc = $dri->domain_create('sygroup.cz', {
    pure_create =>  1,
    contact =>  $cs,
    nsset =>  'nameservers',
    duration =>  DateTime::Duration->new(years => 2),
    auth =>    { pw => 'yumyumyum' }
  });
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'domain create is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="http://www.nic.cz/xml/epp/domain-1.4" xsi:schemaLocation="http://www.nic.cz/xml/epp/domain-1.4 domain-1.4.xsd"><domain:name>sygroup.cz</domain:name><domain:period unit="y">2</domain:period><domain:nsset>nameservers</domain:nsset><domain:registrant>SG1-CZ</domain:registrant><domain:admin>SK1-CZ</domain:admin><domain:authInfo>yumyumyum</domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>' . $E2, 'domain create build xml');
is($dri->get_info('crDate', 'domain', 'sygroup.cz'), '2008-05-07T14:31:26','domain create crdate');
is($dri->get_info('exDate', 'domain', 'sygroup.cz'), '2009-05-07T00:00:00','domain create exdate');

## Domain info
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData xmlns:domain="http://www.nic.cz/xml/epp/domain-1.4" xsi:schemaLocation="http://www.nic.cz/xml/epp/domain-1.4 domain-1.4.xsd"><domain:name>syhosting.cz</domain:name><domain:roid>D0000152990-CZ</domain:roid><domain:status s="outzone">Domain is not generated into zone</domain:status><domain:registrant>TK1-CZ</domain:registrant><domain:admin>TL1-CZ</domain:admin><domain:clID>REG-FRED_A</domain:clID><domain:crID>REG-FRED_A</domain:crID><domain:crDate>2008-05-07T14:31:26+02:00</domain:crDate><domain:exDate>2009-05-07</domain:exDate><domain:authInfo>gnagnagna</domain:authInfo></domain:infData></resData>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $dri->domain_info('syhosting.cz');
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'domain info is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="http://www.nic.cz/xml/epp/domain-1.4" xsi:schemaLocation="http://www.nic.cz/xml/epp/domain-1.4 domain-1.4.xsd"><domain:name>syhosting.cz</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>', 'domain info build xml');
is($dri->get_info('name', 'domain', 'syhosting.cz'), 'syhosting.cz','domain_info name');
is($dri->get_info('roid', 'domain', 'syhosting.cz'), 'D0000152990-CZ','domain_info roid');
$cs = $dri->get_info('contact', 'domain', 'syhosting.cz');
is_deeply([$cs->types()], [qw(admin registrant)], 'domain_info contact types');
is($cs->get('admin')->srid(), 'TL1-CZ', 'domain_info contact admin');
is($cs->get('registrant')->srid(), 'TK1-CZ', 'domain_info contact registrant');
is($dri->get_info('crDate', 'domain', 'syhosting.cz'), '2008-05-07T14:31:26','domain_info crDate');
is($dri->get_info('crID', 'domain', 'syhosting.cz'), 'REG-FRED_A','domain_info crID');
is($dri->get_info('exDate', 'domain', 'syhosting.cz'), '2009-05-07T00:00:00','domain_info exDate');
is($dri->get_info('clID', 'domain', 'syhosting.cz'), 'REG-FRED_A','domain_info clID');
is($dri->get_info('auth', 'domain', 'syhosting.cz')->{pw}, 'gnagnagna','domain_info auth');

## Domain renew
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:renData xmlns:domain="http://www.nic.cz/xml/epp/domain-1.4" xsi:schemaLocation="http://www.nic.cz/xml/epp/domain-1.4 domain-1.4.xsd"><domain:name>sybla.cz</domain:name><domain:exDate>2010-05-07</domain:exDate></domain:renData></resData>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $dri->domain_renew('sybla.cz',
    { duration => DateTime::Duration->new(years => 2), current_expiration => DateTime->new(year => 2008, month => 5, day => 7) });
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'domain renew is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><renew><domain:renew xmlns:domain="http://www.nic.cz/xml/epp/domain-1.4" xsi:schemaLocation="http://www.nic.cz/xml/epp/domain-1.4 domain-1.4.xsd"><domain:name>sybla.cz</domain:name><domain:curExpDate>2008-05-07</domain:curExpDate><domain:period unit="y">2</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command></epp>', 'domain renew build xml');

## Domain check
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:chkData xmlns:domain="http://www.nic.cz/xml/epp/domain-1.4" xsi:schemaLocation="http://www.nic.cz/xml/epp/domain-1.4 domain-1.4.1.xsd"><domain:cd><domain:name avail="1">sybla.cz</domain:name></domain:cd></domain:chkData></resData>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $dri->domain_check('sybla.cz');
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'domain check is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><domain:check xmlns:domain="http://www.nic.cz/xml/epp/domain-1.4" xsi:schemaLocation="http://www.nic.cz/xml/epp/domain-1.4 domain-1.4.xsd"><domain:name>sybla.cz</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command></epp>', 'domain check build xml');

## Domain update
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

$todo = $dri->local_object('changes');
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('TL1-TZ'), 'admin');
$todo->del('contact', $cs);
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DA1-TZ'), 'admin');
$todo->add('contact', $cs);
$todo->set('nsset', 'alfredservers');
$todo->set('auth', { pw => 'coincoin' });

$ok=eval {
  $rc = $dri->domain_update('sybla.cz', $todo);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'domain update is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><domain:update xmlns:domain="http://www.nic.cz/xml/epp/domain-1.4" xsi:schemaLocation="http://www.nic.cz/xml/epp/domain-1.4 domain-1.4.xsd"><domain:name>sybla.cz</domain:name><domain:add><domain:admin>DA1-TZ</domain:admin></domain:add><domain:rem><domain:admin>TL1-TZ</domain:admin></domain:rem><domain:chg><domain:nsset>alfredservers</domain:nsset><domain:authInfo>coincoin</domain:authInfo></domain:chg></domain:update></update><clTRID>ABC-12345</clTRID></command></epp>', 'domain update build xml');

###############################################################################
########## NSSET object

## NSSET check
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><nsset:chkData xmlns:nsset="http://www.nic.cz/xml/epp/nsset-1.2" xsi:schemaLocation="http://www.nic.cz/xml/epp/nsset-1.2 nsset-1.2.xsd"><nsset:cd><nsset:id avail="0">testservers</nsset:id><nsset:id avail="1">prodservers</nsset:id></nsset:cd></nsset:chkData></resData>' . $TRID . '</response>' . $E2;

my $ro = $dri->remote_object('nsset');

$ok=eval {
  $rc = $ro->check('testservers', 'prodservers');
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'nsset check is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><nsset:check xmlns:nsset="http://www.nic.cz/xml/epp/nsset-1.2" xsi:schemaLocation="http://www.nic.cz/xml/epp/nsset-1.2 nsset-1.2.xsd"><nsset:id>testservers</nsset:id><nsset:id>prodservers</nsset:id></nsset:check></check><clTRID>ABC-12345</clTRID></command></epp>', 'nsset check build xml');
is($dri->get_info('exist', 'nsset', 'testservers'), 1,'nsset check existent');
is($dri->get_info('exist', 'nsset', 'prodservers'), 0,'nsset check nonexistent');

## NSSET create
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

my $ns = $dri->local_object('hosts');
$ns->add('dns1.syhosting.ch');
$ns->add('dns2.syhosting.cz', [], ['2001:6b0:1:ea:202:a5ff:fecd:13a6']);
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('TL1-CZ'), 'tech');

$ok=eval {
  $rc = $ro->create('testservers', {
    ns =>    $ns,
    contact =>  $cs,
    reportlevel =>  5,
    auth =>    { pw => 'gnagnagna' }
  });
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'nsset create is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><nsset:create xmlns:nsset="http://www.nic.cz/xml/epp/nsset-1.2" xsi:schemaLocation="http://www.nic.cz/xml/epp/nsset-1.2 nsset-1.2.xsd"><nsset:id>testservers</nsset:id><nsset:ns><nsset:name>dns1.syhosting.ch</nsset:name></nsset:ns><nsset:ns><nsset:name>dns2.syhosting.cz</nsset:name><nsset:addr>2001:6b0:1:ea:202:a5ff:fecd:13a6</nsset:addr></nsset:ns><nsset:tech>TL1-CZ</nsset:tech><nsset:authInfo>gnagnagna</nsset:authInfo><nsset:reportlevel>5</nsset:reportlevel></nsset:create></create><clTRID>ABC-12345</clTRID></command></epp>', 'nsset create build xml');

## NSSET update
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

$todo = $dri->local_object('changes');
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('TL1-CZ'), 'tech');
$todo->del('contact', $cs);
$ns = $dri->local_object('hosts');
$ns->add('dns2.syhosting.cz', [], ['2001:6b0:1:ea:202:a5ff:fecd:13a6']);
$todo->del('ns', $ns);
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DA1-CZ'), 'tech');
$todo->add('contact', $cs);
$ns = $dri->local_object('hosts');
$ns->add('dns3.syhosting.ch', ['194.25.2.129'], ['2001:3f8:bcd::1']);
$todo->add('ns', $ns);
$todo->set('auth', { pw => 'bliblablu'});
$todo->set('reportlevel', 4);

$ok=eval {
  $rc = $ro->update('nameservers', $todo);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'nsset update is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><nsset:update xmlns:nsset="http://www.nic.cz/xml/epp/nsset-1.2" xsi:schemaLocation="http://www.nic.cz/xml/epp/nsset-1.2 nsset-1.2.xsd"><nsset:id>nameservers</nsset:id><nsset:add><nsset:ns><nsset:name>dns3.syhosting.ch</nsset:name><nsset:addr>194.25.2.129</nsset:addr><nsset:addr>2001:3f8:bcd::1</nsset:addr></nsset:ns><nsset:tech>DA1-CZ</nsset:tech></nsset:add><nsset:rem><nsset:name>dns2.syhosting.cz</nsset:name><nsset:tech>TL1-CZ</nsset:tech></nsset:rem><nsset:chg><nsset:authInfo>bliblablu</nsset:authInfo><nsset:reportlevel>4</nsset:reportlevel></nsset:chg></nsset:update></update><clTRID>ABC-12345</clTRID></command></epp>', 'nsset update build xml');

## NSSET delete
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $ro->delete('testservers');
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'nsset delete is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><nsset:delete xmlns:nsset="http://www.nic.cz/xml/epp/nsset-1.2" xsi:schemaLocation="http://www.nic.cz/xml/epp/nsset-1.2 nsset-1.2.xsd"><nsset:id>testservers</nsset:id></nsset:delete></delete><clTRID>ABC-12345</clTRID></command></epp>', 'nsset delete build xml');

## NSSET info
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><nsset:infData xmlns:nsset="http://www.nic.cz/xml/epp/nsset-1.2" xsi:schemaLocation="http://www.nic.cz/xml/epp/nsset-1.2 nsset-1.2.xsd"><nsset:id>prodservers</nsset:id><nsset:roid>N0000164015-CZ</nsset:roid><nsset:status s="ok">Objekt is without restrictions</nsset:status><nsset:clID>REG-FRED_A</nsset:clID><nsset:crID>REG-FRED_A</nsset:crID><nsset:crDate>2008-05-26T17:41:29+02:00</nsset:crDate><nsset:authInfo>blablabla</nsset:authInfo><nsset:ns><nsset:name>dns1.syhosting.cz</nsset:name><nsset:addr>193.219.115.46</nsset:addr></nsset:ns><nsset:ns><nsset:name>dns3.syhosting.cz</nsset:name><nsset:addr>212.101.151.35</nsset:addr></nsset:ns><nsset:ns><nsset:name>dns2.syhosting.cz</nsset:name><nsset:addr>193.219.115.51</nsset:addr></nsset:ns><nsset:tech>TL1-CZ</nsset:tech><nsset:reportlevel>0</nsset:reportlevel></nsset:infData></resData>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $ro->info('prodservers');
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'nsset info is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><nsset:info xmlns:nsset="http://www.nic.cz/xml/epp/nsset-1.2" xsi:schemaLocation="http://www.nic.cz/xml/epp/nsset-1.2 nsset-1.2.xsd"><nsset:id>prodservers</nsset:id></nsset:info></info><clTRID>ABC-12345</clTRID></command></epp>', 'nsset info build xml');
is($dri->get_info('name', 'nsset', 'prodservers'), 'prodservers','nsset info name');
is($dri->get_info('roid', 'nsset', 'prodservers'), 'N0000164015-CZ','nsset info roid');
is($dri->get_info('crID', 'nsset', 'prodservers'), 'REG-FRED_A','nsset info crID');
is($dri->get_info('contact', 'nsset', 'prodservers')->get('tech')->srid(), 'TL1-CZ','nsset info tech');
is($dri->get_info('crDate', 'nsset', 'prodservers'), '2008-05-26T17:41:29','nsset info crDate');
is($dri->get_info('auth', 'nsset', 'prodservers')->{pw}, 'blablabla','nsset info auth');
is(join(',', $dri->get_info('status', 'nsset', 'prodservers')->list_status()),'ok', 'nsset info status');
is($dri->get_info('reportlevel', 'nsset', 'prodservers'), 0,'nsset info reportlevel');
$ns = $dri->get_info('self', 'nsset', 'prodservers');
is(join(',', $ns->get_names()),'dns1.syhosting.cz,dns3.syhosting.cz,dns2.syhosting.cz','nsset info ns');

## NSSET transfer query
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $ro->transfer_query('nameservers', { auth =>
    { pw => 'gnagnagna' }});
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'nsset transfer query is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><transfer op="query"><nsset:transfer xmlns:nsset="http://www.nic.cz/xml/epp/nsset-1.2" xsi:schemaLocation="http://www.nic.cz/xml/epp/nsset-1.2 nsset-1.2.xsd"><nsset:id>nameservers</nsset:id><nsset:authInfo>gnagnagna</nsset:authInfo></nsset:transfer></transfer><clTRID>ABC-12345</clTRID></command></epp>', 'nsset transfer query build xml');

## NSSET transfer request
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $ro->transfer_request('nameservers', { auth =>
    { pw => 'gnagnagna' }});
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'nsset transfer request is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><transfer op="request"><nsset:transfer xmlns:nsset="http://www.nic.cz/xml/epp/nsset-1.2" xsi:schemaLocation="http://www.nic.cz/xml/epp/nsset-1.2 nsset-1.2.xsd"><nsset:id>nameservers</nsset:id><nsset:authInfo>gnagnagna</nsset:authInfo></nsset:transfer></transfer><clTRID>ABC-12345</clTRID></command></epp>', 'nsset transfer request build xml');

###############################################################################
# KeySET object

## KeySET create
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><keyset:creData xmlns:keyset="http://www.nic.cz/xml/epp/keyset-1.3" xsi:schemaLocation="http://www.nic.cz/xml/epp/keyset-1.3 keyset-1.3.1.xsd"><keyset:id>342301</keyset:id><keyset:crDate>2016-08-09T16:41:58+02:00</keyset:crDate></keyset:creData></resData>' . $TRID . '</response>' . $E2;

my $key_params = {
  password => 'passw',
  tech => 'ID89595',
  dnskey => [{
    flags => '257',
    protocol => '3',
    alg => '5',
    pubkey => 'AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8',
  }]
};

$ok=eval {
  $rc = $dri->keyset_create('342301',$key_params);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'keyset create is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><keyset:create xmlns:keyset="http://www.nic.cz/xml/epp/keyset-1.3" xsi:schemaLocation="http://www.nic.cz/xml/epp/keyset-1.3 keyset-1.3.xsd"><keyset:id>342301</keyset:id><keyset:tech>ID89595</keyset:tech><keyset:authInfo>passw</keyset:authInfo><keyset:dnskey><keyset:flags>257</keyset:flags><keyset:protocol>3</keyset:protocol><keyset:alg>5</keyset:alg><keyset:pubKey>AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8</keyset:pubKey></keyset:dnskey></keyset:create></create><clTRID>ABC-12345</clTRID></command></epp>', 'keyset create build xml');
is($dri->get_info('crDate'),'2016-08-09T16:41:58+02:00','keyset create crDate');
is($dri->get_info('id'),342301,'keyset create id');

## KeySET check
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><keyset:chkData xmlns:keyset="http://www.nic.cz/xml/epp/keyset-1.3" xsi:schemaLocation="http://www.nic.cz/xml/epp/keyset-1.3 keyset-1.3.1.xsd"><keyset:cd><keyset:id avail="1">342301</keyset:id></keyset:cd></keyset:chkData></resData>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $dri->keyset_check('342301');
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'keyset check is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><keyset:check xmlns:keyset="http://www.nic.cz/xml/epp/keyset-1.3" xsi:schemaLocation="http://www.nic.cz/xml/epp/keyset-1.3 keyset-1.3.xsd"><keyset:id>342301</keyset:id></keyset:check></check><clTRID>ABC-12345</clTRID></command></epp>', 'keyset check build xml');
is($dri->get_info('action'),'check','keyset check action');
is($dri->get_info('exist'),0,'keyset check exist');
is($dri->get_info('id'),342301,'keyset check id');

## KeySET info
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><keyset:infData xmlns:keyset="http://www.nic.cz/xml/epp/keyset-1.3" xsi:schemaLocation="http://www.nic.cz/xml/epp/keyset-1.3 keyset-1.3.1.xsd"><keyset:id>342334</keyset:id><keyset:roid>K0000847348-CZ</keyset:roid><keyset:status s="ok">Objekt is without restrictions</keyset:status><keyset:clID>REG-FRED_A</keyset:clID><keyset:crID>REG-FRED_A</keyset:crID><keyset:crDate>2016-08-09T16:57:46+02:00</keyset:crDate><keyset:authInfo>passw</keyset:authInfo><keyset:dnskey><keyset:flags>257</keyset:flags><keyset:protocol>3</keyset:protocol><keyset:alg>5</keyset:alg><keyset:pubKey>AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8</keyset:pubKey></keyset:dnskey><keyset:tech>ID012324123</keyset:tech></keyset:infData></resData>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $dri->keyset_info('342301');
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'keyset info is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><keyset:info xmlns:keyset="http://www.nic.cz/xml/epp/keyset-1.3" xsi:schemaLocation="http://www.nic.cz/xml/epp/keyset-1.3 keyset-1.3.xsd"><keyset:id>342301</keyset:id></keyset:info></info><clTRID>ABC-12345</clTRID></command></epp>', 'keyset info build xml');
is($dri->get_info('id'),'342334','keyset info id');
is($dri->get_info('roid'),'K0000847348-CZ','keyset info roid');
is($dri->get_info('status'),'Objekt is without restrictions','keyset info status');
is($dri->get_info('clID'),'REG-FRED_A','keyset info clID');
is($dri->get_info('crID'),'REG-FRED_A','keyset info crID');
is($dri->get_info('authInfo'),'passw','keyset info authInfo');
is($dri->get_info('tech'),'ID012324123','keyset info tech');
is($dri->get_info('dnskey')->{flags},'257','keyset info dnskey flags');
is($dri->get_info('dnskey')->{protocol},'3','keyset info dnskey protocol');
is($dri->get_info('dnskey')->{alg},'5','keyset info dnskey alg');
is($dri->get_info('dnskey')->{pubKey},'AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8','keyset info dnskey pubKey');

## KeySET update
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

$todo = $dri->local_object('changes');
my $dnskeyadd = [{
  flags => '256',
  protocol => '3',
  alg => '5',
  pubkey => 'AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8',
}];
$todo->add('dnskey', $dnskeyadd);
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('TECH1'), 'tech');
$cs->add($dri->local_object('contact')->srid('TECH2'), 'tech');
$cs->add($dri->local_object('contact')->srid('TECH3'), 'tech');
$todo->del('contact', $cs);
$todo->set('auth', { pw => 'coincoin' });

$ok=eval {
  $rc = $dri->keyset_update('342334', $todo);
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'keyset update is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><keyset:update xmlns:keyset="http://www.nic.cz/xml/epp/keyset-1.3" xsi:schemaLocation="http://www.nic.cz/xml/epp/keyset-1.3 keyset-1.3.xsd"><keyset:id>342334</keyset:id><keyset:add><keyset:dnskey><keyset:flags>256</keyset:flags><keyset:protocol>3</keyset:protocol><keyset:alg>5</keyset:alg><keyset:pubKey>AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8</keyset:pubKey></keyset:dnskey></keyset:add><keyset:rem><keyset:tech>TECH1</keyset:tech><keyset:tech>TECH2</keyset:tech><keyset:tech>TECH3</keyset:tech></keyset:rem><keyset:chg><keyset:authInfo>coincoin</keyset:authInfo></keyset:chg></keyset:update></update><clTRID>ABC-12345</clTRID></command></epp>', 'keyset update build xml');

## KeySET delete
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $dri->keyset_delete('342301');
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'keyset delete is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><keyset:delete xmlns:keyset="http://www.nic.cz/xml/epp/keyset-1.3" xsi:schemaLocation="http://www.nic.cz/xml/epp/keyset-1.3 keyset-1.3.xsd"><keyset:id>342301</keyset:id></keyset:delete></delete><clTRID>ABC-12345</clTRID></command></epp>', 'keyset delete build xml');

## KeySET transfer
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;

$ok=eval {
  $rc = $dri->keyset_transfer('342301',{auth =>  { pw => 'gnagnagna' }});
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

is($rc->is_success(), 1, 'keyset transfer is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><transfer><keyset:transfer xmlns:keyset="http://www.nic.cz/xml/epp/keyset-1.3" xsi:schemaLocation="http://www.nic.cz/xml/epp/keyset-1.3 keyset-1.3.xsd"><keyset:id>342301</keyset:id><keyset:authInfo>gnagnagna</keyset:authInfo></keyset:transfer></transfer><clTRID>ABC-12345</clTRID></command></epp>', 'keyset transfer build xml');

exit 0;
