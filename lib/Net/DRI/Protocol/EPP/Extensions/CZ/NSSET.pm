## Domain Registry Interface, .CZ EPP NSSET extension commands
##
## Copyright (c) 2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##           (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>
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

package Net::DRI::Protocol::EPP::Extensions::CZ::NSSET;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Hosts;
use Net::DRI::Data::ContactSet;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CZ::NSSET - .CZ NSSET extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
          (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>
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
	my %tmp1 = (
		create => [ \&create ],
		check  => [ \&check, \&check_parse ],
		info   => [ \&info, \&info_parse ],
		delete => [ \&delete ],
		update => [ \&update ],
		transfer_query => [ \&transfer_query ],
		transfer_request => [ \&transfer_request ],
		transfer_cancel => [ \&transfer_cancel ],
		transfer_answer => [ \&transfer_answer ],
	);

	$tmp1{check_multi} = $tmp1{check};
 
	return { 'nsset' => \%tmp1 };
}

sub ns
{
	my ($mes) = @_;
        my $ns=$mes->ns('nsset');
        return defined($ns)? $ns : 'http://www.nic.cz/xml/epp/nsset-1.2';
}

sub build_command
{
	my ($epp, $msg, $command, $hosts) = @_;
	my $tcommand = (ref($command) eq 'ARRAY' ? $command->[0] : $command);

	my @gn;

	foreach my $h (grep { defined } (ref($hosts) eq 'ARRAY') ?
		@$hosts : ($hosts))
	{
		my $gn = Net::DRI::Util::isa_nsgroup($h) ?
			$h->name() : $h;
		Net::DRI::Exception->die(1, 'protocol/EPP', 10,
			'Invalid NSgroup name: ' . $gn)
			unless (defined($gn) && $gn && !ref($gn) && Net::DRI::Util::xml_is_normalizedstring(
				$gn, 1, 100));
		push(@gn, $gn);
	}

	Net::DRI::Exception->die(1, 'protocol/EPP', 2, 'NSgroup name needed')
		unless @gn;

        my @ns=$msg->nsattrs('nsset');
        @ns=qw(http://www.nic.cz/xml/epp/nsset-1.2 http://www.nic.cz/xml/epp/nsset-1.2 nsset-1.2.xsd) unless @ns;
	$msg->command([$command, 'nsset:' . $tcommand,
		sprintf('xmlns:nsset="%s" xsi:schemaLocation="%s %s"',@ns)]);

	return map { ['nsset:id', $_] } @gn;
}

sub add_nsname
{
	my ($ns) = @_;
	return () unless (defined($ns));
	my @a;

	if (!ref($ns))
	{
		return ['nsset:ns', ['nsset:name', $ns]];
	}
	elsif (ref($ns) eq 'ARRAY')
	{
		return ['nsset:ns', map { ['nsset:name', $_] } @$ns];
	}
	elsif (Net::DRI::Util::isa_hosts($ns))
	{
		for (my $i = 1; $i <= $ns->count(); $i++)
		{
			my ($name, $v4, $v6) = $ns->get_details($i);
			my @b;
			push(@b, ['nsset:name', $name]);
			foreach my $addr (@{$v4}, @{$v6})
			{
				push(@b, ['nsset:addr', $addr]);
			}
			push(@a, ['nsset:ns', @b]);
		}
	}

	return @a;
}

sub build_contacts
{
	my ($cs) = @_;
	return () unless (defined($cs));
	my @a;

	foreach my $type ($cs->types())
	{
		push(@a, map { ['nsset:' . $type, $_->srid()] }
			$cs->get($type));
	}

	return @a;
}

sub build_authinfo
{
	my $rauth = shift;
	return unless (defined($rauth) && ref($rauth) eq 'HASH');
	return ['nsset:authInfo', $rauth->{pw}];
}

sub build_reportlevel
{
	my $level = int(shift);
	return unless (defined($level) && $level >= 0 && $level <= 10);
	return ['nsset:reportlevel', $level];
}

####################################################################################################
########### Query commands

sub check
{
	my ($epp, @hosts)=@_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, 'check', \@hosts);

	$mes->command_body(\@d);
	return;
}

