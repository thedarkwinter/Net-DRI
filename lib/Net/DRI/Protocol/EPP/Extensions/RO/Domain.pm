## Domain Registry Interface, .RO Domain EPP extension commands [https://epp2-test.rotld.ro/epp/index.html]
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI.
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::RO::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use DateTime::Format::ISO8601;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Data::Hosts;
use utf8;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::RO::Domain - .RO EPP Domain extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands {
	my ( $class, $version)=@_;
	my %tmp=(
		create =>               [ \&create, \&create_parse ],
		trade_request =>        [ \&trade_request, \&trade_request_parse ],
		trade_approve =>        [ \&trade_approve, undef ],
		trade_query =>          [ \&trade_query, \&trade_query_parse],
		transfer_request =>     [ \&transfer_request, \&transfer_parse ],
		transfer_cancel  =>     [ \&transfer_cancel, \&transfer_parse ],
		transfer_answer  =>     [ \&transfer_answer, \&transfer_parse ],
		transfer_query  =>      [ \&transfer_query, \&transfer_parse ],
		update =>               [ \&update, undef],
		renew =>                [ \&renew, \&renew_parse],
		info =>                 [ \&info, \&info_parse],
		check =>                [ \&check, \&check_parse]
	);

	return { 'domain' => \%tmp };
}

####################################################################################################

