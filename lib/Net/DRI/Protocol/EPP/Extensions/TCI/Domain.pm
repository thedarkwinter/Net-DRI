## Domain Registry Interface, .RU/.SU/.XN--P1AI EPP Domain Extension for Net::DRI
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

package Net::DRI::Protocol::EPP::Extensions::TCI::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( 
 					create           => [ \&create, undef], 
					update           => [ \&update, ],
          transfer_request => [ \&transfer_request ],
          transfer_cancel  => [ \&transfer_cancel,],
          transfer_answer  => [ \&transfer_answer,],
          transfer_query   => [ \&transfer_query,],
					info             => [ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################
sub _need_fix_ns
{
	my $domain = shift;
	my @parts = split(/\./, $domain, -1);
	if (scalar @parts == 2 && ((uc($parts[-1]) eq 'RU') || (uc($parts[-1]) eq 'XN--P1AI')))
	{
		return 1;	
	}
	return 0;
}

sub transfer_query
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>'query'}],$domain);
 if (_need_fix_ns($domain))
 {
 	 $mes->{command}->[2] =~ s/1\.0/1.1/g;
 }
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
}

sub transfer_answer
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>(Net::DRI::Util::has_key($rd,'approve') && $rd->{approve})? 'approve' : 'reject'}],$domain);
 if (_need_fix_ns($domain))
 {
 	 $mes->{command}->[2] =~ s/1\.0/1.1/g;
 }
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
}

sub transfer_cancel
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>'cancel'}],$domain);
 if (_need_fix_ns($domain))
 {
 	 $mes->{command}->[2] =~ s/1\.0/1.1/g;
 }
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>'request'}],$domain);
 if (_need_fix_ns($domain))
 {
 	 $mes->{command}->[2] =~ s/1\.0/1.1/g;
	 push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);
	 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
	 $mes->command_body(\@d);
 }
 else 
 {
 push @d,["domain:acID", $rd->{acID}];
 $mes->command_body(\@d);
 }
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'create',$domain);

 my $def=$epp->default_parameters();
 if ($def && (ref($def) eq 'HASH') && exists($def->{domain_create}) && (ref($def->{domain_create}) eq 'HASH'))
 {
  $rd={} unless ($rd && ref $rd eq 'HASH' && keys %$rd);
  while(my ($k,$v)=each(%{$def->{domain_create}}))
  {
   next if exists($rd->{$k});
   $rd->{$k}=$v;
  }
 }

 ## Period, OPTIONAL
 push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);

 ## Nameservers, OPTIONAL
 push @d,Net::DRI::Protocol::EPP::Util::build_ns($epp,$rd->{ns},$domain) if Net::DRI::Util::has_ns($rd);

 ## Contacts, all OPTIONAL
 if (Net::DRI::Util::has_contact($rd))
 {
  my $cs=$rd->{contact};
  my @o=$cs->get('registrant');
  push @d,['domain:registrant',$o[0]->srid()] if (@o && Net::DRI::Util::isa_contact($o[0]));
  push @d,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cs);
 }
 elsif ($rd->{registrant})
 {
  push @d,['domain:registrant',$rd->{registrant}];
 }

 if ($rd->{description})
 {
	for my $str (@{$rd->{description}})
	{
		push @d, ['domain:description', $str];
	}
 }

 if (_need_fix_ns($domain))
 {
  push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 }
 $mes->command_body(\@d);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 my $nsadd=$todo->add('ns');
 my $nsdel=$todo->del('ns');
 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 my $cadd=$todo->add('contact');
 my $cdel=$todo->del('contact');

 my (@add,@del);
 push @add,Net::DRI::Protocol::EPP::Util::build_ns($epp,$nsadd,$domain)         if Net::DRI::Util::isa_hosts($nsadd);
 push @add,$sadd->build_xml('domain:status','')                                 if $sadd;
 push @add,$sadd->build_xml('domain:status','core')                             if $sadd;
 push @del,Net::DRI::Protocol::EPP::Util::build_ns($epp,$nsdel,$domain,undef,1) if Net::DRI::Util::isa_hosts($nsdel);
 push @del,$sdel->build_xml('domain:status','')                                 if $sdel;
 push @del,$sdel->build_xml('domain:status','core')                             if $sdel;
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'update',$domain);
 push @d,['domain:add',@add] if @add;
 push @d,['domain:rem',@del] if @del;

 my $chg=$todo->set('registrant');
 my @chg;
 push @chg,['domain:registrant',$chg->srid()] if Net::DRI::Util::isa_contact($chg);
 push @d,['domain:chg',@chg] if @chg;

 @chg = ();
 $chg = $todo->set('description');
 if ($chg)
 {
	for my $str (@$chg)
	{
		push @chg, ['domain:description', $str];
	}
 }

 push @d,['domain:chg',@chg] if @chg;

 @chg = ();
 $chg=$todo->set('auth');
 push @chg,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$chg,1) if ($chg && (ref $chg eq 'HASH') && exists $chg->{pw});

 push @d,['domain:chg',@chg] if @chg;
 
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response('domain','infData');
 return unless defined $infdata;

 my @description;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'description')
  {
   push @description,$c->textContent();
  }
 }
 $rinfo->{domain}->{$oname}->{description}=\@description;
 return;
}
####################################################################################################
1;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TCI::Domain - TCI EPP Domain Extension for Net::DRI

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

Copyright (c) 2010-2011,2016 Dmitry Belyavsky <beldmit@gmail.com>
Copyright (c) 2011-2014 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
