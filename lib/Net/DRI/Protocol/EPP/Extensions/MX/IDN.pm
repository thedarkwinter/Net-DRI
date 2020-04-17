## Domain Registry Interface, .MX EPP IDN extension
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
## Copyright (c) 2015,2020 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::MX::IDN;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::MX::IDN - MX EPP IDN extension commands for Net::DRI

=head1 DESCRIPTION

Adds the IDN Extension ('EPP Manual  LAT.pdf'). This extension is used for the creation of Internationalized Domain Names (IDNs) by
extending the domain:create, domain:info and domain:check commands.

An IDN is a domain name that incorporates at least one of the special characters from
Spanish language (á, é, í, ó, ú, ü, ñ) listed in the .LAT IDN table. For example, the
following domain names are IDNs: méxico.lat, mexíco.lat, mexicó.lat. A base domain
is a domain name that uses one or more of the characters that have variant relations
in the .LAT IDN table. For example, the domain name méxico.lat, if registered, will
be the base domain for its variant domain names: mexico.lat, mexíco.lat, mexicó.lat,
méxíco.lat, mexícó.lat, méxicó.lat and méxícó.lat. If a base domain exists,
registration of its variant domain names will not be permitted. The base domain is
represented by the IDN base tag <idn:base>.

The extension required is: <extURI>http://www.nic.lat/nicmx-idn-1.0</extURI>

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHORS

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>
Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>
Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>.
Copyright (c) 2015,2020 Paulo Jorge <paullojorgge@gmail.com>.
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
            create  => [ \&create_build, undef ],
            check   => [ undef, \&parse ],
            info    => [ undef, \&parse ],
          );
  return { 'domain' => \%tmp };
}

sub create_build
{
  my ($epp,$domain,$rd)=@_;
  if ($rd->{idn})
  {
    Net::DRI::Exception::usererr_invalid_parameters('Value for "idn" key must be a Net::DRI::Data::IDN object') unless UNIVERSAL::isa($rd->{idn},'Net::DRI::Data::IDN');
    Net::DRI::Exception::usererr_insufficient_parameters('IDN object hash must have a ISO 639-1/2 or 15924 language tag') unless (defined $rd->{idn}->iso639_1() || $rd->{idn}->iso639_2() || defined $rd->{idn}->iso15924());
    Net::DRI::Exception::usererr_invalid_parameters('This Registry only allows IDNs associated with the Spanish language (iso639_1=es or iso639_2=spa)') unless lc $rd->{idn}->iso639_1() eq 'es' || lc $rd->{idn}->iso639_2() eq 'spa';
    return unless Net::DRI::Util::has_key($rd,'idn');
    my @n;
    push @n, ['idn:lang',uc($rd->{idn}->iso639_1())];
    $epp->message()->command_extension('idn', ['create', @n, {'xmlns:idn'=>'http://www.nic.lat/nicmx-idn-1.0'}]);
  }
  return;
}

sub parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  foreach ('checkResData','infoResData') # TODO: check if the manual schema is correct! they are not using standard name: chkData and infData
  {
    next unless my $resdata = $mes->get_extension('nicmx-idn',$_);
    foreach my $el (Net::DRI::Util::xml_list_children($resdata))
    {
      my ($name,$content)=@$el;
      $rinfo->{$otype}->{$oname}->{'idn_'.$name} = $content->textContent() if $name =~ m/^(name|base)$/ && $_ eq 'checkResData';
      $rinfo->{$otype}->{$oname}->{'idn_lang'} = $content->textContent() if $name eq 'lang';
    }
  }
  return;
}

####################################################################################################
1;