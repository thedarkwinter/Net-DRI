## Domain Registry Interface, ARI EPP extensions
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ARI;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

sub setup {
 my ($self,$rp)=@_;
 $self->ns({neulevel => ['urn:ietf:params:xml:ns:neulevel-1.0','neulevel-1.0.xsd']});
 return;
}

sub default_extensions {
  my ($self,$pp) = @_;
  my @ext = qw/GracePeriod SecDNS AllocationToken ARI::IDNVariant ARI::KeyValue ARI::ExAvail ARI::Price ARI::TMCHApplication ARI::Block NeuLevel::Message NeuLevel::WhoisType NeuLevel::EXTContact/;
  if (exists $pp->{custom} ) {
    my @custom = (ref $pp->{custom} eq 'ARRAY') ? @{$pp->{custom}} : ($pp->{custom});
    foreach (@custom) {
      push @ext,$_;
    }
  }
  return @ext;
}

####################################################################################################
1;
