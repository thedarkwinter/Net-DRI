## Domain Registry Interface, CentralNic EPP Registration Type extension
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::RegType;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::RegType - CentralNic Registration Type Extension (draft-brown-regtype)

=head1 DESCRIPTION

Adds the RegType extension for (currently only .feebback).

CentralNic RegType extension is defined in https://gitlab.centralnic.com/centralnic/epp-registration-type-extension/blob/master/draft-brown-regtype.txt

=item reg_type

Specify the registration rype.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>
Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my %tmp=(
    info  => [ undef, \&info_parse ],
    check  => [ \&check, undef ],
    create => [ \&create, undef ],
    update => [ \&update, undef ],
    );
 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'regtype' => [ 'urn:ietf:params:xml:ns:regtype-0.2','regtype-0.2.xsd' ] });
 $po->capabilities('domain_update','reg_type',['set']);
 return;
}

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'reg_type');

 my @n;
 push @n,['regtype:type',$rd->{reg_type}];

 my $eid=$mes->command_extension_register('regtype','check');
 $mes->command_extension($eid,\@n);

 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_extension($mes->ns('regtype'),'infData');
 return unless defined $infdata;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($n,$c)=@$el;
   if ($n eq 'type')
   {
    $rinfo->{domain}->{$oname}->{reg_type}=$c->textContent();
   }
 }

 return;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'reg_type');

 my @n;
 push @n,['regtype:type',$rd->{reg_type}];

 my $eid=$mes->command_extension_register('regtype','create');
 $mes->command_extension($eid,\@n);

 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();
 return unless $todo->set('reg_type');

 my @n;
 push @n,['regtype:chg',['regtype:type',$todo->set('reg_type')]];

 my $eid=$mes->command_extension_register('regtype','update');
 $mes->command_extension($eid,\@n);

 return;
}

####################################################################################################
1;
