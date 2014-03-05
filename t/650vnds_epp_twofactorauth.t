#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 9;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['VeriSign::TwoFactorAuth']});


## Auth creation

$R2=$E1.'<response>'.r().'<resData><authSession:creData xmlns:authSession="http://www.verisign.com/epp/authSession-1.0" xsi:schemaLocation="http://www.verisign.com/epp/authSession-1.0 authSession-1.0.xsd"><authSession:token><authSession:serviceProvider>VIP</authSession:serviceProvider><authSession:credentialId>xyz1234</authSession:credentialId><authSession:crDate>2010-12-28T02:25:38.0205Z</authSession:crDate><authSession:exDate>2010-12-28T02:25:38.0205Z</authSession:exDate></authSession:token><authSession:signature>UjBsR09EbGhjZ0dTQUxNQUFBUUNBRU1tQ1p0dU1GUXhEUzhi</authSession:signature></authSession:creData></resData>'.$TRID.'</response>'.$E2;
my $rc=$dri->twofactorauth_create({service_provider=>'VIP',otp=>'otp1234567',credentials=>[qw/xyz1234 pqr1234/]});
is_string($R1,$E1.'<command><create><authSession:create xmlns:authSession="http://www.verisign.com/epp/authSession-1.0" xsi:schemaLocation="http://www.verisign.com/epp/authSession-1.0 authSession-1.0.xsd"><authSession:serviceProvider>VIP</authSession:serviceProvider><authSession:otp>otp1234567</authSession:otp><authSession:credentialList><authSession:credentialId>xyz1234</authSession:credentialId><authSession:credentialId>pqr1234</authSession:credentialId></authSession:credentialList></authSession:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'twofactorauth_create build');
is($rc->get_data('service_provider'),'VIP','twofactorauth_create get_data(service_provider)');
is($rc->get_data('credential_id'),'xyz1234','twofactorauth_create get_data(credential_id)');
is(''.$rc->get_data('crDate'),'2010-12-28T02:25:38','twofactorauth_create get_data(crDate)');
is(''.$rc->get_data('exDate'),'2010-12-28T02:25:38','twofactorauth_create get_data(exDate)');
is($rc->get_data('signature'),'UjBsR09EbGhjZ0dTQUxNQUFBUUNBRU1tQ1p0dU1GUXhEUzhi','twofactorauth_create get_data(signature)');

## Auth use

my $toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->set('ns1.example.com'));

my $auth={ bind => { token_provider => 'VRSN',
                     token => { service_provider => 'VIP',
                                credential => 'xyz1234',
                                crDate => $dri->local_object('datetime',year=>2010,month=>12,day=>28,hour=>2,minute=>25,second=>38,nanosecond=>20_500_000),
                                exDate => $dri->local_object('datetime',year=>2010,month=>12,day=>28,hour=>2,minute=>25,second=>38,nanosecond=>20_500_000),
                              },
                     signature => 'UjBsR09EbGhjZ0dTQUxNQUFBUUNBRU1tQ1p0dU1GUXhEUzhi',
                    }
         };

$rc=$dri->domain_update('example.com',$toc,{ auth => $auth });

is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com</domain:name><domain:add><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj></domain:ns></domain:add></domain:update></update><extension><authExt:authActions xmlns:authExt="http://www.verisign.com/epp/authExt-1.0" xmlns:authSession="http://www.verisign.com/epp/authSession-1.0" xsi:schemaLocation="http://www.verisign.com/epp/authExt-1.0 authExt-1.0.xsd http://www.verisign.com/epp/authSession-1.0 authSession-1.0.xsd"><authExt:bind><authExt:tokenDataList><authExt:tokenData><authExt:tokenProvider>VRSN</authExt:tokenProvider><authExt:token><authSession:serviceProvider>VIP</authSession:serviceProvider><authSession:credentialId>xyz1234</authSession:credentialId><authSession:crDate>2010-12-28T02:25:38.020500Z</authSession:crDate><authSession:exDate>2010-12-28T02:25:38.020500Z</authSession:exDate></authExt:token><authExt:signature>UjBsR09EbGhjZ0dTQUxNQUFBUUNBRU1tQ1p0dU1GUXhEUzhi</authExt:signature></authExt:tokenData></authExt:tokenDataList></authExt:bind></authExt:authActions></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update auth.bind build');

$auth={ validate => { token_provider => 'VRSN',
                      token => { service_provider => 'VIP',
                                 credential => 'xyz1234',
                                 crDate => $dri->local_object('datetime',year=>2010,month=>12,day=>28,hour=>2,minute=>25,second=>38,nanosecond=>20_500_000),
                                 exDate => $dri->local_object('datetime',year=>2010,month=>12,day=>28,hour=>2,minute=>25,second=>38,nanosecond=>20_500_000),
                               },
                      signature => 'UjBsR09EbGhjZ0dTQUxNQUFBUUNBRU1tQ1p0dU1GUXhEUzhi',
                     }
      };

