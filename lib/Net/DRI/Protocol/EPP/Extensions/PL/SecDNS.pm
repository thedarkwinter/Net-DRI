## Domain Registry Interface, EPP DNS for NASK
##
## Copyright (c) 2018 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::PL::SecDNS;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Extensions::SecDNS;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SecDNS - EPP DNS for NASK for Net::DRI - based on standard only XML schema change!

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2018 Paulo Jorge <paullojorgge@gmail.com>.
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
 my %s=(
	'connect' => [ undef, \&Net::DRI::Protocol::EPP::Extensions::SecDNS::parse_greeting ],
	 noop      => [ undef, \&Net::DRI::Protocol::EPP::Extensions::SecDNS::parse_greeting ],
       );
 my %d=(
        info      => [ undef, \&Net::DRI::Protocol::EPP::Extensions::SecDNS::info_parse ],
        create    => [ \&Net::DRI::Protocol::EPP::Extensions::SecDNS::create, undef ],
        update    => [ \&Net::DRI::Protocol::EPP::Extensions::SecDNS::update, undef ],
       );

 return { 'domain' => \%d, 'session' => \%s };
}

sub capabilities_add { return (['domain_update','secdns',['add','del','set']],['domain_update','secdns_urgent',['set']]); }

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'secDNS' => [ 'http://www.dns.pl/nask-epp-schema/secDNS-2.0','secDNS-2.0.xsd' ] });
 return;
}

####################################################################################################
1;
