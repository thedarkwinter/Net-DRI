## Domain Registry Interface, AE EPP extensions (http://labs.centralnic.com/epp/ext/)
##
##
##           (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AE;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

sub setup {
 my ( $self, $rp ) = @_;
 $self->factories('idn',sub { return @_ }); # Overide standard IDN data object conversion, use suplied data hash
 return;
}

sub default_extensions {
 my ($self,$pp) = @_;
 my @extensions = qw/GracePeriod SecDNS LaunchPhase AusRegistry::IDN AusRegistry::KeyValue AusRegistry::Price AusRegistry::Sync AusRegistry::Variant/;
 return @extensions;
}

####################################################################################################
1;
