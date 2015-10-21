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
use Data::Dumper;

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

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

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

 foreach my $name (qw/type contact purveyor mobile/) {
  if ($name eq 'contact') {
   Net::DRI::Exception::usererr_insufficient_parameters('contact type mandatory! Should be one of these: SFZ, HZ, JGZ, ORG, YYZZ or QT') unless $rd->contact_type();
   push @n,['cnnic-contact:'.$name, {'type'=>($rd->contact_type())}, $rd->$name()];
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
  foreach my $el2(qw/type contact purveyor mobile/) {
   $rinfo->{contact}->{$oname}->{$el2} = $c->textContent() if $n eq $el2;
   $rinfo->{contact}->{$oname}->{$el2.'_type'} = $c->getAttribute('type') if $el2 eq 'contact' && $n eq $el2;
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
 my @extcon=('type','contact','purveyor','mobile');
 
# foreach (@extcon) {
#  # add
#  if ($toadd = $todo->add($_)) {
#   $toadd->{'contact_type'} = $todo->add('contact_type')->{'contact_type'} if $_ eq 'contact' && $todo->add('contact_type');
#   push @add, build_cnnic_contact($toadd);
#  }
#  # del
#  if ($todel = $todo->del($_)) {
#   $todel->{'contact_type'} = $todo->del('contact_type')->{'contact_type'} if $_ eq 'contact' && $todo->add('contact_type');
#    push @del, build_cnnic_contact($todel);
#  }
# }
#
# # add/del
# push @n,['cnnic-contact:add',@add] if @add;
# push @n,['cnnic-contact:rem',@del] if @del;
  
 # chg
 push @n,['cnnic-contact:chg',build_cnnic_contact($todo->set('info'))] if $todo->set('info');

 return unless @n;
 my $eid=$mes->command_extension_register('cnnic-contact','update');
 $mes->command_extension($eid,\@n);

 return;
}

1;