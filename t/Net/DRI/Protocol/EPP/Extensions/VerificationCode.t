#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 42;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('VeriSign::COM_NET');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['VerificationCode','-VeriSign::NameStore','-VeriSign::WhoisInfo']});



my ($rc, $vc, $vcp, $vcs);


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.com</domain:name><domain:roid>DOMAIN-REP</domain:roid><domain:status s="ok"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2010-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2015-04-03T22:00:00.0Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><verificationCode:infData xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:status>compliant</verificationCode:status><verificationCode:profile name="sample"><verificationCode:status>compliant</verificationCode:status><verificationCode:set><verificationCode:code type="domain" date="2010-04-03T22:00:00.0Z">1-abc333</verificationCode:code><verificationCode:code type="registrant" date="2010-04-03T22:00:00.0Z">1-abc444</verificationCode:code></verificationCode:set></verificationCode:profile></verificationCode:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response></epp>';
$rc = $dri->domain_info('domain.com', { verification_code => 1 });
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name hosts="all">domain.com</domain:name></domain:info></info><extension><verificationCode:info xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"/></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain_info build with verificationCode');
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


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.com</domain:name><domain:roid>DOMAIN-REP</domain:roid><domain:status s="ok"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2010-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2015-04-03T22:00:00.0Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><verificationCode:infData xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:status>compliant</verificationCode:status><verificationCode:profile name="sample"><verificationCode:status>compliant</verificationCode:status><verificationCode:set><verificationCode:code type="domain" date="2010-04-03T22:00:00.0Z">1-abc333</verificationCode:code><verificationCode:code type="registrant" date="2010-04-03T22:00:00.0Z">1-abc444</verificationCode:code></verificationCode:set></verificationCode:profile><verificationCode:profile name="sample2"><verificationCode:status>notApplicable</verificationCode:status><verificationCode:set><verificationCode:code type="domain" date="2010-04-03T22:00:00.0Z">2-abc555</verificationCode:code></verificationCode:set></verificationCode:profile></verificationCode:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response></epp>';
$rc = $dri->domain_info('domain.com', { verification_code => 1, verification_code_profile => 'sample' });
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name hosts="all">domain.com</domain:name></domain:info></info><extension><verificationCode:info xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0" profile="sample"/></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info build with verificationCode + profile');
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


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.com</domain:name><domain:roid>DOMAIN-REP</domain:roid><domain:status s="serverHold"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2010-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2015-04-03T22:00:00.0Z</domain:exDate></domain:infData></resData><extension><verificationCode:infData xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:status>nonCompliant</verificationCode:status><verificationCode:profile name="sample"><verificationCode:status>nonCompliant</verificationCode:status><verificationCode:missing><verificationCode:code type="domain" due="2010-04-03T22:00:00.0Z"/><verificationCode:code type="registrant" due="2010-04-08T22:00:00.0Z"/></verificationCode:missing></verificationCode:profile></verificationCode:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response></epp>';
$rc = $dri->domain_info('domain.com', { verification_code => 1, verification_code_profile => 'sample' });
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


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.com</domain:name><domain:roid>DOMAIN-REP</domain:roid><domain:status s="ok"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2010-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2015-04-03T22:00:00.0Z</domain:exDate></domain:infData></resData><extension><verificationCode:infData xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:status>pendingCompliance</verificationCode:status><verificationCode:profile name="sample"><verificationCode:status>pendingCompliance</verificationCode:status><verificationCode:missing><verificationCode:code type="registrant" due="2010-04-08T22:00:00.0Z"/></verificationCode:missing><verificationCode:set><verificationCode:code type="domain" date="2010-04-03T22:00:00.0Z">1-abc333</verificationCode:code></verificationCode:set></verificationCode:profile></verificationCode:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response></epp>';
$rc = $dri->domain_info('domain.com', { verification_code => 1, verification_code_profile => 'sample' });
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


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.com</domain:name><domain:roid>DOMAIN-REP</domain:roid><domain:status s="ok"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2010-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2015-04-03T22:00:00.0Z</domain:exDate></domain:infData></resData><extension><verificationCode:infData xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:status>notApplicable</verificationCode:status></verificationCode:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response></epp>';
$rc = $dri->domain_info('domain.com', { verification_code => 1, verification_code_profile => 'sample' });
$vc = $rc->get_data('verification');
is_deeply([ sort { $a cmp $b } keys %$vc ], [ qw/status/ ], 'get_data(verification) keys');
is($vc->{status}, 'notApplicable', 'get_data(verification) status');


my $cs=$dri->local_object('contactset', { registrant => 'jd1234', admin => 'sh8013', tech => 'sh8013'});
$rc=$dri->domain_create('domain.com', { pure_create => 1, contact => $cs, auth => { pw => '2fooBAR' }, verification_code => 'ICAgICAgPHZlcmlmaWNhdGlvbkNvZGU6c2lnbmVkQ29kZQogICAgICAgIHhtbG5zOnZlcmlmaWNhdGlvbkNvZGU9CiAgICAgICAgICAidXJuOmlldGY6cGFyYW1zOnhtbDpuczp2ZXJpZmljYXRpb25Db2RlLTEuMCIKICAgICAgICAgIGlkPSJzaWduZWRDb25Db2RlOnNpZ25lZENvZGU+Cg==' });
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.com</domain:name><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><verificationCode:encodedSignedCode xmlns:verificationCode="urn:ietf:params:xml:ns:verificationCode-1.0"><verificationCode:code>ICAgICAgPHZlcmlmaWNhdGlvbkNvZGU6c2lnbmVkQ29kZQogICAgICAgIHhtbG5zOnZlcmlmaWNhdGlvbkNvZGU9CiAgICAgICAgICAidXJuOmlldGY6cGFyYW1zOnhtbDpuczp2ZXJpZmljYXRpb25Db2RlLTEuMCIKICAgICAgICAgIGlkPSJzaWduZWRDb25Db2RlOnNpZ25lZENvZGU+Cg==</verificationCode:code></verificationCode:encodedSignedCode></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain_create build with verificationCode');


exit 0;
