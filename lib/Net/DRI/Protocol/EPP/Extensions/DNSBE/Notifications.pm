## Domain Registry Interface, DNSBE Registrar EPP extension notifications
## (introduced in release 5.6 october 2008)
##
## Copyright (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::DNSBE::Notifications;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DNSBE::Notifications - DNSBE EPP Notifications Handling for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
          notification => [ undef, \&parse ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $poll=$mes->get_response('dnsbe','pollRes');
 return unless defined $poll;

 my %n;
 foreach my $el (Net::DRI::Util::xml_list_children($poll))
 {
  my ($name,$c)=@$el;
  if ($name=~m/^(action|returncode|type|contact|domainname|date|email|level)$/)
  {
   $n{$1}=$c->textContent();
  }
 }

 # determin object type and set name/id
 if (Net::DRI::Util::has_key(\%n,'domainname'))
 {
  $otype = 'domain';
  $rinfo->{$otype}->{$oname}->{name} = $oname = $n{domainname};
 } elsif (Net::DRI::Util::has_key(\%n,'contact'))
 {
  $otype='contact';
  $rinfo->{$otype}->{$oname}->{srid} = $oname=$n{contact};
 }

 # add other values to object if it is an object
 if (defined $otype)
 {
  $rinfo->{$otype}->{$oname}->{exist} = 1;
  $rinfo->{$otype}->{$oname}->{date} = $po->parse_iso8601($n{date}) if Net::DRI::Util::has_key(\%n,'date') && length $n{date};
  foreach ('action','returncode','type','contact','email','level')
  {
   $rinfo->{$otype}->{$oname}->{$_} = $n{$_} if defined $n{$_};
  }
 } else
 {
  $rinfo->{session}->{notification}=\%n;
 }
 $oname=undef if defined $otype && $otype eq 'contact';
 return;
}

####################################################################################################
1;
