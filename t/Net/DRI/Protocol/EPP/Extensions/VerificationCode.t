#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 42;

use FindBin;
require "$FindBin::Bin/../util.pl";

my $test = Net::DRI::Test->new_epp(['VerificationCode']);
my $dri = $test->dri();


####################################################################################################

my $rc;

my ($vc, $vcp, $vcs);


$test->set_response('<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:roid>DOMAIN-REP</domain:roid><domain:status s="ok"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2010-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2015-04-03T22:00:00.0Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><verificationCode:infData xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:status>compliant</verificationCode:status><verificationCode:profile name="sample"><verificationCode:status>compliant</verificationCode:status><verificationCode:set><verificationCode:code type="domain" date="2010-04-03T22:00:00.0Z">1-abc333</verificationCode:code><verificationCode:code type="registrant" date="2010-04-03T22:00:00.0Z">1-abc444</verificationCode:code></verificationCode:set></verificationCode:profile></verificationCode:infData></extension>');
$rc = $dri->domain_info('domain.example', { verification_code => 1 });
is_string($test->get_command(), '<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name hosts="all">domain.example</domain:name></domain:info></info><extension><verificationCode:info xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"/></extension><clTRID>ABC-12345</clTRID></command>', 'domain_info build with verificationCode');
$vc = $rc->get_data('verification');
is_deeply([ sort { $a cmp $b } keys %$vc ], [ qw/profiles status/ ], 'get_data(verification) keys');
is($vc->{status}, 'compliant', 'get_data(verification) status');
is_deeply([ sort { $a cmp $b } keys %{$vc->{profiles}} ], [ qw/sample/ ], 'get_data(verification) profiles');
$vcp=$vc->{profiles}->{sample};
is_deeply([ sort { $a cmp $b } keys %$vcp ], [ qw/set status/ ], 'get_data(verification) profile sample keys');
is($vcp->{status}, 'compliant', 'get_data(verification) profile sample status');
$vcs=$vc->{profiles}->{sample}->{set};
is(scalar @$vcs, 2, 'get_data(verification) profile sample set');
is_deeply($vcs->[0], { type => 'domain', code => '1-abc333', date => '2010-04-03T22:00:00' }, 'get_data(verification) profile sample set1');
is_deeply($vcs->[1], { type => 'registrant', code => '1-abc444', date => '2010-04-03T22:00:00' }, 'get_data(verification) profile sample set2');


$test->set_response('<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:roid>DOMAIN-REP</domain:roid><domain:status s="ok"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2010-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2015-04-03T22:00:00.0Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><verificationCode:infData xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:status>compliant</verificationCode:status><verificationCode:profile name="sample"><verificationCode:status>compliant</verificationCode:status><verificationCode:set><verificationCode:code type="domain" date="2010-04-03T22:00:00.0Z">1-abc333</verificationCode:code><verificationCode:code type="registrant" date="2010-04-03T22:00:00.0Z">1-abc444</verificationCode:code></verificationCode:set></verificationCode:profile><verificationCode:profile name="sample2"><verificationCode:status>notApplicable</verificationCode:status><verificationCode:set><verificationCode:code type="domain" date="2010-04-03T22:00:00.0Z">2-abc555</verificationCode:code></verificationCode:set></verificationCode:profile></verificationCode:infData></extension>');
$rc = $dri->domain_info('domain.example', { verification_code => 1, verification_code_profile => 'sample' });
is_string($test->get_command(), '<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name hosts="all">domain.example</domain:name></domain:info></info><extension><verificationCode:info xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0" profile="sample"/></extension><clTRID>ABC-12345</clTRID></command>','domain_info build with verificationCode + profile');
$vc = $rc->get_data('verification');
is_deeply([ sort { $a cmp $b } keys %$vc ], [ qw/profiles status/ ], 'get_data(verification) keys');
is($vc->{status}, 'compliant', 'get_data(verification) status');
is_deeply([ sort { $a cmp $b } keys %{$vc->{profiles}} ], [ qw/sample sample2/ ], 'get_data(verification) profiles');
$vcp=$vc->{profiles}->{sample};
is_deeply([ sort { $a cmp $b } keys %$vcp ], [ qw/set status/ ], 'get_data(verification) profile sample keys');
is($vcp->{status}, 'compliant', 'get_data(verification) profile sample status');
$vcs=$vc->{profiles}->{sample}->{set};
is(scalar @$vcs, 2, 'get_data(verification) profile sample set');
is_deeply($vcs->[0], { type => 'domain', code => '1-abc333', date => '2010-04-03T22:00:00' }, 'get_data(verification) profile sample set1');
is_deeply($vcs->[1], { type => 'registrant', code => '1-abc444', date => '2010-04-03T22:00:00' }, 'get_data(verification) profile sample set2');
$vcp=$vc->{profiles}->{sample2};
is_deeply([ sort { $a cmp $b } keys %$vcp ], [ qw/set status/ ], 'get_data(verification) profile sample2 keys');
is($vcp->{status}, 'notApplicable', 'get_data(verification) profile sample2 status');
$vcs=$vc->{profiles}->{sample2}->{set};
is(scalar @$vcs, 1, 'get_data(verification) profile sample2 set');
is_deeply($vcs->[0], { type => 'domain', code => '2-abc555', date => '2010-04-03T22:00:00' }, 'get_data(verification) profile sample2 set1');


