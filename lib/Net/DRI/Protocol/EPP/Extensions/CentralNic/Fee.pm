## Domain Registry Interface, CentralNic EPP Fee extension
## Comlaude EPP extensions
##
## Copyright (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
## Copyright (c) 2014 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use DateTime::Duration;
use DateTime::Format::ISO8601;
use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee - CentralNic EPP Fee extension commands for Net::DRI

=head1 DESCRIPTION

Adds the Price Extension (urn:ietf:params:xml:ns:fee-0.4) to domain commands. The extension is built by adding a hash to any domains commands. This pricing information is returned in all commands when requested.

CentralNic Fees extension is defined in http://tools.ietf.org/html/draft-brown-epp-fees-01

=item currency* (3 letter currency code)

=item action* (create, transfer, renew or restore)

=item duration*

=item phase (launch phase, e.g. landrush)

=item sub_phase (launch sub phase, e.g. phase=>claims, sub_phase=>landrush)

* indicates required fields

 my $fee = {fee=>{currency=>'EUR',action=>'transfer',duration=>$dri->local_object('duration','years',2)}}
 $rc=$dri->domain_check('example9.tld',{fee => $fee} );
 $price = $dri->get_info('fee');


=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>
Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>
Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
            info  => [ \&info, \&info_parse ],
            check => [ \&check, \&check_parse ],
            transfer_query => [ undef, \&transform_parse], ## does not add any elements to the command but does include elements in the response
            create => [ \&create, \&transform_parse ], ## extension adds elements to both the EPP <create> command and response
            delete => [ undef, \&transform_parse ],  ## extension does not add elements to the EPP <delete> command but does include elements in the response
            renew => [ \&renew, \&transform_parse ], ## extension adds elements to both the EPP <renew> command and response
            transfer_request => [ \&transfer, \&transform_parse ], ## extension adds elements to both the EPP <transfer> command and response when the value of the "op" attribute of the <transfer> command element is "request"
            update => [ \&update, \&transform_parse ], ## extension adds elements to both the EPP <renew> command and response
          );
  # check multiple domains...
  $tmp{check_multi}=$tmp{check};
  return { 'domain' => \%tmp };
}

sub setup
{
  my ($class,$po,$version)=@_;
  $po->ns({ map { $_ => [ 'urn:ietf:params:xml:ns:'.$_.'-0.4',$_.'-0.4.xsd' ] } qw/fee/ }); # rfc example don't have xsd (http://tools.ietf.org/html/draft-brown-epp-fees-01)
  #$po->ns({ 'fee' => [ 'urn:centralnic:params:xml:ns:fee-1.0','fee-1.0.xsd' ] }); # need to use their urn or keep the previous ietf?
  $po->capabilities('domain_update','fee',['set']); # add the fee extension in the domain_update command...
  return;
}
####################################################################################################

sub check
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
  return unless Net::DRI::Util::has_key($rd,'fee');

  Net::DRI::Exception::usererr_insufficient_parameters('For "fee" key parameter the value must be a ref hash with keys: currency, action, duration') unless Net::DRI::Util::has_key($rd->{fee},'currency') && Net::DRI::Util::has_key($rd->{fee},'action') && Net::DRI::Util::has_key($rd->{fee},'duration');

  my @n;
  my $rp=$rd->{fee};
  push @n,['fee:domain',$domain];
  Net::DRI::Exception::usererr_invalid_parameters('currency should be 3 letters ISO-4217 code') unless $rp->{currency}=~m/^[A-Z]{3}$/;
  push @n,['fee:currency',$rp->{currency}];

  Net::DRI::Exception::usererr_invalid_parameters('action should be: create, transfer, renew or restore') unless $rp->{action}=~m/^(?:create|transfer|renew|restore)$/;
  Net::DRI::Exception::usererr_invalid_parameters('fee action') unless (exists $rp->{action} && $rp->{action}  =~ m/\w+/);
  Net::DRI::Exception::usererr_invalid_parameters('fee phase') if (exists $rp->{phase} && $rp->{phase}  !~ m/\w+/);
  Net::DRI::Exception::usererr_invalid_parameters('fee subphase') if (exists $rp->{sub_phase} && $rp->{sub_phase}  !~ m/\w+/);
  if (defined $rp->{phase} && $rp->{sub_phase} && $rp->{action})
  {
    push @n,['fee:action',{'phase'=>$rp->{phase},'subphase'=>$rp->{sub_phase}},$rp->{action}];
  } elsif (defined $rp->{phase} && $rp->{action})
  {
    push @n,['fee:action',{'phase'=>$rp->{phase}},$rp->{action}];
  } elsif (defined $rp->{sub_phase} && $rp->{action})
  {
    push @n,['fee:action',{'subphase'=>$rp->{sub_phase}},$rp->{action}];
  } elsif (!defined $rp->{phase} || $rp->{sub_phase})
  {
    push @n,['fee:action',$rp->{action}];
  }

  Net::DRI::Exception::usererr_invalid_parameters('duration should be a DateTime::Duration object') unless Net::DRI::Util::is_class($rp->{duration},'DateTime::Duration');
  my $rj=Net::DRI::Protocol::EPP::Util::build_period($rp->{duration});
  push @n,['fee:period',$rj->[1],$rj->[2]];

  my $eid=$mes->command_extension_register('fee','check');
  $mes->command_extension($eid,\@n);
  return;

}

