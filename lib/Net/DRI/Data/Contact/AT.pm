## Domain Registry Interface, Handling of contact data for .AT
## Contributed by Michael Braunoeder from NIC.AT <mib@nic.at>
##
## Copyright (c) 2006,2008-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::AT;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(type));

=pod

=head1 NAME

Net::DRI::Data::Contact::AT - Handle .AT contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.AT specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 type() 

type of contact : privateperson, organisation or role (mandatory) ; the registry may also return unspecified

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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

 if (!$change)
 {
   Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: name/city/cc/email/auth/srid mandatory') unless (scalar(($self->name())[1]) && scalar(($self->city())[1]) && scalar(($self->cc())[1]) && $self->email() && $self->auth() && $self->srid());

  push @errs,'srid' unless Net::DRI::Util::xml_is_token($self->srid(),3,16);

  Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: type mandatory') unless ($self->type());
 }

 push @errs,'srid' if ($self->srid() && $self->srid()!~m/^\w{1,80}-\w{1,8}$/ && $self->srid()!~m/^AUTO$/i); ## \w includes _ in Perl
 push @errs,'name' if ($self->name() && !Net::DRI::Util::xml_is_normalizedstring(($self->name())[1],1,255));
 push @errs,'org'  if ($self->org()  && !Net::DRI::Util::xml_is_normalizedstring(($self->org())[1],undef,255));

 my @rs=($self->street());
 if ($rs[1])
 {
  push @errs,'street' if ((ref($rs[1]) ne 'ARRAY') || (@{$rs[1]} > 3) || (grep { !Net::DRI::Util::xml_is_normalizedstring($_,undef,255) } @{$rs[1]}));
 }

 push @errs,'city' if ($self->city() && !Net::DRI::Util::xml_is_normalizedstring(($self->city())[1],1,255));
 push @errs,'sp'   if ($self->sp()   && !Net::DRI::Util::xml_is_normalizedstring(($self->sp())[1],undef,255));
 push @errs,'pc'   if ($self->pc()   && !Net::DRI::Util::xml_is_token(($self->pc())[1],1,16));
 push @errs,'cc'   if ($self->cc()   && !Net::DRI::Util::xml_is_token(($self->cc())[1],2,2));
 push @errs,'cc'   if ($self->cc()   && grep { !exists($Net::DRI::Util::CCA2{uc($_)}) }                 ($self->cc()));

 push @errs,'voice' if ($self->voice() && (!Net::DRI::Util::xml_is_token($self->voice(),undef,17) || $self->voice()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/));
 push @errs,'fax'   if ($self->fax()   && (!Net::DRI::Util::xml_is_token($self->fax(),undef,17)   || $self->fax()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/));
 push @errs,'email' if ($self->email() && (!Net::DRI::Util::xml_is_token($self->email(),1,undef)  || !Email::Valid->rfc822($self->email())));

 my $ra=$self->auth();
 push @errs,'auth' if ($ra && (ref($ra) eq 'HASH') && exists($ra->{pw}) && !Net::DRI::Util::xml_is_normalizedstring($ra->{pw}));


 push @errs,'type' if ($self->type() && $self->type()!~m/^(?:privateperson|organisation|role)$/);

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

sub init
{
 my ($self,$what,$ndr)=@_;

 if ($what eq 'create')
 {
  my $a=$self->auth();
  $self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw})); ## Mandatory in EPP, not used by .AT
  $self->srid('auto') unless defined($self->srid()); ## we can not choose the ID
 }
 return;
}

####################################################################################################
1;
