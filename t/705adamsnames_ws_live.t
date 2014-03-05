#!/usr/bin/perl -w

use Net::DRI;
use Test::More;

unless ($ENV{TEST_ADAMSNAMES_WS_LIVE})
{
 plan skip_all => 'Set $ENV{TEST_ADAMSNAMES_WS_LIVE} if you want harmless *live* tests for AdamsNames';
} else
{
 plan tests => 4;
}

my $ok=eval
{
 my $dri=Net::DRI->new({cache_ttl => 10});
 $dri->add_registry('AdamsNames');
 $dri->target('AdamsNames')->add_current_profile('p1','ws');
 my $rc=$dri->domain_info('adamsnames.tc');
 is($rc->is_success(),1,'domain_info(adamsnames.tc) is_success');
 is($rc->get_data('exist'),1,'domain_info(adamsnames.tc) get_data(exist)');
 is($rc->get_data('crDate').'','1998-08-28T00:00:00','domain_info(adamsnames.tc) get_data(crDate)');
 is($rc->get_data('roid'),'ada4404.tc','domain_info(adamsnames.tc) get_data(roid)');

 $dri->end();
};

diag('Caught unexpected exception: '.(ref($@)? $@->as_string() : $@)) if ! $ok;

exit 0;
