#!/usr/bin/perl -w

use Net::DRI;
use Test::More;

unless ($ENV{TEST_OPENSRS_XCP_LIVE_CLIENTID} && $ENV{TEST_OPENSRS_XCP_LIVE_CLIENTPASS})
{
 plan skip_all => 'Set $ENV{TEST_OPENSRS_XCP_LIVE_CLIENTID} and $ENV{TEST_OPENSRS_XCP_LIVE_CLIENTPASS} (the key) if you want (normally harmless) *live* tests for OpenSRS';
} else
{
 plan tests => 3;
}

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->add_registry('OpenSRS');
$dri->target('OpenSRS')->add_current_profile('p1','xcp',{client_login=>$ENV{TEST_OPENSRS_XCP_LIVE_CLIENTID},client_password=>$ENV{TEST_OPENSRS_XCP_LIVE_CLIENTPASS},remote_url=>'https://rr-n1-tor.opensrs.net:55443/resellers/',verify_response => \&verify_response});

my $ok=eval 
{
 my $rc=$dri->account_list_domains();
 is($rc->is_success(),1,'account_list_domains() is_success') or diag(sprintf('Code=%d Native_Code=%s Message=%s',$rc->code(),$rc->native_code(),$rc->message()));
 my $rd=$dri->get_info('list','account','domains');
 is(ref($rd),'ARRAY','get_info(list,account,domains)');
 diag('Successfully retrieved list of '.scalar(@$rd).' domain names: '.join(' ',@$rd)) if ($rd && ref($rd) eq 'ARRAY');
 my $rd2=$dri->get_info('list');
 is_deeply($rd2,$rd,'get_info(list,account,domains) and get_info(list) give the same results');

## If you have a domain name, you could get back information like that:
## (it seems username and password are mandatory for domain_info, and they have nothing to do with reseller login/key)
#  $rc=$dri->domain_info('DOMAIN',{username => 'USERNAME', password => 'PASSWORD'});
#  diag('Nameservers: '.$dri->get_info('ns')->as_string());
#  diag('Expiration: '.$dri->get_info('exDate'));
#  diag('Auto Renew: '.$dri->get_info('auto_renew'));
#  diag('Owner Contact: '.$dri->get_info('contact')->get('registrant')->as_string());
#  diag('Admin Contact: '.$dri->get_info('contact')->get('admin')->as_string());
#  diag('Tech Contact: '.$dri->get_info('contact')->get('tech')->as_string());

 $dri->end();
};

diag('Caught unexpected exception: '.(ref($@)? $@->as_string() : $@)) if ! $ok;

exit 0;

sub verify_response
{
 my ($to,$phase,$count,$req,$ans)=@_; ## Transport object, Phase (1=login,2=normal operations,3=logout), Count (number of times we tried sending that message), HTTP::Request and HTTP::Response objects

 ## If you need to verify SSL stuff right at the beginning before sending anything, use header If-SSL-Cert-Subject (see LWP::Protocol::https)
 diag('Got SSL Cert Issuer: '.$ans->header('Client-SSL-Cert-Issuer'));
 diag('Got SSL Cert Subject: '.$ans->header('Client-SSL-Cert-Subject'));
 diag('Got SSL Cipher: '.$ans->header('Client-SSL-Cipher'));
 diag('Got SSL Warning: '.$ans->header('Client-SSL-Warning'));
}

