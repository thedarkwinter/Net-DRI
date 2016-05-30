## Domain Registry Interface, EPP AusRegistry Sync
##
## Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AusRegistry::Sync;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 state $rop = { 'domain' => { 'update' => [ \&update, undef ] } };
 return $rop;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $ns = { 'sync' => [ 'urn:X-ar:params:xml:ns:sync-1.0','sync-1.0.xsd' ] };
 $po->ns($ns);
 return;
}

sub capabilities_add { return ('domain_update','sync',['set']); }

sub implements { return 'http://ausregistry.github.io/doc/Domain%20Expiry%20Synchronisation%20Extension%20Mapping%20for%20the%20Extensible%20Provisioning%20Protocol.docx'; }

####################################################################################################

############ Transform commands

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $sync=$todo->set('sync');
 return unless defined $sync && $sync;

 Net::DRI::Exception::usererr_invalid_parameters('Sync operation can not be mixed with other domain changes') if grep { $_ ne 'sync' } $todo->types();

 Net::DRI::Util::check_isa($sync,'DateTime');
 my $date = $sync->clone()->set_time_zone('UTC')->strftime('%FT%T.%6NZ');

 my $eid=$mes->command_extension_register('sync', 'update');
 $mes->command_extension($eid,['sync:exDate', $date]);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AusRegistry::Sync - EPP AusRegistry Sync command (Domain Expiry Synchronisation Extension) for Net::DRI

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

Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
