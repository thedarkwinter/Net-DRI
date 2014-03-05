## Domain Registry Interface, EPP Message for EURid
##
## Copyright (c) 2005,2006,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::EURid::Message;

use strict;
use warnings;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Message - EPP EURid Message for Net::DRI

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

Copyright (c) 2005,2006,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 return { 'message' => { 'result' => [ undef, \&parse ] } };
}

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 ## Parse eurid:ext
 my $result=$mes->get_extension('eurid','ext');
 return unless $result;
 my $ns=$mes->ns('eurid');
 $result=$result->getChildrenByTagNameNS($ns,'result');
 return unless $result->size();
 $result=$result->get_node(1);

 ## We add it to the latest status extra_info seen.
 foreach my $el ($result->getChildrenByTagNameNS($ns,'msg'))
 {
  $mes->add_to_extra_info({from => 'eurid', type => 'text', message => $el->textContent()});
 }
 return;
}

####################################################################################################
1;
