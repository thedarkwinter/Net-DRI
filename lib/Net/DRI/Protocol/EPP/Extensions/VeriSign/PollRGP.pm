## Domain Registry Interface, EPP RGP Poll (EPP-RGP-Poll-Mapping.pdf)
##
## Copyright (c) 2006-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::PollRGP;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::PollRGP - EPP RGP Poll Mapping (EPP-RGP-Poll-Mapping.pdf) for Net::DRI

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

Copyright (c) 2006-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           rgpnotification => [ undef, \&parse ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response('http://www.verisign.com/epp/rgp-poll-1.0','pollData');
 return unless defined $infdata;

 my %w=(action => 'rgp_notification');
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
  } elsif ($name eq 'rgpStatus')
  {
   $w{status}=$po->create_local_object('status')->add(Net::DRI::Protocol::EPP::Util::parse_node_status($c));
  } elsif ($name=~m/^(reqDate|reportDueDate)$/)
  {
   $w{Net::DRI::Util::remcam($name)}=$po->parse_iso8601($c->textContent());
  }
 }

 $rinfo->{domain}->{$oname}=\%w;
 return;
}

####################################################################################################
1;
