## Domain Registry Interface, Registrar Registration Expiration Date for EPP
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

package Net::DRI::Protocol::EPP::Extensions::ICANN::RegistrarExpirationDate;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 state $rmcds = { 'domain' => { 'info'             => [ undef, \&parse ],
                                'transfer_query'   => [ undef, \&parse ],
                                'create'           => [ \&build, undef ],
                                'renew'            => [ \&build, undef ],
                                'transfer_request' => [ \&build, undef ],
                                'update'           => [ \&build_update, undef ],
                              },
                };
 return $rmcds;
}


sub setup
{
 my ($class,$po,$version)=@_;
 state $rns = { 'rrExDate' => [ 'urn:ietf:params:xml:ns:rrExDate-1.0', 'rrExDate-1.0.xsd' ]};
 $po->ns($rns);
 return;
}

sub capabilities_add { state $rcaps = ['domain_update','registrar_expiration_date',['set']]; return $rcaps; }

sub implements { return 'https://tools.ietf.org/html/draft-lozano-ietf-eppext-registrar-expiration-date-00'; }

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $ns = $mes->ns('rrExDate');
 my $data = $mes->get_extension($ns, 'rrExDateData');
 return unless defined $data;

 $rinfo->{$otype}->{$oname}->{registrar_expiration_date} = $po->parse_iso8601(Net::DRI::Util::xml_child_content($data, $ns, 'exDate'));

 return;
}

sub build
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'registrar_expiration_date');
 my $date = $rd->{'registrar_expiration_date'};
 $date = $date->clone()->set_time_zone('UTC')->strftime('%FT%T.%1NZ') if (ref $date && Net::DRI::Util::check_isa($date,'DateTime'));
 Net::DRI::Exception::usererr_invalid_parameters('Invalid date specification for "registrar_expiration_date": '.$date) unless $date=~m/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$/;

 my $eid=$mes->command_extension_register('rrExDate', 'rrExDateData');
 $mes->command_extension($eid, [ 'rrExDate:exDate', $date ]);

 return;
}

sub build_update
{
 my ($epp,$domain,$todo)=@_;
 my $toset=$todo->set('registrar_expiration_date');
 return unless defined $toset;
 return build($epp,$domain,{registrar_expiration_date => $toset});
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ICANN::RegistrarExpirationDate - ICANN Registrar Registration Expiration Date EPP Extension (draft-lozano-ietf-eppext-registrar-expiration-date-00) for Net::DRI

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
