## Domain Registry Interface, Handling of contact data
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

#####
package Net::DRI::Data::PriceSet;

use utf8;
use strict;
use warnings;

use base qw(Class::Accessor::Chained); ## provides a new() method

our @ATTRS=qw(price period refundable refund_period comment);
__PACKAGE__->mk_accessors(@ATTRS);

sub new
{
 my $class = shift;
 my $self = bless {@_}, $class;
 return $self;
}

#####

package Net::DRI::Data::Price;

use utf8;
use strict;
use warnings;

use base qw(Class::Accessor::Chained); ## provides a new() method
use DateTime::Duration;
use Net::DRI::Util;
use Net::DRI::Exception;

our @ATTRS=qw(premium category category_name currency accept application registration renew restore transfer);
__PACKAGE__->mk_accessors(@ATTRS);

####################################################################################################

sub new
{
 my $class = shift;
 my $self = bless {@_}, $class;
 foreach my $type (qw/application registration renew restore transfer/) {
  $self->{$type} = Net::DRI::Data::PriceSet->new();
 }
 return $self;
}

sub set
{
 my ($self, $type, $rd) = @_;
 if ($type =~ m/application|registration|renew|restore|transfer/) {
  $self->{$type} = Net::DRI::Data::PriceSet->new(%{$rd});
  $self->{$type}->{period} = DateTime::Duration->new() unless $rd->{period};
  $self->{$type}->{period} = DateTime::Duration->new(years => $rd->{period}) if $rd->{period} && $rd->{period} =~ m/^[0-9]$/;
  $self->{$type}->{refund_period} = DateTime::Duration->new() unless $rd->{refund_period};
  $self->{$type}->{refund_period} = DateTime::Duration->new($rd->{refund_period}) if $rd->{refund_period} && $rd->{refund_period} =~ m/^[0-9]$/;
 }
}

sub set_all
{
 use Data::Dumper;
 my ($self, @sets) = @_;
 my $sets = { @sets };
 foreach my $type (qw/application registration renew restore transfer/) {
  next unless exists $sets->{$type};
  $self->set($type, $sets->{$type});
 }
}

sub clone
{
 my ($self)=@_;
 my $new=Net::DRI::Util::deepcopy($self);
 return $new;
}

####################################################################################################
1;
