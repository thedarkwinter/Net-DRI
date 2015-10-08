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
use utf8;

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
	);
	my %tmp1=(
		info => [ \&promo_info, \&promo_info_parse ],
	);
	return { 'domain' => \%tmp,
			 'promo' => \%tmp1
	};
}

####################################################################################################

sub build_promo {
	my ($pr) = shift;
	my @o;
	
	# validate promotional code
	&validate_promo_code($pr);
		
	# push promotion to extension.
	push @o, [ 'promo:code', $pr ] if (defined($pr));
	return @o;
}

sub promo_build_command {
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
	my $cn_name=$cdata->{dom_name}->{name} if Net::DRI::Util::has_key($cdata,'dom_name');	
	my $cn_price_type=$cdata->{dom_pric}->{type} if Net::DRI::Util::has_key($cdata,'dom_pric');
	my $cn_price_period=$cdata->{dom_pric}->{period} if Net::DRI::Util::has_key($cdata,'dom_pric');
	my $cn_price_unit=$cdata->{dom_pric}->{period_unit} if Net::DRI::Util::has_key($cdata,'dom_pric');
	my $cn_refdate=$cdata->{dom_refd}->{rdate} if Net::DRI::Util::has_key($cdata,'dom_refd');
	my $cn_phrase=$cdata->{dom_phra}->{phrase} if Net::DRI::Util::has_key($cdata,'dom_phra');
	my $cn_custom_phrase=$cdata->{dom_phra}->{custom_phrase} if Net::DRI::Util::has_key($cdata,'dom_phra');

	# domain name element validation
	&check_exist_key($cdata,$cn_name,'dom_name','name');	
	&check_key_length($cn_name,'1','255','name');
	
	# promo pricing element validation
	&check_exist_key($cdata,$cn_price_type,'dom_pric','type');
	&check_exist_key($cdata,$cn_price_period,'dom_pric','period');
	&check_exist_key($cdata,$cn_price_unit,'dom_pric','period_unit');
	
		if (Net::DRI::Util::has_key($cdata,'dom_pric')) {
			# 'cn_price_type' validation
			Net::DRI::Exception::usererr_invalid_parameters('the [type] attribute can only accept values: create | renew') 
				unless ($cn_price_type =~ m/(^create$|^renew$)/);
			# 'cn_price_period' validation
			Net::DRI::Exception::usererr_invalid_parameters('the [period] attribute value must be between 1 and 99') 
				if !($cn_price_period >= 1 && $cn_price_period <= 99 );
			# 'cn_price_unit' validation
			Net::DRI::Exception::usererr_invalid_parameters('the [period_unit] attribute can only accept values: y (year) | m (month)') 
				unless ($cn_price_unit =~ m/(^y$|^m$)/);		
		}

	# promo refdate element validation
	&check_exist_key($cdata,$cn_refdate,'dom_refd','rdate');
	Net::DRI::Util::check_isa($cn_refdate,'DateTime') if Net::DRI::Util::has_key($cdata,'dom_refd'); # must be DateTime object.
	
	# promo phrase element validation
	&check_exist_key($cdata,$cn_phrase,'dom_phra','phrase');
	
		if (Net::DRI::Util::has_key($cdata,'dom_phra')) {
			# 'cn_phrase' validation
			Net::DRI::Exception::usererr_invalid_parameters('the [phrase] attribute can only accept values: sunrise | landrush | claims | open | custom') 
				unless ($cn_phrase =~ m/(^sunrise$|^landrush$|^claims$|^open$|^custom$)/);
			&check_exist_key($cdata,$cn_custom_phrase,'dom_phra','custom_phrase') 
			if ($cn_phrase =~ m/(^custom$)/); # key only required if 'cn_phrase' is 'custom'
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

sub check_exist_key {
	my ($cddata,$child,$parent,$name)=@_;
	Net::DRI::Exception::usererr_insufficient_parameters("the [$name] attribute is missing while [$parent] parent element is present") 
		if ( (Net::DRI::Util::has_key($cddata,$parent)) && ((!defined($child)) || ($child eq '')) ); # must be populated if parent key present.
	return;
}

sub check_key_length {
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
	my @m = build_promo($rd->{'promo_code'});
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
	my @p = build_promo($rd->{'promo_code'});
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
	
	# build mandatory xml elements
	my $prom_info = $rd->{'promo_data'};
	@g=promo_build_command($mes,['info'],$promo_c);
	($mes->command_body(\@g) && return) unless $prom_info;

	# validate 'promo_data'
	&validate_promo_details($prom_info);

	# build optional xml elements
	push @g,['promo:domain',['promo:name',$prom_info->{dom_name}->{name}]] if Net::DRI::Util::has_key($prom_info,'dom_name'); # domain element
		if (($prom_info->{dom_pric}->{type} eq 'create') && (Net::DRI::Util::has_key($prom_info,'dom_pric'))) {
			push @g,['promo:pricing',['promo:create',['promo:period',{unit=>$prom_info->{dom_pric}->{period_unit}},$prom_info->{dom_pric}->{period}]]];
		} elsif (($prom_info->{dom_pric}->{type} eq 'renew') && (Net::DRI::Util::has_key($prom_info,'dom_pric'))) {
			push @g,['promo:pricing',['promo:renew',['promo:period',{name=>$prom_info->{dom_pric}->{period_unit}},$prom_info->{dom_pric}->{period}]]];
		} # period element
	push @g,['promo:refdate',$prom_info->{dom_refd}->{rdate}->strftime('%FT%T.0Z')] if Net::DRI::Util::has_key($prom_info,'dom_refd'); # rdate element
		if ($prom_info->{dom_phra}->{phrase} eq 'custom') {
			push @g,['promo:phase',{name=>$prom_info->{dom_phra}->{custom_phrase}},$prom_info->{dom_phra}->{phrase}] if Net::DRI::Util::has_key($prom_info,'dom_phra'); # phrase element
		} else {
			push @g,['promo:phase',$prom_info->{dom_phra}->{phrase}] if Net::DRI::Util::has_key($prom_info,'dom_phra');
		} # phrase element
	
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
	
	my $infdata=$mes->get_response('promo_info_r','infData');
 	return unless defined $infdata;
 	 
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
			$msg->{$oname}->{$name}=$c->getFirstChild()->getData() if (defined $c);
		} elsif($name=~m/^(validity)$/) {
			$msg->{$oname}->{$name}->{validFrom} = $c->getAttribute('from') if $c->hasAttribute('from');
			$msg->{$oname}->{$name}->{validUntil} = $c->getAttribute('to') if $c->hasAttribute('to');
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
			$msg->{$oname}->{utilization}->{$name}=$c->getFirstChild()->getData() if (defined $c);
		}
	} continue { $c=$c->getNextSibling(); }
	
	$rinfo->{$otype}=$msg;
	
	return;
}

####################################################################################################
1;
