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
use Data::Dumper; # FIXME: delete me!

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
    send_auth_info  => [ \&send_auth_info, undef ],
    test_nsset      => [ \&test_nsset, undef ],
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

sub send_auth_info {
  my ($epp,$name_id,$rd)=@_;
  my $mes=$epp->message();
  my @d;
  my @name_id;

  # print Dumper($name_id);
  # print Dumper($rd);

  Net::DRI::Exception::usererr_insufficient_parameters(
    "Need to send a name for domain or id for contact, nsset or keyset."
  ) unless (defined($name_id));

  Net::DRI::Exception::usererr_invalid_parameters(
    "Unknown object. Should be domain, contact, nsset or keyset."
  ) unless (defined($rd->{'object'}) && $rd->{'object'}=~m/^(domain|contact|nsset|keyset)$/);

  # domain object = name all other ones = id
  if ($rd->{object} eq 'domain') {
    push @name_id, ["$rd->{object}:name", $name_id];
  } else {
    push @name_id, ["$rd->{object}:id", $name_id];01#17-03-06at1
  }

  # push @d, [ 'fred:sendAuthInfo', [ $rd->{object}.":sendAuthInfo" , @name_id ] ];
  push @d, [ 'fred:sendAuthInfo', [ $rd->{object}.":sendAuthInfo " . sprintf($mes->nsattrs($rd->{object})) , @name_id ] ];


  # README: example has one <fred:clTRID> but spec doesn't mention it. Adding next line just in case!
  push @d, [ 'fred:clTRID', $rd->{'cltrid'} ] if $rd->{'cltrid'};

  # print Dumper(\@object_info);
  # print Dumper(\@d);

  my $ext = $mes->command_extension_register('fred', 'extcommand');
  $mes->command_extension( $ext, \@d );

  return;
}

sub test_nsset {
  my ($epp,$id,$rd)=@_;

  Net::DRI::Exception::usererr_insufficient_parameters('NSSET handle mandatory') unless (defined($id));
  Net::DRI::Exception::usererr_invalid_parameters("Level need to be between: 0-10 (inclusive)") if ($rd->{level} > 10 || $rd->{level} < 0);

  my $mes=$epp->message();
  my @d;
  my @nsset;

  push @nsset, [ 'nsset:id', $id ] if $id;
  push @nsset, [ 'nsset:level', $rd->{level} ] if $rd->{level};
  if ($rd->{name}) {
    if (ref $rd->{name} eq 'ARRAY') {
      foreach my $name(@{$rd->{name}}) {
        push @nsset, [ 'nsset:name', $name ] if $name;
      }
    } else {
      push @nsset, [ 'nsset:name', $rd->{name} ];
    }
  }

  push @d, [ 'fred:test', [ "nsset:test " . sprintf($mes->nsattrs('nsset')) , @nsset ] ];

  # README: example has one <fred:clTRID> but spec doesn't mention it. Adding next line just in case!
  push @d, [ 'fred:clTRID', $rd->{'cltrid'} ] if $rd->{'cltrid'};

  my $ext = $mes->command_extension_register('fred', 'extcommand');
  $mes->command_extension( $ext, \@d );

  return;
}

###############################################################################
1;
