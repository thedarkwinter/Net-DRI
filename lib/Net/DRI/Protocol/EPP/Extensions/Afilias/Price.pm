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

sub check_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();	
  my $resdata=$mes->get_extension($mes->ns('price'),'chkData');
  return unless defined $resdata;	
  my %p;
  foreach my $el (Net::DRI::Util::xml_list_children($resdata))
  {
    my ($name,$content)=@$el;
	if ($name eq 'cd')
	{
	  foreach my $el2 (Net::DRI::Util::xml_list_children($content))
	  {
	    my ($name2,$content2)=@$el2;
		if ($name2=~m/^(domain|currency|period)$/)
		{
		  $p{$1}=$content2->textContent();
		}
		$p{'domain_type_attr'}=$content2->getAttribute('type') if $content2->hasAttribute('type');
		$p{'period_unit_attr'}=$content2->getAttribute('unit') if $content2->hasAttribute('unit');
		if ($name2 eq 'pricing')
		{
		  my %p2;
		  my (@pricing,@pricing_attr);
		  foreach my $pricing (Net::DRI::Util::xml_list_children($content2))
		  {
		    my ($name_p,$content_p)=@$pricing;
			if ($name_p eq 'amount')
			{
			  push @pricing,$content_p->textContent() if $content_p->getAttribute('type')=~m/^(create|renew|transfer)$/;
			  push @pricing_attr,$content_p->getAttribute('type') if $content_p->getAttribute('type')=~m/^(create|renew|transfer)$/;
			}
		  }
		  @{$p2{'amount'}}=@pricing;
		  @{$p2{'amount_type_attr'}}=@pricing_attr;
		  $p2{'from_attr'}=$content2->getAttribute('from') if $content2->hasAttribute('from');
		  $p2{'to_attr'}=$content2->getAttribute('to') if $content2->hasAttribute('to');
		  $p{'pricing'}=\%p2;					
		}				
	  }
	}
	$rinfo->{domain}->{$oname}->{'price_ext'}=\%p;
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
        $p{'domain_type_attr'}=$content->getAttribute('type');
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
