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

Adds the SK EPP Contact Ident extension for contact object
FIXME: Update POD!!!! Use this: https://docs.test.sk-nic.sk/commands/#pr%C3%ADkaz-lt-create

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSOnetdri@dotandco.com
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

# FIXME: CHECK IF THIS IS MANDOTORY!!! CHECK ON THEIR OT&E AND WITH THE REGISTRY
sub register_commands
{
 my %tmp=(
    # info  => [ undef, \&info_parse ],
    # create => [ \&create, undef ],
    # update => [ \&update, undef ],
    );
 return { 'contact' => \%tmp };
}

# sub setup
# {
#  my ($class,$po,$version)=@_;
#  $po->ns({ 'sk-contact-ident' => [ 'http://www.sk-nic.sk/xml/epp/sk-contact-ident-0.2','sk-contact-ident-0.2.xsd' ] });
#  $po->capabilities('domain_update','reg_type',['set']);
#  return;
# }
#
# sub info_parse
# {
#  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
#  my $mes=$po->message();
#  return unless $mes->is_success();
#  my $infdata=$mes->get_extension($mes->ns('auxcontact'),'infData');
#  return unless defined $infdata;
#
#  my $contact=$rinfo->{domain}->{$oname}->{contact};
#  foreach my $el (Net::DRI::Util::xml_list_children($infdata))
#  {
#    my ($n,$c)=@$el;
#    if ($n eq 'contact')
#    {
#     my $ctype = $c->getAttribute('type') if $c->hasAttribute('type');
#     $rinfo->{$otype}->{$oname}->{contact}->set($po->create_local_object('contact')->srid($c->textContent()),$ctype) if $ctype;
#    }
#  }
#  return;
# }
#
# sub create
# {
#  my ($epp,$domain,$rd)=@_;
#  my $mes=$epp->message();
#  my $cs=$rd->{contact};
#
#  my @n;
#  foreach my $ctype ($cs->types)
#  {
#   next if $ctype =~ m/^(registrant|admin|billing|tech)$/;
#   my $cont = $cs->get($ctype);
#   push @n,['auxcontact:contact',{type => $ctype},$cont->srid()];
#  }
#  return unless @n;
#
#  my $eid=$mes->command_extension_register('auxcontact','create');
#  $mes->command_extension($eid,\@n);
#
#  return;
# }
#
# sub update
# {
#  my ($epp,$domain,$todo)=@_;
#  my $mes=$epp->message();
#  return unless $todo->add('contact') || $todo->del('contact');
#  my (@n,$toadd,@add,$todel,@del,$cont,$ctype);
#
#  # add
#  if ($toadd = $todo->add('contact'))
#  {
#   foreach $ctype ($toadd->types)# sub setup
# {
#  my ($class,$po,$version)=@_;
#  $po->ns({ 'auxcontact' => [ 'urn:ietf:params:xml:ns:auxcontact-0.1','auxcontact-0.1.xsd' ] });
#  $po->capabilities('domain_update','reg_type',['set']);
#  return;
# }
#
# sub info_parse
# {
#  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
#  my $mes=$po->message();
#  return unless $mes->is_success();
#  my $infdata=$mes->get_extension($mes->ns('auxcontact'),'infData');
#  return unless defined $infdata;
#
#  my $contact=$rinfo->{domain}->{$oname}->{contact};
#  foreach my $el (Net::DRI::Util::xml_list_children($infdata))
#  {
#    my ($n,$c)=@$el;
#    if ($n eq 'contact')
#    {
#     my $ctype = $c->getAttribute('type') if $c->hasAttribute('type');
#     $rinfo->{$otype}->{$oname}->{contact}->set($po->create_local_object('contact')->srid($c->textContent()),$ctype) if $ctype;
#    }
#  }
#  return;
# }
#
# sub create
# {
#  my ($epp,$domain,$rd)=@_;
#  my $mes=$epp->message();
#  my $cs=$rd->{contact};
#
#  my @n;
#  foreach my $ctype ($cs->types)
#  {
#   next if $ctype =~ m/^(registrant|admin|billing|tech)$/;
#   my $cont = $cs->get($ctype);
#   push @n,['auxcontact:contact',{type => $ctype},$cont->srid()];
#  }
#  return unless @n;
#
#  my $eid=$mes->command_extension_register('auxcontact','create');
#  $mes->command_extension($eid,\@n);
#
#  return;
# }
#
# sub update
# {
#  my ($epp,$domain,$todo)=@_;
#  my $mes=$epp->message();
#  return unless $todo->add('contact') || $todo->del('contact');
#  my (@n,$toadd,@add,$todel,@del,$cont,$ctype);
#
#  # add
#  if ($toadd = $todo->add('contact'))
#  {
#   foreach $ctype ($toadd->types)
#   {
#    next if $ctype =~ m/^(registrant|admin|billing|tech)$/;
#    $cont = $toadd->get($ctype);
#    push @add, ['auxcontact:contact',{type => $ctype},$cont->srid()];
#   }
#   push @n,['auxcontact:add',@add] if @add;
#  }
#
#  # del
#  if ($todel = $todo->del('contact'))
#  {
#   foreach $ctype ($todel->types)
#   {
#    next if $ctype =~ m/^(registrant|admin|bill|tech)$/;
#    $cont = $todel->get($ctype);
#    push @del, ['auxcontact:contact',{type => $ctype},$cont->srid()];
#   }
#   push @n,['auxcontact:rem',@del] if @del;
#  }
#
#  return unless @n;
#  my $eid=$mes->command_extension_register('auxcontact','update');
#  $mes->command_extension($eid,\@n);
#
#  return;
#
# }
#   {
#    next if $ctype =~ m/^(registrant|admin|billing|tech)$/;
#    $cont = $toadd->get($ctype);
#    push @add, ['auxcontact:contact',{type => $ctype},$cont->srid()];
#   }
#   push @n,['auxcontact:add',@add] if @add;
#  }
#
#  # del
#  if ($todel = $todo->del('contact'))
#  {
#   foreach $ctype ($todel->types)
#   {
#    next if $ctype =~ m/^(registrant|admin|bill|tech)$/;
#    $cont = $todel->get($ctype);
#    push @del, ['auxcontact:contact',{type => $ctype},$cont->srid()];
#   }
#   push @n,['auxcontact:rem',@del] if @del;
#  }
#
#  return unless @n;
#  my $eid=$mes->command_extension_register('auxcontact','update');
#  $mes->command_extension($eid,\@n);
#
#  return;
#
# }

####################################################################################################
1;
