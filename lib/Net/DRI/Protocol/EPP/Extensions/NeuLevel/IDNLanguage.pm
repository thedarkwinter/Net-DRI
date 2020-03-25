## Domain Registry Interface, Neulevel EPP IDN Language
##
## Copyright (c) 2009,2013 Jouanne Mickael <grigouze@gandi.net>. All rights reserved.
## Copyright (c) 2016,2018-2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NeuLevel::IDNLanguage;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NeuLevel::IDNLanguage - NeuLevel EPP IDN Language Commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Jouanne Mickael E<lt>grigouze@gandi.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2009,2013 Jouanne Mickael <grigouze@gandi.net>.
Copyright (c) 2016,2018-2019 Patrick Mevzek <netdri@dotandco.com>.
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
 state $commands = { 'domain' => { 'create' => [ \&create, undef ] } };
 return $commands;
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'neulevel' => 'urn:ietf:params:xml:ns:neulevel-1.0' });
 return;
}

####################################################################################################

sub create
{
 my ($epp, $domain, $rd)=@_;

 return unless Net::DRI::Util::has_key($rd,'language');

 Net::DRI::Exception::usererr_invalid_parameters('IDN language tag must be of type XML schema language') unless Net::DRI::Util::xml_is_language($rd->{language});
 $epp->message()->command_extension('neulevel', ['extension', ['neulevel:unspec', 'IDNLang=' . $rd->{language}]]);

 return;
}

####################################################################################################
1;