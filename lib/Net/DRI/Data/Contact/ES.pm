## Domain Registry Interface, Handling of contact data for ES
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Data::Contact::ES;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Net::DRI::DRD::EURid;
use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(tipo_identificacion identificacion form_juridica ));

=pod

=head1 NAME

Net::DRI::Data::Contact::ES - Handle ES contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
ES specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 es_tipo_identificacion()

Indicates the type of identification number given in the <es_identificacion> element, and also determines whether this should be validated. It can be 0, corresponding with an “Other Identification type of ID number” –a  generic type that the  application does not check; 1,corresponding to DNIand NIF formats thatmust be checked;and 3, correspondingthe NIE formats thatshould also bechecked by theapplication.

=head2 es_identificacion()

Indicates the legal ID number (passport,DNI,VAT ID,registration number) of the contact.

=head2 es_form_juridica())

Indicates the legal form of the contact company, determining whether the contact is a private person (individual) or an organisation (legal entity).

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT
Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
                       (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
 # 'org' field is not EPP enable anymore. For the name of legal entity, it must be entered in 'name'
 push @errs,'org is not EPP enable - for the name of the legal entity it must be intered in name' if  defined($self->org());
 push @errs,'tipo_identificacion' unless (defined($self->tipo_identificacion()) && $self->tipo_identificacion() =~ m/^(0|1|3)$/);
 push @errs,'identificacion' unless defined($self->identificacion());
 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;
 return 1; ## everything ok.
}

sub init
{
 my ($self,$what,$ndr)=@_;
 if ($what eq 'create')
 {
  my $a=$self->auth();
  $self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw})); ## authInfo is not used
  $self->street( [join ", ", @{ $self->street() }] ); # street is 1 line
  delete $self->{fax};
 }
}
####################################################################################################
1;
