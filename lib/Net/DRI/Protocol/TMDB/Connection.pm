## Domain Registry Interface, TMDB over HTTP/HTTPS Connection handling
##
## Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::TMDB::Connection;

use strict;
use warnings;

use HTTP::Request ();

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

=pod

=head1 NAME

Net::DRI::Protocol::TMDB::Connection - TMDB Connection handling for Net::DRI

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

Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub init
{
 my ($class,$to)=@_;
 $to->{transport}->{ua}->{keep_alive} = 10;
 $to->{transport}->{ua}->{max_redirect} = 2; # seems to require to redirects
}

sub greeting
{
 my ($class,$cm)=@_;
 return $class->keepalive($cm); ## will send an <hello/> message, which is in fact a greeting !
}

####################################################################################################

sub read_data
{
 my ($class,$to,$res)=@_;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING',sprintf('Got unsuccessfull HTTP response: %d %s',$res->code(),$res->message()),'en')) unless $res->is_success();
 return Net::DRI::Data::Raw->new_from_xmlstring($res->decoded_content());
}

sub write_message
{
 my ($class,$to,$msg)=@_;
 my $cred = ($msg->{command} =~ m/^smdrl/) ? $msg->smdrl_data() : $msg->cnis_data();
 Net::DRI::Exception::usererr_insufficient_parameters('TMDB credentials not defined') unless $cred;
 $to->{transport}->{ua}->credentials("$cred->{server}:443", $cred->{realm}, $cred->{username},$cred->{password});
 my $req = HTTP::Request->new('GET',"https://$cred->{server}/" . $msg->command_body());
 return $req;
}

####################################################################################################
1;
