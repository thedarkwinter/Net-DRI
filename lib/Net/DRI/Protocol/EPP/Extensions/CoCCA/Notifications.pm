## Domain Registry Interface, CoCCA/PH notifications
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CoCCA::Notifications;

use strict;
use warnings;

use Net::DRI::Util;
use utf8;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CoCCA::Notifications - CoCCA/.PH EPP Notifications Handling for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands {
 my ($class,$version)=@_;
 my %tmp=(
          retrieve => [ undef, \&parse_poll ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse_poll {
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
	my $mes=$po->message();
	return unless $mes->is_success();

	# get poll message id and content
	my $id=$mes->msg_id();
	my $node=$rinfo->{message}->{$id}->{content};

	# parse the rest of the data in the message.
	if ( $node =~ /<(.*)><domain><name>(.*)?<\/name><change>(.*)?<\/change><details>(.*)?<\/details><\/domain><\/offlineUpdate>/gi ) {
		
		# set variables
		$otype = 'message';
		$oname = 'session';
		if (defined($1)) {$oaction = $1} else {$oaction = 'offlineUpdate'};
		
		# write keys to hash
		$rinfo->{$otype}->{$oname}->{action} = $1 if defined($1);
		$rinfo->{$otype}->{$oname}->{name} = $2 if defined($2);
		$rinfo->{$otype}->{$oname}->{change} = $3 if defined($3);
		$rinfo->{$otype}->{$oname}->{details} = $4 if defined($4);
	}

	return;
}

####################################################################################################
1;
