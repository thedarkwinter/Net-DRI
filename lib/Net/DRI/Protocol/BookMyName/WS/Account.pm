## Domain Registry Interface, BookMyName Web Services Account commands
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

package Net::DRI::Protocol::BookMyName::WS::Account;

use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::BookMyName::WS::Account - BookMyName Web Services Account commands for Net::DRI

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
		list_domains => [\&list_domains, \&list_domains_parse ],
	  );

 return { 'account' => \%tmp };
}

sub list_domains
{
 my ($po)=@_;
 my $msg=$po->message();
 $msg->method('domain_list');
 return;
}

sub list_domains_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $r=$mes->result();
 Net::DRI::Exception->die(1,'protocol/bookmyname/ws',1,'Unexpected reply for domain_list: '.$r) unless (ref($r) eq 'ARRAY'); ## this is not clearly specified in documentation
 my @r=@$r;
 $rinfo->{account}->{domains}->{action}='list';
 $rinfo->{account}->{domains}->{list}=\@r;
 return;
}

####################################################################################################
1;
