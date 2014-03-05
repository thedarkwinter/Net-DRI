#!/usr/bin/perl -w

use Net::DRI;
use Test::More;

unless ($ENV{TEST_BOOKMYNAME_WS_LIVE_CLIENTID} && $ENV{TEST_BOOKMYNAME_WS_LIVE_CLIENTPASS})
{
 plan skip_all => 'Set $ENV{TEST_BOOKMYNAME_WS_LIVE_CLIENTID} and $ENV{TEST_BOOKMYNAME_WS_LIVE_CLIENTPASS} if you want (normally harmless) *live* tests for BookMyName';
} else
{
 plan tests => 4;
}

my $dri=Net::DRI->new({cache_ttl => 10});
$dri->add_registry('BookMyName');
$dri->target('BookMyName')->add_current_profile('p1','ws',{client_login=>$ENV{TEST_BOOKMYNAME_WS_LIVE_CLIENTID},client_password=>$ENV{TEST_BOOKMYNAME_WS_LIVE_CLIENTPASS}});

my $ok=eval {
 my $rc=$dri->account_list_domains();
 diag('Got session ID '.$dri->transport()->session_data()->{id});
 is($rc->is_success(),1,'account_list_domains() is_success') or diag(sprintf('Code=%s Native_Code=%d Message=%s',$rc->code(),$rc->native_code(),$rc->message()));
 my $rd=$dri->get_info('list','account','domains');
 is(ref($rd),'ARRAY','get_info(list,account,domains)');
 diag('Successfully retrieved list of '.scalar(@$rd).' domain names: '.join(' ',@$rd));
 my $rd2=$dri->get_info('list');
 is_deeply($rd2,$rd,'get_info(list,account,domains) and get_info(list) give the same results');

 $rc=$dri->domain_info($rd->[0]);
 is($rc->is_success(),1,'domain_info() is_success') or diag(sprintf('Code=%s Native_Code=%d Message=%s',$rc->code(),$rc->native_code(),$rc->message()));
 my @i=$dri->get_info_keys();
 diag('Successfully got information about: '.join(' ',@i));

 $dri->end();
};

diag('Caught unexpected exception: '.(ref($@)? $@->as_string() : $@)) if ! $ok;

exit 0;
