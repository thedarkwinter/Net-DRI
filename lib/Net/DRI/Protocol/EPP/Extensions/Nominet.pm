## Domain Registry Interface, .UK EPP extensions
## As seen on http://www.nominet.org.uk/registrars/systems/epp/ and http://www.nominet.org.uk/digitalAssets/16844_EPP_Mapping.pdf
##
## Copyright (c) 2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::Nominet;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet - .UK EPP extensions for Net::DRI

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

Copyright (c) 2008,2009 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
 my @extNS=qw/contact-nom-ext-1.0 domain-nom-ext-1.2 std-contact-id-1.0 std-fork-1.0 std-handshake-1.0 std-list-1.0 std-locks-1.0 std-notifications-1.2 std-release-1.0 std-unrenew-1.0 std-warning-1.1 nom-abuse-feed-1.0/;
 foreach my $ns (@extNS) { $self->ns({ (split(/-([^-]+)$/,$ns))[0] => ['http://www.nominet.org.uk/epp/xml/'.$ns,$ns.'.xsd'] }); }
 foreach my $o (qw/first-bill recur-bill auto-bill next-bill notes reseller auto-period next-period renew-not-required/) { $self->capabilities('domain_update',$o,['set']); }
 $self->factories('contact',sub { return Net::DRI::Data::Contact::Nominet->new(); });
 $self->default_parameters({domain_create => { auth => { pw => '' } } }); ## domain:authInfo is not used by Nominet
 return;
}

sub core_contact_types { return (); }
sub default_extensions { return qw/Nominet::Session Nominet::Message Nominet::Domain Nominet::Contact Nominet::Notifications/; }


####################################################################################################
1;
