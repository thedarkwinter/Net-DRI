## Domain Registry Interface, Afilias EPP Renew Redemption Period Extension
##
## Copyright (c) 2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
## Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Afilias::Restore;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Afilias::Restore - EPP renew redemption period support for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($class, $version) = @_;
 state $cmds = { 'domain' => { 'renew' => [ \&renew, undef ] } };

 return $cmds;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $rns = { 'argp' => [ 'urn:EPP:xml:ns:ext:rgp-1.0', 'rgp-1.0.xsd' ] };
 $po->ns($rns);
 return;
}

####################################################################################################

############ Transform commands

sub renew
{
 my ($epp, $domain, $rd) = @_;
 my $mes = $epp->message();

 return unless Net::DRI::Util::has_key($rd,'rgp');

 my $eid = $mes->command_extension_register('argp', 'renew');
 $mes->command_extension($eid, ['argp:restore']);
 return;
}

####################################################################################################
1;
