## Domain Registry Interface, .PRO A/V extensions
##
## Copyright (c) 2008,2009,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::PRO::AV;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use DateTime::Format::ISO8601;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PRO::AV - .PRO EPP A/V extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> and
E<lt>http://oss.bdsprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard E<lt>tonnerre.lombard@sygroup.chE<gt>,
Alexander Biehl, E<lt>info@hexonet.netE<gt>, HEXONET Support GmbH,
E<lt>http://www.hexonet.net/E<gt>.

=head1 COPYRIGHT

Copyright (c) 2008,2009,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
	my %avcmds = (
		create =>	[ \&create, \&create_parse ],
		check =>	[ \&check, \&check_parse ],
		info =>		[ \&info, \&info_parse ],
	);

	return { 'av' => \%avcmds };
}

####################################################################################################
############ Query commands

sub build_command
{
	my ($msg, $command, $domain, $domainattr) = @_;
	my @dom = (ref($domain) ? @$domain : ($domain));

	Net::DRI::Exception->die(1, 'protocol/EPP', 2, 'Domain name needed')
		unless @dom;

	foreach my $d (@dom)
	{
		Net::DRI::Exception->die(1, 'protocol/EPP', 2,
			'Domain name needed') unless (defined($d) && $d);
		Net::DRI::Exception->die(1, 'protocol/EPP', 10,
			'Invalid domain name: ' . $d)
			unless Net::DRI::Util::is_hostname($d);
	}

	my $tcommand = (ref($command) ? $command->[0] : $command);
	$msg->command([$command, 'av:' . $tcommand,sprintf('xmlns:av="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('av'))]);
	return map { ['av:id', $_, $domainattr] } @dom;
}

sub check
{
	my ($epp, $av, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($mes, 'check', $av);
	$mes->command_body(\@d);
	return;
}

sub check_parse
{
	my ($po, $otype, $oaction, $oname, $rinfo) = @_;
	my $mes = $po->message();

	return unless ($mes->is_success());

	my $chkdata = $mes->get_response('av','chkData');
	return unless $chkdata;

	my $cd = $chkdata->getFirstChild();

	while (defined($cd) && $cd)
	{
		my $cdn;
		my $avid;
		my $c;

		next unless ($cd->nodeType() == 1); ## only for element nodes
		$cdn = $cd->localname() || $cd->nodeName();
		$c = $cd->getFirstChild();

		while (defined($c) && $c)
		{
			## only for element nodes
			next unless ($c->nodeType() == 1);
			my $n = $c->localname() || $c->nodeName();

			if ($n eq 'id')
			{
				$avid = $c->getFirstChild()->getData();
				$rinfo->{av}->{$avid}->{action} = 'check';
				$rinfo->{av}->{$avid}->{exist} =
					1 - Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
			}
			elsif ($n eq 'reason')
			{
				$rinfo->{av}->{$avid}->{exist_reason} =
					$c->getFirstChild()->getData();
			}
		} continue { $c = $c->getNextSibling(); }
	} continue { $cd = $cd->getNextSibling(); }
	return;
}

sub info
{
	my ($epp, $av, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($mes, 'info', $av);
	$mes->command_body(\@d);
	return;
}

sub info_parse
{
	my ($po, $otype, $oaction, $oname, $rinfo) = @_;
	my $mes = $po->message();
	my $ns = $mes->ns('av');
	my $infdata;
	my $avid;
	my $cd;
	my $pd;

	return unless ($mes->is_success());

	$infdata = $mes->get_response('av','infData');
	return unless $infdata;

	$cd = $infdata->getFirstChild();
	$pd = DateTime::Format::ISO8601->new();

	while (defined($cd) && $cd)
	{
		next unless ($cd->nodeType() == 1); ## only for element nodes
		my $cdn = $cd->localname() || $cd->nodeName();

		if ($cdn eq 'id')
		{
			$avid = $cd->getFirstChild()->getData();
			$rinfo->{av}->{$avid}->{id} = $avid;
			$rinfo->{av}->{$avid}->{action} = 'info';
		}
		elsif ($cdn =~ /^(?:avurl|roid|host)$/i)
		{
			$rinfo->{av}->{$avid}->{lc($cdn)} =
				$cd->getFirstChild()->getData();
		}
		elsif (lc($cdn) eq 'checktype')
		{
			$rinfo->{av}->{$avid}->{type} =
				$cd->getFirstChild()->getData();
		}
		elsif ($cdn =~ /^(?:c[lr]|up)id$/i)
		{
			$cdn = lc($cdn); $cdn =~ s/id$/ID/;
			$rinfo->{av}->{$avid}->{$cdn} =
				$cd->getFirstChild()->getData();
		}
		elsif ($cdn =~ /^(?:c[lr]|up)date$/i)
		{
			$cdn = lc($cdn); $cdn =~ s/date$/Date/;
			$rinfo->{av}->{$avid}->{$cdn} = $pd->parse_datetime(
				$cd->getFirstChild()->getData());
		}
		elsif (lc($cdn) eq 'contactid')
		{
			my $c = $po->create_local_object('contact');
			$c->srid($cd->getFirstChild()->getData());
			$rinfo->{av}->{$avid}->{contact} = $c;
		}
		elsif (lc($cdn) eq 'avresult')
		{
			my $res = +{};
			my $c = $cd->getFirstChild();

			while (defined($c) && $c)
			{
				## only for element nodes
				next unless ($c->nodeType() == 1);
				my $name = $c->localname() || $c->nodeName();
				next unless ($name);

				if (lc($name) eq 'avcheckid')
				{
					$res->{checkid} =
						$c->getFirstChild()->getData();
				}
				elsif (lc($name) eq 'personalavdatafingerprint')
				{
					$res->{persfingerprint} =
						$c->getFirstChild()->getData();
				}
				elsif (lc($name) eq 'professionalavdatafingerprint')
				{
					$res->{proffingerprint} =
						$c->getFirstChild()->getData();
				}
				elsif (lc($name) eq 'professionalavdatafingerprint')
				{
					$res->{proffingerprint} =
						$c->getFirstChild()->getData();
				}
				elsif ($name =~ /^(?:oobmethodid|profession|jurisdiction|status)$/i)
				{
					$res->{lc($name)} =
						$c->getFirstChild()->getData();
				}
				elsif (lc($name) eq 'resultdata')
				{
					my $inf = $c->getElementsByTagNameNS($ns, 'result');
					$res->{avresult} = $inf->shift()->getFirstChild()->getData() if ($inf);
					$inf = $c->getElementsByTagNameNS($ns, 'date');
					$res->{avDate} = $pd->parse_datetime($inf->shift()->getFirstChild()->getData()) if ($inf);
				}
			} continue { $c = $c->getNextSibling(); }

			$rinfo->{av}->{$avid}->{avresult} = $res;
		}
	} continue { $cd = $cd->getNextSibling(); }
	return;
}

####################################################################################################
############ Transform commands

sub create
{
	my ($epp, $av, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($mes, 'create', $av);

	push(@d, ['av:checkType', $rd->{type}]) if Net::DRI::Util::has_key($rd, 'type');
	push(@d, ['av:host', $rd->{host}]) if Net::DRI::Util::has_key($rd, 'host');
	push(@d, ['av:contact', ['av:contactId', $rd->{contact}->srid()]]) if (Net::DRI::Util::has_key($rd,'contact') && Net::DRI::Util::isa_contact($rd->{contact}));

	$mes->command_body(\@d);
	return;
}

sub create_parse
{
	my ($po, $otype, $oaction, $oname, $rinfo) = @_;
	my $mes = $po->message();
	my $avid;

	return unless ($mes->is_success());

	my $credata = $mes->get_response('av','creData');
	return unless $credata;

	my $cd = $credata->getFirstChild();
	my $pd = DateTime::Format::ISO8601->new();

	while (defined($cd) && $cd)
	{
		next unless ($cd->nodeType() == 1); ## only for element nodes
		my $cdn = $cd->localname() || $cd->nodeName();

		if ($cdn eq 'id')
		{
			$avid = $cd->getFirstChild()->getData();
			$rinfo->{av}->{$avid}->{id} = $avid;
			$rinfo->{av}->{$avid}->{action} = 'create';
		}
		elsif ($cdn =~ /^(avurl|roid)$/i)
		{
			$rinfo->{av}->{$avid}->{lc($cdn)} =
				$cd->getFirstChild()->getData();
		}
		elsif (lc($cdn) eq 'crdate')
		{
			$rinfo->{av}->{$avid}->{crDate} = $pd->parse_datetime(
				$cd->getFirstChild()->getData());
		}
	} continue { $cd = $cd->getNextSibling(); }
	return;
}

####################################################################################################
1;
