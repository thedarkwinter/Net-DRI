## Domain Registry Interface, Handling of contact data for .PT
##
## Copyright (c) 2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::FCCN;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(type identification mobile));

=pod

=head1 NAME

Net::DRI::Data::Contact::FCCN - Handle FCCN (.PT) contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.PT specific data.

=head1 METHODS

The following mutators can be called in chain, as they all return the object itself.

=head2 type()

type of contact (individual or organization)

=head2 identification()

formal identification of the contact

=head2 mobile()

mobile number of the contact

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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
  Net::DRI::Exception::usererr_insufficient_parameters('identification is mandatory') unless ($self->identification() && Net::DRI::Util::has_key($self->identification(),'value'));
 }

 push @errs,'type' if ($self->type() && $self->type()!~m/^(?:individual|organization)$/);
 push @errs,'identification' if ($self->identification() && (($self->identification()->{type} && $self->identification()->{type}!~m/^(?:010|020|030|040|110)$/) || (! Net::DRI::Util::xml_is_token($self->identification()->{value},1,20))));
 push @errs,'mobile' if ($self->mobile() && !Net::DRI::Util::xml_is_token($self->mobile(),undef,17) && $self->mobile()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/);

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

####################################################################################################
1;
