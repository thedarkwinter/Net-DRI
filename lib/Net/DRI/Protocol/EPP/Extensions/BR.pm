## Domain Registry Interface, .BR EPP extensions
##
## Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::BR;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::BR;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::BR - .BR EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub setup
{
 my ($self,$rp)=@_;
 $self->ns({brdomain=> ['urn:ietf:params:xml:ns:brdomain-1.0','brdomain-1.0.xsd'],
            brorg   => ['urn:ietf:params:xml:ns:brorg-1.0','brorg-1.0.xsd'],
           });
 $self->capabilities('domain_update','ticket',['set']);
 $self->capabilities('domain_update','release',['set']);
 $self->capabilities('domain_update','auto_renew',['set']);
 $self->capabilities('contact_update','associated_contacts',['add','del']);
 $self->capabilities('contact_update','responsible',['set']);
 $self->factories('contact',sub { return Net::DRI::Data::Contact::BR->new(); });
 return;
}

sub default_extensions { return qw/BR::Domain BR::Contact SecDNS/; }

####################################################################################################
1;
