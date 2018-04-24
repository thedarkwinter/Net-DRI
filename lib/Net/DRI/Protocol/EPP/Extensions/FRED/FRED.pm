## Domain Registry Interface, FRED Extension EPP commands
##
## Copyright (c) 2018 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
################################################################################

package Net::DRI::Protocol::EPP::Extensions::FRED::FRED;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FRED::FRED - FRED Extension for FRED

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 COPYRIGHT

Copyright (c) 2018 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

################################################################################

sub register_commands {
  my ($class,$version)=@_;
  my %fred=(
    credit_info     => [ \&credit_info, \&credit_info_parse ],
    send_auth_info  => [ \&send_auth_info, undef ], # unimplemented
    dns_test     => [ \&dns_test, undef ], # unimplemented
  );
  my %registrar=(
    balance         => [ \&credit_info, \&credit_info_parse ], # this is more compatible with other registries
  );
  return { 'fred' => \%fred, 'registrar' => \%registrar };
}

################################################################################

################################################################################
# Custom FRED commands:
# - Credit info: https://fred.nic.cz/documentation/html/EPPReference/CommandStructure/CreditInfo.html
# - Send auth.info: https://fred.nic.cz/documentation/html/EPPReference/CommandStructure/SendAuthInfo/index.html
# - Test nsset: https://fred.nic.cz/documentation/html/EPPReference/CommandStructure/TestNsset.html
# - Listing: https://fred.nic.cz/documentation/html/EPPReference/CommandStructure/List/index.html
################################################################################

sub credit_info {
  my ($epp)=@_;
  my $mes=$epp->message();
  my @d;

  # build xml
  push @d, [ 'fred:creditInfo' ];

  my $ext = $mes->command_extension_register('fred', 'extcommand');
  $mes->command_extension( $ext, @d );

  return;
}

sub credit_info_parse {
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  # get response
  my $infdata = $mes->get_response('fred','resCreditInfo');
  return unless $infdata;

  $otype = 'registrar';
  $oaction = 'info';
  $oname = 'self';
  foreach my $el (Net::DRI::Util::xml_list_children($infdata))
  {
    my ($n,$c)=@$el;
    if ($n eq 'zoneCredit')
    {
        my ($zone,$credit) = undef;
        foreach my $el2 (Net::DRI::Util::xml_list_children($c))
        {
          my ($n2,$c2)=@$el2;
          $zone = $c2->textContent() if ($n2 eq 'zone');
          $credit = 0+$c2->textContent() if ($n2 eq 'credit');
        }
        $rinfo->{$otype}->{$oname}->{balance} = $credit if $zone =~ m/^[a-z]{2}$/; # we match the primary TLD here
        push @{$rinfo->{$otype}->{$oname}->{zones}}, { 'zone' => $zone, 'credit' => $credit };
    }
  }

  return;
}

###############################################################################
1;
