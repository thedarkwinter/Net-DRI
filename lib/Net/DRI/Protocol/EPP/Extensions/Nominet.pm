## Domain Registry Interface, .UK EPP extensions
## As seen on http://www.nominet.org.uk/registrars/systems/epp/ and http://www.nominet.org.uk/digitalAssets/16844_EPP_Mapping.pdf
##
## Copyright (c) 2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::Nominet;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet - .UK EPP extensions for Net::DRI

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

Copyright (c) 2008,2009 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

our @NS=qw/account-1.1 domain-2.0 contact-1.1 ns-1.1 notifications-1.2/;

sub setup
{
 my ($self,$rp)=@_;
 foreach my $ns (@NS)
 {
  $self->ns({ (split(/-/,$ns))[0] => ['http://www.nominet.org.uk/epp/xml/nom-'.$ns,'nom-'.$ns.'.xsd'] });
 }

 foreach my $o (qw/ns contact first-bill recur-bill auto-bill next-bill notes/) { $self->capabilities('domain_update',$o,['set']); }
 $self->capabilities('contact_update','info',['set']);
 $self->capabilities('host_update','ip',['set']);
 $self->capabilities('host_update','name',['set']);
 $self->capabilities('account_update','contact',['set']);
 $self->factories('contact',sub { return Net::DRI::Data::Contact::Nominet->new(); });
 $self->default_parameters({domain_create => { auth => { pw => '' } } }); ## domain:authInfo is not used by Nominet
 return;
}

sub core_contact_types { return ('admin','billing'); } ## not really used
sub core_modules
{
 my ($self,$rp)=@_;
 my @c=map { 'Net::DRI::Protocol::EPP::Extensions::Nominet::'.$_ } qw/Domain Contact Host Account Notifications/;
 push @c,'Net::DRI::Protocol::EPP::Core::Session';
 push @c,'Net::DRI::Protocol::EPP::Core::RegistryMessage';
 return @c;
}

sub transport_default
{
 my ($self)=@_;
 my @p=$self->SUPER::transport_default();
 push @p,(protocol_data => { login_service_filter => \&set_objuri });
 return @p;
}

## The registry gives back a mix of 1.0 1.1 1.2 and 1.3 versions of its namespaces and what not, see http://www.nominet.org.uk/registrars/systems/nominetepp/Namespace+URIs/
## We previously kept only the highest seen, which does not seem a good idea
## Now we explicitly set them from what we support; this may break compatibility with registry as soon as they introduce a new version
sub set_objuri
{
 return (['objURI','urn:ietf:params:xml:ns:host-1.0'],map { ['objURI','http://www.nominet.org.uk/epp/xml/nom-'.$_] } @NS);
}

####################################################################################################
1;
