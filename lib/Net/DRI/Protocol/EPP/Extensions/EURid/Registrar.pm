## Domain Registry Interface, EURid Registrar EPP extension commands
## (introduced in release 5.6 october 2008)
##
## Copyright (c) 2009,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::EURid::Registrar;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Registrar - EURid EPP Registrar extension commands for Net::DRI

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

Copyright (c) 2009,2012,2013 Patrick Mevzek <netdri@dotandco.com>.
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
          info => [ \&info, \&info_parse ],
         );

 return { 'registrar' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'registrar' => [ 'http://www.eurid.eu/xml/epp/registrar-1.0','registrar-1.0.xsd' ] });
 return;
}

####################################################################################################

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 $mes->command('info','registrar:info',sprintf('xmlns:registrar="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('registrar')));
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response('registrar','infData');
 return unless defined $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'amountAvailable')
  {
   $rinfo->{registrar}->{info}->{amount_available}=0+$c->textContent();
  } elsif ($name eq 'hitPoints')
  {
   $rinfo->{registrar}->{info}->{hitpoints}={};
   foreach my $sel (Net::DRI::Util::xml_list_children($c))
   {
    my ($n,$cc)=@$sel;
    if ($n eq 'nbrHitPoints')
    {
     $rinfo->{registrar}->{info}->{hitpoints}->{current_number}=0+$cc->textContent();
    } elsif ($n eq 'maxNbrHitPoints')
    {
     $rinfo->{registrar}->{info}->{hitpoints}->{maximum_number}=0+$cc->textContent();
    } elsif ($n eq 'blockedUntil')
    {
     $rinfo->{registrar}->{info}->{hitpoints}->{blocked_until}=$po->parse_iso8601($cc->textContent());
    }
   }
  } elsif ($name eq 'credits')
  {
   $rinfo->{registrar}->{info}->{credits}->{$c->getAttribute('type')}=($c->textContent() eq '')? undef : 0+$c->textContent();
  }
 }
 return;
}

####################################################################################################
1;
