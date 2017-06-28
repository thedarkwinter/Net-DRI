## Domain Registry Interface, United TLD EPP Finance Extension
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::UnitedTLD::Finance;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::UNITEDTLD::Finance - Finance Extension for United TLD registrar balance request.

=head1 DESCRIPTION

Adds the Finance Extension (http://www.unitedtld.com/epp/finance-1.0) to domain command allowing a registrar to check balance.

 # registrar_balance
 $rc = $dri->registrar_balance();
 print $dri->get_info('balance');
 print $dri->get_info('final');
 print $dri->get_info('restricted');
 print $dri->get_info('notification');

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>.
(c) 2014 Michael Holloway <michael@thedarkwinter.com>.
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
           balance => [ \&info, \&info_parse],
        );
 return { 'registrar' => \%tmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->ns({ map { $_ => ['http://www.unitedtld.com/epp/'.$_.'-1.0',$_.'-1.0.xsd'] } qw/finance/ });
}

####################################################################################################

sub info
{
 my ($epp,$domain,$rd,$cmd)=@_;
 my $mes=$epp->message();
 $mes->command(['info','finance:info',sprintf('xmlns:finance="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('finance'))]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response($mes->ns('finance'),'infData');
 return unless defined $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($n,$c)=@$el;
   $rinfo->{registrar}->{$oname}->{$n} = $c->textContent() if $n eq 'balance';
   $rinfo->{registrar}->{$oname}->{$c->getAttribute('type')} = $c->textContent() if $c->hasAttribute('type') && $n eq 'threshold';
 }
 return;
}

1;
