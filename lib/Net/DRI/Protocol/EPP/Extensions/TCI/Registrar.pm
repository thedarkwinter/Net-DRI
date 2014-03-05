## Domain Registry Interface, .RU/.SU/.XN--P1AI EPP REgistrar Extension for Net::DRI
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

package Net::DRI::Protocol::EPP::Extensions::TCI::Registrar;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use DateTime::Format::ISO8601;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( 
 					update => [ \&update, ],
          info   => [ \&info, \&info_parse ],
         );

 return { 'registrar' => \%tmp };
}

####################################################################################################

sub update
{
	my ($epp,$registrar,$todo)=@_;
	my $mes=$epp->message();

	Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

	my $ip_add=$todo->add('ip');
	my $ip_del=$todo->del('ip');

	my $email_add=$todo->add('email');
	my $email_del=$todo->del('email');

	my @d;
	push @d, ['registrar:id', $registrar];
	my (@add,@del);
	if ($email_add)
	{
		for my $key (keys %$email_add)
		{
			my @emails = @{$email_add->{$key}};

			for my $email (@emails)
			{
				push @add, ['registrar:email', $email, {"type" => $key}];
			}
		}
	}
	if ($ip_add)
	{
		for my $ip (@$ip_add)
		{
			push @add, ['registrar:addr', $ip, {"ip" => "v4"}];
		}
	}

	if ($email_del)
	{
		for my $key (keys %$email_del)
		{
			my @emails = @{$email_add->{$key}};

			for my $email (@emails)
			{
				push @del, ['registrar:email', $email, {"type" => $key}];
			}
		}
	}

	if ($ip_del)
	{
		for my $ip (@$ip_del)
		{
			push @del, ['registrar:addr', $ip, {"ip" => "v4"}];
		}
	}

	$mes->command(
			['update','registrar:update',sprintf('xmlns:registrar="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('registrar')),]
			);
	push @d,['registrar:add',@add] if @add;
	push @d,['registrar:rem',@del] if @del;

	my @chg;
	my $chg =  $todo->set('voice');
	for my $str (@$chg)
	{
	 push @chg,['registrar:voice',$str];
	}
	
	$chg =  $todo->set('fax');
	for my $str (@$chg)
	{
	 push @chg,['registrar:fax',$str];
	}

	$chg=$todo->set('www');
	push @chg,['registrar:www',$chg] if $chg;
	
	$chg =  $todo->set('whois');
	push @chg,['registrar:whois',$chg] if $chg;

	push @d,['registrar:chg',@chg] if @chg;

	$mes->command_body(\@d);
	return;
}

sub info
{
 my ($epp,$registrar,$rd)=@_;

 my $mes=$epp->message();

 $mes->command(
 	['info','registrar:info',sprintf('xmlns:registrar="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('registrar')),]
	);
 $mes->command_body(['registrar:id', $registrar]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response("registrar", "infData");
 return unless defined $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;

	if($name eq 'id')
	{
		$rinfo->{registrar}->{info}->{id} = $c->textContent();
	}
	elsif($name eq 'status')
	{
		$rinfo->{registrar}->{info}->{status} ||= [];
		push @{$rinfo->{registrar}->{info}->{status}}, $c->textContent();
	}
	elsif($name eq 'intPostalInfo')
	{
		$rinfo->{registrar}->{info}->{intPostalInfo} ||= [];
		push @{$rinfo->{registrar}->{info}->{intPostalInfo}}, $c->textContent();
	}
	elsif($name eq 'locPostalInfo')
	{
		$rinfo->{registrar}->{info}->{locPostalInfo} ||= [];
		push @{$rinfo->{registrar}->{info}->{locPostalInfo}}, $c->textContent();
	}
	elsif($name eq 'legalInfo')
	{
		$rinfo->{registrar}->{info}->{legalInfo} ||= [];
		push @{$rinfo->{registrar}->{info}->{legalInfo}}, $c->textContent();
	}
	elsif($name eq 'taxpayerNumbers')
	{
		$rinfo->{registrar}->{info}->{taxpayerNumbers} = $c->textContent();
	}
	elsif($name eq 'voice')
	{
		$rinfo->{registrar}->{info}->{voice} ||= [];
		push @{$rinfo->{registrar}->{info}->{voice}}, $c->textContent();
	}
	elsif($name eq 'fax')
	{
		$rinfo->{registrar}->{info}->{fax} ||= [];
		push @{$rinfo->{registrar}->{info}->{fax}}, $c->textContent();
	}
	elsif($name eq 'email')
	{
		my $email_type = $c->getAttribute( "type" );
		$rinfo->{registrar}->{info}->{email}{$email_type} ||= [];
		push @{$rinfo->{registrar}->{info}->{email}{$email_type}}, $c->textContent();
	}
	elsif($name eq 'www')
	{
		$rinfo->{registrar}->{info}->{www} = $c->textContent();
	}
	elsif($name eq 'whois')
	{
		$rinfo->{registrar}->{info}->{whois} = $c->textContent();
	}
	elsif($name eq 'addr')
	{
		$rinfo->{registrar}->{info}->{addr} ||= [];
		push @{$rinfo->{registrar}->{info}->{addr}}, $c->textContent();
	}
	elsif($name eq 'crDate')
	{
		$rinfo->{registrar}->{info}->{crDate} = DateTime::Format::ISO8601->new()->parse_datetime($c->textContent());
	}
	elsif($name eq 'upDate')
	{
		$rinfo->{registrar}->{info}->{upDate} = DateTime::Format::ISO8601->new()->parse_datetime($c->textContent());
	}
 }
 return;
}

####################################################################################################
1;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TCI::Registrar - TCI EPP Registrar Extension for Net::DRI

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
