## Domain Registry Interface, CentralNic EPP Fee extension
##
## Copyright (c) 2020 Ivan Borzenkov <ivan.borenkov@gmail.com>. All rights reserved.
##           (c) 2021 Michael Holloway <michael@thedarkwiner.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::KeySys;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use DateTime::Duration;
use DateTime::Format::ISO8601;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::KeySys - CentralNic EPP KeySys extension commands for Net::DRI

=head1 DESCRIPTION

Partially implemented KeySys extension

=cut

####################################################################################################

sub register_commands
{
    my %tmp=(
        update => [ \&update, undef ],
    );
    return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'keysys' => [ 'http://www.key-systems.net/epp/keysys-1.0','keysys-1.0.xsd' ] });
 return;
}

sub update
{
    my ($epp, $domain, $rd) = @_;

    if (!Net::DRI::Util::check_isa($rd,'Net::DRI::Data::Changes') || !$rd->{'registrant'}) {
        return
    }

    my $mes = $epp->message();
    my $eid=$mes->command_extension_register('keysys:update','xmlns:keysys="http://www.key-systems.net/epp/keysys-1.0"', 'keysys');
    my @kv = ();
    push @kv, ['keysys:domain', ['keysys:accept-trade', 1]];
    $mes->command_extension($eid,\@kv);
    return;
}

####################################################################################################
1;