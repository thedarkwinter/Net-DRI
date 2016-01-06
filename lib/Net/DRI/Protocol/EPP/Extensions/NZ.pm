## Domain Registry Interface, .NZ policies
##
## Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2016 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2016 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NZ;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::NZ;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NZ - .NZ EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>;
Michael Holloway E<lt>michael@thedarkwinter.comE<gt>;
Patrick Mevzek E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2016: Paulo Jorge <paullojorgge@gmail.com>; 
Michael Holloway <michael@thedarkwinter.com>;
Patrick Mevzek <netdri@dotandco.com>.
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
 
 # contact
 $self->capabilities('contact_update','info',['set']); # no add or remove option should be used with the <contact:update> command
 foreach my $o (qw/auth disclose status/) { $self->capabilities('contact_update',$o,undef); } # No status updates are possible for contact objects. No AuthInfo and Disclosure information is stored for contact objects. Therefore these details cannot be updated with a <contact:update>
 $self->factories('contact',sub { return Net::DRI::Data::Contact::NZ->new(); });
 # domain
 $self->default_parameters({domain_create => { auth => { pw => '' } } }); # send always empty since a UDAI is generated with a domain create. The UDAI is placed in the registrar's message queue for retrieval.

 return;
}

sub default_extensions { return qw/SecDNS/; }

####################################################################################################
1;
