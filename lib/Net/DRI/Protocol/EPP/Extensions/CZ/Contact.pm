## Domain Registry Interface, .CZ Contact EPP extension commands
##
## Copyright (c) 2008,2010,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##                    All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::EPP::Extensions::CZ::Contact;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CZ::Contact - .CZ EPP Contact extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt> or
E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2010,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
	my ($class, $version) = @_;
	my %tmp = ( 
		info =>   [ undef, \&info_parse ],
		create => [ \&create, undef ],
		update => [ \&update, undef ]
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
			unless Net::DRI::Util::xml_is_token($n, 3, 16);
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

sub info_parse
{
	my ($po, $otype, $oaction, $oname, $rinfo) = @_;
	my $mes = $po->message();

	return unless $mes->is_success();

	my $infdata = $mes->get_response('contact','infData');
	return unless $infdata;

	my $s = $rinfo->{contact}->{$oname}->{self};
	my $el = $infdata->getElementsByTagNameNS($mes->ns('contact'),
		'authInfo');
	while (my $ai = $el->shift())
	{
		$s->auth({pw => $ai->getFirstChild()->getData()})
			if (defined($ai) && defined($ai->getFirstChild()) &&
				$ai->getFirstChild()->nodeType() == 3);
	}
        return;
}

############ Transform commands

sub build_authinfo
{
	my $contact = shift;
	my $az = $contact->auth();
	return () unless ($az && ref($az) && exists($az->{pw}));
	return ['contact:authInfo', $az->{pw}];
}

sub build_disclose
{
	my $contact = shift;
	my $d=$contact->disclose();
	return () unless ($d && ref($d));
	my %v=map { $_ => 1 } values(%$d);
	return () unless (keys(%v)==1); ## 1 or 0 as values, not both at same time

	my @d;
	push(@d, ['contact:name']) if (exists($d->{name}));
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

	@tmp = $contact->name();
	if (defined($tmp[0])) { push(@post, ['contact:name', $tmp[0]]); }

	@tmp = $contact->org();
	if (defined($tmp[0])) { push(@post, ['contact:org', $tmp[0]]); }

	@tmp = $contact->street();
	if (defined($tmp[0])) { foreach (@{$tmp[0]}) {
		push(@addr, ['contact:street', $_]);
	} }

	@tmp = $contact->city();
	if (defined($tmp[0])) { push(@addr, ['contact:city', $tmp[0]]); }

	@tmp = $contact->sp();
	if (defined($tmp[0])) { push(@addr, ['contact:sp', $tmp[0]]); }

	@tmp = $contact->pc();
	if (defined($tmp[0])) { push(@addr, ['contact:pc', $tmp[0]]); }

	@tmp = $contact->cc();
	if (defined($tmp[0])) { push(@addr, ['contact:cc', $tmp[0]]); }

	push(@post, ['contact:addr', @addr]) if (@addr);
	push(@d, ['contact:postalInfo', @post]);
	push(@d, Net::DRI::Protocol::EPP::Util::build_tel('contact:voice', $contact->voice()))
		if (defined($contact->voice()));
	push(@d, Net::DRI::Protocol::EPP::Util::build_tel('contact:fax', $contact->fax()))
		if (defined($contact->fax()));
	push(@d, ['contact:email', $contact->email()])
		if (defined($contact->email()));
	push(@d, build_authinfo($contact));
	push(@d, build_disclose($contact));

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
