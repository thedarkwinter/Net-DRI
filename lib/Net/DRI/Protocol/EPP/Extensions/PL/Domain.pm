## Domain Registry Interface, .PL Domain EPP extension commands
##
## Copyright (c) 2006,2008-2011,2013 Patrick Mevzek <netdri@dotandco.com> and Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. 
## All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::PL::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::Hosts;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PL::Domain - .PL EPP Domain extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHORS

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>
Tonnerre Lombard <tonnerre.lombard@sygroup.ch>

=head1 COPYRIGHT

Copyright (c) 2006,2008-2011,2013 Patrick Mevzek <netdri@dotandco.com> and Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
          create => [ \&create ],
          update => [ \&update ],
          info   => [ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:extdom="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('pl_domain')));
}

sub build_ns
{
 my ($epp,$ns,$domain,$xmlns)=@_;
 $xmlns='domain' unless defined($xmlns);
 return map { [$xmlns . ':ns',$_] } $ns->get_names();
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'create',$domain);
 my $def = $epp->default_parameters();

 if ($def && (ref($def) eq 'HASH') && exists($def->{domain_create}) && (ref($def->{domain_create}) eq 'HASH'))
 {
  $rd={} unless ($rd && (ref($rd) eq 'HASH') && keys(%$rd));
  while(my ($k,$v)=each(%{$def->{domain_create}}))
  {
   next if exists($rd->{$k});
   $rd->{$k}=$v
  }
 }

 ## Period, OPTIONAL
 push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);

 ## Nameservers, OPTIONAL
 push @d,build_ns($epp,$rd->{ns},$domain) if Net::DRI::Util::has_ns($rd);

 ## Contacts, all OPTIONAL
 if (Net::DRI::Util::has_contact($rd))
 {
  my $cs=$rd->{contact};
  my @o=$cs->get('registrant');
  push @d,['domain:registrant',$o[0]->srid()] if (@o);
  push @d,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cs);
 }

 ## AuthInfo
 Net::DRI::Exception::usererr_insufficient_parameters("authInfo is mandatory") unless (Net::DRI::Util::has_auth($rd));
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth});
 $mes->command_body(\@d);

 return unless exists($rd->{reason}) || exists($rd->{book});

 my $eid=build_command_extension($mes,$epp,'extdom:create');

 my @e;
 push @e,['extdom:reason',$rd->{reason}] if (exists($rd->{reason}) && $rd->{reason});
 push @e,['extdom:book']                 if (exists($rd->{book}) && $rd->{book});

 $mes->command_extension($eid,\@e);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'update',$domain);

 my $nsadd=$todo->add('ns');
 my $nsdel=$todo->del('ns');
 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 my $cadd=$todo->add('contact');
 my $cdel=$todo->del('contact');
 my (@add,@del);

 push @add,build_ns($epp,$nsadd,$domain)		if $nsadd && !$nsadd->is_empty();
 push @add,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cadd) if $cadd;
 push @add,$sadd->build_xml('domain:status','core')	if $sadd;
 push @del,build_ns($epp,$nsdel,$domain,undef,1)	if $nsdel && !$nsdel->is_empty();
 push @del,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cdel) if $cdel;
 push @del,$sdel->build_xml('domain:status','core')	if $sdel;

 push @d,['domain:add',@add] if @add;
 push @d,['domain:rem',@del] if @del;

 my $chg=$todo->set('registrant');
 my @chg;
 push @chg,['domain:registrant',$chg->srid()] if Net::DRI::Util::isa_contact($chg,'Net::DRI::Data::Contact::PL');
 $chg=$todo->set('auth');
 push @chg,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$chg,1) if ($chg && (ref $chg eq 'HASH') && exists $chg->{pw});
 push @d,['domain:chg',@chg] if @chg;
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes = $po->message();
 return unless $mes->is_success();
 my $infdata = $mes->get_response('domain','infData');
 return unless $infdata;
 my $ns = Net::DRI::Data::Hosts->new();
 my $c = $infdata->getFirstChild();

 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name = $c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'name')
  {
   $oname = lc($c->getFirstChild()->getData());
  }
  elsif ($name eq 'ns')
  {
   $ns->add($c->getFirstChild()->getData());
  }
 } continue { $c = $c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{ns} = $ns;
 return;
}

####################################################################################################
1;
