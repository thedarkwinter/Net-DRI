## Domain Registry Interface, .MX domain extensions from 'EPP Manual 2.0 MX.PDF'
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::MX::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

use DateTime::Format::ISO8601;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::MX::Domain - .MX EPP Domain extension commands for Net::DRI

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

Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>.
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
          restore => [ \&restore, undef ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub restore
{
  my ($epp,$domain)=@_;
  my $mes=$epp->message();

  Net::DRI::Exception::usererr_insufficient_parameters('Domain name is mandatory') unless defined $domain;
  Net::DRI::Exception::usererr_insufficient_parameters('Invalid domain name') unless Net::DRI::Util::xml_is_token($domain,1,255);

  $mes->command(['renew','nicmx-domrst:restore',sprintf('xmlns:nicmx-domrst="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ext_domrst'))]);
  $mes->command_body(['nicmx-domrst:name',$domain]);
  return;
}

####################################################################################################
1;