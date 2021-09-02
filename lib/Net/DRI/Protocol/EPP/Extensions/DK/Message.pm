## Domain Registry Interface, .DK Message EPP extension commands
##
## Copyright (c) 2021 Paulo Castanheira <paulo.s.castanheira@gmail.com>.
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
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::DK::Message;

use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DK::Message - .DK EPP Message extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.com<gt>

Please also see the SUPPORT file in the distribution.

=head1 AUTHOR

Paulo Castanheira, E<lt>paulo.s.castanheira@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2021 Tonnerre Lombard <paulo.s.castanheira@gmail.com>.
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
  my %tmp=( notification => [ undef, \&parse ] );

  return { 'message' => \%tmp };
}

####################################################################################################

sub parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  return unless my $msgid=$mes->msg_id();
  
  if (my $data = $mes->get_extension('dkhm','risk_assessment')) {
    $rinfo->{domain}->{$oname}->{risk_assessment} = $data->getFirstChild()->textContent();
  }

  return $rinfo;
}

####################################################################################################
1;