sub check_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success;

  my $chkdata=$mes->node_extension;
  return unless defined $chkdata;

  my %p;
  foreach my $el (Net::DRI::Util::xml_list_children($chkdata))
  {
    my ($name,$content)=@$el;
    if ($name eq 'chkData')
    {
      my $dn = '';
      foreach my $el2 (Net::DRI::Util::xml_list_children($content))
      {
        my ($name2,$content2)=@$el2;
        $dn = $content2->textContent() if $name2 eq 'domain';
      }
      push @{$rinfo->{domain}->{$dn}->{fee}},fee_set_parse($content);
    }
  }
  return;
}

sub info
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();

  return unless Net::DRI::Util::has_key($rd,'fee');

  Net::DRI::Exception::usererr_invalid_parameters('fee extension can be used only with one domain:name in check operation') if (ref $domain && @$domain > 1);
  Net::DRI::Exception::usererr_insufficient_parameters('For "fee" key parameter the value must be a ref hash with keys: currency, action, duration') unless Net::DRI::Util::has_key($rd->{fee},'currency') && Net::DRI::Util::has_key($rd->{fee},'action') && Net::DRI::Util::has_key($rd->{fee},'duration');

  my @n;
  my $rp=$rd->{fee};

  Net::DRI::Exception::usererr_invalid_parameters('currency should be 3 letters ISO-4217 code') unless $rp->{currency}=~m/^[A-Z]{3}$/;
  push @n,['fee:currency',$rp->{currency}];

  Net::DRI::Exception::usererr_invalid_parameters('action should be: create, transfer, renew or restore') unless $rp->{action}=~m/^(?:create|transfer|renew|restore)$/;
  Net::DRI::Exception::usererr_invalid_parameters('fee action') unless (exists $rp->{action} && $rp->{action}  =~ m/\w+/);
  Net::DRI::Exception::usererr_invalid_parameters('fee action phase') if (exists $rp->{phase} && $rp->{phase}  !~ m/\w+/);
  Net::DRI::Exception::usererr_invalid_parameters('fee action subphase') if (exists $rp->{sub_phase} && $rp->{sub_phase}  !~ m/\w+/);
  if (defined $rp->{phase} && $rp->{sub_phase} && $rp->{action})
  {
    push @n,['fee:action',{'phase'=>$rp->{phase},'subphase'=>$rp->{sub_phase}},$rp->{action}];
  } elsif (defined $rp->{phase} && $rp->{action})
  {
    push @n,['fee:action',{'phase'=>$rp->{phase}},$rp->{action}];
  } elsif (defined $rp->{sub_phase} && $rp->{action})
  {
    push @n,['fee:action',{'subphase'=>$rp->{sub_phase}},$rp->{action}];
  } elsif (!defined $rp->{phase} || $rp->{sub_phase})
  {
    push @n,['fee:action',$rp->{action}];
  }

  Net::DRI::Exception::usererr_invalid_parameters('duration should be a DateTime::Duration object') unless Net::DRI::Util::is_class($rp->{duration},'DateTime::Duration');
  my $rj=Net::DRI::Protocol::EPP::Util::build_period($rp->{duration});
  push @n,['fee:period',$rj->[1],$rj->[2]];

  my $eid=$mes->command_extension_register('fee','info');
  $mes->command_extension($eid,\@n);
  return;
}

