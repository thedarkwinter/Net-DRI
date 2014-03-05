## Domain Registry Interface, .AERO Domain EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::AERO::Domain;

use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AERO::Domain - .AERO EPP Domain extension commands for Net::DRI

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
          create => [ \&create, undef ],
          info   => [ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:aero="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('aero')));
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('ens attribute is mandatory, as ref hash with keys auth_id and auth_key') 
         unless (exists($rd->{ens}) && (ref($rd->{ens}) eq 'HASH') && exists($rd->{ens}->{auth_id}) && $rd->{ens}->{auth_id} && exists($rd->{ens}->{auth_key}) && $rd->{ens}->{auth_key});

 my @n;
 push @n,['aero:ensAuthID',$rd->{ens}->{auth_id}];
 push @n,['aero:ensAuthKey',$rd->{ens}->{auth_key}];

 my $eid=build_command_extension($mes,$epp,'aero:create');
 $mes->command_extension($eid,\@n);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('aero','infData');
 return unless $infdata;

 my %ens;
 my $c=$infdata->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'ensAuthID')
  {
   $ens{auth_id}=$c->getFirstChild()->getData();
  }

 } continue { $c=$c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{ens}=\%ens;
 return;
}

####################################################################################################
1;
