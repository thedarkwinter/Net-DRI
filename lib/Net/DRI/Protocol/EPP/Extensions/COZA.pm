## Domain Registry Interface, CO.ZA EPP extensions
## From http://registry.coza.net.za/doku.php?id=technical
##
## Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::COZA;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::COZA;

####################################################################################################

sub setup
{
 my ($self,$rp)=@_;
 $self->capabilities('contact_update','status',undef); ## No changes in status possible for .CO.ZA contacts
 $self->capabilities('contact_update','cancel_action',['set']);
 $self->capabilities('domain_update','cancel_action',['set']);
 $self->capabilities('domain_update','auto_renew',['set']);
 $self->factories('contact',sub { return Net::DRI::Data::Contact::COZA->new(); });
 return;
}

sub default_extensions { return qw/COZA::Contact COZA::Domain/; }

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::COZA - .CO.ZA EPP extensions for Net::DRI

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

Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

