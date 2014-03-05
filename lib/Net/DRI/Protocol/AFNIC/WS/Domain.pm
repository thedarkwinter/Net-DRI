## Domain Registry Interface, AFNIC Web Services Domain commands
##
## Copyright (c) 2005,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::AFNIC::WS::Domain;

use strict;
use warnings;

=pod

=head1 NAME

Net::DRI::Protocol::AFNIC::WS::Domain - AFNIC Web Services Domain commands for Net::DRI

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

Copyright (c) 2005,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

##########################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
	   check => [ \&check, \&check_parse ],
         );

 return { 'domain' => \%tmp };
}

sub build_msg
{
 my ($msg,$command,$domain)=@_;
 Net::DRI::Exception->die(1,'protocol/afnic/ws',2,"Domain name needed") unless defined($domain) && $domain;
 Net::DRI::Exception->die(1,'protocol/afnic/ws',10,"Invalid domain name") unless ($domain=~m/^[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?\.[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?$/i); ## from RRP grammar

 $msg->method($command) if defined($command);
 return;
}

sub check
{
 my ($po,$domain)=@_;
 my $msg=$po->message();
 build_msg($msg,'check_domain',$domain);
 $msg->params([$domain]);
 $msg->service('Domain');
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $r=$mes->result(); ## { free => 0|1, reason => \d+, message => '' }
 $rinfo->{domain}->{$oname}->{exist}=1-($r->{free});
 return;
}

#########################################################################################################
1;
