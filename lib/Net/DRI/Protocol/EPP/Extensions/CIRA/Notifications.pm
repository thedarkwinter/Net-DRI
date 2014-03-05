## Domain Registry Interface, CIRA EPP Notifications
##
## Copyright (c) 2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CIRA::Notifications;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           review_cira => [ undef, \&parse ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $node=$mes->get_response('poll','extData');
 return unless defined $node;

 my $id=$mes->msg_id();
 $rinfo->{message}->{$id}->{action}='review_cira';

 foreach my $el (Net::DRI::Util::xml_list_children($node))
 {
  my ($name,$n)=@$el;
  unless ($name=~m/^(?:msgID|domainName|contactID|balance|deadline|hostName|ipAddress)$/o)
  {
   Net::DRI::Exception::err_assert('Unknown node name '.$name.' in .CA notification parsing, please report!');
  }
  $rinfo->{message}->{$id}->{Net::DRI::Util::remcam($name)}=$n->textContent();
 }
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CIRA::Notifications - CIRA (.CA) EPP Notifications for Net::DRI

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

Copyright (c) 2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
