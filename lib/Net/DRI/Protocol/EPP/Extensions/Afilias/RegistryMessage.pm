## Domain Registry Interface, EPP RegistryMessage extension for Afilias
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Afilias::RegistryMessage;

use strict;
use warnings;
use Net::DRI::Util;
use JSON qw( decode_json );

####################################################################################################

sub register_commands
{
  my ($class,$version)=@_;
  my %tmp=(
      retrieve => [ undef, \&parse ],
  );
  return { 'message' => \%tmp };
}

####################################################################################################

sub parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  my $msgid=$mes->msg_id();
  return unless (defined($msgid) && $msgid);
  return unless ($mes->result_code() == 1301);
  
  my $rd=$rinfo->{message}->{$msgid};
  my $json=$rd->{content};
  my $decoded_json=decode_json($json);
  
  $rd->{change_type}=$decoded_json->{changeType};
  $rd->{name}=$decoded_json->{name};
  $rd->{added_statuses}=$decoded_json->{addedStatuses};
  $rd->{removed_statuses}=$decoded_json->{removedStatuses};
  $rd->{auth_info_updated}=$decoded_json->{authInfoUpdated} if Net::DRI::Util::xml_parse_boolean($decoded_json->{authInfoUpdated});

  return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Afilias::RegistryMessage - EPP Afilias RegistryMessage for Net::DRI

=head1 DESCRIPTION

EPP RegistryMessage extension: poll queue enhancements.

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

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