$test->set_response('<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:roid>DOMAIN-REP</domain:roid><domain:status s="serverHold"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2010-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2015-04-03T22:00:00.0Z</domain:exDate></domain:infData></resData><extension><verificationCode:infData xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:status>nonCompliant</verificationCode:status><verificationCode:profile name="sample"><verificationCode:status>nonCompliant</verificationCode:status><verificationCode:missing><verificationCode:code type="domain" due="2010-04-03T22:00:00.0Z"/><verificationCode:code type="registrant" due="2010-04-08T22:00:00.0Z"/></verificationCode:missing></verificationCode:profile></verificationCode:infData></extension>');
$rc = $dri->domain_info('domain.example', { verification_code => 1, verification_code_profile => 'sample' });
$vc = $rc->get_data('verification');
is_deeply([ sort { $a cmp $b } keys %$vc ], [ qw/profiles status/ ], 'get_data(verification) keys');
is($vc->{status}, 'nonCompliant', 'get_data(verification) status');
is_deeply([ sort { $a cmp $b } keys %{$vc->{profiles}} ], [ qw/sample/ ], 'get_data(verification) profiles');
$vcp=$vc->{profiles}->{sample};
is_deeply([ sort { $a cmp $b } keys %$vcp ], [ qw/missing status/ ], 'get_data(verification) profile sample keys');
is($vcp->{status}, 'nonCompliant', 'get_data(verification) profile sample status');
$vcs=$vc->{profiles}->{sample}->{missing};
is(scalar @$vcs, 2, 'get_data(verification) profile sample missing');
is_deeply($vcs->[0], { type => 'domain',due => '2010-04-03T22:00:00' }, 'get_data(verification) profile sample missing1');
is_deeply($vcs->[1], { type => 'registrant',due => '2010-04-08T22:00:00' }, 'get_data(verification) profile sample missing2');


$test->set_response('<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:roid>DOMAIN-REP</domain:roid><domain:status s="ok"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2010-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2015-04-03T22:00:00.0Z</domain:exDate></domain:infData></resData><extension><verificationCode:infData xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:status>pendingCompliance</verificationCode:status><verificationCode:profile name="sample"><verificationCode:status>pendingCompliance</verificationCode:status><verificationCode:missing><verificationCode:code type="registrant" due="2010-04-08T22:00:00.0Z"/></verificationCode:missing><verificationCode:set><verificationCode:code type="domain" date="2010-04-03T22:00:00.0Z">1-abc333</verificationCode:code></verificationCode:set></verificationCode:profile></verificationCode:infData></extension>');
$rc = $dri->domain_info('domain.example', { verification_code => 1, verification_code_profile => 'sample' });
$vc = $rc->get_data('verification');
is_deeply([ sort { $a cmp $b } keys %$vc ], [ qw/profiles status/ ], 'get_data(verification) keys');
is($vc->{status}, 'pendingCompliance', 'get_data(verification) status');
is_deeply([ sort { $a cmp $b } keys %{$vc->{profiles}} ], [ qw/sample/ ], 'get_data(verification) profiles');
$vcp=$vc->{profiles}->{sample};
is_deeply([ sort { $a cmp $b } keys %$vcp ], [ qw/missing set status/ ], 'get_data(verification) profile sample keys');
is($vcp->{status}, 'pendingCompliance', 'get_data(verification) profile sample status');
$vcs=$vc->{profiles}->{sample}->{missing};
is(scalar @$vcs, 1, 'get_data(verification) profile sample missing');
is_deeply($vcs->[0], { type => 'registrant',due => '2010-04-08T22:00:00' }, 'get_data(verification) profile sample missing1');
$vcs=$vc->{profiles}->{sample}->{set};
is(scalar @$vcs, 1, 'get_data(verification) profile sample set');
is_deeply($vcs->[0], { type => 'domain', code => '1-abc333', date => '2010-04-03T22:00:00' }, 'get_data(verification) profile sample set1');


$test->set_response('<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:roid>DOMAIN-REP</domain:roid><domain:status s="ok"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2010-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2015-04-03T22:00:00.0Z</domain:exDate></domain:infData></resData><extension><verificationCode:infData xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:status>notApplicable</verificationCode:status></verificationCode:infData></extension>');
$rc = $dri->domain_info('domain.example', { verification_code => 1, verification_code_profile => 'sample' });
$vc = $rc->get_data('verification');
is_deeply([ sort { $a cmp $b } keys %$vc ], [ qw/status/ ], 'get_data(verification) keys');
is($vc->{status}, 'notApplicable', 'get_data(verification) status');


my $cs=$dri->local_object('contactset', { registrant => 'jd1234', admin => 'sh8013', tech => 'sh8013'});
$rc=$dri->domain_create('domain.example', { pure_create => 1, contact => $cs, auth => { pw => '2fooBAR' }, verification_code => 'ICAgICAgPHZlcmlmaWNhdGlvbkNvZGU6c2lnbmVkQ29kZQogICAgICAgIHhtbG5zOnZlcmlmaWNhdGlvbkNvZGU9CiAgICAgICAgICAidXJuOmlldGY6cGFyYW1zOnhtbDpuczp2ZXJpZmljYXRpb25Db2RlLTEuMCIKICAgICAgICAgIGlkPSJzaWduZWRDb25Db2RlOnNpZ25lZENvZGU+Cg==' });
is_string($test->get_command(), '<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><verificationCode:encodedSignedCode xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:code>ICAgICAgPHZlcmlmaWNhdGlvbkNvZGU6c2lnbmVkQ29kZQogICAgICAgIHhtbG5zOnZlcmlmaWNhdGlvbkNvZGU9CiAgICAgICAgICAidXJuOmlldGY6cGFyYW1zOnhtbDpuczp2ZXJpZmljYXRpb25Db2RlLTEuMCIKICAgICAgICAgIGlkPSJzaWduZWRDb25Db2RlOnNpZ25lZENvZGU+Cg==</verificationCode:code></verificationCode:encodedSignedCode></extension><clTRID>ABC-12345</clTRID></command>', 'domain_create build with verificationCode');


exit 0;