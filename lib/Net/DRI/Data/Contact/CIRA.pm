## Domain Registry Interface, Handling of contact data for CIRA
##
## Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::CIRA;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(legal_form lang is_individual ip_address agreement reseller_id whois_display));

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

 push @errs,'legal_form' if (defined $self->legal_form() && $self->legal_form()!~m!^(?:CCO|CCT|RES|GOV|EDU|ASS|HOP|PRT|TDM|TRD|PLT|LAM|TRS|ABO|INB|LGR|OMK|MAJ)$!);
 push @errs,'lang' if (defined $self->lang() && $self->lang()!~m/^(?:fr|en)$/o);
 push @errs,'ip_address' if (defined $self->ip_address() && !Net::DRI::Util::is_ipv4($self->ip_address(),1) && !Net::DRI::Util::is_ipv6($self->ip_address(),1));
 if (defined $self->agreement())
 {
  my $ra=$self->agreement();
  push @errs,'agreement' if (ref($ra) ne 'HASH' || 2!=keys(%$ra) || !exists($ra->{version}) || !exists($ra->{signed}) || length($ra->{version}) > 4 || $ra->{signed}!~m/^(?:0|1)$/);
 }
 push @errs,'reseller_id' if (defined $self->reseller_id() && length($self->reseller_id()) > 255);
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

Net::DRI::Data::Contact::CIRA - Handle CIRA (.CA) contact data for Net::DRI

=head1 SYNOPSIS

This module is not used directly, but objects will be created in this class
automatically when needed.

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
CIRA specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 legal_form()

legal form (see registry list of possible CPR values), mandatory for registrant contacts, otherwise optional

=head2 lang()

contact preferred language, either 'fr' or 'en'

=head2 ip_address()

(optional) registrant originating IP address (v4 or v6)

=head2 agreement()

ref hash with keys version and signed (value being 1 or 0); optional for non registrant contacts
registry also adds a third key, 'timestamp'

=head2 reseller_id()

(optional) ID of the registrar reseller

=head2 whois_display()

for registrant contacts, either FULL or PRIVATE

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
