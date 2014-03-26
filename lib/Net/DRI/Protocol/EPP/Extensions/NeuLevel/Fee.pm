## Domain Registry Interface, Neulevel EPP Fee Extension
##
## Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NeuLevel::Fee;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NeuLevel::Fee - NeuLevel EPP Fee extennsion for Net::DRI

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

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
(c) 2013-2014 Michael Holloway <michael@thedarkwinter.com>.
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
           check => [ \&check, \&check_parse ],
           create => [ \&transform, undef ],
           renew => [ \&transform, undef ],
           update => [ \&transform, undef ], # rgp restore
           transfer_request => [ \&transform, undef ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub check
{
 my ($epp,$domain,$rd)=@_;
 return unless Net::DRI::Util::has_key($rd,'fee');
 my $unspec = 'FeeCheck=Y';
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('neulevel','extension');
 $mes->command_extension($eid,['neulevel:unspec', $unspec]);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('neulevel','extension');
 return unless defined $infdata;

 my %t;
 my $unspec;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  next unless $n eq 'unspec';
  foreach my $kv (split(/ /,$c->textContent()))
  {
   my ($k,$v) = split(/=/,$kv);
   next unless $k =~ m/^(?:TierName|AnnualTierPrice)$/;
   $rinfo->{$otype}->{$oname}->{fee}->{tier}=$v if $k eq 'TierName';
   $rinfo->{$otype}->{$oname}->{fee}->{price}=$v if $k eq 'AnnualTierPrice';
  }
 }

 return;
}

# works for all except check
sub transform
{
 my ($epp,$domain,$rd)=@_;
 return unless Net::DRI::Util::has_key($rd,'fee');
 my $fee = $rd->{fee};
 Net::DRI::Exception::usererr_insufficient_parameters('fee should be a hash reference containing tier and price') unless (ref($fee) eq 'HASH' && exists $fee->{tier} && exists $fee->{price});
 Net::DRI::Exception::usererr_insufficient_parameters('fee tier') unless $fee->{tier} =~ m/^\w+$/;
 Net::DRI::Exception::usererr_insufficient_parameters('fee price') unless $fee->{price} =~ m/^\d+$/;
 my $unspec = 'TierName=' . $fee->{tier} . ' AnnualTierPrice=' . $fee->{price};
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('neulevel','extension');
 $mes->command_extension($eid,['neulevel:unspec', $unspec]);
 return;
}

1;
