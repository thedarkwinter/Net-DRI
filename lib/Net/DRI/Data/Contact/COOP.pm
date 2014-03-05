## Domain Registry Interface, Handling of contact data for .COOP
##
## Copyright (c) 2006-2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::COOP;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(sponsors state lang mailing_list));

=pod

=head1 NAME

Net::DRI::Data::Contact::COOP - Handle .COOP contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.COOP specific data.

Organizations must have names and phone numbers.

Contact ids must begin with a prefix given by the registry (tied to the registrar account).
If you specify a localized version for data, you need the internationalized version also
(see documentation of Net::DRI::Data::Contact and its loc2int method) ; you can however
specify just internationalized data, without a localized version.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 sponsors()

list of sponsors as registry contact ids (mandatory for registrants, at least 2)

=head2 state()

verification state : verified, pendingVerification, ableToApeal, underInvestigation, refused

=head2 lang()

language of contact

=head2 mailing_list()

boolean showing opt-in status of contact for .COOP newsletters

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006-2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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

 if ($self->sponsors())
 {
  foreach my $id (ref($self->sponsors())? @{$self->sponsors()} : ($self->sponsors()))
  {
   next if Net::DRI::Util::xml_is_token($id,3,16); ## clIDType
   push @errs,'sponsors';
   last;
  }
 }
 push @errs,'lang' if ($self->lang() && !Net::DRI::Util::xml_is_language($self->lang()));
 push @errs,'mailing_list' if ($self->mailing_list() && !Net::DRI::Util::xml_is_boolean($self->mailing_list()));

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

####################################################################################################
1;
