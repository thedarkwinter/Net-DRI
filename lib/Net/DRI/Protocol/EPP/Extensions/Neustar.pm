## Domain Registry Interface, Neustar New gTLD EPP extensions
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::Neustar;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

sub setup
{
 my ($self,$rp)=@_;
 $self->ns({neulevel => ['urn:ietf:params:xml:ns:neulevel-1.0','neulevel-1.0.xsd']});
 return;
}

sub default_extensions {
 my ($self,$pp) = @_;
 $self->{brown_fee_version} = $pp->{brown_fee_version} if exists $pp->{brown_fee_version};
 my @ext = qw/GracePeriod SecDNS LaunchPhase IDN AllocationToken NeuLevel::Message NeuLevel::EXTContact NeuLevel::WhoisType/;
 if (exists $pp->{custom} )
 {
   my @custom = (ref $pp->{custom} eq 'ARRAY') ? @{$pp->{custom}} : ($pp->{custom});
   foreach (@custom) { push @ext,$_; }
 }
 return @ext;
}

####################################################################################################
1;
