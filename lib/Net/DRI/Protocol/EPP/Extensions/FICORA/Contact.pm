## Domain Registry Interface, FICORA - .FI Contact EPP extension commands
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::FICORA::Contact;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FICORA::Contact - .FI EPP Contact extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>.
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
          create => [ \&create, undef ],
          update => [ \&update, undef ],
          info   => [ undef, \&info_parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub build_command
{
  my ($msg, $command, $contact) = @_;
	my @contact = (ref($contact) eq 'ARRAY')? @$contact : ($contact);
	my @c = map { Net::DRI::Util::isa_contact($_) ?
		$_->srid() : $_ } @contact;

	Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed')
		unless @c;
	foreach my $n (@c)
	{
		Net::DRI::Exception->die(1, 'protocol/EPP', 2,
			'Contact id needed') unless (defined($n) && $n && !ref($n));
		Net::DRI::Exception->die(1, 'protocol/EPP', 10,
			'Invalid contact id: ' . $n)
			unless Net::DRI::Util::xml_is_token($n, 1, 32);
	}

	my $tcommand = (ref($command)) ? $command->[0] : $command;
	$msg->command([$command, 'contact:' . $tcommand,
		sprintf('xmlns:contact="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('contact'))]);

	my @d = map { ['contact:id', $_] } @c;
  # by the technical documentation auth info is not support on create and update
  # but the element is defined on their schema!
  # lets keep/build for transfer and info - we can reuse in the future - who knows?
  if (($tcommand =~ m/^(?:transfer|info)$/) && ref($contact[0]) &&
		Net::DRI::Util::isa_contact($contact[0]))
	{
		my $az = $contact[0]->auth();
		if ($az && ref($az) && exists($az->{pw}))
		{
			push(@d, ['contact:authInfo',['contact:pw', $az->{pw}]]);
		}
	}

	return @d;
}


sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes, 'create', $contact);

 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact '.$contact) unless Net::DRI::Util::isa_contact($contact);
 $contact->validate(); # will trigger an Exception if needed
 push @d,build_ficora_contact($contact,$epp->{contacti18n});
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

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($name,$content)=@$el;
   if ($name eq 'postalInfo')
   {
     foreach my $el_postalInfo (Net::DRI::Util::xml_list_children($content))
     {
       my ($name_postalInfo,$content_postalInfo)=@$el_postalInfo;
       $rinfo->{contact}->{$oname}->{$name_postalInfo}=$content_postalInfo->textContent() if $name_postalInfo =~ m/^(firstname|lastname)$/;
       $rinfo->{contact}->{$oname}->{self}->{$name_postalInfo}=$content_postalInfo->textContent() if $name_postalInfo =~ m/^(firstname|lastname)$/;
     }
   }
   $rinfo->{contact}->{$oname}->{$name}=$content->textContent() if $name eq 'legalemail';
   $rinfo->{contact}->{$oname}->{self}->{$name}=$content->textContent() if $name eq 'legalemail';
 }
}


sub build_ficora_contact
{
  my ($contact, $v) = @_;
  my (@post, @addr, $ident);
  my @tmp;
  my @d;

  # id - done under build_command()

  # role
  push(@d, ['contact:role', $contact->role()])
    if (defined($contact->role()));

  # type
  push(@d, ['contact:type', $contact->type()])
    if (defined($contact->type()));


  ###
  # postal info element
  ###

  # isfinnish
  @tmp = $contact->isfinnish();
  if (defined($tmp[0])) { push(@post, ['contact:isfinnish', $tmp[0]]); }

  # firstname
  @tmp = $contact->firstname();
  if (defined($tmp[0])) { push(@post, ['contact:firstname', $tmp[0]]); }

  # lastname
  @tmp = $contact->lastname();
  if (defined($tmp[0])) { push(@post, ['contact:lastname', $tmp[0]]); }

  # name
  @tmp = $contact->name();
  if (defined($tmp[0])) { push(@post, ['contact:name', $tmp[0]]); }

  # org
  @tmp = $contact->org();
  if (defined($tmp[0])) { push(@post, ['contact:org', $tmp[0]]); }

  # birthDate
  @tmp = $contact->birthdate();
  if (defined($tmp[0])) { push(@post, ['contact:birthDate', $tmp[0]]); }

  # identity
  @tmp = $contact->identity();
  if (defined($tmp[0])) { push(@post, ['contact:identity', $tmp[0]]); }

  # registernumber
  @tmp = $contact->registernumber();
  if (defined($tmp[0])) { push(@post, ['contact:registernumber', $tmp[0]]); }

  ##
  # addr
  ##

  # street
  @tmp = $contact->street();
  if (defined($tmp[0])) { foreach (@{$tmp[0]}) {
    push(@addr, ['contact:street', $_]);
  } }

  # city
  @tmp = $contact->city();
  if (defined($tmp[0])) { push(@addr, ['contact:city', $tmp[0]]); }

  # sp
  @tmp = $contact->sp();
  if (defined($tmp[0])) { push(@addr, ['contact:sp', $tmp[0]]); }

  # pc
  @tmp = $contact->pc();
  if (defined($tmp[0])) { push(@addr, ['contact:pc', $tmp[0]]); }

  # c
  @tmp = $contact->cc();
  if (defined($tmp[0])) { push(@addr, ['contact:cc', $tmp[0]]); }

  push(@post, ['contact:addr', @addr]) if (@addr);
  ##
  # end addr
  ##

  push(@d, ['contact:postalInfo', @post, {type=>'loc'}]);
  ###
  # postal info element
  ###


  @tmp = $contact->id();
  if (defined($tmp[0])) { push(@post, ['contact:id', $tmp[0]]); }

  @tmp = $contact->role();
  if (defined($tmp[0])) { push(@post, ['contact:role', $tmp[0]]); }

  @tmp = $contact->type();
  if (defined($tmp[0])) { push(@post, ['contact:type', $tmp[0]]); }

  # voice
  push(@d, Net::DRI::Protocol::EPP::Util::build_tel('contact:voice', $contact->voice()))
    if (defined($contact->voice()));

  # fax
  push(@d, Net::DRI::Protocol::EPP::Util::build_tel('contact:fax', $contact->fax()))
    if (defined($contact->fax()));

  # email
  push(@d, ['contact:email', $contact->email()])
    if (defined($contact->email()));

  # legalemail
  push(@d, ['contact:legalemail', $contact->legalemail()])
    if (defined($contact->legalemail()));

  # authInfo - done under build_command()

  # disclose
  push(@d, build_disclose($contact));

  return @d;
}


sub build_disclose {
  my $contact = shift;
  my $d=$contact->disclose();
  return () unless ($d && ref($d));
  my %v=map { $_ => 1 } values(%$d);
  return () unless (keys(%v)==1); ## 1 or 0 as values, not both at same time

  my @d;
  push(@d, ['contact:voice']) if (exists($d->{voice}));
  push(@d, ['contact:email']) if (exists($d->{email}));
  push(@d, ['contact:addr']) if (exists($d->{addr}));

  return ['contact:disclose',@d,{flag=>(keys(%v))[0]}];
}


sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');

 my @d=build_command($mes,'update',$contact);
 push @d,['contact:add',$sadd->build_xml('contact:status')] if Net::DRI::Util::isa_statuslist($sadd);
 push @d,['contact:rem',$sdel->build_xml('contact:status')] if Net::DRI::Util::isa_statuslist($sdel);

 my $newc=$todo->set('info');
 if (defined $newc)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact '.$newc) unless Net::DRI::Util::isa_contact($newc);
  $newc->validate(1); ## will trigger an Exception if needed
  my @c=build_ficora_contact($newc,$epp->{contacti18n});
  push @d,['contact:chg',@c] if @c;
 }
 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;
