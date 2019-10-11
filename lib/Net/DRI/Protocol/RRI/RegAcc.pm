## Domain Registry Interface, RRI RegAcc commands (DENIC-29)
##
## Copyright (c) 2007,2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
##           (c) 2012,2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2019 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::RRI::RegAcc;

use strict;
use warnings;

##use IDNA::Punycode;
use DateTime::Format::ISO8601 ();

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::ContactSet;
use Net::DRI::Protocol::RRI::Contact;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::RRI::RegAcc - RRI RegAcc commands (DENIC-29-EN_3.0) for Net::DRI

=head1 DESCRIPTION

This request is used to query public registrar contact details of own RegAccs and of
those administered by others. You can query your own public registrar contact details
as well as those of others.


=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
          (c) 2012,2013 Michael Holloway <michael@thedarkwinter.com>.
          (c) 2019 Paulo Jorge <paullojorgge@gmail.com>.
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
           info   => [ \&info, \&info_parse ],
         );

 return { 'regacc' => \%tmp };
}

sub build_command
{
 my ($msg, $command, $regacc) = @_;
 my @regacc = (ref($regacc))? @$regacc : ($regacc);
 Net::DRI::Exception->die(1,'protocol/RRI', 2, 'RegAcc handle needed') unless @regacc;

 my $tcommand = (ref($command)) ? $command->[0] : $command;
 my @ns = @{$msg->ns->{'regacc'}};
 $msg->command(['regacc', $tcommand, ($ns[0])]);

 my @r;
 push @r, ['regacc:handle', $regacc];

 return @r;
}

####################################################################################################
########### Query commands

sub info
{
 my ($rri, $regacc, $rd)=@_;
 my $mes = $rri->message();
 my @d = build_command($mes, 'info', $regacc);
 $mes->command_body(\@d);
 $mes->cltrid(undef);
 return;
}

sub info_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes = $po->message();
 return unless $mes->is_success();
 my $infdata = $mes->get_content('infoData', $mes->ns('regacc'));
 return unless $infdata;

 my $cs = Net::DRI::Data::ContactSet->new();
 my $ns = Net::DRI::Data::Hosts->new();
 my $c = $infdata->getFirstChild();

 my %cd=map { $_ => [] } qw/street city sp pc cc/;

 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name = $c->localname() || $c->nodeName();
  next unless $name;

  if ($name=~m/^(handle|name|phone|fax|email|url|memberacc)$/)
  {
   $rinfo->{regacc}->{$oname}->{$1}=$c->textContent();
  }
  elsif ($name eq 'postal')
  {
   Net::DRI::Protocol::RRI::Contact::parse_postalinfo($c,\%cd);
  }
  elsif ($name eq 'contact')
  {
   foreach my $el_contact (Net::DRI::Util::xml_list_children($c))
   {
      my ($name_contact,$c_contact)=@$el_contact;      
      $rinfo->{regacc}->{$oname}->{$name}->{$c->getAttribute('role')}->{$name_contact}=$c_contact->textContent();
   }
  }
  elsif ($name eq 'changed')
  {
   $rinfo->{regacc}->{$oname}->{crDate} =
   $rinfo->{regacc}->{$oname}->{upDate} =
   $rinfo->{regacc}->{$oname}->{changed} =
	DateTime::Format::ISO8601->new()->
		parse_datetime($c->getFirstChild()->getData());
  }
 } continue { $c = $c->getNextSibling(); }

 $rinfo->{regacc}->{$oname}->{street} = shift (@{$cd{street}});
 $rinfo->{regacc}->{$oname}->{city} = shift (@{$cd{city}});
 $rinfo->{regacc}->{$oname}->{pc} = shift (@{$cd{pc}}); 
 $rinfo->{regacc}->{$oname}->{cc} = shift (@{$cd{cc}});

 $rinfo->{regacc}->{$oname}->{action} = 'info';

 return;
}

####################################################################################################
1;
