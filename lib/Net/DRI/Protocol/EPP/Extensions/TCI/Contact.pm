## Domain Registry Interface, .RU/.SU/.XN--P1AI EPP Contact Extension for Net::DRI
##
## Copyright (c) 2010-2011 Dmitry Belyavsky <beldmit@gmail.com>
##               2011-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::TCI::Contact;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Protocol::EPP::Core::Contact;

####################################################################################################

sub register_commands
{
	my ($class, $version) = @_;
	my %tmp = ( 
		create => [ \&create, \&create_parse ],
		update => [ \&update, undef ],
		info   => [ \&info, \&info_parse ],
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
			unless Net::DRI::Util::xml_is_token($n, 3, 32);
	}

	my $tcommand = (ref($command)) ? $command->[0] : $command;
	$msg->command([$command, 'contact:' . $tcommand,
		sprintf('xmlns:contact="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('contact'))]);

	my @d = map { ['contact:id', $_] } @c;
	if (($tcommand =~ m/^(?:info|transfer)$/) && ref($contact[0]) &&
		Net::DRI::Util::isa_contact($contact[0]))
	{
		my $az = $contact[0]->auth();
		if ($az && ref($az) && exists($az->{pw}))
		{
			push(@d, ['contact:authInfo', $az->{pw}]);
		}
	}

	return @d;
}

############ Query commands
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
	my ($po, $otype, $oaction, $oname, $rinfo) = @_;
	my $mes = $po->message();
	return unless $mes->is_success();

	my $infdata = $mes->get_response('contact','infData');
	return unless $infdata;

 	my $contact=$po->create_local_object('contact');
	my @s;

	foreach my $el (Net::DRI::Util::xml_list_children($infdata))
	{
		my ($name,$c)=@$el;
		if ($name eq 'id')
		{
			$oname=$c->textContent();
			$rinfo->{contact}->{$oname}->{action}='info';
			$rinfo->{contact}->{$oname}->{exist}=1;
			$rinfo->{contact}->{$oname}->{id}=$oname;
			$contact->srid($oname);
		} elsif ($name eq 'roid')
		{
			$contact->roid($c->textContent());
			$rinfo->{contact}->{$oname}->{roid}=$contact->roid();
		} elsif ($name eq 'status')
		{
			push @s,Net::DRI::Protocol::EPP::Util::parse_status($c);
		} elsif ($name=~m/^(clID|crID|upID)$/)
		{
			$rinfo->{contact}->{$oname}->{$1}=$c->textContent();
		} elsif ($name=~m/^(crDate|upDate|trDate)$/)
		{
			$rinfo->{contact}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
		} elsif ($name eq 'person')
		{
			$contact->person(parse_contact_data($c));
		} elsif ($name eq 'organization')
		{
			$contact->organization(parse_contact_data($c));
		} elsif ($name eq 'verified')
		{
			$contact->verified(1);
		} elsif ($name eq 'unverified')
		{
			$contact->unverified(1);
		}
		else
		{
			warn "Unspecified behaviour for tag $name"
		}
	}

	$rinfo->{contact}->{$oname}->{status}=$po->create_local_object('status')->add(@s);
	$rinfo->{contact}->{$oname}->{self}=$contact;
	return;
}

sub parse_contact_data
{
	my $element = shift;
	my $result = {};

	foreach my $el (Net::DRI::Util::xml_list_children($element))
	{
		my ($name,$c)=@$el;
		if (($name eq 'email') || ($name eq 'fax') || ($name eq 'voice') || ($name eq 'passport'))
		{
			push @{$result->{$name}}, $c->textContent();
		} 
		elsif (($name eq 'taxpayerNumbers') || ($name eq 'birthday'))
		{
			$result->{$name} = $c->textContent();
		}
		elsif (($name eq 'intPostalInfo') || ($name eq 'locPostalInfo') || ($name eq 'legalInfo'))
		{
			$result->{$name} = parse_address_data($c);
		}
		elsif ($name eq 'disclose')
		{
			$result->{disclose} = parse_disclose($c);
		}
		else
		{
			warn "Unspecified behaviour for tag $name"
		}
	}
	return $result;
}

sub parse_disclose
{
 my $c=shift;
 my $flag=Net::DRI::Util::xml_parse_boolean($c->getAttribute('flag'));
 my %tmp;
 foreach my $el (Net::DRI::Util::xml_list_children($c))
 {
  my ($name,$n)=@$el;
  if ($name=~m/^(intName|locName|birthday|passport|name|org|addr|intOrg|locOrg|intAddress|locAddress|legalAddress|taxpayerNumbers)$/)
  {
   my $t=$n->getAttribute('type');
   $tmp{$1}=$flag;
  } elsif ($name=~m/^(voice|fax|email)$/)
  {
   $tmp{$1}=$flag;
  }
	else
	{
		warn "Unspecified behaviour for tag $name";
	}
 }
 return \%tmp;
}

sub parse_address_data
{
	my $element = shift;
	my $result  = {};
	foreach my $el (Net::DRI::Util::xml_list_children($element))
	{
		my ($name,$c)=@$el;
		if (($name eq 'name') || ($name eq 'org'))
		{
			$result->{$name} = $c->textContent();
		}
		elsif ($name eq 'address')
		{
			push @{$result->{$name}}, $c->textContent();
		}
		else
		{
			warn "Unspecified behaviour for tag $name"
		}
	}

	return $result;
}

############ Transform commands

sub build_disclose
{
	my $contact = shift;
	my $d=$contact->disclose();
	return () unless ($d && ref($d));
	my %v=map { $_ => 1 } values(%$d);
	return () unless (keys(%v)==1); ## 1 or 0 as values, not both at same time

	my @d;
	push(@d, ['contact:intName']) if (exists($d->{intName}));
	push(@d, ['contact:locName']) if (exists($d->{locName}));

	push(@d, ['contact:org']) if (exists($d->{org}));
	push(@d, ['contact:addr']) if (exists($d->{addr}));
	push(@d, ['contact:voice']) if (exists($d->{voice}));
	push(@d, ['contact:fax']) if (exists($d->{fax}));
	push(@d, ['contact:email']) if (exists($d->{email}));

	return ['contact:disclose',@d,{flag=>(keys(%v))[0]}];
}

sub build_cdata
{
	my ($contact, $v) = @_;
	my (@post, @addr);
	my @tmp;
	my @d;

	my ($tag_top, $tag_title, $data);
	if ($contact->person())
	{
		$tag_top   = 'person';
		$tag_title = 'name';
		$data      = $contact->person();
	}
	elsif ($contact->organization())
	{
		$tag_top   = 'organization';
		$tag_title = 'org';
		$data      = $contact->organization();
	}

	my   @contact_data;
	push @contact_data, ['contact:intPostalInfo'  , _make_postal_info($data->{intPostalInfo}, $tag_title)];
	push @contact_data, ['contact:locPostalInfo'  , _make_postal_info($data->{locPostalInfo}, $tag_title)];

	if ($contact->organization())
	{
		push @contact_data, ['contact:legalInfo'    , _make_postal_info($data->{legalInfo}, $tag_title )];
	}

	push @contact_data, ['contact:taxpayerNumbers', $data->{taxpayerNumbers}];

	if ($contact->person())
	{
		#birthday
		push @contact_data, ['contact:birthday', $data->{birthday}];

		#passport
		for my $str (@{$data->{passport}})
		{
			push @contact_data, ['contact:passport', $str];
		}
	}

	for my $str (@{$data->{voice}})
	{
		push @contact_data, ['contact:voice', $str];
	}

	if ($data->{fax} && scalar @{$data->{fax}})
	{
		for my $str (@{$data->{fax}})
		{
			push @contact_data, ['contact:fax', $str];
		}
	}
	else
	{
		push @contact_data, ['contact:fax'];
	}
	
	for my $str (@{$data->{email}})
	{
		push @contact_data, ['contact:email', $str];
	}

	push(@contact_data, build_disclose($contact));

	push @d, ["contact:$tag_top", @contact_data];

	if ($contact->verified())
	{
		push @d, ['contact:verified'];
	}
	elsif ($contact->unverified())
	{
		push @d, ['contact:unverified'];
	}

	return @d;
}

sub _make_postal_info
{
	my $data = shift;
	my $tag  = shift;

	my @d;
	
	push @d, ["contact:$tag", $data->{$tag}] if $data->{$tag};
	for my $str (@{$data->{address}})
	{
		push @d, ['contact:address', $str];
	}

	return @d;
}

sub create 
{
	my ($epp, $contact) = @_;
	my $mes = $epp->message();
	my @d = build_command($mes, 'create', $contact);

	Net::DRI::Exception->die(1, 'protocol/EPP', 10, 'Invalid contact ' .
		$contact) unless Net::DRI::Util::isa_contact($contact);
	$contact->validate(); ## will trigger an Exception if needed
	push(@d, build_cdata($contact, $epp->{contacti18n}));
	$mes->command_body(\@d);
	return;
}

sub create_parse
{
	my (@args)=@_;
	return Net::DRI::Protocol::EPP::Core::Contact::create_parse(@args);
}

sub update 
{
	my ($epp, $contact, $todo) = @_;
	my $mes = $epp->message();

	Net::DRI::Exception::usererr_invalid_parameters($todo .
		' must be a Net::DRI::Data::Changes object')
		unless Net::DRI::Util::isa_changes($todo);
	if ((grep { ! /^(?:add|del)$/ } $todo->types('status')) ||
		(grep { ! /^(?:set)$/ } $todo->types('info')))
	{
		Net::DRI::Exception->die(0, 'protocol/EPP', 11,
			'Only status add/del or info set available for ' .
			'contact');
	}

	my @d = build_command($mes, 'update', $contact);

	my $sadd = $todo->add('status');
	my $sdel = $todo->del('status');
	push(@d, ['contact:add', $sadd->build_xml('contact:status')])
		if ($sadd);
	push(@d, ['contact:rem', $sdel->build_xml('contact:status')])
		if ($sdel);

	my $newc = $todo->set('info');
	if ($newc)
	{
		Net::DRI::Exception->die(1, 'protocol/EPP', 10,
			'Invalid contact ' . $newc)
			unless Net::DRI::Util::isa_contact($newc);
		$newc->validate(1); ## will trigger an Exception if needed
		my @c = build_cdata($newc, $epp->{contacti18n});
		push(@d, ['contact:chg', @c]) if (@c);
	}

	$mes->command_body(\@d);
	return;
}

####################################################################################################
1;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TCI::Contact - TCI EPP Contact Extension for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Dmitry Belyavsky, E<lt>beldmit@gmail.comE<gt>
Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010-2011 Dmitry Belyavsky <beldmit@gmail.com>
Copyright (c) 2011-2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
