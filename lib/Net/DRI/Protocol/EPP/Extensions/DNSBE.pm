## Domain Registry Interface, DNSBE EPP extensions
##
## Copyright (c) 2006-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::DNSBE;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::BE;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DNSBE - DNSBE (.BE) EPP extensions for Net::DRI

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

Copyright (c) 2006-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my $version=$self->version();
 $self->ns({ dnsbe   => ['http://www.dns.be/xml/epp/dnsbe-1.0','dnsbe-1.0.xsd'],
             nsgroup => ['http://www.dns.be/xml/epp/nsgroup-1.0','nsgroup-1.0.xsd'],
             keygroup=> ['http://www.dns.be/xml/epp/keygroup-1.0','keygroup-1.0.xsd'],
          });
 $self->capabilities('contact_update','status',undef); ## No changes in status possible for .BE domains/contacts
 $self->capabilities('domain_update','status',undef);
 $self->capabilities('domain_update','auth',undef); ## No change in authinfo (since it is not used from the beginning)
 $self->capabilities('domain_update','nsgroup',['add','del']);
 $self->factories('contact',sub { return Net::DRI::Data::Contact::BE->new(); });
 $self->default_parameters({domain_create => { auth => { pw => '' } } });
 return;
}

sub core_contact_types { return ('admin','tech','billing','onsite'); }
sub default_extensions { return qw/DNSBE::Message DNSBE::Domain DNSBE::Contact DNSBE::Notifications NSgroup Keygroup SecDNS/; }

####################################################################################################
1;
