## Domain Registry Interface, .SI Domain EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::ARNES::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ARNES::Domain - ARNES (.SI) EPP Domain extension commands for Net::DRI

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

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( 
          transfer_registrant_request => [ \&trade ],
          transfer_request => [ \&transfer ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub transfer_registrant
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>'request'}],$domain);

 my $cs=$rd->{contact};
 my $creg=$cs->get('registrant');
 Net::DRI::Exception::usererr_invalid_parameters('registrant must be a contact object') unless (Net::DRI::Util::isa_contact($creg,'Net::DRI::Data::Contact::ARNES'));
 push @d,['domain:registrant',$creg->srid()];
 push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);

 $mes->command_body(\@d);
 return;
}

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:dnssi="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('dnssi')));
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my @d;
 push @d,Net::DRI::Protocol::EPP::Util::build_ns($epp,$rd->{ns},$domain) if Net::DRI::Util::has_ns($rd);

 Net::DRI::Exception::usererr_insufficient_parameters('Registrant, admin and tech contact are required for .SI domain name transfer') unless (Net::DRI::Util::has_contact($rd) && $rd->{contact}->has_type('registrant') && $rd->{contact}->has_type('admin') && $rd->{contact}->has_type('tech'));

 my $cs=$rd->{contact};
 my @o=$cs->get('registrant');
 push @d,['domain:registrant',$o[0]->srid()];
 push @d,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cs);

 my $eid=build_command_extension($mes,$epp,'dnssi:ext');
 $mes->command_extension($eid,['dnssi:transfer',['dnssi:domain',\@d]]);
 return;
}

####################################################################################################
1;
