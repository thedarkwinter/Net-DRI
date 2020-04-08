## Domain Registry Interface, Registration Type Extension Mapping for EPP
##
## Copyright (c) 2016,2018-2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
## Copyright (c) 2020 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

Copyright (c) 2016,2018-2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
Copyright (c) 2020 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

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
    create => [ \&create, undef ], 
    update => [ \&update, undef ],
    );
 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'regType' => 'urn:ietf:params:xml:ns:regtype-0.1' });
 $po->capabilities('domain_update','reg_type',['set']);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_extension('regType','infData');
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
 return unless Net::DRI::Util::has_key($rd,'reg_type');

 my @n;
 push @n,['regType:type',$rd->{reg_type}];

 $epp->message()->command_extension('regType', ['create', @n]);
 
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 return unless $todo->set('reg_type');

 my @n;
 push @n,['regType:chg',['regType:type',$todo->set('reg_type')]];

 $epp->message()->command_extension('regType', ['update', @n]);
 
 return;
}

####################################################################################################
1;
