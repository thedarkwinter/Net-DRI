## Domain Registry Interface, Handling of contact data for BR
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

package Net::DRI::Data::Contact::BR;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(orgid type associated_contacts associated_domains responsible proxy));

=pod

=head1 NAME

Net::DRI::Data::Contact::BR - Handle BR contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
BR specific data.

=head1 METHODS

The following mutators can be called in chain, as they all return the object itself.

=head2 orgid()

organization id

=head2 type()

type of contact (admin, billing or member)

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

 if (!$change)
 {
##  Net::DRI::Exception::usererr_insufficient_parameters('orgid is mandatory') unless $self->orgid();
 }

 push @errs,'orgid' if ($self->orgid() && !Net::DRI::Util::xml_is_token($self->orgid(),1,30));

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

sub init
{
 my ($self,$what,$ndr)=@_;

 if ($what eq 'create')
 {
  $self->srid('auto') unless defined($self->srid()); ## we can not choose the ID for pure contacts (but we can for brorg creations it seems)
 }
 return;
}

####################################################################################################
1;
