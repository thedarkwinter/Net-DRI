## Domain Registry Interface, Handling of contact data for .SI
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

package Net::DRI::Data::Contact::ARNES;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

__PACKAGE__->register_attributes(qw(maticna emso));

=pod

=head1 NAME

Net::DRI::Data::Contact::ARNES - Handle .SI contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.SI specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 maticna()

stores maticna stevilka (organization id)

=head2 emso()

stores EMSO (individual id)

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

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

sub validate
{
 my ($self,$change)=@_;
 $change||=0;
 my @errs;

 $self->SUPER::validate($change); ## will trigger an Exception if problem

 push @errs,'maticna' if ($self->maticna() && $self->maticna()!~m/^\d{10}$/);
 push @errs,'emso'    if ($self->emso()    && $self->emso()!~m/^\d{13}$/);

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

sub init
{
 my ($self,$what,$ndr)=@_;

 if ($what eq 'create')
 {
  $self->srid('auto') unless defined($self->srid()); ## we can not choose the ID
 }
 return;
}


####################################################################################################
1;
