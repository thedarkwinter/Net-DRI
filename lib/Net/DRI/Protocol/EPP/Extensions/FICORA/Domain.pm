## Domain Registry Interface, FICORA - .FI Domain EPP extension commands
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::FICORA::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FICORA::Domain - .FI EPP Domain extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>.
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
          info              => [ undef, \&info_parse ],
          autorenew         => [ \&autorenew, undef ],
          delete            => [ \&delete, undef],
          update            => [ \&update, undef],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 # .FI: <domain:registrant> and <domain:period> is mandatory
 Net::DRI::Exception::usererr_insufficient_parameters('Registrant contact required for FICORA (.FI) domain name creation') unless (Net::DRI::Util::has_contact($rd) && $rd->{contact}->has_type('registrant'));
 Net::DRI::Exception::usererr_insufficient_parameters('Period required for FICORA (.FI) domain name creation') unless Net::DRI::Util::has_duration($rd);

 return;
}

sub info_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  my $infdata=$mes->get_response('domain','infData');
  return unless defined $infdata;

  foreach my $el (Net::DRI::Util::xml_list_children($infdata))
  {
    my ($name,$content)=@$el;

    # registrylock
    $rinfo->{domain}->{$oname}->{'registrylock'}=$content->textContent() if $name eq 'registrylock';

    # autorenew
    $rinfo->{domain}->{$oname}->{'autorenew'}=$content->textContent() if $name eq 'autorenew';

    # ds: FIXME: do we need to parse this or is this a bug on their tech documentation?
    # <domain:dsData> => should not be parsed in secDNS-1 extension???
  }

  return;
}


# Auto renew is an extension for the <domain:renew> message. In the extension, the
# request may be given a <domain:autorenew> element with values 0 or 1. Value 1 sets
# the auto renewal process on to the specific domain name and removes the auto
# renewal process. Automatic renewal renews a domain name 30 days before expiration.
# Before renewing, the ISP will be messaged a Poll message that the renewing will
# happen in x days.
sub autorenew
{
  my ($epp,$domain,$rd)=@_;
  Net::DRI::Exception::usererr_insufficient_parameters('value (must be 0 or 1)') unless Net::DRI::Util::has_key($rd,'value');

  my $mes=$epp->message();
  my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'autorenew',$domain);

  my $value = $rd->{value} if $rd->{value};
  Net::DRI::Exception::usererr_invalid_parameters('value must be 0 or 1') unless ($value =~ m/^(0|1)$/) ;
  push @d,['domain:value',$value];

  $mes->command_body(\@d);

  # ugly but lets hard code first position of command array
  # they expect renew and not autorenew!
  $mes->command()->[0] = 'renew';

  return;
}


sub delete
{
  my ($epp,$domain,$rd)=@_;

  my $mes=$epp->message();
  my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'delete',$domain);
  $mes->command_body(\@d);

  my @de; # for the extension
  my $eid=$mes->command_extension_register('domain-ext:delete',sprintf('xmlns:domain-ext="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('domain-ext'))) if ( $rd->{delDate} || $rd->{cancel} );

  if ($rd->{delDate})
  {
    # schedule contains delDate tag, which should contain the scheduled time for
    # domain delete. delDate cannot be set to more than one year from now or
    # beyond the current expiration time.
    Net::DRI::Util::check_isa($rd->{delDate},'DateTime');
    push @de,['domain-ext:delDate',$rd->{delDate}->strftime('%Y-%m-%dT%T.%1NZ')];
    $mes->command_extension($eid,['domain-ext:schedule',@de]);
  } elsif ($rd->{cancel})
  {
    # When the Cancel tag is given, the message will be handled as domain name
    # delete removal, where the delDate is not considered. In this case, the domain
    # name should still be in patent period and in state removed or awaiting removal.
    # In the end, the domain name will return to granted state, but the expiration time
    # will not be affected.
    $mes->command_extension($eid,['domain-ext:cancel','']);
  }

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
  my $adel=$todo->del('auth'); # they have an authInfo element for deletion

  my (@add,@del);
  push @add,Net::DRI::Protocol::EPP::Util::build_ns($epp,$nsadd,$domain)         if Net::DRI::Util::isa_hosts($nsadd);
  push @add,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cadd)       if Net::DRI::Util::isa_contactset($cadd);
  push @add,$sadd->build_xml('domain:status','core')                             if Net::DRI::Util::isa_statuslist($sadd);
  push @del,Net::DRI::Protocol::EPP::Util::build_ns($epp,$nsdel,$domain,undef,1) if Net::DRI::Util::isa_hosts($nsdel);
  push @del,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cdel)       if Net::DRI::Util::isa_contactset($cdel);
  push @del,$sdel->build_xml('domain:status','core') if Net::DRI::Util::isa_statuslist($sdel);

  # build authInfo for delete action
  my $pwdel = $adel->{'pw'} if $adel->{'pw'};
  my $regtransfer = $adel->{'pwregistranttransfer'} if $adel->{'pwregistranttransfer'};
  my @delauthinfo;
  @delauthinfo = ['domain:pw',$pwdel] if $pwdel;
  push @delauthinfo, ['domain:pwregistranttransfer',$regtransfer] if $regtransfer;
  push @del, ['domain:authInfo',@delauthinfo] if @delauthinfo;
  # END build authInfo for delete action

  my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'update',$domain);
  push @d,['domain:add',@add] if @add;
  push @d,['domain:rem',@del] if @del;

  my $chg=$todo->set('registrant');
  my @chg;
  my @chgauthinfo;
  push @chg,['domain:registrant',$chg->srid()] if Net::DRI::Util::isa_contact($chg);
  $chg=$todo->set('auth');

  push @chgauthinfo, ['domain:pw',$chg->{pw}] if $chg->{pw};
  push @chgauthinfo, ['domain:pwregistranttransfer',$chg->{pwregistranttransfer}] if $chg->{pwregistranttransfer};
  push @chg,['domain:authInfo',@chgauthinfo] if @chgauthinfo;

  # now lets build new element => registrylock
  my ($registrylock,$type,$smsnumber,$numbertosend);
  my @smsnumber;
  my @numbertosend;
  my $authkey;

  $registrylock = $todo->set('registrylock') if $todo->set('registrylock');
  $type = $registrylock->{'type'} if $registrylock->{'type'};
  $smsnumber = $registrylock->{'smsnumber'} if $registrylock->{'smsnumber'};
  $numbertosend = $registrylock->{'numbertosend'} if $registrylock->{'numbertosend'};

  foreach my $elsms (@{$smsnumber}) {
    push @smsnumber,['domain:smsnumber',$elsms];
  }
  foreach my $elnum (@{$numbertosend}) {
    push @numbertosend,['domain:numbertosend',$elnum];
  }

  $authkey = ['domain:authkey', $registrylock->{'authkey'}] if $registrylock->{'authkey'};

  if ( defined($todo->set('registrylock')) ) {
    Net::DRI::Exception::usererr_insufficient_parameters('operation type is mandatory for registrylock and need to be: activate, deactivate, requestkey') unless ( $type =~ m/^(activate|deactivate|requestkey)$/ );
    push @chg,['domain:registrylock',(@smsnumber,@numbertosend,$authkey),{type=>$type}];
  }
  # END now lets build new element => registrylock

  push @d,['domain:chg',@chg] if @chg;
  $mes->command_body(\@d);

  return;
}

####################################################################################################
1;
