## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::DRD::TCI_gTLD;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

#__PACKAGE__->make_exception_for_unavailable_operations(qw/host_check host_info host_update host_delete host_create contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse domain_renew/);

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'TCI_gTLD'; }
sub tlds     { return ('xn--80adxhks', 'xn--d1acj3b', 'tatar', 'moscow'); } # testing : 'xn--1-7sbc5ceg', 'xn--2-7sbc5ceg',
sub object_types { return ('domain','contact','host'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::TCI_gTLD',{}) if $type eq 'epp';
 return;
}

####################################################################################################
1;
