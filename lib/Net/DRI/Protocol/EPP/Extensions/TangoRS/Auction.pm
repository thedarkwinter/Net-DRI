## Domain Registry Interface, Tango-RS EPP Auction Extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::TangoRS::Auction;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TangoRS::Auction - Auction Extension for Tango-RS and Corenic

=head1 DESCRIPTION

Adds the Auction Extension (http://xmlns.xmlns.tango-rs.net/epp/auction-1.0) to domain commands. The extension is built by adding an additional hash with following data to the create and update commands. This information is also returned from an info command. Hash contains currency and bid, both required.

=item currency [curreny code]

=item  bid [total bid]

 domain_create('domain.tld',{... auction=>{currency => 'EUR','{bid=>'10000.00'})

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
(c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
           info=> [ undef, \&info_parse],
           create => [ \&create, undef ],
           update => [ \&update, undef ],
        );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_bid
{
  my ($rd) = shift;
  Net::DRI::Exception::usererr_invalid_parameters('auction currency') unless exists $rd->{currency} && $rd->{currency}  =~ m/^\w{3}$/; # 3 letter currency code
  Net::DRI::Exception::usererr_invalid_parameters('auction bid') unless exists $rd->{bid} && $rd->{bid}  =~ m/^\d+(.\d+)?$/;
  my @n;
  push @n, ['auction:bid',{'currency'=>uc($rd->{currency}) },$rd->{bid} ] ;
  return @n;
}

####################################################################################################

sub create
{
 my ($epp,$domain,$rd)=@_;
 return unless Net::DRI::Util::has_key($rd,'auction');

 my @n = build_bid($rd->{'auction'});
 return unless @n;

 $epp->message()->command_extension('auction', ['create', @n]);

 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 return unless $todo->set('auction');

 my @n = build_bid($todo->set('auction'));
 return unless @n;

 $epp->message()->command_extension('auction', ['update', @n]);

 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_extension('auction','infData');
 return unless defined $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($n,$c)=@$el;
   $rinfo->{domain}->{$oname}->{auction}= { 'bid' => $c->textContent(), 'currency' => $c->getAttribute('currency') } if $n eq 'bid';
 }

 return;
}

####################################################################################################


1;
