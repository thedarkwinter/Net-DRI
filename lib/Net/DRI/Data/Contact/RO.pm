## Domain Registry Interface, Handling of contact data for .RO [https://epp2-test.rotld.ro/epp/index.html]
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI.
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::Data::Contact::RO;

use strict;
use warnings;

use base qw(Net::DRI::Data::Contact);

use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(vat orgno type));

=pod

=head1 NAME

Net::DRI::Data::Contact::RO - Handle RO contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
RO specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 orgno()

=head2 vat()

VAT is mandatory for .RO Contacts.

=head2 type()

Legend:
p - Private Person
ap - Authorized Person
nc - Non-Commercial Organization
c - Commercial
gi - Government Institute
pi - Public Institute
o - Other Juridical

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>d.makuni@live.co.uk<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub validate {
	my ($self,$change)=@_;
	$change||=0;
	my @errs;

	$self->SUPER::validate($change); ## This will trigger exception if a problem is found.

	# 'org' field validation
	push @errs,'"org" field is not used and must be left blank' if ((defined $self->org()) && ($self->org() ne ''));

	# registry specified 'mandatory' fields for create commands
	if (!$change) {
		if ($self->cc() eq 'RO') {
			Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: vat field is mandatory for romanian contacts') unless ($self->vat());
			Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: VAT number given must be in the correct format for romanian contacts') unless ($self->vat()=~ m/(RO)?[0-9]{2,10}/i);
		}
		# 'srid' field validation
		push @errs,'"srid" is specified by the registry and MUST be set to "auto"' if ((defined $self->srid()) && ($self->srid()!~m/^(AUTO)$/i));
		# 'type' field validation
		Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: type field is mandatory') unless ($self->type());
	}

	# other registry specified 'mandatory' fields
	Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: sp field is mandatory') unless ($self->sp());
	Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: email field is mandatory') unless ($self->email());

	# 'vat' and 'orgno' field length validation
	push @errs,'"vat" field must be 5 to 40 characters long' if ((defined $self->vat()) && ($self->vat()!~m/^.{5,40}$/));
	push @errs,'"orgno" field must be 1 to 40 characters long' if ((defined $self->orgno()) && ($self->orgno()!~m/^.{1,40}$/));

	# 'type' valid values - p / ap / nc / c / gi / pi / o
	my @type_values= qw(p ap nc c gi pi o);
	if (defined $self->type()) {
		push @errs,'"type" field can only accept the values: p / ap / nc / c / gi / pi / o' unless (grep {$_ eq $self->type()} @type_values);
	}

	Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join(' / ',@errs)) if @errs;
	return 1; # PASSED
}

sub init {
	my ($self,$what,$ndr)=@_;
	if ($what eq 'create') {
		my $a=$self->auth();
		$self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw})); #authInfo is not used!
	}
	return;
}

####################################################################################################
1;
