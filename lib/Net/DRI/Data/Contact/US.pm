## Domain Registry Interface, Handling of contact data for .US
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

package Net::DRI::Data::Contact::US;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Util;
use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(application_purpose nexus_category));

=pod

=head1 NAME

Net::DRI::Data::Contact::US - Handle .US contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.US specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.
They are needed only for registrant contacts.

=head2 application_purpose()

intended usage for the domain name

=head2 nexus_category()

the nexus cateogry

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

 if (defined($self->application_purpose()))
 {
  push @errs,'application_purpose' unless ($self->application_purpose()=~m/^P[1-5]$/ || ($change && ($self->application_purpose() eq '')));
 }

 if (defined($self->nexus_category()))
 {
  push @errs,'nexus_category' unless ($self->nexus_category()=~m!^C(?:1[12]|21|3[12]/([A-Z][A-Z]))$! || ($change && ($self->nexus_category() eq '')));
  push @errs,'nexus_category' if ($1 && !exists($Net::DRI::Util::CCA2{$1}));
 }

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

####################################################################################################
1;
