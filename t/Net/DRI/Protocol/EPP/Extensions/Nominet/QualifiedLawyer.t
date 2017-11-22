#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 13;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_current_registry('Nominet::MMX');
$dri->driver()->{info}->{contact_i18n} = 2; # force to use type="int" only. both enabled by default for NGTLDs :)
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$co,$co2,$toc);

##########################################
## Qualified Lawyer Extension - EPP Query Commands

# contact info
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>aw2015</contact:id><contact:roid>51-Minds</contact:roid><contact:status s="ok">No changes pending</contact:status><contact:postalInfo type="int"><contact:name>Andy Wiens</contact:name><contact:org>Minds + Machines</contact:org><contact:addr><contact:street>32 Nassau St</contact:street><contact:city>Dublin</contact:city><contact:sp>Leinster</contact:sp><contact:pc>Dublin 2</contact:pc><contact:cc>IE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+353.16778933</contact:voice><contact:email>andy@mindsandmachines.com</contact:email><contact:clID>basic</contact:clID><contact:crID>basic</contact:crID><contact:crDate>2015-09-28T18:18:51.0156Z</contact:crDate><contact:authInfo><contact:pw>takeAw@y</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:name type="loc"/></contact:disclose></contact:infData></resData><extension><info xmlns="urn:ietf:params:xml:ns:qualifiedLawyer-1.0" xmlns:qualifiedLawyer="urn:ietf:params:xml:ns:qualifiedLawyer-1.0"><qualifiedLawyer:accreditationId>KS-123456</qualifiedLawyer:accreditationId><qualifiedLawyer:accreditationBody>Kansas Bar Association</qualifiedLawyer:accreditationBody><qualifiedLawyer:accreditationYear>2003Z</qualifiedLawyer:accreditationYear><qualifiedLawyer:jurisdictionCC>US</qualifiedLawyer:jurisdictionCC><qualifiedLawyer:jurisdictionSP>Kansas</qualifiedLawyer:jurisdictionSP></info></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('aw2015')->auth({pw=>'takeAw@y'});
$rc=$dri->contact_info($co);
is($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>aw2015</contact:id><contact:authInfo><contact:pw>takeAw@y</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
is($dri->get_info('accreditation_id'),'KS-123456','contact_info get_info(accreditationId)');
is($dri->get_info('accreditation_body'),'Kansas Bar Association','contact_info get_info(accreditationBody)');
is($dri->get_info('accreditation_year'),'2003Z','contact_info get_info(accreditationYear)');
is($dri->get_info('jurisdiction_cc'),'US','contact_info get_info(jurisdictionCC)');
is($dri->get_info('jurisdiction_sp'),'Kansas','contact_info get_info(jurisdictionSP)');
# END: contact info

## END: Qualified Lawyer Extension - EPP Query Commands
##########################################


##########################################
## Qualified Lawyer Extension - EPP Transform Commands

# contact create
$R2='';
$co=$dri->local_object('contact')->srid('aw2015');
$co->name('Andy Wiens');
$co->org('Minds + Machines');
$co->street(['32 Nassau St']);
$co->city('Dublin');
$co->sp('Leinster');
$co->pc('Dublin 2');
$co->cc('IE');
$co->voice('+353.16778933');
$co->email('andy@mindsandmachines.com');
$co->auth({pw=>'takeAw@y'});
$co->disclose({voice=>1,fax=>1,email=>1});
$co->accreditation_id('KS-123456');
$co->accreditation_body('Kansas Bar Association');
$co->accreditation_year('2003Z');
$co->jurisdiction_cc('US');
$co->jurisdiction_sp('Kansas');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>aw2015</contact:id><contact:postalInfo type="int"><contact:name>Andy Wiens</contact:name><contact:org>Minds + Machines</contact:org><contact:addr><contact:street>32 Nassau St</contact:street><contact:city>Dublin</contact:city><contact:sp>Leinster</contact:sp><contact:pc>Dublin 2</contact:pc><contact:cc>IE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+353.16778933</contact:voice><contact:email>andy@mindsandmachines.com</contact:email><contact:authInfo><contact:pw>takeAw@y</contact:pw></contact:authInfo><contact:disclose flag="1"><contact:voice/><contact:fax/><contact:email/></contact:disclose></contact:create></create><extension><qualifiedLawyer:create xmlns:qualifiedLawyer="urn:ietf:params:xml:ns:qualifiedLawyer-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:qualifiedLawyer-1.0 qualifiedLawyer-1.0.xsd"><qualifiedLawyer:accreditationId>KS-123456</qualifiedLawyer:accreditationId><qualifiedLawyer:accreditationBody>Kansas Bar Association</qualifiedLawyer:accreditationBody><qualifiedLawyer:accreditationYear>2003Z</qualifiedLawyer:accreditationYear><qualifiedLawyer:jurisdictionCC>US</qualifiedLawyer:jurisdictionCC><qualifiedLawyer:jurisdictionSP>Kansas</qualifiedLawyer:jurisdictionSP></qualifiedLawyer:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create qualified lawyer build');
is($rc->is_success(),1,'contact_create qualified lawyer is_success');
# END: contact create

# contact update
$R2='';
$co=$dri->local_object('contact')->srid('aw2015');
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->accreditation_id('UK-123456');
$co2->accreditation_body('London Bar Association');
$co2->accreditation_year('2015Z');
$co2->jurisdiction_cc('UK');
$co2->jurisdiction_sp('London');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>aw2015</contact:id></contact:update></update><extension><qualifiedLawyer:update xmlns:qualifiedLawyer="urn:ietf:params:xml:ns:qualifiedLawyer-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:qualifiedLawyer-1.0 qualifiedLawyer-1.0.xsd"><qualifiedLawyer:accreditationId>UK-123456</qualifiedLawyer:accreditationId><qualifiedLawyer:accreditationBody>London Bar Association</qualifiedLawyer:accreditationBody><qualifiedLawyer:accreditationYear>2015Z</qualifiedLawyer:accreditationYear><qualifiedLawyer:jurisdictionCC>UK</qualifiedLawyer:jurisdictionCC><qualifiedLawyer:jurisdictionSP>London</qualifiedLawyer:jurisdictionSP></qualifiedLawyer:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update qualified lawyer build');
is($rc->is_success(),1,'contact_update qualified lawyer is_success');
# END: contact update

## END: Qualified Lawyer Extension - EPP Transform Commands
##########################################

exit 0;
