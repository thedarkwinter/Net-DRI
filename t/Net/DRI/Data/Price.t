#!/usr/bin/perl -w

use strict;
use Net::DRI::Data::Price;
use DateTime;

use Data::Dumper;
use Test::More tests => 40;

################################################################################
## Example 1: Standard Pricing + Sunrise Application Fee
##  - Using set() 
my $p = Net::DRI::Data::Price->new(
    premium => 0, 
    currency => 'USD', 
    category => 'standard', 
    category_name => 'Standard Price'
    );
isa_ok($p,'Net::DRI::Data::Price');
is($p->premium(),0,'Price is not premium');
is($p->currency(),'USD','Price currency');
is($p->category(),'standard', 'Price category');
is($p->category_name(),'Standard Price','Price category_name');

## a registration fee for 2 years, refundable for 5 days (rgp)
$p->set('registration', { 
    price => 10.00, 
    period => DateTime::Duration->new(years => 2),  # integeger also valid
    refundable => 1, 
    refund_period => DateTime::Duration->new(days => 5), # integeger also valid
    });
is($p->registration->price(),10.00,'Price registration price');
isa_ok($p->registration->period(),'DateTime::Duration','Price period isa DateTime::Duration');
is($p->registration->period()->years(),2,'Price period');
is($p->registration->refundable(),1,'Price refundable');
isa_ok($p->registration->refund_period(),'DateTime::Duration','Price refund_period isa DateTime::Duration');
is($p->registration->refund_period()->in_units('days'),5,'Price refund_period');

## a non refundable application fee, period set to one year for testing, probably useless
$p->set('application', { 
    price => 125.00, 
    period => 1, 
    refundable => 0, 
    'comment' => 'Sunrise Application Fee',
    });
is($p->application->price(),125.00,'Price application price');
isa_ok($p->application->period(),'DateTime::Duration','Price period isa DateTime::Duration');
is($p->application->period()->years(),1,'Price period');
is($p->application->refundable(),0,'Price refundable');
isa_ok($p->application->refund_period(),'DateTime::Duration','Price refund_period isa DateTime::Duration');
is($p->application->refund_period()->in_units('days'),0,'Price refund_period');

## these are not defined for whatever reason (not looked up, not needed, not supported etc)
is($p->renew()->price(), undef, 'Price renew (not defined)');
is($p->transfer()->price(), undef, 'Price transfer (not defined)');
is($p->restore()->price(), undef, 'Price restore (not defined)');


################################################################################
## Example 2: Premium Pricing, No Application Fee
##  - Using set_all() 

$p = Net::DRI::Data::Price->new(
    premium => 1, 
    currency => 'USD', 
    category => 'lux', 
    category_name => 'Luxury Goods'
    );
isa_ok($p,'Net::DRI::Data::Price');
is($p->premium(),1,'Price is premium');
is($p->currency(),'USD','Price currency');
is($p->category(),'lux', 'Price category');
is($p->category_name(),'Luxury Goods','Price category_name');

$p->set_all(
  'registration' => { price => 500.00, period => 1, refundable => 1, refund_period => DateTime::Duration->new(days => 5), comment => 'Premium Registration Fee' },
  'renew' => { price => 500.00,  period => 1, refundable => 1, refund_period => DateTime::Duration->new(days => 45), comment => 'Premium Renewal Fee' },
  'transfer' => { price => 500.00,  refundable => 0, comment => 'Premium Transfer Fee' },
  'restore' => { price => 120.00,  refundable => 0, comment => 'Premium Restore Fee' },
  );

# application
is($p->application->price(),undef,'Price application price (undef)');

# registration
is($p->registration->price(),500.00,'Price registration price');
isa_ok($p->registration->period(),'DateTime::Duration','Price period isa DateTime::Duration');
is($p->registration->period()->years(),1,'Price period');
is($p->registration->refundable(),1,'Price refundable');
isa_ok($p->registration->refund_period(),'DateTime::Duration','Price refund_period isa DateTime::Duration');
is($p->registration->refund_period()->in_units('days'),5,'Price refund_period');

# renew
is($p->renew->price(),500.00,'Price renew price');
isa_ok($p->renew->period(),'DateTime::Duration','Price period isa DateTime::Duration');
is($p->renew->period()->years(),1,'Price period');
is($p->renew->refundable(),1,'Price refundable');
isa_ok($p->renew->refund_period(),'DateTime::Duration','Price refund_period isa DateTime::Duration');
is($p->renew()->refund_period()->in_units('days'),45,'Price refund_period');

# transfer
is($p->transfer->price(),500.00,'Price transfer price');

# restore
is($p->restore->price(),120.00,'Price restore price');

exit 0;