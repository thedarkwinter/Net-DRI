## Domain Registry Interface, .MX EPP AdmStatus extension
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
## Copyright (c) 2015,2020 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::MX::AdmStatus;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::MX::AdmStatus - MX EPP Administrative Status extension commands for Net::DRI

=head1 DESCRIPTION

Adds the Administrative Status Extension ('EPP Manual  LAT.pdf'). This extension is
use to give information about the Administrative Status of a domain as part of the 
response of a domain:info command. The Administrative Status is used to identify an
inactive status within a domain's lifecycle.

The extension is displayed when the domain has one of the following Administrative Status: "Blocked by external authority", 
"Suspended by external authority", "Blocked by URS petition", "Suspended by URS determination", "Blocked by Transfer Dispute"

The extension required is: <extURI>http://www.nic.mx/nicmx-admstatus-1.1</extURI>

MX Administrative Status extension is defined in 'EPP Manual  LAT.pdf'

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
Copyright (c) 2015,2020 Paulo Jorge <paullojorgge@gmail.com>.
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
            info  => [ undef, \&info_parse ],
          );
  return { 'domain' => \%tmp };
}

sub info_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  my $infdata=$mes->get_extension('nicmx-admstatus','adminStatus');
  return unless defined $infdata;

  foreach my $el (Net::DRI::Util::xml_list_children($infdata))
  {
    my ($name,$content) = @$el;
    $rinfo->{domain}->{$oname}->{$name} = $content->textContent() if $name =~ m/^(value|msg)$/;
    $rinfo->{domain}->{$oname}->{'lang'} = $content->getAttribute('lang') if $content->hasAttribute('lang');
  }
  return;
}

####################################################################################################
1;