## Domain Registry Interface, Neulevel EPP CO Extension
##
## Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NeuLevel::CO;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NeuLevel::CO - NeuLevel .CO DomainSuspendedIndicator extension for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
(c) 2017 Michael Holloway <michael@thedarkwinter.com>.
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
           create   => [ \&transform, undef ],
           info     => [ undef, \&parse ],
           renew    => [ \&transform, undef ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('neulevel','extension');
 return unless defined $infdata;

 my %t;
 my $unspec;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  next unless $n eq 'unspec';
  foreach my $kv (split(/ /,$c->textContent()))
  {
   my ($k,$v) = split(/=/,$kv);
   $rinfo->{$otype}->{$oname}->{domain_suspended_indicator}=$v if $k eq 'DomainSuspendedIndicator';
  }
 }

 sub transform
 {
  my ($epp,$domain,$rd)=@_;
  return unless Net::DRI::Util::has_key($rd,'unspec');
  my $unspec;
  my $rd_unspec = $rd->{'unspec'};
  if ($rd_unspec->{'reservation_domain'}) {
    $unspec = 'ReservationDomain=' . $rd_unspec->{'reservation_domain'};
  } elsif ($rd_unspec->{'restore_reason_code'} && $rd_unspec->{'restore_comment'} && $rd_unspec->{'true_data'} && $rd_unspec->{'valid_use'}) {
    $unspec = 'RestoreReasonCode=' . $rd_unspec->{'restore_reason_code'} . ' RestoreComment=' . $rd_unspec->{'restore_comment'} . ' TrueData=' . $rd_unspec->{'true_data'} . ' ValidUse=' . $rd_unspec->{'valid_use'};
  }
  $epp->message()->command_extension('neulevel', ['extension', ['neulevel:unspec', $unspec]]);
  return;
 }

 return;
}

1;
