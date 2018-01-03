## Domain Registry Interface, Handling of contact data for NominetMMX
##
## Copyright (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Data::Contact::NominetMMX;

use strict;
use warnings;

use base qw(Net::DRI::Data::Contact);
__PACKAGE__->register_attributes(qw(accreditation_id accreditation_body accreditation_year jurisdiction_cc jurisdiction_sp));

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Data::Contact::NominetMMX - Handle NominetMMX contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for TANGO specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 accreditation_id(), accreditation_body(), jurisdiction_sp()

Token with maxLength value="256"

=head2 accreditation_year()

Token with length value="5"??? => Ask NominetMMX since it's not defined in their XSD - based in their tecnical example!

=head2 jurisdiction_cc()

Token with length value="2"

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT
Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
(c) 2015 Michael Holloway <michael@thedarkwinter.com>.
(c) 2015 Paulo Jorge <paullojorgge@gmail.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

####################################################################################################

sub validate
{
 my ($self,$change)=@_;
 $change||=0;
 my @errs;

 $self->SUPER::validate($change); ## will trigger an Exception if problem

 if ($self->accreditation_id() || $self->accreditation_body() || $self->accreditation_year() || $self->jurisdiction_cc())
 {
  Net::DRI::Exception::usererr_insufficient_parameters('accreditation_id, accreditation_body, accreditation_year and jurisdiction_cc are mandatory for MAM Qualified Lawyer extension!') unless ($self->accreditation_id() && $self->accreditation_body() && $self->accreditation_year() && $self->jurisdiction_cc());
  push @errs, 'accreditation_id, accreditation_body and jurisdiction_sp should exist and should be a string between 1 and 256 characters' unless (Net::DRI::Util::xml_is_token($self->accreditation_id(),1,256) && Net::DRI::Util::xml_is_token($self->accreditation_body(),1,256) && Net::DRI::Util::xml_is_token($self->jurisdiction_sp(),1,256));
  push @errs, 'accreditation_year is represented by a four­‐digit year including the century (ex.: 2015Z)' unless Net::DRI::Util::xml_is_token($self->accreditation_year(),5,5);
  push @errs, 'jurisdiction_cc should be a string with 2 characters (ex.: US)' unless Net::DRI::Util::xml_is_token($self->jurisdiction_cc(),2,2);
  Net::DRI::Exception::usererr_invalid_parameters(join(' / ',@errs)) if @errs;
 }

 return 1; ## everything ok
}

####################################################################################################
1;
