## Domain Registry Interface, EPP E.164 Number Mapping (RFC4114)
##
## Copyright (c) 2005-2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::E164;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

our $NS='urn:ietf:params:xml:ns:e164epp-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::E164 - EPP E.164 Number Mapping (RFC4114) for Net::DRI

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

Copyright (c) 2005-2009,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           info   => [ undef, \&info_parse ],
           create => [ \&create, undef ],
           update => [ \&update, undef ],
         );

 return { 'domain' => \%tmp };
}

sub capabilities_add { return ('domain_update','e164',['add','del']); }

####################################################################################################

sub format_naptr
{
 my $e=shift;

 Net::DRI::Exception::usererr_insufficient_parameters('Attributes order, pref and svc must exist') unless ((ref($e) eq 'HASH') && exists($e->{order}) && exists($e->{pref}) && exists($e->{svc}));

 Net::DRI::Exception::usererr_invalid_parameters('Order must be 16-bit unsigned integer') unless Net::DRI::Util::verify_ushort($e->{order});
 Net::DRI::Exception::usererr_invalid_parameters('Pref must be 16-bit unsigned integer') unless Net::DRI::Util::verify_ushort($e->{pref});
 Net::DRI::Exception::usererr_invalid_parameters('Svc must be at least 1 character as xml token type') unless Net::DRI::Util::xml_is_token($e->{svc},1,undef);

 my @c;
 push @c,['e164:order',$e->{order}];
 push @c,['e164:pref',$e->{pref}];
 if (exists($e->{flags}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('Flags must be a single letter or number') unless ($e->{flags}=~m/^[A-Z0-9]$/i);
  push @c,['e164:flags',$e->{flags}];
 }
 push @c,['e164:svc',$e->{svc}];
 if (exists($e->{regex}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('Regex must be at least 1 character as xml token type') unless Net::DRI::Util::xml_is_token($e->{regex},1,undef);
  push @c,['e164:regex',$e->{regex}];
 }
 if (exists($e->{replacement}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('Regex must be between 1 and 255 characters as xml token type') unless Net::DRI::Util::xml_is_token($e->{regex},1,255);
  push @c,['e164:replacement',$e->{replacement}];
 }

 return @c;
}

####################################################################################################
########### Query commands

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension($NS,'infData');
 return unless defined $infdata;

 my @naptr;
 foreach my $el ($infdata->getChildrenByTagNameNS($NS,'naptr'))
 {
  my %n;
  foreach my $sel (Net::DRI::Util::xml_list_children($el))
  {
   my ($name,$c)=@$sel;
   if ($name=~m/^(order|pref|flags|svc|regex|replacement)$/)
   {
    $n{$1}=$c->textContent();
   }
  }
  push @naptr,\%n;
 }

 $rinfo->{domain}->{$oname}->{e164}=\@naptr;
 return;
}

############ Transform commands

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $def=$epp->default_parameters();

 ## IENUMAT works without the e164 extension part
 unless (exists($rd->{e164}) && (ref($rd->{e164}) eq 'ARRAY') && @{$rd->{e164}})
 {
  Net::DRI::Exception::usererr_insufficient_parameters('One or more E164 data block must be provided') unless (defined($def) && exists($def->{rfc4114_relax}) && $def->{rfc4114_relax});
  return;
 }

 my $eid=$mes->command_extension_register('e164:create','xmlns:e164="urn:ietf:params:xml:ns:e164epp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:e164epp-1.0 e164epp-1.0.xsd"');
 my @n=map { ['e164:naptr',format_naptr($_)] } (@{$rd->{e164}});
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $toadd=$todo->add('e164');
 my $todel=$todo->del('e164');

 return unless (defined($toadd) || defined($todel));

 my $eid=$mes->command_extension_register('e164:update','xmlns:e164="urn:ietf:params:xml:ns:e164epp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:e164epp-1.0 e164epp-1.0.xsd"');
 
 my @n;
 push @n,['e164:add',map { ['e164:naptr',format_naptr($_)] } (ref($toadd) eq 'ARRAY')? @$toadd : ($toadd)] if (defined($toadd));
 push @n,['e164:rem',map { ['e164:naptr',format_naptr($_)] } (ref($todel) eq 'ARRAY')? @$todel : ($todel)] if (defined($todel));

 $mes->command_extension($eid,\@n);
 return;
}

####################################################################################################
1;
