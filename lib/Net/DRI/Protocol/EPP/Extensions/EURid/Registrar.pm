## Domain Registry Interface, EURid RegistrarFinance EPP extension commands
##
## Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>.
##               2016 Michael Holloway <michael.holloway@comlaude.com>.
##               All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::EURid::Registrar;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

####################################################################################################

sub register_commands
{
  my ($class,$version)=@_;
  my %tmp=(
          info   => [ \&info, \&parse_info ],
         );
  return { 'registrar' => \%tmp };
}

sub setup
{
  my ($class,$po,$version)=@_;
  $po->ns({ 'registrar_finance'    => [ 'http://www.eurid.eu/xml/epp/registrarFinance-1.0','registrarFinance-1.0' ] });
  $po->ns({ 'registrar_hit_points' => [ 'http://www.eurid.eu/xml/epp/registrarHitPoints-1.0','registrarHitPoints-1.0' ] });
  $po->ns({ 'registration_limit'   => [ 'http://www.eurid.eu/xml/epp/registrationLimit-1.0','registrationLimit-1.0' ] });
  return;
}

####################################################################################################
## Helpers

sub _parse_info_finance
{
  my ($po, $registrar, $infdata) = @_;
  foreach my $el (Net::DRI::Util::xml_list_children($infdata))
  {
    my ($n,$c)=@$el;
    #print "Got finfance $name\n\n\n";
    if ($n eq 'paymentMode')
    {
      $registrar->{Net::DRI::Util::xml2perl($n)}=$c->textContent();
    } elsif ($n =~ m/(?:availableAmount|accountBalance|dueAmount|overdueAmount)/)
    {
      $registrar->{Net::DRI::Util::xml2perl($n)}=0+$c->textContent();
      $registrar->{amount_available} = 0+$c->textContent() if $n eq 'availableAmount'; # backwards compatible
    }
  }
  return;
}

sub _parse_info_hitpoints
{
  my ($po, $registrar, $infdata) = @_;
  $registrar->{hitpoints}={}; # backwards compatible
  foreach my $sel (Net::DRI::Util::xml_list_children($infdata))
  {
    my ($n,$c)=@$sel;
    if ($n eq 'nbrHitPoints')
    {
      $registrar->{hitpoints}->{current_number}=0+$c->textContent();
    } elsif ($n eq 'maxNbrHitPoints')
    {
      $registrar->{hitpoints}->{maximum_number}=0+$c->textContent();
    } elsif ($n eq 'blockedUntil')
    {
      $registrar->{hitpoints}->{blocked_until}=$po->parse_iso8601($c->textContent());
    }
  }
  return;
}

sub _parse_info_registration_limit
{
  my ($po, $registrar, $infdata) = @_;
  $registrar->{registration_limit}={};
  foreach my $sel (Net::DRI::Util::xml_list_children($infdata))
  {
    my ($n,$c)=@$sel;
    if ($n eq 'monthlyRegistrations')
    {
      $registrar->{registration_limit}->{monthly_registrations}=0+$c->textContent();
    } elsif ($n eq 'maxMonthlyRegistrations')
    {
      $registrar->{registration_limit}->{max_monthly_registrations}=0+$c->textContent();
    } elsif ($n eq 'limitedUntil')
    {
      $registrar->{registration_limit}->{limited_until}=$po->parse_iso8601($c->textContent());
    }
  }
  return;
}

####################################################################################################
# Query commands
sub parse_info
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $registrar = {};
 my ($infdata);

 if ($infdata=$mes->get_response('registrar_finance','infData'))
 {
   _parse_info_finance($po, $registrar, $infdata);
 }

 elsif ($infdata=$mes->get_response('registrar_hit_points','hitPoints'))
 {
    _parse_info_hitpoints($po, $registrar, $infdata);
 }

 elsif ($infdata=$mes->get_response('registration_limit','registrationLimit'))
 {
    _parse_info_registration_limit($po, $registrar, $infdata);
 }

 $otype = 'message';
 $registrar->{object_type} = 'registrar';
 $oname = $registrar->{object_id} = $registrar->{name} = 'registrar';
 $oaction = $registrar->{action} = 'info';
 $rinfo->{message}->{registrar} = $registrar;
 $rinfo->{registrar}->{registrar} = $rinfo->{message}->{registrar};

 return;
}

sub info
{
 my ($epp,$registrar,$rd)=@_;
 my $mes=$epp->message();
 if ($rd && exists $rd->{type} && $rd->{type} eq 'hit_points')
 {
   $mes->command('info','registrar:hitPoints',sprintf('xmlns:registrar="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('registrar_hit_points')));
 } elsif ($rd && exists $rd->{type} && $rd->{type} eq 'registration_limit')
 {
   $mes->command('info','registrar:registrationLimit',sprintf('xmlns:registrar="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('registration_limit')));
 } else # default to finance
 {
   $mes->command('info','registrar:finance',sprintf('xmlns:registrar="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('registrar_finance')));
 }
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::IDN - EURid IDN EPP Extension for Net::DRI

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

 Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>.
               2016 Michael Holloway <michael.holloway@comlaude.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
