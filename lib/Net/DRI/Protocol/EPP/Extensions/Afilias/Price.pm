## Domain Registry Interface, EPP Message for Afilias
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2014 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Afilias::Price;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;


####################################################################################################

sub register_commands
{
  my ($class,$version)=@_;
  my %tmp=(
        check             => [ undef, \&check_parse ],
        create            => [ undef, \&transform_parse ],
        renew             => [ undef, \&transform_parse ],
        transfer_request  => [ undef, \&transform_parse ],
  );
  # check multiple domains
  $tmp{check_multi}=$tmp{check};
  return { 'domain'=>\%tmp };  				
}

sub setup
{
  my ($class,$po,$version)=@_;
  $po->ns({ map { $_ => [ 'urn:afilias:params:xml:ns:'.$_.'-1.0',$_.'-1.0.xsd' ] } qw/price/ });
  return;
}

####################################################################################################
## Price Standardisation

sub set_premium_values {
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 return unless exists $rinfo->{domain}->{$oname}->{price_ext} && (ref $rinfo->{domain}->{$oname}->{price_ext} eq 'HASH');
 my $ch = $rinfo->{domain}->{$oname}->{price_ext};
 $rinfo->{domain}->{$oname}->{is_premium} = $ch->{premium};
 #$rinfo->{domain}->{$oname}->{price_category} = $ch->{description};
 $rinfo->{domain}->{$oname}->{price_currency} = $ch->{currency};
 $rinfo->{domain}->{$oname}->{price_duration} = $ch->{duration};
 $rinfo->{domain}->{$oname}->{create_price} = $ch->{create};
 $rinfo->{domain}->{$oname}->{renew_price} = $ch->{renew};
 $rinfo->{domain}->{$oname}->{restore_price} = $ch->{restore};
 $rinfo->{domain}->{$oname}->{transfer_price} = $ch->{transfer};
 return;
}

####################################################################################################

sub check_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  my $resdata=$mes->get_extension($mes->ns('price'),'chkData');
  return unless defined $resdata;	

  my (%p,$this_domain);
  foreach my $el (Net::DRI::Util::xml_list_children($resdata))
  {
    my ($name,$content)=@$el;
    if ($name eq 'cd')
    {
      undef %p;
      foreach my $el2 (Net::DRI::Util::xml_list_children($content))
      {
        my ($name2,$content2)=@$el2;
        if ($name2 eq 'domain')
        {
          $this_domain = $p{'domain'} = $content2->textContent();
          $p{'premium'} = ($content2->hasAttribute('type') && $content2->getAttribute('type') eq 'premium') ? 1 : 0;
        }
        elsif ($name2 eq 'period')
        {
          my $unit={y=>'years',m=>'months'}->{$content2->getAttribute('unit')};
          $p{'duration'} = DateTime::Duration->new($unit => 0+$content2->textContent());
        }
        elsif ($name2 eq 'currency')
        {
          $p{currency} = $content2->textContent();
        }
        if ($name2 eq 'pricing')
        {
          foreach my $pricing (Net::DRI::Util::xml_list_children($content2))
          {
            my ($name_p,$content_p)=@$pricing;
            next unless $content_p->hasAttribute('type') && $content_p->getAttribute('type')=~m/^(create|renew|transfer)$/;
            $p{$1} = 0+$content_p->textContent() if ($name_p eq 'amount');
          }
          $p{'valid_from'}=$po->parse_iso8601($content2->getAttribute('from')) if $content2->hasAttribute('from');
          $p{'valid_to'}=$po->parse_iso8601($content2->getAttribute('to')) if $content2->hasAttribute('to');
        }				
        $rinfo->{domain}->{$this_domain}->{'price_ext'}=\%p;
        set_premium_values($po,$otype,$oaction,$this_domain,$rinfo);
      }
    }
  }
  return;
}



sub transform_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  my $resdata;
  foreach my $ex (qw/creData renData trnData/)
  {
    next unless $resdata=$mes->get_extension($mes->ns('price'),$ex);
    my %p;
    foreach my $el (Net::DRI::Util::xml_list_children($resdata))
    {
      my ($name,$content)=@$el;
      if ($name eq 'domain')
      {
        $p{'domain'}=$content->textContent();
        $p{'premium'} = ($content->hasAttribute('type') && $content->getAttribute('type') eq 'premium') ? 1 : 0;
        $rinfo->{domain}->{$oname}->{is_premium} = $p{'premium'} if exists $p{'premium'};
      }
    }
    $rinfo->{domain}->{$oname}->{'price_ext'}=\%p;
  }
  return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Afilias::Price - EPP Afilias Price for Net::DRI

=head1 DESCRIPTION

EPP Price extension: add the price extension for Afilias premium domains.

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

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
