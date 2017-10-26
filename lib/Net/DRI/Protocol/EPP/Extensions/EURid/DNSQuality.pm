## Domain Registry Interface, EURid DNSQuality EPP extension commands
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>.
##               2017 Michael Holloway <michael.holloway@comlaude.com>.
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

package Net::DRI::Protocol::EPP::Extensions::EURid::DNSQuality;

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
          dns_quality_info   => [ \&info, \&parse_info ],
         );
  return { 'domain' => \%tmp };
}

sub setup
{
  my ($class,$po,$version)=@_;
  $po->ns({ 'dns_quality' => [ 'http://www.eurid.eu/xml/epp/dnsQuality-2.0','dnsQuality-2.0.xsd' ] });
  return;
}

####################################################################################################
# Query commands
sub parse_info
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 return unless my $infdata=$mes->get_response('dns_quality','infData');
 my $d = {};
 $otype = $d->{object_type} = 'domain';
 $oaction = $d->{action} = 'info';
 $d->{exist} = 1;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($n,$c)=@$el;
   #print "Got finfance $name\n\n\n";
   if ($n eq 'name') {
     $oname = $d->{object_id} = $d->{name} = $c->textContent();
   } elsif ($n eq 'checkTime') {
    $d->{check_time} = $po->parse_iso8601($c->textContent());
   } elsif ($n eq 'score') {
    $d->{score} = 0+$c->textContent();
   }
 }
 $rinfo->{domain}->{$oname} = $d;
 $rinfo->{message}->{domain} = $rinfo->{$otype}->{$oname};
 return;
}

sub info
{
 my ($epp,$dom,$rd)=@_;
 my $mes=$epp->message();

 $mes->command('info','dnsQuality:info',sprintf('xmlns:dnsQuality="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('dns_quality')));
 my @d = ['dnsQuality:name', $dom];
 $mes->command_body(\@d);

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::DNSQuality - EURid DNSQuality Extension for Net::DRI

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

 Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>.
               2017 Michael Holloway <michael.holloway@comlaude.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
