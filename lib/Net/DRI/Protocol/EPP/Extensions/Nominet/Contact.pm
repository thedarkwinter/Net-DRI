## Domain Registry Interface, .UK EPP Contact commands
##
## Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::Contact - .UK EPP Contact commands for Net::DRI

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

Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
		info   => [ \&info, \&info_parse ],
		update => [ \&update ],
	);

 return { 'contact' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$contact)=@_;
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless (defined($contact));

 my $id=Net::DRI::Util::isa_contact($contact,'Net::DRI::Data::Contact::Nominet')? $contact->roid() : $contact;
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless (defined($id) && $id && !ref($id));
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact id: '.$id) unless Net::DRI::Util::xml_is_token($id,3,16); ## inherited from Core EPP
 my $tcommand=(ref($command))? $command->[0] : $command;
 $msg->command([$command,'contact:'.$tcommand,sprintf('xmlns:contact="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('contact'))]);
 return (['contact:roid',$id]);
}

####################################################################################################
########### Query commands

sub info
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'info',$c);
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response('contact','infData');
 return unless defined $infdata;

 my $contact=$po->create_local_object('contact');
 parse_infdata($po,$infdata,$contact,$oname,$rinfo);
 return;
}

sub parse_infdata
{
 my ($po,$infdata,$contact,$oname,$rinfo)=@_;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'roid')
  {
   $oname=$c->textContent();
   $contact->roid($oname);
   $rinfo->{contact}->{$oname}->{roid}=$contact->roid();
   $rinfo->{contact}->{$oname}->{action}='info';
   $rinfo->{contact}->{$oname}->{exist}=1;
  } elsif ($name eq 'name')
  {
   $contact->name($c->textContent());
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'email')
  {
   $contact->email($c->textContent());
  } elsif ($name eq 'phone') ## diverving from EPP voice
  {
   $contact->voice(Net::DRI::Protocol::EPP::Util::parse_tel($c));
  } elsif ($name eq 'fax')
  {
   $contact->fax(Net::DRI::Protocol::EPP::Util::parse_tel($c));
  } elsif ($name eq 'mobile')
  {
    $contact->mobile(Net::DRI::Protocol::EPP::Util::parse_tel($c));
  }
 }

 $rinfo->{contact}->{$oname}->{self}=$contact;
 return;
}

# ############ Transform commands

sub build_cdata
{
 my ($contact)=@_;
 my @d;
 push @d,['contact:name',$contact->name()] if (defined($contact->name()));
 push @d,Net::DRI::Protocol::EPP::Util::build_tel('contact:phone',$contact->voice()) if defined $contact->voice();
 push @d,Net::DRI::Protocol::EPP::Util::build_tel('contact:fax',$contact->fax()) if defined $contact->fax();
 push @d,Net::DRI::Protocol::EPP::Util::build_tel('contact:mobile',$contact->mobile()) if defined $contact->mobile();
 push @d,['contact:email',$contact->email()] if defined($contact->email());
 return @d;
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);
 if (grep { ! /^(?:set)$/ } $todo->types('info'))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only info set available for contact in .UK');
 }

 my @d=build_command($mes,'update',$contact);
 my $newc=$todo->set('info');
 if ($newc)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact '.$newc) unless (Net::DRI::Util::isa_contact($newc,'Net::DRI::Data::Contact::Nominet'));
  $newc->validate(1); ## will trigger an Exception if needed
  my @c=build_cdata($newc);
  if (@c)
  {
   push @d,@c;
  } else
  {
   Net::DRI::Exception->die(0,'protocol/EPP',11,'Nothing to update !');
  }
 } else
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Nothing to update !');
 }
 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;
