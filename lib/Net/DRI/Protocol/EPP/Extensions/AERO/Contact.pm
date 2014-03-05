## Domain Registry Interface, .AERO Contact EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::AERO::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use DateTime::Format::ISO8601;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AERO::Contact - .AERO EPP Contact extension commands for Net::DRI

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
          info => [ undef, \&info_parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('aero','infData');
 return unless $infdata;

 my $c=$infdata->getChildrenByTagNameNS($mes->ns('aero'),'ensInfo');
 return unless ($c && $c->size()==1);
 $c=$c->shift()->getFirstChild();

 my %ens;
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if (my ($tag)=($name=~m/^(\S+)$/))
  {
   $ens{Net::DRI::Util::remcam($tag)}=$c->getFirstChild()->getData();
  }

 } continue { $c=$c->getNextSibling(); }

 $ens{last_checked_date}=DateTime::Format::ISO8601->new()->parse_datetime($ens{last_checked_date}) if exists($ens{last_checked_date});

 $rinfo->{contact}->{$oname}->{self}->ens(\%ens);
 return;
}

####################################################################################################
1;
