## Domain Registry Interface, Handling of contact data for .CH/.LI
##
## Copyright (c) 2008,2009,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##                    All rights reserved.
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

package Net::DRI::Data::Contact::SWITCH;

use strict;
use warnings;
use base qw/Net::DRI::Data::Contact/;

use Net::DRI::Exception;
use Net::DRI::Util;
use Email::Valid;

=pod

=head1 NAME

Net::DRI::Data::Contact::SWITCH - Handle .CH/.LI contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.CH/.LI specific data.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://oss.bsdprojects.net/projects/netdri/ or
http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2009,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
   Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: name/city/cc/email/srid mandatory') unless (scalar(($self->name())[1]) && scalar(($self->city())[1]) && scalar(($self->cc())[1]) && $self->email() && $self->srid());

  push @errs,'srid' unless Net::DRI::Util::xml_is_token($self->srid(),3,16);
 }

 push @errs,'srid' if ($self->srid() && $self->srid()!~m/^\w{1,80}-\w{1,8}$/); ## \w includes _ in Perl
 push @errs,'name' if ($self->name() && grep { !Net::DRI::Util::xml_is_normalizedstring($_,1,255) }     ($self->name()));
 push @errs,'org'  if ($self->org()  && grep { !Net::DRI::Util::xml_is_normalizedstring($_,undef,255) } ($self->org()));

 my @rs=($self->street());
 foreach my $i (0,1)
 {
  next unless $rs[$i];
  push @errs,'street' if ((ref($rs[$i]) ne 'ARRAY') || (@{$rs[$i]} > 3) || (grep { !Net::DRI::Util::xml_is_normalizedstring($_,undef,255) } @{$rs[$i]}));
 }

 push @errs,'city' if ($self->city() && grep { !Net::DRI::Util::xml_is_normalizedstring($_,1,255) }     ($self->city()));
 push @errs,'sp'   if ($self->sp()   && grep { !Net::DRI::Util::xml_is_normalizedstring($_,undef,255) } ($self->sp()));
 push @errs,'pc'   if ($self->pc()   && grep { !Net::DRI::Util::xml_is_token($_,undef,16) }             ($self->pc()));
 push @errs,'cc'   if ($self->cc()   && grep { !Net::DRI::Util::xml_is_token($_,2,2) }                  ($self->cc()));
 push @errs,'cc'   if ($self->cc()   && grep { !exists($Net::DRI::Util::CCA2{uc($_)}) }                 ($self->cc()));

 push @errs,'voice' if ($self->voice() && !Net::DRI::Util::xml_is_token($self->voice(),undef,17) && $self->voice()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/);
 push @errs,'fax'   if ($self->fax()   && !Net::DRI::Util::xml_is_token($self->fax(),undef,17)   && $self->fax()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/);
 push @errs,'email' if ($self->email() && !Net::DRI::Util::xml_is_token($self->email(),1,undef) && !Email::Valid->rfc822($self->email()));

 $self->auth({pw => ''});

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

sub init
{
 my ($self,$what,$ndr)=@_;

 if ($what eq 'create')
 {
  my $a=$self->auth();
  $self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw})); ## Mandatory in EPP, not used by .CH/.LI
  $self->srid('auto') unless defined($self->srid()); ## we can not choose the ID
 }
 return;
}

####################################################################################################
1;
