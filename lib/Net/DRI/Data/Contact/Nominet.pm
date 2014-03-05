## Domain Registry Interface, Handling of contact data for Nominet (.UK)
##
## Copyright (c) 2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::Nominet;

use strict;
use warnings;

use base qw(Net::DRI::Data::Contact);
use Email::Valid;
use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(type co_no opt_out mobile));

=pod

=head1 NAME

Net::DRI::Data::Contact::Nominet - Handle .UK contact data for Net::DRI

=head1 DESCRIPTION

Please refer to Net::DRI::Data::Contact for core methods
and http://www.nominet.org.uk/registrars/systems/data/fields/ for registry extra data

=head1 METHODS

=head2 type()

(registrant contact only) describes what type of organisation the domain name has been registered for ;
see http://www.nominet.org.uk/registrars/systems/data/regtype/

=head2 co_no()

(registrant contact only) registered number of the company or organisation

=head2 opt_out()

(registrant contact only) do not display address details in whois if yes (Y)

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub roid { my ($self,@args)=@_; return $self->srid(@args); }

sub validate
{
 my ($self,$change)=@_;
 $change||=0;
 my @errs;

 if (!$change)
 {
  Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: name mandatory') unless ($self->name());
 }

 push @errs,'srid' if (defined($self->srid()) && $change && $self->srid()!~m/^C?\d+(?:-UK)?$/); ## C for contacts, nothing for registrant/account
 push @errs,'name' if (defined($self->name()) && !Net::DRI::Util::xml_is_token($self->name(),1,255));
 push @errs,'org' if (defined($self->org()) && !Net::DRI::Util::xml_is_token($self->org(),1,255));
 ## See http://www.nominet.org.uk/registrars/systems/data/regtype/
 push @errs,'type' if (defined($self->type()) && $self->type()!~m/^(?:LTD|PLC|IND|FIND|RCHAR|SCH|LLP|STRA|PTNR|GOV|CRC|STAT|FCORP|IP|FOTHER|OTHER|UNKNOWN)$/);
 push @errs,'co_no' if (defined($self->co_no()) && !Net::DRI::Util::xml_is_token($self->co_no(),undef,255));
 ## TO FIX : co_no is mandatory for registrations in .net, .ltd and .plc SLDs
 push @errs,'opt_out' if (defined($self->opt_out()) && $self->opt_out()!~m/^[YN]$/i);

 push @errs,'voice' if (defined($self->voice()) && !Net::DRI::Util::xml_is_token($self->voice(),undef,17) && $self->voice()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/);
 push @errs,'fax'   if (defined($self->fax())   && !Net::DRI::Util::xml_is_token($self->fax(),undef,17)   && $self->fax()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/);
 push @errs,'mobile'   if (defined($self->mobile())   && !Net::DRI::Util::xml_is_token($self->mobile(),undef,17)   && $self->mobile()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/); ## Defined in schema, but not in .UK EPP documentation !
 push @errs,'email' if (defined($self->email()) && !Net::DRI::Util::xml_is_token($self->email(),1,undef) && !Email::Valid->rfc822($self->email()));

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 if (defined($self->type()) && defined($self->opt_out()))
 {
  Net::DRI::Exception::usererr_invalid_parameters('opt_out must be N if type is not IND or FIND') if ($self->type()!~m/^(?:IND|FIND)$/ && lc($self->opt_out()) ne 'n');
 }
 Net::DRI::Exception::usererr_invalid_parameters('co_no must be defined if type is SCH') if (defined($self->type()) && $self->type() eq 'SCH' && !defined($self->co_no()));

 return 1; ## everything ok.
}

####################################################################################################
1;
