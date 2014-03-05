## Domain Registry Interface, Handling of contact data for .CAT
##
## Copyright (c) 2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::CAT;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Email::Valid;
use Net::DRI::Util;
use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(lang email_sponsor maintainer));

=pod

=head1 NAME

Net::DRI::Data::Contact::CAT - Handle .CAT contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.CAT specific data.

.CAT uses only localized data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 lang()

optional language of contact, according to RFC3066

=head2 maintainer()

optional free-form element that is published in whois

=head2 email_sponsor()

e-mail address to use when participating in the community sponsoring model of the puntCAT registry ; 
may be identical to the primary e-mail address

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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

 push @errs,'lang'          if ($self->lang() && !Net::DRI::Util::xml_is_language($self->lang()));
 push @errs,'maintainer'    if ($self->maintainer() && !Net::DRI::Util::xml_is_token($self->maintainer(),undef,128));
 push @errs,'email_sponsor' if ($self->email_sponsor() && !Net::DRI::Util::xml_is_token($self->email_sponsor(),1,undef) && !Email::Valid->rfc822($self->email_sponsor()));

 push @errs,'srid'          if ($self->srid() && $self->srid()=~m/^REG-/);

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

####################################################################################################
1;
