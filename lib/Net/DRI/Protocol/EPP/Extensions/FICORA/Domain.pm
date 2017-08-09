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
          delete_schedule   => [ \&delete_schedule, undef],
          delete_cancel     => [ \&delete_cancel, undef],
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


# schedule contains delDate tag, which should contain the scheduled time for
# domain delete. delDate cannot be set to more than one year from now or
# beyond the current expiration time.
sub delete_schedule
{
  my ($epp,$domain,$rd)=@_;

  # will not bother doing validation for more than one year from now or beyong exDate
  # i assume that the Registry does it from their side and return an error message!
  Net::DRI::Exception::usererr_insufficient_parameters('delDate mandatory') unless Net::DRI::Util::has_key($rd,'delDate');

  my $mes=$epp->message();
  my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'delete',$domain);
  $mes->command_body(\@d);

  my @de; # for the extension
  my $eid=$mes->command_extension_register('domain-ext:delete',sprintf('xmlns:domain-ext="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('domain-ext')));
  Net::DRI::Util::check_isa($rd->{delDate},'DateTime');
  push @de,['domain-ext:delDate',$rd->{delDate}->strftime('%Y-%m-%dT%T.%1NZ')];
  $mes->command_extension($eid,['domain-ext:schedule',@de]);

  return;
}



# When the Cancel tag is given, the message will be handled as domain name
# delete removal, where the delDate is not considered. In this case, the domain
# name should still be in patent period and in state removed or awaiting removal.
# In the end, the domain name will return to granted state, but the expiration time
# will not be affected.
sub delete_cancel
{
  my ($epp,$domain,$rd)=@_;

  my $mes=$epp->message();
  my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'delete',$domain);
  $mes->command_body(\@d);

  my $eid=$mes->command_extension_register('domain-ext:delete',sprintf('xmlns:domain-ext="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('domain-ext')));
  $mes->command_extension($eid,['domain-ext:cancel','']);

  return;
}

####################################################################################################
1;
