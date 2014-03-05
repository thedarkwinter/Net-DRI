## Domain Registry Interface, .PRO domain extensions
##
## Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##           (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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

package Net::DRI::Protocol::EPP::Extensions::PRO::Domain;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PRO::Domain - .PRO EPP domain extensions for Net::DRI

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

Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
          (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           create =>		[ \&add_pro_extinfo ],
           update =>		[ \&add_pro_extinfo ],
	   info =>		[ undef, \&parse ]
         );

 return { 'domain' => \%tmp };
}

####################################################################################################
############ Transform commands

sub add_pro_extinfo
{
 my ($epp, $domain, $rd) = @_;
 my $mes = $epp->message();
 my @prodata;
 my @tmdata;
 my $pw;

 $rd = +{ pro => $rd->set('pro') } if Net::DRI::Util::isa_changes($rd);
 return unless (Net::DRI::Util::has_key($rd,'pro') && (ref($rd->{pro}) eq 'HASH'));
 my $ph = $rd->{pro};

 push(@prodata, ['rpro:tradeMarkName', $ph->{tmname}])
	if (exists($ph->{tmname}));
 push(@prodata, ['rpro:tradeMarkJurisdiction', $ph->{tmjurisdiction}])
	if (exists($ph->{tmjurisdiction}));
 push(@prodata, ['rpro:tradeMarkDate', $ph->{tmdate}->strftime('%Y-%m-%dT%H:%M:%S.%1NZ')])
	if (exists($ph->{tmdate}) && Net::DRI::Util::is_class($ph->{tmdate}, 'DateTime'));
 push(@prodata, ['rpro:tradeMarkNumber', int($ph->{tmnumber})])
	if (exists($ph->{tmnumber}) && int($ph->{tmnumber}));

 push(@prodata, ['rpro:registrationType', (exists($ph->{activate}) &&
	$ph->{activate} ? +{ activate => 'y' } : +{}), $ph->{type}])
	if (exists($ph->{type}));
 push(@prodata, ['rpro:redirectTarget', $ph->{redirect}])
	if (exists($ph->{redirect}) &&
		Net::DRI::Util::is_hostname($ph->{redirect}));
 push(@prodata, ['rpro:tradeMark', @tmdata]) if (@tmdata);

 if (Net::DRI::Util::has_auth($ph) && exists($ph->{auth}->{pw}))
 {
  $pw = $ph->{auth}->{pw};
  delete($ph->{auth}->{pw});
 }

 push(@prodata, ['rpro:authorization', $ph->{auth}, $pw])
	if (exists($ph->{auth}));
 return unless (@prodata);

 my $eid = $mes->command_extension_register('rpro:proDomain',sprintf('xmlns:rpro="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('rpro')));
 $mes->command_extension($eid, [@prodata]);
 return;
}

sub parse
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes = $po->message();
 my $infdata = $mes->get_extension('rpro','proDomain');
 my $pro = {};
 my $c;

 return unless ($infdata);

 $c = $infdata->getFirstChild();

 while (defined($c) && $c)
 {
	my $name = $c->localname() || $c->nodeName();
	next unless $name;

	if ($name eq 'registrationType')
	{
		$pro->{type} = $c->getFirstChild()->getData();
	}
	elsif ($name eq 'redirectTarget')
	{
		$pro->{redirect} = $c->getFirstChild()->getData();
	}
	elsif ($name eq 'tradeMark')
	{
		my $to = $c->getFirstChild();

		while (defined($to) && $to)
		{
			my $totag = $to->localname() || $to->nodeName();
			next unless ($totag);

			if ($totag eq 'tradeMarkName')
			{
				$pro->{tmname} =
					$to->getFirstChild()->getData();
			}
			elsif ($totag eq 'tradeMarkJurisdiction')
			{
				$pro->{tmjurisdiction} =
					$to->getFirstChild()->getData();
			}
			elsif ($totag eq 'tradeMarkDate')
			{
				$pro->{tmdate} = $po->parse_iso8601(
					$to->getFirstChild()->getData());
			}
			elsif ($totag eq 'tradeMarkNumber')
			{
				$pro->{tmnumber} = int($to->getFirstChild()->
					getData());
			}
		} continue { $to=$to->getNextSibling(); }
	}
 } continue { $c=$c->getNextSibling(); }

 $rinfo->{$otype}->{$oname}->{pro} = $pro;
 return;
}

####################################################################################################
1;
