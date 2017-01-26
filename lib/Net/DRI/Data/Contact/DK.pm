## Domain Registry Interface, Handling of contact data for .DK
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
## Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Data::Contact::DK;

use strict;
use warnings;

use base qw(Net::DRI::Data::Contact);

use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(vat type ean pnumber mobile alt_email contact_validated));

=pod

=head1 NAME

Net::DRI::Data::Contact::DK - Handle DK contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
DK specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 type()

Type - which has to be one of:

- company - indicating a company

- public_organization - indicating a public organization

- association - indicating an association

- individual - indicating an individual

=head2 ean()

EAN - this number is only supported for user types: company, public_organization and association. It is only mandatory for public_organization and optional for company and association. EAN is used by the public sector in Denmark for electronic invoicing, private companies can also be assigned EAN, but this it not so widespread at this time. EAN is required by law for public sector organisations, so this field has to be completed and it has to validate for this type

=head2 orgno()

orgno is an alias of ean.

=head2 cvr()

CVR - (VAT number) this is only supported for user types: company, public_organization and association. The number is required for handling VAT correctly, mandatory for user types company and public_organization and optional for the user type association.

=head2 vat()

vat is an alias of cvr.

=head2 vatno()

vatno is an alias of cvr.

=head2 pnumber()

pnumber - (production unit number) this is only supported for user types: company, public_organization and association. The number is used for handling validation correctly and the field is optional.

=head2 mobile()

Contact objects can have a mobile phone number in addition to voice and fax

=head2 mobile_phone()

mobile_phone is an alias of mobile

=head2 alt_email()

Contact objects can have a secondary email address in addition to email

=head2 secondary_mail()

secondary_mail is an alias of alt_email

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

#aliases
sub cvr { return $_[0]->vat(@_); }
sub vatno { return $_[0]->vat(@_); }
sub orgno { return $_[0]->ean(@_); }
sub mobile_phone { return $_[0]->mobile(@_); }
sub secondary_mail { return $_[0]->alt_email(@_); }

sub validate {
	my ($self,$change)=@_;
	$change||=0;
	my @errs;

	# This will trigger exception if a problem is found.
	$self->SUPER::validate($change);

	unless ($change) {
	  # 'type' field is mandatory for all contacts.
	  Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: type field is mandatory') unless ($self->type());

	  # type valid values - company / public_organization / association / individual
	  my @type_values= qw(company public_organization association individual);
	  push @errs,'"type" field can only accept the values: company|public_organization|association|individual' unless (grep {$_ eq $self->type()} @type_values);
	}

	# 'type' field validation on other field(s) dependant on this field value.
	if ($self->type()) {
		if ( $self->type() eq 'company' ) {

			# 'vat' is mandatory for this contact type.
			push @errs,'"vat" field is mandatory for this contact type (company)' unless ($self->vat());

		} elsif ( $self->type() eq 'public_organization' ) {

			# 'vat' is mandatory for this contact type.
			push @errs,'"vat" field is mandatory for this contact type (public_organization)' unless ($self->vat());

		} elsif ( $self->type() eq 'association' ) {

			# 'ean' is mandatory for this contact type. Validation Specified within the EPP spec but field is currently unimplemented.
			# push @errs,'"ean" field is mandatory for this contact type (association)' unless ($self->ean());

		} elsif ( $self->type() eq 'individual' ) {

			# "ean" field is not supported for this contact type
			push @errs,'"ean" field is not supported by this contact type (individual)' if (defined $self->ean());

			# "vat" field is not supported for this contact type
			push @errs,'"vat" field is not supported by this contact type (individual)' if (defined $self->vat());
		}
  }
	Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join(' / ',@errs)) if @errs;

	return 1; # everything is as it should be!
}

sub init {
	my ($self,$what,$ndr)=@_;

    if ( $what eq 'create' ) {
    	my $a=$self->auth();
		$self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw})); #authInfo is not used!
        $self->srid('auto') unless defined( $self->srid() );    ## we can not choose the ID
    }

	return;
}

####################################################################################################
1;
