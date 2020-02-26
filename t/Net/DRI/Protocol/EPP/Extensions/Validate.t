#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use FindBin;
require "$FindBin::Bin/../util.pl";

my $test = Net::DRI::Test->new_epp(['Validate']);
my $dri = $test->dri();
$dri->{info}->{contact_i18n} = 2; # INT only

####################################################################################################
eval {
my $ro = $dri->remote_object('contact');

$test->set_response(<<'EPP');
<resData>
  <validate:chkData
    xmlns:validate="urn:ietf:params:xml:ns:validate-0.2">
    <validate:cd>
      <validate:id>sh8013</validate:id>
      <validate:response>1000</validate:response>
    </validate:cd>
    <validate:cd>
      <validate:id>sh8014</validate:id>
      <validate:response>2306</validate:response>
      <validate:kv key="contact:city"
        value="City not valid for state."/>
      <validate:kv contactType="Admin" key="contact:cc"
        value="Invalid country code for admin, must be mx."/>
      <validate:kv contactType="Billing" key="VAT"
        value="VAT required for Billing contact."/>
    </validate:cd>
  </validate:chkData>
</resData>
EPP

my $co1 = $dri->local_object('contact');
$co1->name('John Doe');
$co1->org('Example Inc.');
$co1->street(['123 Example Dr.', 'Suite 100']);
$co1->city('Dulles');
$co1->sp('VA');
$co1->pc('20166-6503');
$co1->cc('US');
$co1->voice('+1.7035555555');
$co1->fax('+1.7035555556');
$co1->email('jdoe@example.com');
$co1->auth({ pw => '2fooBAR'});
$co1->loc2int();
my %cd1 = (
    type => 'registrant',
    zone => 'COM',
    contact => $co1->srid('sh8013'),
    kv => { 'VAT' => '1234567890' },
);
my %cd2 = (
    type => 'tech',
    zone => 'COM',
    contact => $dri->local_object('contact')->srid('sh8012'),
);
my $co2 = $co1->clone()->srid('sh8014');
my %cd3 = (
    type => 'admin',
    zone => 'COM',
    contact => $co2,
);
my %cd4 = (
    type => 'billing',
    zone => 'COM',
    contact => $co2,
);
my $rc = $ro->validate([\%cd1, \%cd2, \%cd3, \%cd4]);
my $command=<<'EPP';
<command>
  <check>
    <validate:check xmlns:validate="urn:ietf:params:xml:ns:validate-0.2">
      <validate:contact contactType="registrant" tld="COM">
        <validate:id>sh8013</validate:id>
        <validate:postalInfo type="loc">
          <contact:name>John Doe</contact:name>
          <contact:org>Example Inc.</contact:org>
          <contact:addr>
            <contact:street>123 Example Dr.</contact:street>
            <contact:street>Suite 100</contact:street>
            <contact:city>Dulles</contact:city>
            <contact:sp>VA</contact:sp>
            <contact:pc>20166-6503</contact:pc>
            <contact:cc>US</contact:cc>
          </contact:addr>
        </validate:postalInfo>
        <validate:voice>+1.7035555555</validate:voice>
        <validate:fax>+1.7035555556</validate:fax>
        <validate:email>jdoe@example.com</validate:email>
        <validate:authInfo>
          <contact:pw>2fooBAR</contact:pw>
        </validate:authInfo>
        <validate:kv key="VAT" value="1234567890"/>
      </validate:contact>
      <validate:contact contactType="tech" tld="COM">
        <validate:id>sh8012</validate:id>
      </validate:contact>
      <validate:contact contactType="admin" tld="COM">
        <validate:id>sh8014</validate:id>
        <validate:postalInfo type="loc">
          <contact:name>John Doe</contact:name>
          <contact:org>Example Inc.</contact:org>
          <contact:addr>
            <contact:street>123 Example Dr.</contact:street>
            <contact:street>Suite 100</contact:street>
            <contact:city>Dulles</contact:city>
            <contact:sp>VA</contact:sp>
            <contact:pc>20166-6503</contact:pc>
            <contact:cc>US</contact:cc>
          </contact:addr>
        </validate:postalInfo>
        <validate:voice>+1.7035555555</validate:voice>
        <validate:fax>+1.7035555556</validate:fax>
        <validate:email>jdoe@example.com</validate:email>
        <validate:authInfo>
          <contact:pw>2fooBAR</contact:pw>
        </validate:authInfo>
      </validate:contact>
      <validate:contact contactType="billing" tld="COM">
        <validate:id>sh8014</validate:id>
        <validate:postalInfo type="loc">
          <contact:name>John Doe</contact:name>
          <contact:org>Example Inc.</contact:org>
          <contact:addr>
            <contact:street>123 Example Dr.</contact:street>
            <contact:street>Suite 100</contact:street>
            <contact:city>Dulles</contact:city>
            <contact:sp>VA</contact:sp>
            <contact:pc>20166-6503</contact:pc>
            <contact:cc>US</contact:cc>
          </contact:addr>
        </validate:postalInfo>
        <validate:voice>+1.7035555555</validate:voice>
        <validate:fax>+1.7035555556</validate:fax>
        <validate:email>jdoe@example.com</validate:email>
        <validate:authInfo>
          <contact:pw>2fooBAR</contact:pw>
        </validate:authInfo>
      </validate:contact>
    </validate:check>
  </check>
  <clTRID>ABC-12345</clTRID>
</command>
EPP
is_string($test->get_command, $test->format_xml($command), 'contact_validate build');

is($rc->get_data('contact', 'sh8013', 'action'), 'validate', 'get_data contact1 action');
is_deeply($rc->get_data('contact', 'sh8013', 'validate'), { response => 1000 }, 'get_data contact1 validate');
is($rc->get_data('contact', 'sh8014', 'action'), 'validate', 'get_data contact2 action');
my %d2 = (
    'response'     => 2306,
    'contact:city' => { '*'       => 'City not valid for state.' },
    'contact:cc'   => { 'admin'   => 'Invalid country code for admin, must be mx.' },
    'VAT'          => { 'billing' => 'VAT required for Billing contact.' }
);
is_deeply($rc->get_data('contact', 'sh8014', 'validate'), \%d2, 'get_data contact2 validate');
};

print $@->as_string() if $@;

exit 0;