## Domain Registry Interface, Nomulus Metadata Extension Mapping for EPP
##
## Copyright (c) 2017-2018 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nomulus::Metadata;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 state $rd = {};
 $rd->{create} = $rd->{update} = $rd->{delete} = [ \&build, undef ];
 state $cmds = { 'domain' => $rd };
 return $cmds;
}

sub capabilities_add { return ['domain_update','metadata',['set']]; }

sub setup
{
 my ($class,$po,$version)=@_;
 state $ns = { 'metadata' => 'urn:google:params:xml:ns:metadata-1.0' };
 $po->ns($ns);
 return;
}

sub implements { return 'https://github.com/google/nomulus/blob/5012893c1d761d60591f165a1c5640624b28df9d/java/google/registry/xml/xsd/metadata.xsd'; }

####################################################################################################

sub build
{
 my ($epp,$domain,$rd)=@_;

 my $metadata = $epp->extract_argument('metadata', $rd  );
 return unless defined $metadata;

 my @data;
 push @data, [ 'metadata:reason', $metadata->{'reason'} ] if Net::DRI::Util::has_key($metadata, 'reason');
 Net::DRI::Exception::usererr_insufficient_parameters('requested_by_registrar must be defined') unless Net::DRI::Util::has_key($metadata, 'requested_by_registrar');
 push @data, [ 'metadata:requestedByRegistrar', $metadata->{'requested_by_registrar'} ? 'true' : 'false' ];
 push @data, [ 'metadata:anchorTenant', $metadata->{'anchor_tenant'} ? 'true' : 'false' ] if Net::DRI::Util::has_key($metadata, 'anchor_tenant');

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('metadata', 'metadata');
 $mes->command_extension($eid, \@data);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nomulus::Metadata - EPP Metadata Nomulus Extension mapping for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

From Google documentation:
Domain name extension schema for annotating EPP operations with metadata.
This is a proprietary, internal-only, non-public extension only for use
inside the Google registry.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017-2018 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
