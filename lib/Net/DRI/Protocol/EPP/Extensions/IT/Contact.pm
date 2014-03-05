## Domain Registry Interface, .IT Contact EPP extension
##
## Copyright (C) 2009-2010,2013 Tower Technologies. All rights reserved.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License v2.

package Net::DRI::Protocol::EPP::Extensions::IT::Contact;

use strict;
use warnings;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::IT::Contact - .IT EPP Contact extension for Net::DRI

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>noc@towertech.itE<gt>

Please also see the SUPPORT file in the distribution.

=head1 AUTHOR

Alessandro Zummo, E<lt>a.zummo@towertech.itE<gt>

=head1 COPYRIGHT

Copyright (C) 2009-2010,2013 Tower Technologies.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License v2 as published by
the Free Software Foundation.

See the LICENSE file that comes with this distribution for more details.

=cut


sub register_commands
{
       my ($class, $version) = @_;

       my $ops = {
               'create' => [ \&create, undef ],
       };

       return { 'contact' => $ops };
}

sub build_command_extension
{
       my ($msg, $epp, $tag) = @_;

       return $msg->command_extension_register($tag,
               sprintf('xmlns:extcon="%s" xsi:schemaLocation="%s %s"', $msg->nsattrs('it_contact')));
}

sub fix_contact
{
       my ($epp, $c, $op) = @_;
       my $msg = $epp->message;

       my $eid = build_command_extension($msg, $epp, 'extcon:' . $op);

       my @ext;

       push @ext, [ 'extcon:consentForPublishing', $c->consent_for_publishing ]
               if defined $c->consent_for_publishing;

       # registrant data (do not alter the order, there's people
       # who likes to use <sequence> in xsds)
       my @registrant;

       push @registrant, [ 'extcon:nationalityCode', $c->nationality_code ]
               if defined $c->nationality_code;

       push @registrant, [ 'extcon:entityType', $c->entity_type ]
               if defined $c->entity_type;

       push @registrant, [ 'extcon:regCode', $c->reg_code ]
               if defined $c->reg_code;


       push @ext, [ 'extcon:registrant', @registrant ]
               if scalar @registrant;

       $msg->command_extension($eid, [ @ext ])
               if scalar @ext;
       return;
}

sub create
{
       my ($epp, $contact) = @_;

       return fix_contact($epp, $contact, 'create');
}

1;
