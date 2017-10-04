## Domain Registry Interface, TangoRS Message EPP extension commands
##
## Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>
##                    All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::TangoRS::Message;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Extensions::LaunchPhase;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TangoRS::Message - TangoRS EPP Message extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/project/netdri/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>.
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
 return { 'message' => { 'retrieve' => [ undef, \&info_parse ] } };
}

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension($mes->ns('launch'),'infData');
 return unless defined $infdata;

 # we can use info_parse() from default LaunchPhase extension to get poll message extension data
 # by default Net-DRI is using TangoRS::LaunchPhase for ../Extensions/CORE.pm
 return Net::DRI::Protocol::EPP::Extensions::LaunchPhase::info_parse(@_);
}

####################################################################################################
1;
