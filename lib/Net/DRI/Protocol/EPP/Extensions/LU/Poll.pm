## Domain Registry Interface, EPP DNS-LU Poll extensions 
##
## Copyright (c) 2007,2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::LU::Poll;

use strict;
use warnings;

use Net::DRI::Util;

use DateTime::Format::ISO8601;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LU::Poll - EPP DNS-LU Poll extensions (DocRegistrar-2.0.6.pdf pages 35-37) for Net::DRI

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

Copyright (c) 2007,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           dnslu => [ undef, \&parse ],
         );
 return { 'message' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->node_msg();
 return unless $infdata;

 my $pollmsg=$infdata->getFirstChild();
 my %w=(action => 'dnslu_notification', type => $infdata->getAttribute('type')); ## list of types p.36
 $w{type}=$pollmsg->getAttribute('type') if (!defined($w{type}) && $pollmsg->localname() eq 'pollmsg'); 

 my (%ns,%e);
 my $c=$pollmsg->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name=~m/^(roid|object|clTRID|svTRID|reason)$/)
  {
   $w{$name}=$c->getFirstChild()->getData();
  } elsif ($name eq 'exDate')
  {
   $w{$name}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
  } elsif ($name eq 'ns')
  {
   $ns{$c->getAttribute('name')}=$c->getFirstChild()->getData();
  } elsif ($name eq 'extra')
  {
   $e{$c->getAttribute('name')}=$c->getFirstChild()->getData();
  }

 } continue { $c=$c->getNextSibling(); }
 $w{ns}=\%ns if %ns;
 $w{extra}=\%e if %e;

 $rinfo->{session}->{notification}=\%w;
 return;
}

####################################################################################################
1;
