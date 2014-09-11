## Domain Registry Interface, Nominet Session Command
##
## Copyright (c) 2005-2010,2012,2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Session;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my %s=(
	'connect' => [ undef, \&parse_greeting ],
	 noop      => [ undef, \&parse_greeting ],
     );
 return { 'session' => \%s };
}

# Nominet anounces multiple versions of objects and extensions, but fails the login if you select multiple.
# Additionally, they annouce the schema's for standard EPP and Nominet EPP (which they are dropping 11/2013)
# This hard codes the selection, which is no doubt a bad idea, but its probably worse to select the latest
sub parse_greeting
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $srv = $po->default_parameters()->{server};

 my @objNS = qw/domain contact host/;
 $srv->{objects} = [ map { "urn:ietf:params:xml:ns:$_-1.0" } @objNS ];
 my @extNS=qw/contact-nom-ext-1.0 domain-nom-ext-1.2 std-contact-id-1.0 std-fork-1.0 std-handshake-1.0 std-list-1.0 std-locks-1.0 std-notifications-1.2 std-release-1.0 std-unrenew-1.0 std-warning-1.1 nom-abuse-feed-1.0 nom-direct-rights-1.0/;
 $srv->{extensions_selected} = [ map { "http://www.nominet.org.uk/epp/xml/$_" } @extNS ];
 push @{$srv->{extensions_selected}},'urn:ietf:params:xml:ns:secDNS-1.1';
 return;
}

####################################################################################################
1;