sub info_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  my $infdata=$mes->get_extension($mes->ns('fee'),'infData');
  return unless defined $infdata;

  my %p;
  foreach my $el (Net::DRI::Util::xml_list_children($infdata))
  {
    my ($name,$content)=@$el;
    if ($name eq 'action')
    {
      $p{action}=$content->textContent();
      $p{phase}=$content->getAttribute('phase');
      $p{sub_phase}=$content->getAttribute('subphase');
    } elsif ($name=~m/^(currency)$/)
    {
      $p{$1}=$content->textContent();
    } elsif ($name eq 'period')
    {
      my $unit={y=>'years',m=>'months'}->{$content->getAttribute('unit')};
      $p{duration}=DateTime::Duration->new($unit => 0+$content->textContent());
    } elsif ($name eq 'fee')
    {
      $p{fee}=0+$content->textContent();
    }
  }
  $rinfo->{domain}->{$oname}->{fee}=\%p; # extension fields
  return;
}

# parse fee extension
sub transform_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  my $resdata;
  foreach my $ex (qw/creData delData renData trnData updData/)
  {
    next unless $resdata=$mes->get_extension($mes->ns('fee'),$ex);
    my %p;
    foreach my $el (Net::DRI::Util::xml_list_children($resdata))
    {
      my ($name,$content)=@$el;
      if ($name=~m/^(currency)$/)
      {
        $p{$1}=$content->textContent();
      } elsif ($name eq 'fee')
      {
        $p{fee}=0+$content->textContent();
      }
    }
    $rinfo->{domain}->{$oname}->{fee}=\%p;
  }
  return;
}

# add fee extension to commands
sub transform_build
{
  my ($epp,$domain,$rd,$cmd)=@_;
  my $mes=$epp->message();
  return unless Net::DRI::Util::has_key($rd,'fee');

  Net::DRI::Exception::usererr_invalid_parameters('fee extension can be used only with one domain:name in check operation') if (ref $domain && @$domain > 1);
  Net::DRI::Exception::usererr_insufficient_parameters('For "fee" key parameter the value must be a ref hash with keys: currency, fee') unless Net::DRI::Util::has_key($rd->{fee},'currency') && Net::DRI::Util::has_key($rd->{fee},'fee');

  my @n;
  my $rp=$rd->{fee};
  Net::DRI::Exception::usererr_invalid_parameters('currency should be 3 letters ISO-4217 code') unless $rp->{currency}=~m/^[A-Z]{3}$/;
  push @n,['fee:currency',$rp->{currency}];
  push @n,['fee:fee',$rp->{fee}]; # need protect fee param?

  my $eid=$mes->command_extension_register('fee',$cmd);
  $mes->command_extension($eid,\@n);
  return;
}

sub create
{
  transform_build(@_,'create');
}

sub renew
{
  transform_build(@_,'create'); # left the next functions even if we repeat code (could change since the extension was made from a draft RFC)
}

sub transfer
{
  transform_build(@_,'create');
}

sub update
{
  my ($epp,$domain,$todo)=@_;
  return unless my $ch=$todo->set('fee');
  transform_build($epp,$domain,{'fee' => $ch},'create');
}

sub fee_set_parse
{
  my $start = shift;
  return unless $start;
  my $set = {};
  foreach my $el (Net::DRI::Util::xml_list_children($start))
  {
    my ($name,$content)=@$el;
    if ($name eq 'action')
    {
      $set->{'action'} = $content->textContent();
      $set->{'phase'} = $content->getAttribute('phase') if $content->hasAttribute('phase');
      $set->{'sub_phase'} = $content->getAttribute('subphase') if $content->hasAttribute('subphase');
    } elsif ($name =~ m/^(domain|currency|fee)$/)
    {
      $set->{$1} = $content->textContent();
    } elsif ($name eq 'period')
    {
      my $unit={y=>'years',m=>'months'}->{$content->getAttribute('unit')};
      $set->{'duration'} = DateTime::Duration->new($unit => 0+$content->textContent());
    }
  }
 
  return $set;
}
####################################################################################################
1;
