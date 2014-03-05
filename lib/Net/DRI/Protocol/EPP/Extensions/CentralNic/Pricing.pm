## Domain Registry Interface, CentralNic EPP Pricing extension
## From https://www.centralnic.com/company/labs/epp/ext/pricing
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::Pricing;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::Pricing - CentralNic EPP Pricing extension commands for Net::DRI

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
          check => [ \&check, \&check_parse ],
         );
 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'pricing' => [ 'urn:centralnic:params:xml:ns:pricing-1.0','pricing-1.0.xsd' ] });
 return;
}

####################################################################################################

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'pricing');

 Net::DRI::Exception::usererr_invalid_parameters('pricing extension can be used only with one domain:name in check operation') if (ref $domain && @$domain > 1);
 Net::DRI::Exception::usererr_insufficient_parameters('For "pricing" key parameter the value must be a ref hash with keys: currency, action, duration') unless Net::DRI::Util::has_key($rd->{pricing},'currency') && Net::DRI::Util::has_key($rd->{pricing},'action') && Net::DRI::Util::has_key($rd->{pricing},'duration');

 my @n;
 my $rp=$rd->{pricing};
 Net::DRI::Exception::usererr_invalid_parameters('currency should be 3 letters ISO-4217 code') unless $rp->{currency}=~m/^[A-Z]{3}$/;
 push @n,['pricing:currency',$rp->{currency}];
 Net::DRI::Exception::usererr_invalid_parameters('action should be: create, transfer, renew or restore') unless $rp->{action}=~m/^(?:create|transfer|renew|restore)$/;
 push @n,['pricing:action',$rp->{action}];
 Net::DRI::Exception::usererr_invalid_parameters('duration should be a DateTime::Duration object') unless Net::DRI::Util::is_class($rp->{duration},'DateTime::Duration');
 my $rj=Net::DRI::Protocol::EPP::Util::build_period($rp->{duration});
 push @n,['pricing:period',$rj->[1],$rj->[2]];

 my $eid=$mes->command_extension_register('pricing','check');
 $mes->command_extension($eid,\@n);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_extension('pricing','chkData');
 return unless $chkdata;

 my %p;
 foreach my $el (Net::DRI::Util::xml_list_children($chkdata))
 {
  my ($name,$node)=@$el;
  if ($name=~m/^(currency|action)$/)
  {
   $p{$1}=$node->textContent();
  } elsif ($name eq 'period')
  {
   my $unit={y=>'years',m=>'months'}->{$node->getAttribute('unit')};
   $p{duration}=DateTime::Duration->new($unit => 0+$node->textContent());
  } elsif ($name eq 'price')
  {
   $p{price}=0+$node->textContent();
  }
 }

 $rinfo->{domain}->{$oname}->{pricing}=\%p;
 return;
}

####################################################################################################
1;
