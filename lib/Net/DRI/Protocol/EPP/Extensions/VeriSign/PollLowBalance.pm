## Domain Registry Interface, EPP Low Balance (EPP-LowBalance-Mapping.pdf)
##
## Copyright (c) 2006-2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::PollLowBalance;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::PollLowBalance - EPP Low Balance Mapping (EPP-LowBalance-Mapping.pdf) for Net::DRI

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

Copyright (c) 2006-2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           lowbalance => [ undef, \&parse ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response('http://www.verisign.com/epp/lowbalance-poll-1.0','pollData');
 return unless $infdata;

 my %w=(action => 'lowbalance_notification');
 my $c=$infdata->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name=~m/^(registrarName|creditLimit|availableCredit)$/)
  {
   $w{Net::DRI::Util::remcam($name)}=$c->getFirstChild()->getData();
  } elsif ($name eq 'creditThreshold')
  {
   $w{Net::DRI::Util::remcam($name)}=$c->getFirstChild()->getData();
   $w{'credit_threshold_type'}=$c->getAttribute('type');
  }
 } continue { $c=$c->getNextSibling(); }

 $rinfo->{session}->{lowbalance}=\%w;
 return;
}

####################################################################################################
1;
