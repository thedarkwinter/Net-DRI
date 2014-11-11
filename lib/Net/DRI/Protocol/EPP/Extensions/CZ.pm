## Domain Registry Interface, .CZ EPP extensions
##
## Copyright (c) 2008,2009,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##                    All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CZ;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CZ - .CZ EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt> or
E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2009,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
 $self->{defaulti18ntype}='loc'; # The registry does not provide contact postalinfo i18n type, although it is mandatory by EPP
 $self->ns({ domain  => ['http://www.nic.cz/xml/epp/domain-1.4','domain-1.4.xsd'],
             contact => ['http://www.nic.cz/xml/epp/contact-1.5','contact-1.5.xsd'],
          });
 $self->capabilities('domain_update','status',undef);
 $self->capabilities('domain_update','nsset',['set']);
 $self->capabilities('nsset_update','ns',['add','del']);
 $self->capabilities('nsset_update','contact',['add','del']);
 $self->capabilities('nsset_update','auth',['set']);
 $self->capabilities('nsset_update','reportlevel',['set']);
 return;
}

sub core_contact_types { return ('admin','tech','billing','onsite'); }
sub default_extensions { return qw/CZ::NSSET CZ::Contact CZ::Domain NSgroup/; }

####################################################################################################
1;
