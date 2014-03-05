## Domain Registry Interface, VeriSign EPP Premium Domain Extension
##
## Copyright (c) 2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::PremiumDomain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 return { 'domain' => { 'check'  => [ \&check, \&check_parse ],
                        'update' => [ \&update, undef ],
                      } };
}

sub capabilities_add { return ('domain_update','premium_short_name',['set']); }

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'premiumdomain' => [ 'http://www.verisign.com/epp/premiumdomain-1.0','premiumdomain-1.0.xsd' ] });
 return;
}

####################################################################################################

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $pd;
 if (Net::DRI::Util::has_key($rd,'premium_domain'))
 {
  $pd=$rd->{premium_domain};
 } else
 {
  my $def=$epp->default_parameters();
  if (Net::DRI::Util::has_key($def,'premium_domain'))
  {
   $pd=$def->{premium_domain};
  } else
  {
   Net::DRI::Exception::usererr_insufficient_parameters('Premium domain flag must be provided');
  }
 }
 Net::DRI::Exception::usererr_invalid_parameters('Premium domain flag must be true/false/1/0') unless Net::DRI::Util::xml_is_boolean($pd);

 my $eid=$mes->command_extension_register('premiumdomain:check',sprintf('xmlns:premiumdomain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('premiumdomain')));
 $mes->command_extension($eid,['premiumdomain:flag',$pd]);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_extension('premiumdomain','chkData');
 return unless defined $chkdata;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('premiumdomain'),'cd'))
 {
  my $domain;
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'name')
   {
    $domain=lc($c->textContent());
    $rinfo->{domain}->{$domain}->{is_premium}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('premium'));
   } elsif ($n eq 'price')
   {
    $rinfo->{domain}->{$domain}->{price}={ amount => 0+$c->textContent(), unit => $c->getAttribute('unit') };
   } elsif ($n eq 'renewalPrice')
   {
    $rinfo->{domain}->{$domain}->{renewal_price}={ amount => 0+$c->textContent(), unit => $c->getAttribute('unit') };
   }
  }
 }
 return;
}

sub update
{
 my ($po,$domain,$todo)=@_;

 my $chg=$todo->set('premium_short_name');
 return unless defined $chg && length $chg;

 my $mes=$po->message();
 my $eid=$mes->command_extension_register('premiumdomain:reassign',sprintf('xmlns:premiumdomain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('premiumdomain')));
 $mes->command_extension($eid,['premiumdomain:shortName',$chg]);
 return;
}

#########################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::PremiumDomain - VeriSign EPP Premium Domain Extension for Net::DRI

=head1 SYNOPSIS

        $dri=Net::DRI->new();
        $dri->add_registry('VNDS',{client_id=>'XXXXXX');
        $dri->add_profile('p1','epp',{... transport ...},{extensions => [ 'VeriSign::DomainPremium' ]});

        $dri->protocol->default_parameters()->{premium_domain}=1;

        ...

        $rc=$dri->domain_check('example.tv');

        ...

        $rc=$dri->domain_update('premium.tv',$dri->local_object('changes')->set('premium_short_name','testregistrar'));

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

Copyright (c) 2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
