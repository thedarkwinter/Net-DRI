## Domain Registry Interface, PIR EPP extensions
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

package Net::DRI::Protocol::EPP::Extensions::PIR;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

sub setup
{
 my ($self,$rp)=@_;
 $self->ns({
  ipr       => ['urn:afilias:params:xml:ns:ipr-1.1','ipr-1.1.xsd'],
  idn       => ['urn:afilias:params:xml:ns:idn-1.0','idn-1.0.xsd'],
  oxrs      => ['urn:afilias:params:xml:ns:oxrs-1.1','oxrs-1.1.xsd'],
  registrar => ['urn:ietf:params:xml:ns:registrar-1.0','registrar-1.0.xsd'],
  validation 	=> ['urn:afilias:params:xml:ns:validation-1.0','validation-1.0.xsd'],
 });
 return;
}

sub default_extensions {
 my ($self,$pp) = @_;
 $self->{brown_fee_version} = $pp->{brown_fee_version} if exists $pp->{brown_fee_version};
 my @extensions = qw/GracePeriod SecDNS LaunchPhase Afilias::IPR Afilias::IDNLanguage Afilias::Message Afilias::Registrar Afilias::JSONMessage Afilias::Validation CentralNic::Fee/;
 return @extensions;
}



####################################################################################################

1;