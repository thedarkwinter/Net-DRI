## Domain Registry Interface, EURid EPP Session commands
##
## Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::EPP::Extensions::EURid::Session;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Session - EURid EPP Session commands for Net::DRI

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

Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>.
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
          'connect' => [ undef, \&parse_greeting ],
           noop     => [ undef, \&parse_greeting ], ## for keepalives
         );

 return { 'session' => \%tmp };
}

sub parse_greeting
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $g=$mes->node_greeting();
 return unless $mes->is_success() && defined $g; ## make sure we are not called for all parsing operations (after poll), just after true greeting

 my $rserver=$rinfo->{session}->{server};

 ## For now, we always remove the DSS extension (see release 8.2)
 my $nsdss='http://www.eurid.eu/xml/epp/dss-1.0';
 return unless grep { $_ eq $nsdss } @{$rserver->{extensions_selected}};

 my %ctxlog=(action=>'greeting',direction=>'in',trid=>$mes->cltrid());
 $po->log_output('info','protocol',{%ctxlog,message=>qq{Extension "$nsdss" is presented by server, we deselect it}});
 $rserver->{extensions_selected}=[ grep { $_ ne $nsdss } @{$rserver->{extensions_selected}} ];

 return;
}

####################################################################################################
1;
