## Domain Registry Interface, OpenSRS XCP Account commands
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

package Net::DRI::Protocol::OpenSRS::XCP::Account;

use strict;
use warnings;

use Net::DRI::Exception;
use DateTime;

=pod

=head1 NAME

Net::DRI::Protocol::OpenSRS::XCP::Account - OpenSRS XCP Account commands for Net::DRI

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
 my ($xcp)=@_;
 my $msg=$xcp->message();
 $msg->command({action=>'get_domains_by_expiredate',object=>'domain'});
 $msg->command_attributes({exp_from=>DateTime->from_epoch(epoch => time()-60*60*24)->strftime('%F'),exp_to=>'2030-01-01',limit=>1000000}); ## We have to provide a limit !
 return;
}

sub list_domains_parse
{
 my ($xcp,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$xcp->message();
 return unless $mes->is_success();

 my $ra=$mes->response_attributes();
 my $rd=$ra->{'exp_domains'};
 Net::DRI::Exception->die(1,'protocol/opensrs/xcp',1,'Unexpected reply for get_domains_by_expiredate: '.$rd) unless (defined($rd) && ref($rd) eq 'ARRAY');
 my @r=map { $_->{name} } @$rd;
 $rinfo->{account}->{domains}->{action}='list';
 $rinfo->{account}->{domains}->{list}=\@r;
 return;
}

####################################################################################################
1;
