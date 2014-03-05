## Domain Registry Interface, OpenSRS XCP Session commands
##
## Copyright (c) 2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::OpenSRS::XCP::Session;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::OpenSRS::XCP::Session - OpenSRS XCP Session commands for Net::DRI

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

Copyright (c) 2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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
		set_cookie => [\&set_cookie, \&set_cookie_parse ],
	  );

 return { 'session' => \%tmp };
}

sub set_cookie
{
 my ($xcp,$ep)=@_;
 my $msg=$xcp->message();
 Net::DRI::Exception::usererr_insufficient_parameters('Domain+Username+Password are required for session_set_cookie') if grep { ! Net::DRI::Util::has_key($ep,$_) } qw/domain username password/;
 my %r=(action=>'set',object=>'cookie');
 $r{registrant_ip}=$ep->{registrant_ip} if Net::DRI::Util::has_key($ep,'registrant_ip');
 $msg->command(\%r);
 $msg->command_attributes({domain => $ep->{domain}, reg_username=> $ep->{username}, reg_password => $ep->{password}});
 return;
}

sub set_cookie_parse
{
 my ($xcp,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$xcp->message();
 return unless $mes->is_success();

 my $ra=$mes->response_attributes();
 ## We do not parse all other attributes: f_owner, domain_count, permission, last_access_time, expiredate, last_ip, waiting_requests_no, redirect_url
 my $rd=$ra->{'cookie'};
 $rinfo->{session}->{cookie}->{action}='set';
 $rinfo->{session}->{cookie}->{value}=$rd;
 return;
}

####################################################################################################
1;
