#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use FindBin;
require "$FindBin::Bin/../../util.pl";

my $test = Net::DRI::Test->new_epp(['Nomulus::Superuser']);
my $dri = $test->dri();

####################################################################################################

my $rc;

$test->set_response();
$rc = $dri->domain_delete('delete.example', {superuser => {redemption_grace_period => $dri->local_object('duration', days=>42), pending_delete => $dri->local_object('duration', days=>53) }});
is_string($test->get_command(),'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>delete.example</domain:name></domain:delete></delete><extension><superuser:domainDelete xmlns:superuser="urn:google:params:xml:ns:superuser-1.0"><superuser:redemptionGracePeriodDays>42</superuser:redemptionGracePeriodDays><superuser:pendingDeleteDays>53</superuser:pendingDeleteDays></superuser:domainDelete></extension><clTRID>ABC-12345</clTRID></command>','domain_delete build');

$rc = $dri->domain_transfer_start('transfer.example', {auth => {roid => 'JD1234-REP', pw => '2fooBAR'}, superuser => {duration => $dri->local_object('duration', years => 1), transfer_length => 2}});
is_string($test->get_command(),'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>transfer.example</domain:name><domain:authInfo><domain:pw roid="JD1234-REP">2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><superuser:domainTransferRequest xmlns:superuser="urn:google:params:xml:ns:superuser-1.0"><superuser:renewalPeriod unit="y">1</superuser:renewalPeriod><superuser:automaticTransferLength>2</superuser:automaticTransferLength></superuser:domainTransferRequest></extension><clTRID>ABC-12345</clTRID></command>', 'domain_transfer_start build');

exit 0;