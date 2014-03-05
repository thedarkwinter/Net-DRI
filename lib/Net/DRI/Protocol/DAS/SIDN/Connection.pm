## Domain Registry Interface, DAS Connection handling for .NL
##
## Copyright (c) 2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::DAS::SIDN::Connection;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

=pod

=head1 NAME

Net::DRI::Protocol::DAS::SIDN::Connection - .NL DAS Connection handling for Net::DRI

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

Copyright (c) 2009 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub read_data
{
 my ($class,$to,$sock)=@_;

 my $l=$sock->getline();
 $l=~s/\s*$//; ## seems better than chomp
 $l=Net::DRI::Util::decode_ascii($l);
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','Unable to read answer (connection closed by registry ?)','en')) unless $l=~m/^\S+ is \S+$/;
 return Net::DRI::Data::Raw->new_from_string($l);
}

sub write_message
{
 my ($class,$to,$msg)=@_;
 return Net::DRI::Util::encode_ascii($msg->as_string());
}

sub transport_default
{
 my ($self,$tname)=@_;
 return (defer => 1, close_after => 1, socktype => 'tcp', remote_port => 43, remote_host => 'whois.domain-registry.nl');
}

####################################################################################################
1;
