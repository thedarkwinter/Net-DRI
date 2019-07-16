## Domain Registry Interface, Handling of contact data for CNNIC 
##
## Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Data::Contact::CNNIC;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Util;
__PACKAGE__->register_attributes(qw(type code));

=pod

=head1 NAME

Net::DRI::Data::Contact::CNNIC - Handle CNNIC contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for CNNIC specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 type()

IDType can be one of the following:

# SFZ: ID

# ORG: Organization Code Certificate

# YYZZ: Business License

# TYDM: Certificate for Uniform Social Credit Code

# HZ:	Passport

# GAJMTX: Exit-Entry Permit for Travelling to and from Hong Kong and Macao

# QT: Others

# BDDM: Military Code Designation

# JDDWFW: Military Paid External Service License

# SYDWFR: Public Institution Legal Person Certificate

# WGCZJG: Resident Representative Offices of Foreign Enterprises Registration Form

# TWJMTX: Travel passes for Taiwan Residents to Enter or Leave the Mainland

# WJLSFZ: Foreign Permanent Resident ID Card

# SHTTFR: Social Organization Legal Person Registration Certificate

# ZJCS: Religion Activity Site Registration Certificate

# MBFQY: Private Non-Enterprise Entity Registration Certificate

# JJHFR: Fund Legal Person Registration Certificate

# LSZY: Practicing License of Law Firm

# WGZHWH: Registration Certificate of Foreign Cultural Center in China

# WLCZJG: Resident Representative Office of Tourism Departments of Foreign Government Approval Registration Certificate

# SFJD: Judicial Expertise License

# JWJG: Overseas Organization Certificate

# SHFWJG: Social Service Agency Registration Certificate

# MBXXBX: Private School Permit

# YLJGZY: Medical Institution Practicing License

# GZJGZY: Notary Organization Practicing License

# BJWSXX: Beijing School for Children of Foreign Embassy Staff in China Permit

# GATJZZ: Residence permit for Hong Kong, Macao and Taiwan residents

=head2 code()

String between 1 and 20 characters

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
 my @id_type = (
  "SFZ", "ORG", "YYZZ", "TYDM", "HZ", "GAJMTX", "QT", "BDDM", "JDDWFW", "SYDWFR",
  "WGCZJG", "TWJMTX", "WJLSFZ", "SHTTFR", "ZJCS", "MBFQY", "JJHFR", "LSZY",
  "WGZHWH", "WLCZJG", "SFJD", "JWJG", "SHFWJG", "MBXXBX", "YLJGZY", "GZJGZY",
  "BJWSXX", "GATJZZ"
 );
 $self->SUPER::validate($change); ## will trigger an Exception if problem
 if ($self->type() || $self->code()) {
  Net::DRI::Exception::usererr_invalid_parameters('contact type should be one of: ' . join(' ', @id_type) ) unless ( grep { $self->type() =~ m/^(?:$_)$/ } @id_type );
  Net::DRI::Exception::usererr_invalid_parameters('contact code should be a string between 1 and 20 characters') unless Net::DRI::Util::xml_is_token($self->code(),1,20);
 }
 return 1;
}

####################################################################################################

1;
