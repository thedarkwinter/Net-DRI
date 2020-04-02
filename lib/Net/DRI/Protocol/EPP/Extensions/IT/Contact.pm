## Domain Registry Interface, .IT Contact EPP extension
##
## Copyright (C) 2009-2010,2013,2016 Tower Technologies. All rights reserved.
##           (c) 2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2020 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

Copyright (C) 2009-2010,2013,2016 Tower Technologies.
Copyright (c) 2019 Patrick Mevzek <netdri@dotandco.com>.
Copyright (c) 2020 Paulo Jorge <paullojorgge@gmail.com>.
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
               'info' => [ undef, \&info_parse ],
               'update' => [ \&update, undef ],
       };

       return { 'contact' => $ops };
}

sub fix_contact
{
       my ($epp, $c, $op) = @_;

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

       if (@ext)
       {
               $epp->message()->command_extension('extcon', [$op, @ext]);
       }
       return;
}

sub create
{
       my ($epp, $contact) = @_;

       return fix_contact($epp, $contact, 'create');
}

sub update
{
        my ($epp,$contact,$todo)=@_;
        my $newc=$todo->set('info');
        return unless defined($newc->consent_for_publishing());

        my @n;
        push @n, [ 'extcon:consentForPublishing',$newc->consent_for_publishing() ];

        $epp->message()->command_extension('extcon', ['update', @n]);

        return;
}

sub info_parse
{
       my ($po, $type, $action, $oname, $rinfo) = @_;
       my $msg = $po->message;
       my $ns = $msg->ns('extcon');

       my $infdata = $msg->get_extension('extcon', 'infData');
       return unless $infdata;
       my $s=$rinfo->{contact}->{$oname}->{self};
       
       foreach my $el (Net::DRI::Util::xml_list_children($infdata))
       {
          my ($name,$c)=@$el;
          $s->consent_for_publishing( ($c->textContent()eq'true')?1:0 ) if $name eq 'consentForPublishing';
           if ($name eq 'registrant')
           {
               foreach my $el2 (Net::DRI::Util::xml_list_children($c))
               {
                       my ($name2,$c2)=@$el2;
                       $s->nationality_code($c2->textContent()) if $name2 eq 'nationalityCode';
                       $s->entity_type($c2->textContent()) if $name2 eq 'entityType';
                       $s->reg_code($c2->textContent()) if $name2 eq 'regCode';
               }
           }
       }
       return;
}
1;
