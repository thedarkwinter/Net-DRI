## Domain Registry Interface, .MX EPP Rar extension
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
## Copyright (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::MX::Rar;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::MX::Rar - MX EPP Fee extension commands for Net::DRI

=head1 DESCRIPTION

Adds the Rar Extension ('EPP Manual 2.0 MX.PDF'). This extension allows to check the .MX balance from the Registrar through EPP

MX Fees extension is defined in 'EPP Manual 2.0 MX.PDF'

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHORS

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>
Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>
Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
            balance  => [ \&info, \&info_parse ],
          );
  return { 'registrar' => \%tmp };
}

sub info
{
  my ($epp)=@_;
  my $mes=$epp->message();
  $mes->command(['info','rar:info',sprintf('xmlns:rar="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('rar'))]);
  return;
}

sub info_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  my $resdata;
  foreach my $res ('infData')
  {
    next unless $resdata=$mes->get_response($mes->ns('rar'),$res);
    foreach my $el(Net::DRI::Util::xml_list_children($resdata))
    {
      my ($n,$c)=@$el;
      $rinfo->{registrar}->{$oname}->{$1}=$c->textContent() if $n=~m/^(id|roid|name|balance)$/;
    }
  }
  return;
}

####################################################################################################
1;