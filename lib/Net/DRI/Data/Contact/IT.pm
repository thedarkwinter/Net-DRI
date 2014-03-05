## Domain Registry Interface, Handling of contact data for .IT
##
## Copyright (C) 2009-2010 Tower Technologies. All rights reserved.
##
## This program free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License v2.

package Net::DRI::Data::Contact::IT;

use strict;
use warnings;

use base qw / Net::DRI::Data::Contact /;

use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw/
       consent_for_publishing entity_type
       nationality_code reg_code /);

=pod

=head1 NAME

Net::DRI::Data::Contact::IT - Handle .IT contact data for Net::DRI

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>noc@towertech.itE<gt>

Please also see the SUPPORT file in the distribution.

=head1 AUTHOR

Alessandro Zummo, E<lt>a.zummo@towertech.itE<gt>

=head1 COPYRIGHT

Copyright (C) 2009-2010 Tower Technologies.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License v2 as published by
the Free Software Foundation.

See the LICENSE file that comes with this distribution for more details.


=cut


sub validate
{
       my ($self, $change) = @_;
       $change ||= 0;
       my @errs;
 
       $self->SUPER::validate($change);

       push @errs, 'consent_for_publishing'
               if defined $self->consent_for_publishing
               and $self->consent_for_publishing !~m/^(?:0|1)$/;
 
       push @errs, 'nationality_code'
               if defined $self->nationality_code
               and $self->nationality_code !~m/^[a-zA-Z]{2}$/;
 
       push @errs, 'entity_type'
               if defined $self->entity_type
               and $self->entity_type !~m/^[1-7]$/;
 
       Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: ' . join('/', @errs))
               if scalar @errs;

       return 1;
}

1;
