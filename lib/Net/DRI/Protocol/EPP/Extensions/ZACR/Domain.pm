 ## Domain Registry Interface, ZACR Domain EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::ZACR::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
          update         => [ \&update , undef ],
          info           => [ \&info   , \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'cozadomain' => [ 'http://co.za/epp/extensions/cozadomain-1-0','coza-domain-1.0.xsd' ] });
 $po->capabilities('domain_update','cancel_action',['set']);
 $po->capabilities('domain_update','auto_renew',['set']);
 return;
}

####################################################################################################

## There is no update_parse as this is done by result code and message
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
  my @actions = qw/PendingManualSuspension PendingUpdate PendingManualDeletion PendingGracePeriodSuspension PendingSuspension PendingDeletion PendingClosedRedemption/;
  Net::DRI::Exception::usererr_invalid_parameters("cancel_action parameter must be one of @actions") unless grep ($_ eq $cancel, @actions);
  my $eid=$mes->command_extension_register('cozadomain','update',{cancelPendingAction=>$cancel});
 }
 return;
}

## We always add the extension as it requests the extension back from the server with autorenew flags
sub info
{
 my ($epp,$domain,$rp)=@_;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('cozadomain','info');
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
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ZACR::Domain - ZACR Domain EPP Extension for Net::DRI

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
