## Domain Registry Interface, Auxiliary Contacts Extension Mapping for EPP
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::AuxContact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::AuxContact- CentralNic Auxiliary Contact Extension (draft-brown-auxcontact)

=head1 DESCRIPTION

Adds the Auxiliary Contact extension for (currently only .feebback).

.Feedback uses the extra contact type "real-registrant"

CentralNic auxcontact extension is defined in https://gitlab.centralnic.com/centralnic/epp-auxcontact-extension/blob/master/draft-brown-auxcontact.txt

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
    info   => [ undef, \&info_parse ],
    create => [ \&create, undef ],
    update => [ \&update, undef ],
    );
 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'auxcontact' => 'urn:ietf:params:xml:ns:auxcontact-0.1' });
 $po->capabilities('domain_update','reg_type',['set']);
 return;
}

sub implements { return 'https://gitlab.centralnic.com/centralnic/epp-auxcontact-extension/blob/1b7a0e935523b306387d236908017ea7ba72f794/draft-brown-auxcontact.txt'; }

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_extension('auxcontact','infData');
 return unless defined $infdata;
 
 my $contact=$rinfo->{domain}->{$oname}->{contact};
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($n,$c)=@$el;
   if ($n eq 'contact')
   {
    my $ctype = $c->getAttribute('type') if $c->hasAttribute('type');
    $rinfo->{$otype}->{$oname}->{contact}->set($po->create_local_object('contact')->srid($c->textContent()),$ctype) if $ctype;
   }
 }
 return;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $cs=$rd->{contact};

 my @n;
 foreach my $ctype ($cs->types)
 {
  next if $ctype =~ m/^(registrant|admin|billing|tech)$/;
  my $cont = $cs->get($ctype);
  push @n,['auxcontact:contact',{type => $ctype},$cont->srid()];
 }
 return unless @n;

 $epp->message()->command_extension('auxcontact', ['create', @n]);
 
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 return unless $todo->add('contact') || $todo->del('contact');
 my (@n,$toadd,@add,$todel,@del,$cont,$ctype);

 # add
 if ($toadd = $todo->add('contact'))
 {
  foreach $ctype ($toadd->types)
  {
   next if $ctype =~ m/^(registrant|admin|billing|tech)$/;
   $cont = $toadd->get($ctype);
   push @add, ['auxcontact:contact',{type => $ctype},$cont->srid()];
  }
  push @n,['auxcontact:add',@add] if @add;
 }

 # del
 if ($todel = $todo->del('contact'))
 {
  foreach $ctype ($todel->types)
  {
   next if $ctype =~ m/^(registrant|admin|billing|tech)$/;
   $cont = $todel->get($ctype);
   push @del, ['auxcontact:contact',{type => $ctype},$cont->srid()];
  }
  push @n,['auxcontact:rem',@del] if @del;
 }

 return unless @n;
 $epp->message()->command_extension('auxcontact', ['update', @n]);
 
 return;

}

####################################################################################################
1;
