## Domain Registry Interface, Handling of contact data for LU
##
## Copyright (c) 2007-2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::LU;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(type));

=pod

=head1 NAME

Net::DRI::Data::Contact::LU - Handle .LU contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.LU specific data.

This registry uses only localized data with characters in US-ASCII and ISO-LATIN-1

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 type() 

type of contact : holder_org, holder_pers (for contact objects used as holders) or contact

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2007-2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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

 if (!$change)
 {
  Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: pc mandatory') unless (scalar($self->pc()));
 }

 push @errs,'sp' if $self->sp(); ## not allowed
 push @errs,'type' if ($self->type() && $self->type()!~m/^(?:holder_org|holder_pers|contact)/);
 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 if ($self->type() && ($self->type() ne 'contact'))
 {
  push @errs,'voice' if $self->voice();
  push @errs,'fax'   if $self->fax();
  push @errs,'org'   if $self->org();
  Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information (not allowed for holders): '.join('/',@errs)) if @errs;
 }

 return 1; ## everything ok.
}

sub init
{
 my ($self,$what,$ndr)=@_;

 if ($what eq 'create')
 {
  my $a=$self->auth();
  $self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw}));
 }
 return;
}

####################################################################################################
1;
