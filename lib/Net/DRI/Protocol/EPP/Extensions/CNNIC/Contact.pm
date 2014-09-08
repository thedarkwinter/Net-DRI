## Domain Registry Interface, CNNIC Contact EPP Extension
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

package Net::DRI::Protocol::EPP::Extensions::CNNIC::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CNNIC::Contact - CNNIC Contact Extensions

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
           create   => [ \&create, undef ],
           update   => [ \&update, undef ],
           info     => [ undef, \&parse],
        );
 return { 'contact' => \%tmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->ns({'cnnic-contact' =>['urn:ietf:params:xml:ns:cnnic-contact-1.0','cnnic-contact-1.0.xsd']});
}

####################################################################################################
## Parsing

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless my $data=$mes->get_extension($mes->ns('cnnic-contact'),'infData');
 my $obj=$rinfo->{contact}->{$oname}->{self};
 foreach my $el (Net::DRI::Util::xml_list_children($data)) 
 {
  my ($n,$c)=@$el;
  $obj->type($c->getAttribute('type')) if $n eq 'contact' && $c->hasAttribute('type');
  $obj->code($c->textContent()) if $n eq 'contact';
 }
 return;
}

####################################################################################################
## Building

sub create
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 return unless $c->type();
 my @n;
 push @n,['cnnic-contact:contact',{'type'=>($c->type())}, $c->code()];
 my $eid=$mes->command_extension_register('cnnic-contact','create');
 $mes->command_extension($eid,\@n);
 return;
}

sub update {
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();
 my $add=$todo->add('info');
 my $del=$todo->del('info');
 my $set=$todo->set('info');
 my @n;

 push @n,['cnnic-contact:add', ['cnnic-contact:contact',{'type'=>($add->type())}, $add->code()]]
  if ($add && $add->type() && $add->code());

 push @n,['cnnic-contact:rem', ['cnnic-contact:contact',{'type'=>($del->type())}, $del->code()]]
  if ($del && $del->type() && $del->code());

 push @n,['cnnic-contact:chg', ['cnnic-contact:contact',{'type'=>($set->type())}, $set->code()]]
  if ($set && $set->type() && $set->code());

 return unless @n;

 my $eid=$mes->command_extension_register('cnnic-contact','update');
 $mes->command_extension($eid,\@n);
 return;
}

1;