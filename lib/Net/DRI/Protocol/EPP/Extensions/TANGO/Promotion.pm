## Domain Registry Interface, CoreNIC EPP Promotion Extension
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::TANGO::Promotion;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use DateTime::Format::Strptime;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TANGO::Promotion - Promotion Extension for Tango-RS and Corenic

=head1 DESCRIPTION

Adds the Promotion Extension (http://xmlns.xmlns.tango-rs.net/epp/promotion-1.0) to domain commands. 
The extension is built by adding an additional hash with following data to the create and update commands. 

=item code [promotional code]

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands {
	my ($class,$version)=@_;
	my %tmp=(
		create => [ \&create, undef ],
		renew => [ \&renew, undef ],
	); # domain commands
	my %tmp1=(
		info => [ \&promo_info, \&promo_info_parse ],
	); # promotion commands
	return { 'domain' => \%tmp,
			 'promo' => \%tmp1
	};
}

####################################################################################################

sub build_promo_extension {
	my ($pr) = shift;
	my @o;
	
	# validate promotional code
	&validate_promo_code($pr);
		
	# push promotion to extension.
	push @o, [ 'promo:code', $pr ] if (defined($pr));
	return @o;
}

sub build_promo_command {
	my ($msg,$command,$promo,$codeattr)=@_;
	my @d;
	
	# validate promotional code
	Net::DRI::Exception->die(1,'protocol/EPP',2,'Promotional code is mandatory') unless $promo;
	&validate_promo_code($promo);
	
	# build promo code xml
	my $tcommand=ref $command ? $command->[0] : $command;
	$msg->command([$command,'promo:'.$tcommand,sprintf('xmlns:promo="%s"',$msg->nsattrs('promo_info'))]);
	push @d, ['promo:code',$promo,$codeattr];
	
	return @d;
}

sub validate_promo_details {
	my ($cdata) = shift;

	# get hash data into variables
	my $cn_name=$cdata->{domain}->{name} if Net::DRI::Util::has_key($cdata,'domain');	
	my $cn_price_type=$cdata->{price}->{type} if Net::DRI::Util::has_key($cdata,'price');
	my $cn_duration=$cdata->{price}->{duration} if Net::DRI::Util::has_key($cdata,'price');
	my $cn_refdate=$cdata->{ref_date}->{rdate} if Net::DRI::Util::has_key($cdata,'ref_date');
	my $cn_phase=$cdata->{lp}->{phase} if Net::DRI::Util::has_key($cdata,'lp');
	my $cn_custom_phase=$cdata->{lp}->{sub_phase} if Net::DRI::Util::has_key($cdata,'lp');

	# domain name element validation
	&validate_key_exists($cdata,$cn_name,'domain','name');	
	&validate_key_length($cn_name,'1','255','name');
	
	# promo pricing element validation
	&validate_key_exists($cdata,$cn_price_type,'price','type');
	
		# promo pricing data  validation
		if (Net::DRI::Util::has_key($cdata,'price')) {
			# 'cn_price_type' validation
			Net::DRI::Exception::usererr_invalid_parameters('the [type] attribute can only accept values: create | renew') 
				unless ($cn_price_type =~ m/(^create$|^renew$)/);
			# 'cn_duration' validation
			Net::DRI::Exception::usererr_invalid_parameters('the total duration in months must be between 1 and 99.') 
				if !($cn_duration->in_units('months') >= 1 && $cn_duration->in_units('months') <= 99 );
		}

	# promo refdate element validation
	&validate_key_exists($cdata,$cn_refdate,'ref_date','rdate');
	Net::DRI::Util::check_isa($cn_refdate,'DateTime') if Net::DRI::Util::has_key($cdata,'ref_date'); # must be DateTime object.
	
	# promo phase element validation
	&validate_key_exists($cdata,$cn_phase,'lp','phase');
	
		if (Net::DRI::Util::has_key($cdata,'lp')) {
			# 'cn_phase' validation
			Net::DRI::Exception::usererr_invalid_parameters('the [phase] attribute can only accept values: sunrise | landrush | claims | open | custom') 
				unless ($cn_phase =~ m/(^sunrise$|^landrush$|^claims$|^open$|^custom$)/);
			&validate_key_exists($cdata,$cn_custom_phase,'lp','sub_phase') 
			if ($cn_phase =~ m/(^custom$)/); # key only required if 'cn_phase' is 'custom'
		}
		
	return;
}

sub validate_promo_code {
	my ($prcde) = shift;
	# character limit between 1-20.
	Net::DRI::Exception::usererr_invalid_parameters('promotion code can only be between 1-20 characters.') 
		unless ($prcde =~ m/^.{1,20}$/);
	return;
}

sub validate_key_exists {
	my ($cddata,$child,$parent,$name)=@_;
	Net::DRI::Exception::usererr_insufficient_parameters("the [$name] attribute is missing while [$parent] parent element is present") 
		if ( (Net::DRI::Util::has_key($cddata,$parent)) && ((!defined($child)) || ($child eq '')) ); # must be populated if parent key present.
	return;
}

sub validate_key_length {
	my ($value,$min,$max,$name)=@_;
	return unless $value;
	my $regexp = qr/^.{$min,$max}$/;
	Net::DRI::Exception::usererr_invalid_parameters("the [$name] attribute must be between $min and $max characters") 
		unless ($value =~ $regexp);
	return;
}

####################################################################################################

sub create {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	return unless Net::DRI::Util::has_key($rd,'promo_code'); # make sure the key exists
	
	# modify command body namespace
	$mes->command(['create','domain:create',sprintf('xmlns="%s"',$mes->nsattrs('domain'))]);
	
	# build promo extension
	my @m = build_promo_extension($rd->{'promo_code'});
	return unless @m;
	
	# push extension element into command
	my $eid=$mes->command_extension_register('promo:create',sprintf('xmlns:promo="%s"',$mes->nsattrs('promo')));
	$mes->command_extension($eid,\@m);
	
	return;
}

sub renew {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	return unless $rd->{'promo_code'};
	
	# modify command body namespace
	$mes->command(['update','domain:renew',sprintf('xmlns="%s"',$mes->nsattrs('domain'))]);
	
	# build promo extension
	my @p = build_promo_extension($rd->{'promo_code'});
	return unless @p;
	
	# push extension element into command
	my $eid=$mes->command_extension_register('promo:renew',sprintf('xmlns:promo="%s"',$mes->nsattrs('promo')));
	$mes->command_extension($eid,\@p);

	return;
}

sub promo_info {
	my ($epp,$promo_c,$rd)=@_;
	my $mes=$epp->message();
	my (@g);
	our $tmp_promo_c = $promo_c; # since they don't return it in the info code, we need to sort of "know it"
	
	# build mandatory xml elements
	my $prom_info = $rd->{'promo_data'};
	@g=build_promo_command($mes,['info'],$promo_c);
	($mes->command_body(\@g) && return) unless $prom_info;

	# validate 'promo_data'
	&validate_promo_details($prom_info);

	# get DateTime total time in 'months'
	my $duration = $prom_info->{price}->{duration};
	my $total_months = $duration->in_units('months');

	# build optional xml elements
	push @g,['promo:domain',['promo:name',$prom_info->{domain}->{name}]] if Net::DRI::Util::has_key($prom_info,'domain'); # domain element
		if (($prom_info->{price}->{type} eq 'create') && (Net::DRI::Util::has_key($prom_info,'price'))) {
			push @g,['promo:pricing',['promo:create',['promo:period',{unit=>'m'},$total_months]]];
		} elsif (($prom_info->{price}->{type} eq 'renew') && (Net::DRI::Util::has_key($prom_info,'price'))) {
			push @g,['promo:pricing',['promo:renew',['promo:period',{unit=>'m'},$total_months]]];
		} # period element
	push @g,['promo:refdate',$prom_info->{ref_date}->{rdate}->strftime('%FT%T.0Z')] if Net::DRI::Util::has_key($prom_info,'ref_date'); # rdate element
		if ($prom_info->{lp}->{phase} eq 'custom') {
			push @g,['promo:phase',{name=>$prom_info->{lp}->{sub_phase}},$prom_info->{lp}->{phase}] if Net::DRI::Util::has_key($prom_info,'lp'); # phase element
		} else {
			push @g,['promo:phase',$prom_info->{lp}->{phase}] if Net::DRI::Util::has_key($prom_info,'lp');
		} # phase element
	
	# construct xml command
	$mes->command_body(\@g);
	
	return;
}

sub promo_info_parse {
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
	my $mes=$po->message();
	return unless $mes->is_success();
	
	my $msg = {};
	my ($proData,$priData,$utiData,$c);
	our $tmp_promo_c;
	
	my $infdata=$mes->get_response('promo_info_r','infData');
 	return unless defined $infdata;

    $otype='promo';
    $oaction='info';
    $oname = $tmp_promo_c; # normally this should be the id of the object you are looking up, but they don't seem to return it

 	# separate the promo,utilization and pricing section
 	foreach my $el (Net::DRI::Util::xml_list_children($infdata)) {
		my ($name,$c)=@$el;		
			if ($name eq 'promo') {
				$proData=$c;
			} elsif ($name eq 'pricing') {
				$priData=$c;
			}
		foreach my $el (Net::DRI::Util::xml_list_children($proData)) {
			my ($name,$c)=@$el;		
				if ($name eq 'utilization') {
					$utiData=$c;
				}
		}
	} 	
 	
 	# parse promo section ($proData)
	$c=$proData->getFirstChild();
	while($c) {
		next unless ($c->nodeType() == 1); # element nodes ONLY
		my $name=$c->localname() || $c->nodeName();
		next unless $name || $c->getFirstChild();
		if ($name=~m/^(promotionName)$/) {
			$name=Net::DRI::Util::remcam($name);
			$msg->{$oname}->{$name}=$c->getFirstChild()->getData() if (defined $c);
		} elsif($name=~m/^(validity)$/) {
			$msg->{$oname}->{$name}->{valid_from} = $po->parse_iso8601($c->getAttribute('from')) if $c->hasAttribute('from');
			$msg->{$oname}->{$name}->{valid_until} = $po->parse_iso8601($c->getAttribute('to')) if $c->hasAttribute('to');
		} elsif($name=~m/^(utilization)$/) {
			$msg->{$oname}->{$name}->{available} = $c->getAttribute('avail') if $c->hasAttribute('avail');
		}
	} continue { $c=$c->getNextSibling(); }
 	
 	# parse price section ($priData)
 	$c=$priData->getFirstChild();
	while($c) {
		next unless ($c->nodeType() == 1); # element nodes ONLY
		my $name=$c->localname() || $c->nodeName();
		next unless $name || $c->getFirstChild();
		if ($name=~m/^(total)$/) {
			$msg->{$oname}->{$name}->{price} = $c->getAttribute('value') if $c->hasAttribute('value');
			$msg->{$oname}->{$name}->{currency} = $c->getAttribute('mu') if $c->hasAttribute('mu');
		}
	} continue { $c=$c->getNextSibling(); }

 	# parse utilization section ($utiData)
 	$c=$utiData->getFirstChild();
	while($c) {
		next unless ($c->nodeType() == 1); # element nodes ONLY
		my $name=$c->localname() || $c->nodeName();
		next unless $name || $c->getFirstChild();
		if ($name=~m/^(enabled|operations|codeUsable|inValidityPeriod|validDomainName)$/) {
			$name=Net::DRI::Util::remcam($name);
			$msg->{$oname}->{utilization}->{$name}=$c->getFirstChild()->getData() if (defined $c);
		}
	} continue { $c=$c->getNextSibling(); }
	
	$rinfo->{$otype}=$msg;
	
	return;
}

####################################################################################################
1;
