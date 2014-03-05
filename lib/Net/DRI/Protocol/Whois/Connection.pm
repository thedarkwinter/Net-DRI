## Domain Registry Interface, Whois Connection handling
##
## Copyright (c) 2007-2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::Whois::Connection;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Connection - Whois Connection handling for Net::DRI

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

Copyright (c) 2007-2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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

 my @r;
 while(my $l=$sock->getline())
 {
  chomp $l;
  push @r,Net::DRI::Util::decode_latin1($l);
 }

 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','Unable to read answer (connection closed by registry ?)','en')) unless (@r > 5);
 return Net::DRI::Data::Raw->new_from_array(\@r);
}

sub write_message
{
 my ($class,$to,$msg)=@_;
 return Net::DRI::Util::encode_ascii($msg->as_string());
}

sub transport_default
{
 my ($self,$tname)=@_;
 return (defer => 1, close_after => 1, socktype => 'tcp', remote_port => 43);
}

####################################################################################################
1;
