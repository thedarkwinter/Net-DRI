## Domain Registry Interface, Telnic (.TEL) EPP extensions
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Telnic;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

sub setup
{
 my ($self,$rp)=@_;
 $self->ns({
            neulevel  => ['urn:ietf:params:xml:ns:neulevel-1.0','neulevel-1.0.xsd'],
           });
 $self->capabilities('domain_update','whois_type',['set']);

 return;
}

sub default_extensions { return qw/NeuLevel::IDNLanguage NeuLevel::UIN NeuLevel::WhoisType/; }

####################################################################################################
1;
