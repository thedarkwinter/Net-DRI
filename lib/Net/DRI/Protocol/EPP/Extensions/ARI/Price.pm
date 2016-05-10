## Domain Registry Interface, EPP ARI Price Extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013-2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ARI::Price;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ARI::Price - Price Extensions for ARI : L<http://ausregistry.github.io/doc/price-1.2/price-1.2.html>

=head1 DESCRIPTION

Adds the Price Extension (urn:ar:params:xml:ns:price-1.2) to domain commands. The extension is built by adding a hash to check, create, transfer and renew commands. This pricing information is returned instead of the standard information of a check command, which can optionally include a duration.

 eg. 
my $price = { duration=>DateTime::Duration->new(years=>5) };
$rc=$dri->domain_check('example9.tld',{price => $price} );
$price = $dri->get_info('price');
$dri->domain_create('example9.tld',{... price => $price}); # if your price hash contacts price and/or renewal_price, this will verify the prices before allowing registration. if you, it will go through acknowlodgeing the price without checking it
 
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
     check=> [ \&check, \&check_parse ],
     check_multi => [ \&check, \&check_parse],
     create => [ \&create, undef ],
     transfer_request => [ \&transfer, undef ],
     renew => [ \&renew, undef ],
     update => [ \&update, undef ],
     );
 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'price' => [ 'urn:ar:params:xml:ns:price-1.2','price-1.2.xsd' ]});
 $po->capabilities('domain_update','price',['set']);
 return;
}

####################################################################################################
## Price Standardisation

sub set_premium_values {
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 return unless $otype && $oaction && $oname;
 return unless exists $rinfo->{domain}->{$oname}->{price} && (ref $rinfo->{domain}->{$oname}->{price} eq 'HASH');
 my $ch = $rinfo->{domain}->{$oname}->{price};
 $rinfo->{domain}->{$oname}->{is_premium} = $ch->{premium};
 $rinfo->{domain}->{$oname}->{price_category} = $ch->{category};
 #$rinfo->{domain}->{$oname}->{price_currency} = undef; # this depends on registrar contract
 $rinfo->{domain}->{$oname}->{price_duration} = $ch->{duration};
 $rinfo->{domain}->{$oname}->{create_price} = $ch->{price};
 $rinfo->{domain}->{$oname}->{renew_price} = $ch->{renewal_price};
 $rinfo->{domain}->{$oname}->{restore_price} = $ch->{restore_price};
 $rinfo->{domain}->{$oname}->{transfer_price} = $ch->{transfer_price};
 return;
}

####################################################################################################

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'price');
 my $eid=$mes->command_extension_register('price','check');
 my @n;
 if (Net::DRI::Util::has_key($rd->{price},'duration') && UNIVERSAL::isa($rd->{'price'}->{'duration'},'DateTime::Duration'))
 {
  push @n, ['price:period',$rd->{'price'}->{'duration'}->in_units('years'),{'unit' => 'y'}];
 } elsif (Net::DRI::Util::has_key($rd->{price},'duration') && $rd->{'price'}->{'duration'} =~ m/^(\d|10)$/)
 {
  push @n, ['price:period',$rd->{'price'}->{'duration'},{'unit' => 'y'}];
 }
 $mes->command_extension($eid,\@n );
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $chkdata=$mes->get_extension($mes->ns('price'),'chkData');
 return unless defined $chkdata;
 
 foreach my $el (Net::DRI::Util::xml_list_children($chkdata))
 {
   my ($n,$c)=@$el;
   if ($n eq 'cd')
   {
    my $dn = '';
    foreach my $el2 (Net::DRI::Util::xml_list_children($c))
    {
     my ($n2,$c2)=@$el2;
     if ($n2 eq 'name')
     {
      $dn = $c2->textContent();
      $rinfo->{domain}->{$dn}->{action}='check';
      $rinfo->{domain}->{$dn}->{price}->{premium} = $c2->getAttribute('premium') if $c2->hasAttribute('premium');
     }
     elsif ($n2 =~ m/^(createPrice|renewPrice|transferPrice|restorePrice|reason)$/)
     {
      $rinfo->{domain}->{$dn}->{price}->{Net::DRI::Util::xml2perl($n2)} = $c2->textContent();
     }
     elsif ($n2 eq 'category')
     {
      $rinfo->{domain}->{$dn}->{price}->{Net::DRI::Util::xml2perl($n2)} = $c2->textContent();
      $rinfo->{domain}->{$dn}->{price}->{premium} = (uc($c2->textContent()) eq 'STANDARD') ? 0 : 1; # technicall this means nonstandard rather than premium
     }
     elsif ($n2 eq 'period')
     {
       my ($u,$t) = ($c2->hasAttribute('unit')?$c2->getAttribute('unit'):'y',$c2->textContent());
       $rinfo->{domain}->{$dn}->{price}->{duration} = ($u eq 'm') ? DateTime::Duration->new(months=>$t) : DateTime::Duration->new(years=>$t);
     }
    }
    $rinfo->{domain}->{$dn}->{price}->{price} = $rinfo->{domain}->{$dn}->{price}->{create_price}; # to maintain backwards compatibility!
    $rinfo->{domain}->{$dn}->{price}->{renewal_price} = $rinfo->{domain}->{$dn}->{price}->{renew_price}; # to maintain backwards compatibility!
    set_premium_values($po,$otype,$oaction,$dn,$rinfo);
   }
 }
 return;
}

sub create { return ack_price(@_,'create'); }
sub transfer { return ack_price(@_,'transfer'); }
sub renew { return ack_price(@_,'renew'); }

sub update {
   my ($epp,$domain,$todo)=@_;
   return unless my $ch = $todo->set('price');
   return ack_price($epp,$domain,{price=>$ch},'update');
}

sub ack_price
{
 my ($epp,$domain,$rd,$cmd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'price') && defined $cmd && $cmd =~ m/^(create|transfer|renew|update)$/;

 my (@n,@a);
 if (Net::DRI::Util::has_key($rd->{price},'price') || Net::DRI::Util::has_key($rd->{price},'renewal_price'))
 {
  my $price = $rd->{price};
  push @a,['price:price',$price->{price}] if $price->{price};
 }
 push @n,['price:ack',@a];
 my $eid=$mes->command_extension_register('price',$cmd);
 $mes->command_extension($eid,\@n );

 return;
}

####################################################################################################
1;
