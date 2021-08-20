## Domain Registry Interface, Handling of contact data for IE (Titan platform)
##
## Copyright (c) 2020 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Data::Contact::IE;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(lang contact_type cro_number supporting_number ticket_status ticket_id ticket_remark rant_validation_status whois_display));

####################################################################################################

sub validate
{
 my ($self,$change)=@_;
 $change||=0;

 $self->SUPER::validate(1); ## will trigger an Exception if problem

 my @errs;
 if (!$change)
 {
  my @missing=grep { my $r=scalar $self->$_(); (defined $r && length $r)? 0 : 1 } qw/name cc lang srid auth/;
  Net::DRI::Exception::usererr_insufficient_parameters('Mandatory contact information missing: '.join('/',@missing)) if @missing;
  push @errs,'srid' unless Net::DRI::Util::xml_is_token($self->srid(),3,16);
 }

 push @errs,'sp' if (defined $self->sp() && defined $self->cc() && $self->cc() eq 'CA' && $self->sp()!~m/^(?:AB|BC|MB|NB|NL|NT|NS|NU|ON|PE|QC|SK|YT)$/);

 push @errs,'contact_type' if (defined $self->contact_type() && $self->contact_type()!~m!^(?:CHA|COM|OTH)$!);
 push @errs,'lang' if (defined $self->lang() && $self->lang()!~m/^(?:fr|en)$/o);
 push @errs,'whois_display' if (defined $self->whois_display() && $self->whois_display()!~m/^(?:FULL|PRIVATE)$/o);

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
 }
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Data::Contact::IE - Handle IE (.IE) contact data for Net::DRI

=head1 SYNOPSIS

This module is not used directly, but objects will be created in this class
automatically when needed.

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
CIRA specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 lang()

contact preferred language for communication. Include EN (English) and FR (French)

=head2 contact_type()

The contacts Connection to Ireland (CTI) category that is used to indicate how the Regis-
trant meets specific presence requirements. CTI category values include Charity, Company, and Other.

CTI category information is mandatory if you intend to use the contact as a Registrant for a domain
name.

NOTE: This property is only supported if you have specified that you are using the Fury 2.0 exten-
sion during your EPP login.

CTI categories include:

  - CHA - a charitable organization based in Ireland

  - COM - a business or company that is incorporated in Ireland

  - OTH - an individual or organization that does not fall into the charity or company categories but has a connection to Ireland

=head2 cro_number()

The Companies Registration Office (CRO) identifier that can be used to ensure the company is in a valid state to be registering domains.

=head2 supporting_number()

The identifier for a charity or a supporting number (RBN or VAT, for example) for other contact types.

=head2 ticket_status()

Indicates the status of the validation ticket. This field only applies if a ticket has been created for the contact.

=head2 ticket_id()

Indicates the identifier of the validation ticket. This field only applies if a ticket has been created for the contact.

=head2 ticket_remark()

Indicates the latest remark for a validation ticket. This field only applies if a ticket has been created for the contact.

=head2 rant_validation_status()

Indicates whether a contact has been validated.

=head2 whois_display()

for registrant contacts, either FULL or PRIVATE

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2020 Paulo Jorge <paullojorgge@gmail>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut