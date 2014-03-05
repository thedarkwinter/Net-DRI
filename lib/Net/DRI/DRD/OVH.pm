## Domain Registry Interface, OVH Registry Driver
##
## Copyright (c) 2008,2009,2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::OVH;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

=pod

=head1 NAME

Net::DRI::DRD::OVH - OVH Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 CURRENT LIMITATIONS

Only domain_info and account_list_domains are implemented for now

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2009,2011 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub name { return 'OVH'; }
sub tlds { return qw/fr com net org info biz eu me.uk co.uk org.uk de be re es/; } ## As seen on http://www.ovh.com/fr/particulier/produits/domaines.xml
sub object_types { return ('domain'); }
sub profile_types { return qw/ws/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 #return ('Net::DRI::Transport::HTTP::SOAPWSDL',{wsdl_uri => 'https://www.ovh.com/soapi/ovh.wsdl',proxy_uri => 'http://www.ovh.com:1664',servicename => 'managerService',portname => 'managerPort'},'Net::DRI::Protocol::OVH::WS',{}) if $type eq 'ws';
 return ('Net::DRI::Transport::HTTP::SOAPLite',{uri => 'https://soapi.ovh.com/manager',proxy_uri => 'https://www.ovh.com:1664'},'Net::DRI::Protocol::OVH::WS',{}) if $type eq 'ws';
 return;
}

####################################################################################################

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 return;
}

####################################################################################################
1;
