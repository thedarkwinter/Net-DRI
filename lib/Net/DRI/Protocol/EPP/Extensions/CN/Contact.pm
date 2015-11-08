## Domain Registry Interface, CNNIC Contact EPP Extension
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CN::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CN::Contact - CN Contact Extensions

=head1 DESCRIPTION

Adds the EPP Registry extension

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
(c) 2015 Michael Holloway <michael@thedarkwinter.com>.
(c) 2015 Paulo Jorge <paullojorgge@gmail.com>.
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
           create   => [ \&create, undef ],
           update   => [ \&update, undef ],
           info     => [ undef, \&info_parse],
        );

 return { 'contact' => \%tmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->ns({ 'cnnic-contact' => [ 'urn:ietf:params:xml:ns:cnnic-contact-1.0','cnnic-contact-1.0.xsd' ] });

 return;
}

####################################################################################################

sub build_cnnic_contact
{
 my ($rd) = shift;
 my @n;

 foreach my $name (qw/type orgno purveyor mobile/) {
  if ($name eq 'orgno' && $rd->$name()) {
   Net::DRI::Exception::usererr_insufficient_parameters('orgtype mandatory! Should be one of these: SFZ, HZ, JGZ, ORG, YYZZ or QT') unless $rd->orgtype();
   push @n,['cnnic-contact:contact', {'type'=>($rd->orgtype())}, $rd->$name()];
  }
  else {
   push @n,['cnnic-contact:'.$name, $rd->$name()] if $rd->$name();
  }
 }

 return @n;
}

####################################################################################################
## Parsing

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless my $data=$mes->get_extension($mes->ns('cnnic-contact'),'infData');
 foreach my $el (Net::DRI::Util::xml_list_children($data)) 
 {
  my ($n,$c)=@$el;
  if ($n eq 'contact') {
   $rinfo->{contact}->{$oname}->{'orgno'} = $c->textContent();
   $rinfo->{contact}->{$oname}->{'orgtype'} = $c->getAttribute('type');
  } elsif ($n =~ m/^(type|purveyor|mobile)$/) {
   $rinfo->{contact}->{$oname}->{$n} = $c->textContent();
  }
 }

 return;
}

####################################################################################################
## Building

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 my @n=build_cnnic_contact($contact);
 return unless @n;
 my $eid=$mes->command_extension_register('cnnic-contact','create');
 $mes->command_extension($eid,\@n);

 return;
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();
 my (@n,$toadd,@add,$todel,@del,@cont,@tmpadd,@tmpdel);
 my @extcon=('type','orgno','purveyor','mobile');
 
 foreach (@extcon) {
  # add
  if ($toadd = $todo->add($_))
  {
   if ($_ eq 'orgno')
   {
    Net::DRI::Exception::usererr_insufficient_parameters('mandatory to update orgno and orgtype which should be one of these: SFZ, HZ, JGZ, ORG, YYZZ or QT') unless $todo->add('orgtype');
    Net::DRI::Exception::usererr_invalid_parameters('orgtype should be one of these: SFZ, HZ, JGZ, ORG, YYZZ or QT') if $todo->add('orgtype')->{'orgtype'} !~ m/^(?:SFZ|HZ|JGZ|ORG|YYZZ|QT)$/;
    push @add, ['cnnic-contact:contact',$toadd->{$_},{'type'=>$todo->add('orgtype')->{'orgtype'}}] if $toadd->{$_};
   } else {
    push @add, ['cnnic-contact:'.$_,$toadd->{$_}] if $toadd->{$_};
   }
  }
  # del
  if ($todel = $todo->del($_)) {
   if ($_ eq 'orgno')
   {
    Net::DRI::Exception::usererr_insufficient_parameters('mandatory to update orgno and orgtype which should be one of these: SFZ, HZ, JGZ, ORG, YYZZ or QT') unless $todo->del('orgtype');
    Net::DRI::Exception::usererr_invalid_parameters('orgtype should be one of these: SFZ, HZ, JGZ, ORG, YYZZ or QT') if $todo->del('orgtype')->{'orgtype'} !~ m/^(?:SFZ|HZ|JGZ|ORG|YYZZ|QT)$/;
    push @del, ['cnnic-contact:contact',$todel->{$_},{'type'=>$todo->del('orgtype')->{'orgtype'}}] if $todel->{$_};
   } else {
    push @del, ['cnnic-contact:'.$_,$todel->{$_}] if $todel->{$_};
   }
  }
 }

 # add/del
 push @n,['cnnic-contact:add',@add] if @add;
 push @n,['cnnic-contact:rem',@del] if @del;
 # chg
 push @n,['cnnic-contact:chg',build_cnnic_contact($todo->set('info'))] if $todo->set('info');

 return unless @n;
 my $eid=$mes->command_extension_register('cnnic-contact','update');
 $mes->command_extension($eid,\@n);

 return;
}

1;