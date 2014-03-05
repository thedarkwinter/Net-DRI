## Domain Registry Interface, EPP E.164 Validation Information Example from RFC5076
##
## Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::E164Validation::RFC5076;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

our $NS='urn:ietf:params:xml:ns:e164valex-1.1';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::E164Validation::RFC5076 - EPP E.164 Validation Information Example from RFC5076 for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub load
{
 return $NS;
}

sub info_parse
{
 my ($class,$po,$top)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('Root element for information validation of URI='.$NS.' must be simpleVal') unless (($top->localname() || $top->nodeName()) eq 'simpleVal');

 my %n;
 foreach my $el (Net::DRI::Util::xml_list_children($top))
 {
  my ($name,$c)=@$el;
  if ($name=~m/^(methodID|validationEntityID|registrarID)$/)
  {
   $n{Net::DRI::Util::remcam($1)}=$c->textContent();
  } elsif ($name=~m/^(executionDate|expirationDate)$/)
  {
   $n{Net::DRI::Util::remcam($1)}=$po->parse_iso8601($c->textContent());
  }
 }
 return \%n;
}

sub output_date
{
 my $d=shift;
 return unless defined($d);
 if (Net::DRI::Util::is_class($d,'DateTime'))
 {
  return $d->strftime('%Y-%m-%d');
 } else
 {
  return unless ($d=~m/^\d{4}-\d{2}-\d{2}$/);
  return $d;
 }
}

sub create
{
 my ($class,$rd)=@_;

 my @c;
 Net::DRI::Exception::usererr_insufficient_parameters('method_id and execution_date are mandatory in validation information') unless (exists $rd->{method_id} && exists $rd->{execution_date});
 Net::DRI::Exception::usererr_invalid_parameters('method_id must be an xml token from 1 to 63 characters') unless Net::DRI::Util::xml_is_token($rd->{method_id},1,63);
 push @c,['valex:methodID',$rd->{method_id}];

 if (exists $rd->{validation_entity_id})
 {
  Net::DRI::Exception::usererr_invalid_parameters('validation_entity_id must be an xml token from 3 to 16 characters') unless Net::DRI::Util::xml_is_token($rd->{validation_entity_id},3,16);
  push @c,['valex:validationEntityID',$rd->{validation_entity_id}];
 }
 if (exists $rd->{registrar_id})
 {
  Net::DRI::Exception::usererr_invalid_parameters('registrar_id must be an xml token from 3 to 16 characters') unless Net::DRI::Util::xml_is_token($rd->{registrar_id},3,16);
  push @c,['valex:registrarID',$rd->{registrar_id}];
 }

 my $d=output_date($rd->{execution_date});
 Net::DRI::Exception::usererr_invalid_parameters('execution_date must be a DateTime object or a string like YYYY-MM-DD') unless defined($d);
 push @c,['valex:executionDate',$d];

 if (exists $rd->{expiration_date})
 {
  $d=output_date($rd->{expiration_date});
  Net::DRI::Exception::usererr_invalid_parameters('expiration_date must be a DateTime object or a string like YYYY-MM-DD') unless defined($d);
  push @c,['valex:expirationDate',$d];
 }

 return ['valex:simpleVal',{'xmlns:valex' => $NS},@c];
}

sub renew    { my (@args)=@_; return create(@args); }
sub transfer { my (@args)=@_; return create(@args); }
sub update   { my (@args)=@_; return create(@args); }

####################################################################################################
1;