sub check_parse
{
	my ($po, $otype, $oaction, $oname, $rinfo) = @_;
	my $mes = $po->message();
	return unless $mes->is_success();

	my $ns = ns($mes);
	my $chkdata = $mes->get_response($ns,'chkData');
	return unless $chkdata;

	foreach my $cd ($chkdata->getElementsByTagNameNS($ns, 'cd'))
	{
		my $c = $cd->getFirstChild();
		my $nsset;
		while ($c)
		{
			## only for element nodes
			next unless ($c->nodeType() == 1);
			my $n = $c->localname() || $c->nodeName();
			if ($n eq 'id')
			{
				$nsset = $c->getFirstChild()->getData();
				$rinfo->{nsset}->{$nsset}->{exist} =
					1 - Net::DRI::Util::xml_parse_boolean
						($c->getAttribute('avail'));
				$rinfo->{nsset}->{$nsset}->{action} =
					'check';
			}
		} continue { $c = $c->getNextSibling(); }
	}
	return;
}

sub info
{
	my ($epp, $hosts) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, 'info', $hosts);

	$mes->command_body(\@d);
	return;
}

sub info_parse
{
	my ($po, $otype, $oaction, $oname, $rinfo) = @_;
	my $mes = $po->message();
	return unless $mes->is_success();

	my $infdata = $mes->get_response(ns($mes),'infData');
	return unless $infdata;

	my $ns = Net::DRI::Data::Hosts->new();
	my $cs = Net::DRI::Data::ContactSet->new();
        my @s;
	my $c = $infdata->getFirstChild();
	while ($c)
	{
		next unless ($c->nodeType() == 1); ## only for element nodes
		my $name = $c->localname() || $c->nodeName();
		next unless $name;
		if ($name eq 'id')
		{
			$oname = $c->getFirstChild()->getData();
                        $rinfo->{nsset}->{$oname}->{name} =
				$rinfo->{nsset}->{$oname}->{id} = $oname;
			$rinfo->{nsset}->{$oname}->{exist} = 1;
			$rinfo->{nsset}->{$oname}->{action} = 'info';
		}
		elsif ($name eq 'roid')
		{
			$rinfo->{nsset}->{$oname}->{roid} = $c->getFirstChild()
				->getData();
		}
		elsif ($name eq 'reportlevel')
		{
			$rinfo->{nsset}->{$oname}->{reportlevel} =
				int($c->getFirstChild()->getData());
		}
		elsif ($name eq 'status')
		{
			push(@s,Net::DRI::Protocol::EPP::Util::parse_node_status($c));
		}
		elsif ($name eq 'authInfo')
		{
			$rinfo->{nsset}->{$oname}->{auth} =
				{ pw => $c->getFirstChild()->getData() };
		}
		elsif ($name =~ /^((?:c[lr]|tr|up)ID)$/)
		{
			$rinfo->{nsset}->{$oname}->{$1} =
				$c->getFirstChild()->getData();
		}
		elsif ($name =~ /^((?:c[lr]|tr|up)Date)$/)
		{
			$rinfo->{nsset}->{$oname}->{$1} = $po->parse_iso8601($c->textContent());
		}
		elsif ($name eq 'ns')
		{
			my $hostname;
			my @v4;
			my @v6;
			foreach my $xname ($c->getElementsByTagNameNS(ns($mes),
				'name'))
			{
				$hostname = $xname->getFirstChild()->getData();
			}
			foreach my $xaddr ($c->getElementsByTagNameNS(ns($mes),
				'addr'))
			{
				my $xa = $xaddr->getFirstChild()->getData();
				if ($xa =~ /^\d+\.\d+\.\d+\.\d+$/)
				{
					push(@v4, $xa);
				}
				else
				{
					push(@v6, $xa);
				}
			}
			$ns->add($hostname, \@v4, \@v6);
		}
		elsif ($name =~ /^(registrant|billing|admin|tech)$/)
		{
			$cs->add($po->create_local_object('contact')->srid($c->getFirstChild()->getData()),
				$name);
		}
	} continue { $c = $c->getNextSibling(); }

	$rinfo->{nsset}->{$oname}->{self} = $ns;
	$rinfo->{nsset}->{$oname}->{contact} = $cs;
	$rinfo->{nsset}->{$oname}->{status} = $po->create_local_object('status')->add(@s);
	return;
}

