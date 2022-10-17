## Domain Registry Interface, NameAction Connection handling
##
## Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::NameAction::Connection;

use strict;
use warnings;

use Digest::MD5 ();
use HTTP::Request ();
use URI;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

=pod

=head1 NAME

Net::DRI::Protocol::NameAction::Connection - NameAction Connection handling for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>paulo.s.castanheira@gmail.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 AUTHOR

Paulo Castanheira, E<lt>paulo.s.castanheira@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>.
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
 my $t=$to->transport_data();
 foreach my $p (qw/client_login client_password remote_url/)
 {
  Net::DRI::Exception::usererr_insufficient_parameters($p.' must be defined') unless (exists($t->{$p}) && $t->{$p});
 }
 return;
}

## From Protocol Message object to something suitable for transport (various types)
sub write_message
{
 my ($class,$to,$msg)=@_;
 my $url = build_url(@_);
 my $req=HTTP::Request->new('POST',$url);
 $req->header('Content-Type','text/xml');
 $req->content('');
 return $req;
}

sub build_url
{
 my ($class,$to,$msg)=@_;
 my $t=$to->transport_data();
 
 my $uri = URI->new($t->{remote_url});
 $uri->query_form(  User => $t->{client_login},
                    Pass => $t->{client_password},
                    @{$msg->command()}
                  );
 return $uri->as_string();
}

## From transport (various types) to Net::DRI::Data::Raw object (which will be parsed inside Protocol::reaction)
sub read_data
{
 my ($class,$to,$res)=@_;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING',sprintf('Got unsuccessfull HTTP response: %d %s',$res->code(),$res->message()),'en')) unless $res->is_success();
 return Net::DRI::Data::Raw->new_from_xmlstring($res->decoded_content());
}

####################################################################################################
1;