sub create {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my (@e,@f);

	$mes->command(['create','domain:create',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);
	return unless ( (defined $rd->{'reserve_domain'}) || (defined $rd->{'domain_terms'}) );

	# Domain Password Validation
	Net::DRI::Exception::usererr_insufficient_parameters('auth-pw is required for .RO')
		unless ((defined $rd->{auth}->{pw}) && ($rd->{auth}->{pw} ne ''));
	Net::DRI::Exception::usererr_invalid_parameters('auth-pw supplied must have no spaces; one capital, small & special character with length between 6-40')
		unless ($rd->{auth}->{pw}=~ m/^[a-z0-9\-\.\,\:\;\[\]\{\}\_\+\=\@\#\$\^\*\?\!\|\~]{6,40}$/i);

	push @f,['rotld:agreement',{legal_use => $rd->{'domain_terms'}->{'legal_use'}, registration_rules => $rd->{'domain_terms'}->{'reg_rules'}}];
	if ($rd->{'reserve_domain'}->{'reserve'} == 1) {push @f,['rotld:reserve'];}

	push @e,['rotld:create',['rotld:domain',@f]];
	my $eid=$mes->command_extension_register('rotld:ext',sprintf('xmlns:rotld="%s"',$mes->nsattrs('ro_domain_ext')));
	$mes->command_extension($eid,\@e);
	return;
}

sub create_parse {
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
	my $mes=$po->message();
	return unless $mes->is_success();

	my $idndata=$mes->get_extension('ro_idn_ext','mapping');
	return unless defined $idndata;

	my $ns=$mes->ns('ro_idn_ext');
	$idndata=$idndata->getChildrenByTagNameNS($ns,'name');
	return unless $idndata->size();

	my $c=$idndata->shift->getFirstChild();
	while($c) {
		next unless ($c->nodeType() == 1); # element nodes ONLY
		my $name=$c->localname() || $c->nodeName();
		next unless $name && $c->getFirstChild();
		if ($name=~m/^(ace|unicode)$/) {
			$rinfo->{domain}->{$oname}->{$name}=$c->getFirstChild()->getData() if (defined $c);
		}
	} continue { $c=$c->getNextSibling(); }
	return;
}

sub trade_request {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my (@e,@f);

	my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['trade',{'op'=>'request'}],$domain);
	$mes->command_body(\@d);
	$mes->command([['trade',{'op'=>'request'}],'domain:trade',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);

	push @f,['rotld:authorization_key', $rd->{'trade_auth_info'}->{'authorization_key'} ] if (defined $rd->{'trade_auth_info'}->{'authorization_key'});
	push @f,['rotld:c_registrant', $rd->{'trade_auth_info'}->{'c_registrant'} ] if (defined $rd->{'trade_auth_info'}->{'c_registrant'});
	push @f,['rotld:domain_password', $rd->{'trade_auth_info'}->{'domain_password'} ] if (defined $rd->{'trade_auth_info'}->{'domain_password'});
	push @e,['rotld:trade',['rotld:domain',['rotld:request',@f]]];

	my $eid=$mes->command_extension_register('rotld:ext',sprintf('xmlns:rotld="%s"',$mes->nsattrs('ro_domain_ext')));
	$mes->command_extension($eid,\@e);
	return;
}

sub trade_request_parse {
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
	my $mes=$po->message();
	return unless $mes->is_success();

	my $trddata=$mes->get_extension('ro_domain_ext','ext');
	return unless defined $trddata;

	my $ns=$mes->ns('ro_domain_ext');
	$trddata=$trddata->getChildrenByTagNameNS($ns,'trdData');
	return unless $trddata->size();
	$trddata=$trddata->shift()->getChildrenByTagNameNS($ns,'domain');
	return unless $trddata->size();
	$trddata=$trddata->shift()->getChildrenByTagNameNS($ns,'request');
	return unless $trddata->size();

	my $c=$trddata->shift->getFirstChild();
	while($c) {
		next unless ($c->nodeType() == 1); # Element Nodes ONLY!
		my $name=$c->localname() || $c->nodeName();
		next unless $name && $c->getFirstChild();
		if ($name=~m/^(tid|authorization_key)$/) {
			$rinfo->{domain}->{$oname}->{$name}=$c->getFirstChild()->getData();
		}
	} continue { $c=$c->getNextSibling(); }
	return;
}

sub trade_approve {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my (@e,@f);

	my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['trade',{'op'=>'approve'}],$domain);
	$mes->command_body(\@d);
	$mes->command([['trade',{'op'=>'approve'}],'domain:trade',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);

	return unless ((defined $rd->{'tid'}));

	push @f,['rotld:tid', $rd->{'tid'} ] if (defined $rd->{'tid'});
	push @e,['rotld:trade',['rotld:domain',['rotld:approve',@f]]];

	my $eid=$mes->command_extension_register('rotld:ext',sprintf('xmlns:rotld="%s"',$mes->nsattrs('ro_domain_ext')));
	$mes->command_extension($eid,\@e);
	return;
}

sub trade_query {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my (@e,@f);

	my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['trade',{'op'=>'query'}],$domain);
	$mes->command_body(\@d);
	$mes->command([['trade',{'op'=>'query'}],'domain:trade',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);

	return unless ((defined $rd->{'tid'}));

	push @f,['rotld:tid', $rd->{'tid'} ] if (defined $rd->{'tid'});
	push @e,['rotld:trade',['rotld:domain',['rotld:query',@f]]];

	my $eid=$mes->command_extension_register('rotld:ext',sprintf('xmlns:rotld="%s"',$mes->nsattrs('ro_domain_ext')));
	$mes->command_extension($eid,\@e);
	return;
}

sub trade_query_parse {
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
	my $mes=$po->message();
	return unless $mes->is_success();

	my $trddata=$mes->get_extension('ro_domain_ext','ext');
	return unless defined $trddata;

	my $ns=$mes->ns('ro_domain_ext');
	$trddata=$trddata->getChildrenByTagNameNS($ns,'trdData');
	return unless $trddata->size();
	$trddata=$trddata->shift()->getChildrenByTagNameNS($ns,'domain');
	return unless $trddata->size();
	$trddata=$trddata->shift()->getChildrenByTagNameNS($ns,'query');
	return unless $trddata->size();

	my $c=$trddata->shift->getFirstChild();
	while($c) {
		next unless ($c->nodeType() == 1); # element nodes ONLY
		my $name=$c->localname() || $c->nodeName();
		next unless $name && $c->getFirstChild();
		if ($name=~m/^(registry_confirm|registrar_confirm|close_date|tid)$/) {
			$rinfo->{domain}->{$oname}->{$name}=$c->getFirstChild()->getData() if (defined $c);
		}
	} continue { $c=$c->getNextSibling(); }
	return;
}

sub transfer_request {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my (@e,@f);

	my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>'request'}],$domain);
	$mes->command_body(\@d);
	$mes->command([['transfer',{'op'=>'request'}],'domain:transfer',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);

	return unless ((defined $rd->{'authorization_key'}));

	push @f,['rotld:authorization_key', $rd->{'authorization_key'} ] if (defined $rd->{'authorization_key'});
	push @e,['rotld:transfer',['rotld:domain',@f]];

	my $eid=$mes->command_extension_register('rotld:ext',sprintf('xmlns:rotld="%s"',$mes->nsattrs('ro_domain_ext')));
	$mes->command_extension($eid,\@e);
	return;
}

sub transfer_answer {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my (@e,@f,$op);

  if (Net::DRI::Util::has_key($rd,'approve') && ($rd->{approve})) {
		$op = 'approve';
	} else {
		$op = 'reject';
	}

	my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>$op}],$domain);
	$mes->command_body(\@d);
	$mes->command([['transfer',{'op'=>$op}],'domain:transfer',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);

	return unless ((defined $rd->{'authorization_key'}));

	push @f,['rotld:authorization_key', $rd->{'authorization_key'} ] if (defined $rd->{'authorization_key'});
	push @e,['rotld:transfer',['rotld:domain',@f]];

	my $eid=$mes->command_extension_register('rotld:ext',sprintf('xmlns:rotld="%s"',$mes->nsattrs('ro_domain_ext')));
	$mes->command_extension($eid,\@e);
	return;
}