sub transfer_query
{
	my ($epp, $name, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, ['transfer', {'op' => 'query'}],
		$name);
	push(@d, build_authinfo($rd->{auth})) if Net::DRI::Util::has_auth($rd);
	$mes->command_body(\@d);
	return;
}

############ Transform commands

sub create
{
	my ($epp, $name, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, 'create', $name);
	my $hosts = $rd->{ns};
	my $cs = $rd->{contact};

	push(@d, add_nsname($hosts));
	push(@d, build_contacts($cs));
	push(@d, build_authinfo($rd->{auth}));
	push(@d, build_reportlevel($rd->{reportlevel}));
	$mes->command_body(\@d);
	return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
	my ($epp, $hosts) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, 'delete', $hosts);

	$mes->command_body(\@d);
	return;
}

sub transfer_request
{
	my ($epp, $name, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, ['transfer', {'op' => 'request'}],
		$name);

	push(@d, build_authinfo($rd->{auth})) if Net::DRI::Util::has_auth($rd);
	$mes->command_body(\@d);
	return;
}

sub transfer_answer
{
	my ($epp, $name, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, ['transfer',
		{'op' => (Net::DRI::Util::has_key($rd, 'approve') && $rd->{approve} ?
			'approve' : 'reject')}], $name);

	push(@d, build_authinfo($rd->{auth})) if Net::DRI::Util::has_auth($rd);
	$mes->command_body(\@d);
	return;
}

sub transfer_cancel
{
	my ($epp, $name, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, ['transfer', {'op' => 'cancel'}],
		$name);

	push(@d, build_authinfo($rd->{auth})) if Net::DRI::Util::has_auth($rd);
	$mes->command_body(\@d);
	return;
}

sub update
{
	my ($epp, $hosts, $todo) = @_;
	my $mes = $epp->message();

	Net::DRI::Exception::usererr_invalid_parameters($todo .
		' must be a Net::DRI::Data::Changes object')
		unless Net::DRI::Util::isa_changes($todo);

	if ((grep { ! /^(?:ns|contact|auth|reportlevel)$/ } $todo->types()))
	{
		Net::DRI::Exception->die(0, 'protocol/EPP', 11,
			'Only ns/contact add/del and auth/reportlevel set ' .
			'available for nsset');
	}

	my @d = build_command($epp, $mes, 'update', $hosts);

	my $nsadd = $todo->add('ns');
	my $nsdel = $todo->del('ns');
	my $cadd = $todo->add('contact');
	my $cdel = $todo->del('contact');
	my $auth = $todo->set('auth');
	my $level = $todo->set('reportlevel');

	my (@add, @del, @set);
	push(@add, add_nsname($nsadd)) if ($nsadd && !$nsadd->is_empty());
	push(@add, build_contacts($cadd)) if ($cadd);

	push(@del, map { ['nsset:name', $_] } $nsdel->get_names())
		if ($nsdel && !$nsdel->is_empty());
	push(@del, build_contacts($cdel)) if ($cdel);

	push(@set, ['nsset:authInfo', $auth->{pw}])
		if (defined($auth) && Net::DRI::Util::has_key($auth, 'pw'));
	push(@set, build_reportlevel($level)) if (defined($level));

	push(@d, ['nsset:add', @add]) if (@add);
	push(@d, ['nsset:rem', @del]) if (@del);
	push(@d, ['nsset:chg', @set]) if (@set);

	$mes->command_body(\@d);
	return;
}

####################################################################################################
1;
