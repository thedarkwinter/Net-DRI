## Domain Registry Interface, CentralNic Release EPP extension
## (http://labs.centralnic.com/epp/ext/release.php)
##
## Copyright (c) 2007,2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::Release;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Core::Domain;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::Release - EPP Release CentralNic extension commands for Net::DRI

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

Copyright (c) 2007,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my %tmp=( release => [ \&release, \&release_parse ]);
 return { 'domain' => \%tmp };
}

####################################################################################################

sub release
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined($domain) && $domain;
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);

 Net::DRI::Exception::usererr_invalid_parameters('release operation needs a clID') unless (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{clID}) && defined($rd->{clID}) && $rd->{clID});

 $mes->command([['transfer',{'op'=>'release'}],'domain:transfer',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('domain'))]);
 my @d=(['domain:name',$domain],['domain:clID',$rd->{clID}]);
 $mes->command_body(\@d);
 return;
}

sub release_parse
{
 my (@args)=@_;
 return Net::DRI::Protocol::EPP::Core::Domain::transfer_parse(@args);
}

####################################################################################################
1;