sub transfer_cancel {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my (@e,@f);

	my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>'cancel'}],$domain);
	$mes->command_body(\@d);
	$mes->command([['transfer',{'op'=>'cancel'}],'domain:transfer',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);

	return unless ((defined $rd->{'authorization_key'}));

	push @f,['rotld:authorization_key', $rd->{'authorization_key'} ] if (defined $rd->{'authorization_key'});
	push @e,['rotld:transfer',['rotld:domain',@f]];

	my $eid=$mes->command_extension_register('rotld:ext',sprintf('xmlns:rotld="%s"',$mes->nsattrs('ro_domain_ext')));
	$mes->command_extension($eid,\@e);
	return;
}

sub transfer_query {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my (@e,@f);

	my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>'query'}],$domain);
	$mes->command_body(\@d);
	$mes->command([['transfer',{'op'=>'query'}],'domain:transfer',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);

	return unless ((defined $rd->{'authorization_key'}));

	push @f,['rotld:authorization_key', $rd->{'authorization_key'} ] if (defined $rd->{'authorization_key'});
	push @e,['rotld:transfer',['rotld:domain',@f]];

	my $eid=$mes->command_extension_register('rotld:ext',sprintf('xmlns:rotld="%s"',$mes->nsattrs('ro_domain_ext')));
	$mes->command_extension($eid,\@e);
	return;
}

sub transfer_parse {
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $trndata=$mes->get_response('ro_domain','trnData');
 return unless defined $trndata;

 foreach my $el (Net::DRI::Util::xml_list_children($trndata)) {
  my ($name,$c)=@$el;
  if ($name eq 'name') {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='transfer';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(trStatus|reID|acID)$/) {
   $rinfo->{domain}->{$oname}->{$1}=$c->textContent() if ($c->textContent());
  } elsif ($name=~m/^(reDate|acDate|exDate)$/) {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent()) if ($c->textContent());
  }
 }
 return;
}

