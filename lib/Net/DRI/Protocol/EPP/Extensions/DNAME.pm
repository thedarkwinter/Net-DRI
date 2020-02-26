## EPP Mapping for DNAME delegation of domain names (draft-bortzmeyer-regext-epp-dname-02)
##
## Copyright (c) 2018-2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::DNAME;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 state $rd = { info => [ undef, \&info_parse ] };
 $rd->{create} = $rd->{update} = [ \&command, undef ];

 state $cmds = { 'domain' => $rd };

 return $cmds;
}

sub capabilities_add { return ['domain_update','dname',['set']]; }

sub setup
{
 my ($class,$po,$version)=@_;

 state $ns = { 'dnameDeleg' => 'urn:ietf:params:xml:ns:dnameDeleg-1.0' };
 $po->ns($ns);
 return;
}

sub implements { return 'https://tools.ietf.org/html/draft-bortzmeyer-regext-epp-dname-02'; }

####################################################################################################

sub command
{
 my ($epp,$domain,$data)=@_;

 my $dname = $epp->extract_argument('dname', $data);
 return unless defined $dname;

 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for DNAME: '.$dname) unless Net::DRI::Util::xml_is_token($dname, 1, 255);

 $epp->message()->command_extension('dnameDeleg',['dnameTarget', $dname]);

 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('dnameDeleg','dnameTarget');
 return unless defined $data;
 $rinfo->{domain}->{$oname}->{dname}=$data->textContent();

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DNAME - EPP Mapping for DNAME delegation of domain names (draft-bortzmeyer-regext-epp-dname-02) for Net::DRI

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

Copyright (c) 2018-2019 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut