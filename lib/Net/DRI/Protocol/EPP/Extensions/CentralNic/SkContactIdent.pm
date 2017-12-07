## CentralNic SK EPP Contact Ident extension
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
## Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::SkContactIdent;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::SkContactIdent- CentralNic SK EPP Contact Ident extension

=head1 DESCRIPTION

In case of a natural person ("PERS" constant): date of birth (not mandatory - format: YYYY-MM-DD) and legal entity.

In case entrepreneur ("CORP" constant): identification number.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO netdri@dotandco.com
=head1 COPYRIGHT

Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.

Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my %ops=(
    create => [ \&create, undef ]
    );
 return { 'contact' => \%ops };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'skContactIdent' => [ 'http://www.sk-nic.sk/xml/epp/sk-contact-ident-0.2','sk-contact-ident-0.2.xsd' ] });
 return;
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 my @n;

 push @n,['skContactIdent:legalForm', $contact->legal_form()];
 if ( $contact->ident_value() ) {
  push @n,['skContactIdent:identValue', [ 'skContactIdent:corpIdent', $contact->ident_value()] ] if lc($contact->legal_form()) eq 'corp';
  # README: the next one i am not sure... just a guess! - not on their technical documentation neither XSD samples!
  push @n,['skContactIdent:identValue', [ 'skContactIdent:persIdent', $contact->ident_value()] ] if lc($contact->legal_form()) eq 'pers';
 }

 return unless @n;
 my $eid=$mes->command_extension_register('skContactIdent','create');
 $mes->command_extension($eid,\@n);

 return;
}

####################################################################################################
1;