sub update {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my (@e,@f);

	$mes->command(['update','domain:update',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);

	return unless ( (defined $rd->set('activate_domain')) && ($rd->set('activate_domain')=~m/^(1)$/));
	push @e,['rotld:update',['rotld:domain',['rotld:activate']]];

	my $eid=$mes->command_extension_register('rotld:ext',sprintf('xmlns:rotld="%s"',$mes->nsattrs('ro_domain_ext')));
	$mes->command_extension($eid,\@e);
	return;
}

sub renew {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	$mes->command(['renew','domain:renew',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);
	return;
}

sub renew_parse {
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rendata=$mes->get_response('ro_domain','renData');
 return unless defined $rendata;

 foreach my $el (Net::DRI::Util::xml_list_children($rendata)) {
  my ($name,$c)=@$el;
  if ($name eq 'name') {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='renew';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(exDate)$/) {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent()) if ($c->textContent());
  }
 }
 return;
}

sub info {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	$mes->command(['info','domain:info',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);
	return;
}

sub info_parse {
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response('ro_domain','infData');
 return unless defined $infdata;

 my (@s,@host);
 my $cs=$po->create_local_object('contactset');
 my %ccache;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata)) {
  my ($name,$c)=@$el;
  if ($name eq 'name') {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='info';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name eq 'roid') {
   $rinfo->{domain}->{$oname}->{roid}=$c->textContent();
  } elsif ($name eq 'status') {
   push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c);
  } elsif ($name eq 'registrant') {
   my $id=$c->textContent();
   $ccache{$id}=$po->create_local_object('contact')->srid($id) unless exists $ccache{$id};
   $cs->set($ccache{$id},'registrant');
  } elsif ($name eq 'contact') {
   my $id=$c->textContent();
   $ccache{$id}=$po->create_local_object('contact')->srid($id) unless exists $ccache{$id};
   $cs->add($ccache{$id},$c->getAttribute('type'));
  } elsif ($name eq 'ns') {
   if ($po->{hostasns} == 1) {
    $rinfo->{domain}->{$oname}->{ns} = $po->create_local_object('hosts') unless defined ($rinfo->{domain}->{$oname}->{ns});
    $rinfo->{domain}->{$oname}->{ns}->add($c->textContent());
   } else {
    $rinfo->{domain}->{$oname}->{ns}=Net::DRI::Protocol::EPP::Util::parse_ns($po,$c);
   }
  } elsif ($name eq 'host') {
   push @host,$c->textContent();
  } elsif ($name=~m/^(clID|crID|upID)$/) {
   $rinfo->{domain}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate|trDate|exDate)$/) {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent()) if ($c->textContent());
  } elsif ($name eq 'authInfo') {
   $rinfo->{domain}->{$oname}->{auth}={pw => Net::DRI::Util::xml_child_content($c,$mes->ns('domain'),'pw')};
  }
 }

 $rinfo->{domain}->{$oname}->{contact}=$cs;
 $rinfo->{domain}->{$oname}->{status}=$po->create_local_object('status')->add(@s);
 $rinfo->{domain}->{$oname}->{subordinate_hosts}=$po->create_local_object('hosts')->set(@host) if @host;

 my $idndata=$mes->get_extension('ro_idn_ext','mapping');
 return unless defined $idndata;

 my $ns=$mes->ns('ro_idn_ext');
 $idndata=$idndata->getChildrenByTagNameNS($ns,'name');
 return unless $idndata->size();

 my $c=$idndata->shift->getFirstChild();
 while($c) {
	 next unless ($c->nodeType() == 1); # element nodes ONLY
	 my $name=$c->localname() || $c->nodeName();
	 next unless $name && $c->getFirstChild();
	 if ($name=~m/^(ace|unicode)$/) {
		 $rinfo->{domain}->{$oname}->{$name}=$c->getFirstChild()->getData() if (defined $c);
	 }
 } continue { $c=$c->getNextSibling(); }

 return;
}

sub check {
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	$mes->command(['check','domain:check',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ro_domain'))]);
	return;
}

sub check_parse {
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
	my $mes=$po->message();
	return unless $mes->is_success();
	my $msg = {};

	# IDN & Domain Renew Availability Extension(s)
	my $idndata=$mes->get_extension('ro_idn_ext','mapping');
	my $trddata=$mes->get_extension('ro_domain_ext','ext');
	return unless ((defined $idndata) || (defined $trddata));

	if (defined $idndata) {
		my $ns=$mes->ns('ro_idn_ext');
		$idndata=$idndata->getChildrenByTagNameNS($ns,'name');
		if ($idndata->size()) {
			my $c=$idndata->shift->getFirstChild();
			while($c) {
				next unless ($c->nodeType() == 1); # element nodes ONLY
				my $name=$c->localname() || $c->nodeName();
				next unless $name && $c->getFirstChild();
				if ($name=~m/^(ace|unicode)$/) {
					$rinfo->{domain}->{$oname}->{$name}=$c->getFirstChild()->getData() if (defined $c);
				}
			} continue { $c=$c->getNextSibling(); }
		}
	}

	if (defined $trddata) {
		foreach my $el (Net::DRI::Util::xml_list_children($trddata)) {
			my ($name,$c)=@$el;
				if ($name eq 'check_renew_availability') {
					$msg->{renewable} = $c->getAttribute('renewable') if $c->hasAttribute('renewable');
				}
		}
		my $ns=$mes->ns('ro_domain_ext');
		$trddata=$trddata->getChildrenByTagNameNS($ns,'check_renew_availability');
		if ($trddata->size()) {
			my $c=$trddata->shift->getFirstChild();
			while($c) {
				next unless ($c->nodeType() == 1); # element nodes ONLY
				my $name=$c->localname() || $c->nodeName();
				next unless $name && $c->getFirstChild();
				if ($name=~m/^(reason|name)$/) {
					$msg->{reason} = $c->getFirstChild()->getData() if (defined $c);
				}
			} continue { $c=$c->getNextSibling(); }
			$rinfo->{domain}->{$oname}->{renew_availability} = $msg;
		}
	}
	return;
}

####################################################################################################
1;
