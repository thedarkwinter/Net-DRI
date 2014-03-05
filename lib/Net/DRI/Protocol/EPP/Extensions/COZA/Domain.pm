## Domain Registry Interface, .CO.ZA Domain EPP extension commands
## From http://registry.coza.net.za/doku.php?id=eppdomainextension
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

package Net::DRI::Protocol::EPP::Extensions::COZA::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
          update         => [ \&update , \&update_parse ],
          info           => [ \&info   , \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'cozadomain' => [ 'http://co.za/epp/extensions/cozadomain-1-0','coza-domain-1.0.xsd' ] });
 return;
}

####################################################################################################

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $autorenew=$todo->set('auto_renew');
 if (defined $autorenew)
 {
  my $eid=$mes->command_extension_register('cozadomain','update');
  $mes->command_extension($eid,[['cozadomain:chg',['cozadomain:autorenew',$autorenew ? 'true' : 'false']]]);
  return;
 }

 my $cancel=$todo->set('cancel_action');
 if (defined $cancel)
 {
  Net::DRI::Exception::usererr_invalid_parameters('cancel_action parameter must be PendingUpdate or PendingSuspension') unless $cancel=~m/^Pending(?:Update|Suspension)$/;
  my $eid=$mes->command_extension_register('cozadomain','update',{cancelPendingAction=>$cancel});
 }
 return;
}

sub update_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $updata=$mes->get_extension('cozadomain','cozaData');
 return unless defined $updata;

## We do not parse the <cozadomain:detail result="success">AutoRenew 'False' successful</cozadomain:detail>
 return;
}

sub info
{
 my ($epp,$domain,$rp)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rp,'transfer_cost') && $rp->{transfer_cost};

 my $eid=$mes->command_extension_register('cozadomain','info');
 $mes->command_extension($eid,[['cozadomain:transferQuote','true']]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('cozadomain','infData');
 return unless defined $infdata;

 my $ns=$mes->ns('cozadomain');
 my $autorenew=Net::DRI::Util::xml_traverse($infdata,$ns,'autorenew');
 $rinfo->{domain}->{$oname}->{auto_renew}=Net::DRI::Util::xml_parse_boolean($autorenew->textContent()) if defined $autorenew;

 my $cost=Net::DRI::Util::xml_traverse($infdata,$ns,'transferQuoteRes','cost');
 $rinfo->{domain}->{$oname}->{transfer_cost}=0+$cost->textContent() if defined $cost;
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::COZA::Domain - .CO.ZA Domain EPP Extension for Net::DRI

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

Copyright (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