$rc=$dri->domain_update('example.com',$toc,{ auth => $auth });

is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com</domain:name><domain:add><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj></domain:ns></domain:add></domain:update></update><extension><authExt:authActions xmlns:authExt="http://www.verisign.com/epp/authExt-1.0" xmlns:authSession="http://www.verisign.com/epp/authSession-1.0" xsi:schemaLocation="http://www.verisign.com/epp/authExt-1.0 authExt-1.0.xsd http://www.verisign.com/epp/authSession-1.0 authSession-1.0.xsd"><authExt:validate><authExt:tokenData><authExt:tokenProvider>VRSN</authExt:tokenProvider><authExt:token><authSession:serviceProvider>VIP</authSession:serviceProvider><authSession:credentialId>xyz1234</authSession:credentialId><authSession:crDate>2010-12-28T02:25:38.020500Z</authSession:crDate><authSession:exDate>2010-12-28T02:25:38.020500Z</authSession:exDate></authExt:token><authExt:signature>UjBsR09EbGhjZ0dTQUxNQUFBUUNBRU1tQ1p0dU1GUXhEUzhi</authExt:signature></authExt:tokenData></authExt:validate></authExt:authActions></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update auth.validate build');

$auth={ validate => { token_provider => 'VRSN',
                      token => { service_provider => 'VIP',
                                 credential => 'xyz1234',
                                 crDate => $dri->local_object('datetime',year=>2010,month=>12,day=>28,hour=>2,minute=>25,second=>38,nanosecond=>20_500_000),
                                 exDate => $dri->local_object('datetime',year=>2010,month=>12,day=>28,hour=>2,minute=>25,second=>38,nanosecond=>20_500_000),
                               },
                      signature => 'UjBsR09EbGhjZ0dTQUxNQUFBUUNBRU1tQ1p0dU1GUXhEUzhi',
                     },
        bind => { token_provider => 'VRSN',
                     token => { service_provider => 'VIP',
                                credential => 'xyz456',
                                crDate => $dri->local_object('datetime',year=>2001,month=>12,day=>17,hour=>9,minute=>30,second=>47,nanosecond=>0),
                                exDate => $dri->local_object('datetime',year=>2001,month=>12,day=>17,hour=>9,minute=>30,second=>47,nanosecond=>0),
                              },
                     signature => 'UjBsR09EbGhjZ0dTQUxNQUFBUUNBRU1tQ1p0dU1GUXhEUzhi',
                    },
        unbind => [ 'xyz1234' ],
      };

$rc=$dri->domain_update('example.com',$toc,{ auth => $auth });

is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com</domain:name><domain:add><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj></domain:ns></domain:add></domain:update></update><extension><authExt:authActions xmlns:authExt="http://www.verisign.com/epp/authExt-1.0" xmlns:authSession="http://www.verisign.com/epp/authSession-1.0" xsi:schemaLocation="http://www.verisign.com/epp/authExt-1.0 authExt-1.0.xsd http://www.verisign.com/epp/authSession-1.0 authSession-1.0.xsd"><authExt:validate><authExt:tokenData><authExt:tokenProvider>VRSN</authExt:tokenProvider><authExt:token><authSession:serviceProvider>VIP</authSession:serviceProvider><authSession:credentialId>xyz1234</authSession:credentialId><authSession:crDate>2010-12-28T02:25:38.020500Z</authSession:crDate><authSession:exDate>2010-12-28T02:25:38.020500Z</authSession:exDate></authExt:token><authExt:signature>UjBsR09EbGhjZ0dTQUxNQUFBUUNBRU1tQ1p0dU1GUXhEUzhi</authExt:signature></authExt:tokenData></authExt:validate><authExt:bind><authExt:tokenDataList><authExt:tokenData><authExt:tokenProvider>VRSN</authExt:tokenProvider><authExt:token><authSession:serviceProvider>VIP</authSession:serviceProvider><authSession:credentialId>xyz456</authSession:credentialId><authSession:crDate>2001-12-17T09:30:47Z</authSession:crDate><authSession:exDate>2001-12-17T09:30:47Z</authSession:exDate></authExt:token><authExt:signature>UjBsR09EbGhjZ0dTQUxNQUFBUUNBRU1tQ1p0dU1GUXhEUzhi</authExt:signature></authExt:tokenData></authExt:tokenDataList></authExt:bind><authExt:unbind><authSession:credentialId>xyz1234</authSession:credentialId></authExt:unbind></authExt:authActions></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update auth.bind+auth.validate+auth.unbind build');

exit 0;
