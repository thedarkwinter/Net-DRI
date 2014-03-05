## Domain Registry Interface, .CO.ZA Contact EPP extension commands
## From http://registry.coza.net.za/doku.php?id=eppcontactextension
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

package Net::DRI::Protocol::EPP::Extensions::COZA::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
          info   => [ \&info,   \&info_parse ],
          update => [ \&update, undef ],
         );

 return { 'contact' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'cozacontact' => [ 'http://co.za/epp/extensions/cozacontact-1-0','coza-contact-1.0.xsd' ] });
 return;
}

####################################################################################################

sub info
{
 my ($epp,$c,$rp)=@_;
 my $mes=$epp->message();

 if (Net::DRI::Util::has_key($rp,'domain_listing') && $rp->{domain_listing})
 {
  my $eid=$mes->command_extension_register('cozacontact','info');
  $mes->command_extension($eid,[['cozacontact:domainListing','true']]);
 }

 if (Net::DRI::Util::has_key($rp,'balance') && $rp->{balance})
 {
  my $eid=$mes->command_extension_register('cozacontact','info');
  $mes->command_extension($eid,[['cozacontact:balance','true']]);
 }
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('cozacontact','infData');
 return unless defined $infdata;

 my %l;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$node)=@$el;
  next unless $name eq 'domain';
  push @{$l{lc $node->getAttribute('level')}},$node->textContent();
 }
 $rinfo->{contact}->{$oname}->{domain_listing}=\%l;

 my $ns=$mes->ns('cozacontact');
 my $balance=Net::DRI::Util::xml_traverse($infdata,$ns,'balance');
 $rinfo->{registrar}->{$oname}->{balance}=0+$balance->textContent() if defined $balance;
 return;
}

sub update
{
 my ($epp,$c,$todo)=@_;
 my $mes=$epp->message();

 my $cancel=$todo->set('cancel_action');
 return unless defined $cancel;

 Net::DRI::Exception::usererr_invalid_parameters('cancel_action parameter must be PendingUpdate') unless $cancel=~m/^Pending(?:Update)$/;
 my $eid=$mes->command_extension_register('cozacontact','update',{cancelPendingAction=>$cancel});
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::COZA::Contact - .CO.ZA Contact EPP Extension for Net::DRI

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

