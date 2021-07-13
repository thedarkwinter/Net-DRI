## Domain Registry Interface, Handling of contact data for GoDaddy registry
##
## Copyright (c) 2006,2008-2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
## Copyright (c) 2021 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Data::Contact::GoDaddy;

use utf8;
use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Email::Valid;

use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(application_purpose ext_contact nexus_category));

=pod

=head1 NAME

Net::DRI::Data::Contact::GoDaddy - Handle GoDaddy registry contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for GoDaddy registry specific data.
Please read the following in order to understand what's mandatory for .US and .NYC domains!

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 application_purpose()

For .US domains the registrant need to meet some Nexus requirements. A Nexus category and App purpose are mandatory! Other contacts may have this as well, but are not required to.

=head4 Intended Usage of Domain:

P1 = Business for profit

P2 = Nonprofit

P3 = Personal

P4 = Educational

P5 = Governmental

=head2 nexus_category()

=head4 Nexus Category - .NYC:

For .NYC domains one of the contacts must be based in New York, and the nexus category must be one of INDIV or ORG.

=head4 Nexus Category - .US:

For .US domains the nexus category must be:

C11 (US Citizen)

C12 (Permanent Resident)

C21 (US organization)

C31 (Foreign organization doing business in US)

C32 (Foreign organization with US office)

=head2 ext_contact()

For .NYC domains the nexus contact need to be: Y/N.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmailcomE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
(c) 2014 Michael Holloway <michael@thedarkwinter.com>.
(c) 2021 Paulo Jorge <paullojorgge@gmail.com>.
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
 $self->SUPER::validate(1); ## will trigger an Exception if problem
 my @errs;
 return 1 unless $self->nexus_category();

 if (defined($self->application_purpose()))
 {
  push @errs,'application_purpose' unless ($self->application_purpose()=~m/^P[1-5]$/ || ($change && ($self->application_purpose() eq '')));
 }

 return 1;
}

####################################################################################################
1;
