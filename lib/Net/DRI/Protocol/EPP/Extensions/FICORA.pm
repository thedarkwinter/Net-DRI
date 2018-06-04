## Domain Registry Interface, .FI
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::FICORA;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;
use Net::DRI::Data::Contact::FICORA;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FICORA for Net::DRI

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

Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub setup {
  my ( $self, $rp ) = @_;
  $self->factories('contact',sub { return Net::DRI::Data::Contact::FICORA->new(); });
  $self->ns({ 'domain-ext'  => ['urn:ietf:params:xml:ns:domain-ext-1.0','domain-ext-1.0.xsd'] });
  $self->capabilities('domain_update','auth',[ 'del', 'set' ]);
  $self->capabilities('domain_update','registrylock',[ 'set' ]);

  return;
}

sub core_contact_types { return ('billing', 'tech'); } ## Since GDPR, no admin contact - FICORA permit the creation of a domain object with admin type but its not listed on any EPP response
sub default_extensions { return qw/FICORA::Balance FICORA::Contact FICORA::Domain FICORA::Message SecDNS/; }

####################################################################################################
1;
