## Domain Registry Interface, EURid DNSSECEligibility EPP extension commands
##
## Copyright (c) 2018 Patrick Mevzek <netdri@dotandco.com>.
##               2018 Michael Holloway <michael@thedarkwinter.com>.
##               2018 Paulo Jorge <paullojorgge@gmail>.
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

package Net::DRI::Protocol::EPP::Extensions::EURid::DNSSECEligibility;

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
          dnssec_eligibility_info   => [ \&info, \&parse_info ],
         );
  return { 'domain' => \%tmp };
}

sub setup
{
  my ($class,$po,$version)=@_;
  $po->ns({ 'dnssec_eligibility' => [ 'http://www.eurid.eu/xml/epp/dnssecEligibility-1.0','dnssecEligibility-1.0.xsd' ] });
  return;
}

####################################################################################################
# Query commands
sub parse_info
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 return unless my $infdata=$mes->get_response('dnssec_eligibility','infData');
 my $d = {};
 $otype = $d->{object_type} = 'domain';
 $oaction = $d->{action} = 'info';
 $d->{exist} = 1;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($n,$c)=@$el;
   if ($n eq 'name') {
     $oname = $d->{object_id} = $d->{name} = $c->textContent();
   } elsif ($n=~m/^(eligible|msg|code)$/) {
     $d->{$n} = $c->textContent() if $c->textContent();
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

 $mes->command('info','dnssecEligibility:info',sprintf('xmlns:dnssecEligibility="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('dnssec_eligibility')));
 my @d = ['dnssecEligibility:name', $dom];
 $mes->command_body(\@d);

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::DNSSECEligibility - EURid DNSSECEligibility Extension for Net::DRI

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

 Copyright (c) 2018 Patrick Mevzek <netdri@dotandco.com>.
               2018 Michael Holloway <michael@thedarkwinter.com>.
               2018 Paulo Jorge <paullojorgge@gmail>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
