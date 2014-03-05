## Domain Registry Interface, .NL DAS Domain commands
##
## Copyright (c) 2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::DAS::SIDN::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::DAS::SIDN::Domain - .NL DAS Domain commands for Net::DRI

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

Copyright (c) 2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           check  => [ \&check, \&check_parse ],
         );

 return { 'domain' => \%tmp };
}

sub check
{
 my ($po,$domain,$rd)=@_;
 my $mes=$po->message();
 Net::DRI::Exception->die(1,'protocol/DAS',2,'Domain name needed') unless $domain;
 Net::DRI::Exception->die(1,'protocol/DAS',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain) && $domain=~m/\.nl$/i;
 $mes->command_param(lc $domain);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rr=$mes->response();
 my ($dom,$e)=($rr=~m/^(\S+) is (free|active)/);
 Net::DRI::Exception->die(1,'protocol/DAS',1,'Unexpected reply for domain_check: '.$rr) unless defined $dom && defined $e;
 $rinfo->{domain}->{$dom}->{action}='check';
 $rinfo->{domain}->{$dom}->{exist}=($e eq 'active')? 1 : 0;
 $rinfo->{domain}->{$dom}->{exist_reason}=$rr;
 return;
}

####################################################################################################
1;
