## Domain Registry Interface, CoCCA IP Protection
## from http://cocca.org.nz/index.php/cocca-tools/extensions.html
##
## Copyright (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CoCCA::IPVerification;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CoCCA::IPVerification - CoCCA IP Protection EPP Extension for Net::DRI

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

Copyright (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           create => [ \&create, undef ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'cocca' => [ 'https://production.coccaregistry.net/cocca-ip-verification-1.1','cocca-ip-verification-1.1.xsd' ] });
 return;
}

####################################################################################################

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my @ipv;

 if (Net::DRI::Util::has_key($rd,'chip'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('chip code must be an XML token from 1 to 255 characters') unless Net::DRI::Util::xml_is_token($rd->{chip},1,255);
  push @ipv,['cocca:chip',['cocca:code',$rd->{chip}]];
 } elsif (Net::DRI::Util::has_key($rd,'trademark'))
 {
  foreach my $tm (ref $rd->{trademark} eq 'ARRAY' ? @{$rd->{trademark}} : ($rd->{trademark}))
  {
   my @t;

   ## Key names were chosen to mimic the ones in CloudRegistry/LaunchPhase
   Net::DRI::Exception::usererr_insufficient_parameters('trademark name is mandatory') unless Net::DRI::Util::has_key($tm,'trademark_name');
   Net::DRI::Exception::usererr_invalid_parameters('trademark name must be an XML token from 1 to 255 characters') unless Net::DRI::Util::xml_is_token($tm->{trademark_name},1,255);
   push @t,['cocca:registeredMark',$tm->{trademark_name}];

   Net::DRI::Exception::usererr_insufficient_parameters('trademark number is mandatory') unless Net::DRI::Util::has_key($tm,'trademark_number');
   Net::DRI::Exception::usererr_invalid_parameters('trademark number must be an XML token from 1 to 255 characters') unless Net::DRI::Util::xml_is_token($tm->{trademark_number},1,255);
   push @t,['cocca:registrationNumber',$tm->{trademark_number}];

   Net::DRI::Exception::usererr_insufficient_parameters('trademark locality is mandatory') unless Net::DRI::Util::has_key($tm,'trademark_locality');
   Net::DRI::Exception::usererr_invalid_parameters('trademark locality must be a 2 letters country code') unless Net::DRI::Util::xml_is_token($tm->{trademark_locality},2,2);
   push @t,['cocca:registrationLocality',$tm->{trademark_locality}];

   Net::DRI::Exception::usererr_insufficient_parameters('trademark entitlement is mandatory') unless Net::DRI::Util::has_key($tm,'trademark_entitlement');
   Net::DRI::Exception::usererr_invalid_parameters('trademark entitlement must be "OWNER" or "ASSIGNEE"') unless Net::DRI::Util::xml_is_token($tm->{trademark_entitlement}) && $tm->{trademark_entitlement}=~m/^(?:OWNER|ASSIGNEE)$/i;
   push @t,['cocca:capacity',uc $tm->{trademark_entitlement}];

   if (Net::DRI::Util::has_key($tm,'legal_id'))
   {
    Net::DRI::Exception::usererr_invalid_parameters('legal id must be an XML token from 1 to 255 characters') unless Net::DRI::Util::xml_is_token($tm->{legal_id},1,255);
    push @t,['cocca:companyNumber',$tm->{legal_id}];
   }

   push @ipv,['cocca:trademark',@t];
  }
  @ipv=['cocca:trademarks',@ipv];
 }

 return unless @ipv;

 my $eid=$mes->command_extension_register('cocca:extension',sprintf('xmlns:cocca="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('cocca')));
 $mes->command_extension($eid,[@ipv]);
 return;
}

####################################################################################################
1;
