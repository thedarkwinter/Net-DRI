## Domain Registry Interface, SIDN EPP Contact commands
##
## Copyright (c) 2009,2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::SIDN::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           info   => [ undef, \&info_parse ],
           create => [ \&create, undef ],
	   update => [ \&update ],
         );

 return { 'contact' => \%tmp };
}

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:sidn="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('sidn')));
}

####################################################################################################
########### Query commands

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('sidn','ext');
 return unless defined $infdata;

 my $ns=$mes->ns('sidn');
 $infdata=Net::DRI::Util::xml_traverse($infdata,$ns,'infData','contact');
 return unless defined $infdata;

 my $contact=$rinfo->{contact}->{$oname}->{self};

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'legalForm')
  {
   $contact->legal_form($c->textContent());
  } elsif ($name eq 'legalFormRegNo')
  {
   $contact->legal_id($c->textContent());
  } elsif ($name eq 'limited')
  {
   $contact->limited(Net::DRI::Util::xml_parse_boolean($c->textContent()));
  }
 }
 return;
}

########### Transform commands

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

 ## $contact->validate() has been called
 my @n;
 push @n,['sidn:legalForm',$contact->legal_form()];
 push @n,['sidn:legalFormRegNo',$contact->legal_id()] if $contact->legal_id();

 my $eid=build_command_extension($mes,$epp,'sidn:ext');
 $mes->command_extension($eid,['sidn:create',['sidn:contact',@n]]);
 return;
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 my $newc=$todo->set('info');
 return unless defined $newc;

 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact '.$newc) unless Net::DRI::Util::isa_contact($newc,'Net::DRI::Data::Contact::SIDN');
 $newc->validate(1); ## will trigger an Exception if needed

 my @n;
 push @n,['sidn:legalForm',$newc->legal_form()] if $newc->legal_form();
 push @n,['sidn:legalFormRegNo',$newc->legal_id()] if $newc->legal_id();

 return unless @n;

 my $eid=build_command_extension($mes,$epp,'sidn:ext');
 $mes->command_extension($eid,['sidn:update',['sidn:contact',@n]]);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SIDN::Contact - SIDN EPP Contact commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2009,2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
