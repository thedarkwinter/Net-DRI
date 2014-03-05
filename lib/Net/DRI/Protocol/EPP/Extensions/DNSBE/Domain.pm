## Domain Registry Interface, DNSBE Domain EPP extension commands
## (based on Registration_guidelines_v4_7_2-Part_4-epp.pdf)
##
## Copyright (c) 2006-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::DNSBE::Domain;

use strict;
use warnings;

use Carp;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Hosts;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DNSBE::Domain - DNSBE EPP Domain extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
          create            => [ \&create, undef ],
          update            => [ \&update, undef ],
          info              => [ undef, \&info_parse ],
          delete            => [ \&delete, undef ],
          transfer_request  => [ \&transfer_request, undef ],
          undelete          => [ \&undelete, undef ],
          transferq_request => [ \&transferq_request, undef ],
          trade             => [ \&trade, undef ],
          reactivate        => [ \&reactivate, undef ],
          request_authcode  => [ \&request_authcode, undef ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:dnsbe="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('dnsbe')));
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 ## Registrant contact is mandatory (optional in EPP), already added in Core, we just verify here
 Net::DRI::Exception->die(0,'protocol/EPP',11,'Registrant contact is mandatory in domain_create')
     unless (Net::DRI::Util::has_contact($rd) &&  $rd->{contact}->get('registrant')->srid());

 return unless exists($rd->{nsgroup});
 my @n=add_nsgroup($rd->{nsgroup});

 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 $mes->command_extension($eid,['dnsbe:create',['dnsbe:domain',@n]]);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 if (grep { ! /^(?:add|del)$/ } $todo->types('nsgroup'))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only nsgroup add/del available for domain');
 }

 my $nsgadd=$todo->add('nsgroup');
 my $nsgdel=$todo->del('nsgroup');
 return unless ($nsgadd || $nsgdel);

 my @n;
 push @n,['dnsbe:add',add_nsgroup($nsgadd)] if $nsgadd;
 push @n,['dnsbe:rem',add_nsgroup($nsgdel)] if $nsgdel;

 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 $mes->command_extension($eid,['dnsbe:update',['dnsbe:domain',@n]]);
 return;
}

## This is not written in the PDF document, but it should probably be there, like for .EU
sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('dnsbe','infData');
 return unless $infdata;

 my @c;
 foreach my $el ($infdata->getChildrenByTagNameNS($mes->ns('dnsbe'),'nsgroup'))
 {
  push @c,Net::DRI::Data::Hosts->new()->name($el->getFirstChild()->getData());
 }

 $rinfo->{domain}->{$oname}->{nsgroup}=\@c;
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless (exists($rd->{deleteDate}) && $rd->{deleteDate});

 Net::DRI::Util::check_isa($rd->{deleteDate},'DateTime');

 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 my @n=('dnsbe:delete',['dnsbe:domain',['dnsbe:deleteDate',$rd->{deleteDate}->set_time_zone('UTC')->strftime("%Y-%m-%dT%T.%NZ")]]);
 $mes->command_extension($eid,\@n);
 return;
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my @n=add_transfer($epp,$mes,$domain,$rd);
 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 $mes->command_extension($eid,['dnsbe:transfer',['dnsbe:domain',@n]]);
 return;
}

sub add_transfer
{
 my ($epp,$mes,$domain,$rd)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('registrant and billing are mandatory') unless (Net::DRI::Util::has_contact($rd) && $rd->{contact}->has_type('registrant') && $rd->{contact}->has_type('billing'));

 my $cs=$rd->{contact};
 my @n;

 my $creg=$cs->get('registrant');
 Net::DRI::Exception::usererr_invalid_parameters('registrant must be a contact object or #AUTO#') unless (Net::DRI::Util::isa_contact($creg,'Net::DRI::Data::Contact::BE') || (!ref($creg) && ($creg eq '#AUTO#')));
 push @n,['dnsbe:registrant',ref($creg)? $creg->srid() : '#AUTO#' ];

 if (exists($rd->{trDate}))
 {
  Net::DRI::Util::check_isa($rd->{trDate},'DateTime');
  push @n,['dnsbe:trDate',$rd->{trDate}->set_time_zone('UTC')->strftime('%Y-%m-%dT%T.%NZ')];
 }

 my $cbill=$cs->get('billing');
 Net::DRI::Exception::usererr_invalid_parameters('billing must be a contact object') unless Net::DRI::Util::isa_contact($cbill,'Net::DRI::Data::Contact::BE');
 push @n,['dnsbe:billing',$cbill->srid()];

 push @n,add_contact('accmgr',$cs,1) if $cs->has_type('accmgr');
 push @n,add_contact('tech',$cs,9) if $cs->has_type('tech');
 push @n,add_contact('onsite',$cs,5) if $cs->has_type('onsite');

 if (Net::DRI::Util::has_ns($rd))
 {
  my $n=Net::DRI::Protocol::EPP::Util::build_ns($epp,$rd->{ns},$domain,'dnsbe');
  my @ns=$mes->nsattrs('domain');
  push @$n,{'xmlns:domain'=>shift(@ns),'xsi:schemaLocation'=>sprintf('%s %s',@ns)};
  push @n,$n;
 }

 push @n,add_nsgroup($rd->{nsgroup}) if (exists($rd->{nsgroup}));
 return @n;
}

sub add_nsgroup
{
 my ($nsg)=@_;
 return unless (defined($nsg) && $nsg);
 my @a=grep { defined($_) && $_ && !ref($_) && Net::DRI::Util::xml_is_normalizedstring($_,1,100) } map { Net::DRI::Util::isa_hosts($_)? $_->name() : $_ } (ref($nsg) eq 'ARRAY')? @$nsg : ($nsg);
 return map { ['dnsbe:nsgroup',$_] } grep {defined} @a[0..8];
}

sub add_contact
{
 my ($type,$cs,$max)=@_;
 $max--;
 my @r=grep { Net::DRI::Util::isa_contact($_,'Net::DRI::Data::Contact::BE') } ($cs->get($type));
 return map { ['dnsbe:'.$type,$_->srid()] } grep {defined} @r[0..$max];
}

sub undelete
{
 my ($epp,$domain)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'undelete',$domain);
 $mes->command_body(\@d);
 return;
}

sub transferq_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transferq',{'op'=>'request'}],$domain);

 Carp::croak('Key "period" should be key "duration"') if Net::DRI::Util::has_key($rd,'period');
 push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{period}) if Net::DRI::Util::has_duration($rd);
 $mes->command_body(\@d);

 my @n=add_transfer($epp,$mes,$domain,$rd);
 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 $mes->command_extension($eid,['dnsbe:transferq',['dnsbe:domain',@n]]);
 return;
}

sub trade
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['trade',{'op'=>'request'}],$domain);
 $mes->command_body(\@d);

 my @n=add_transfer($epp,$mes,$domain,$rd);
 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 $mes->command_extension($eid,['dnsbe:trade',['dnsbe:domain',@n]]);
 return;
}

sub reactivate
{
 my ($epp,$domain)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'reactivate',$domain);
 $mes->command_body(\@d);
 return;
}

sub request_authcode
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $trid = $mes->cltrid();
 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 my @d;
 push @d,['dnsbe:domainName',$domain];
 push @d,['dnsbe:url',$rd->{'url'}] if $rd->{'url'};
 $mes->command_extension($eid,['dnsbe:command',['dnsbe:requestAuthCode',@d],['dnsbe:clTRID',$trid]]);
 # missing TRID
 return;
}

####################################################################################################
1;
