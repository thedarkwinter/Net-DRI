## Domain Registry Interface, CentralNic EPP Fee extension
##
## Copyright (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2016 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee - CentralNic EPP Fee extension commands for Net::DRI (draft-brown-epp-fees-01, 02, 03, 04, 05, and 06)

=head1 DESCRIPTION

Adds the Price Extension (urn:ietf:params:xml:ns:fee-0.4, -0.5, -0.6, -0.7, -0.8, -0.9) to domain commands. This extension supports both versions. The extension is built by adding a hash to any domains commands. This pricing information is returned in all commands when requested.

CentralNic Fees extension is defined in http://tools.ietf.org/html/draft-brown-epp-fees-07

NOTE: fee-0.4 is no longer in use anywhere as far as I am aware (GMO has upgraded) so theoretically support for it can be dropped now.

=item currency* (3 letter currency code - option in 0.5+)

=item action* (create, transfer, renew or restore)

=item duration* (Datetime::Duration - optional in 0.5+)

=item phase (launch phase, e.g. landrush)

=item sub_phase (launch sub phase, e.g. phase=>claims, sub_phase=>landrush)

 my $fee = {fee=>{currency=>'EUR',action=>'transfer',duration=>$dri->local_object('duration','years',2)}}
 $rc=$dri->domain_check('example9.tld',{fee => $fee} );
 $price = $dri->get_info('fee');

Or

 $rc=$dri->domain_check_price('example9.tld');
 $dri->get_info('is_premium');
 $dri->get_info('price_currency');
 $dri->get_info('create_price'); // renew_price / transfer_price / restore_price



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
  my %s=(
    'connect' => [ undef, \&parse_greeting ],
    'noop'    => [ undef, \&parse_greeting ],
  );

  my %d=(
            info  => [ \&info, \&info_parse ], # Info command support dropped in draft-05 (-0.8)
            check => [ \&check, \&check_parse ],
            transfer_query => [ undef, \&transform_parse], ## does not add any elements to the command but does include elements in the response
            create => [ \&create, \&transform_parse ], ## extension adds elements to both the EPP <create> command and response
            delete => [ undef, \&transform_parse ],  ## extension does not add elements to the EPP <delete> command but does include elements in the response
            renew => [ \&renew, \&transform_parse ], ## extension adds elements to both the EPP <renew> command and response
            transfer_request => [ \&transfer, \&transform_parse ], ## extension adds elements to both the EPP <transfer> command and response when the value of the "op" attribute of the <transfer> command element is "request"
            update => [ \&update, \&transform_parse ], ## extension adds elements to both the EPP <renew> command and response
          );
  # check multiple domains...
  $d{check_multi}=$d{check};
  return { 'domain' => \%d, 'session' => \%s };
}

sub setup
{
  my ($class,$po,$version)=@_;
  # update from 0.4 - 0.5 has big changes, so lets default to 0.5 unless specified.
  # This means any commands called before greeting will use that version until its bumped to highest version
  my $v = (exists $po->{brown_fee_version} && $po->{brown_fee_version} =~ m/^\d.(\d+)$/) ? $po->{brown_fee_version} : '0.5';
  $po->ns({ 'fee' => [ 'urn:ietf:params:xml:ns:fee-'.$v,'fee-'.$v.'.xsd' ] });
  $po->capabilities('domain_update','fee',['set']);
  return;
}

####################################################################################################
### DEVELOPING
## Please run t/621centralnic_epp.t, t/678mam_epp.t and t/693crr_epp.t as they use different versions of the extension!
####################################################################################################

## parse_greeting to determine extension version from server
sub parse_greeting
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless defined $mes->node_greeting();
 eval { $po->switch_to_highest_namespace_version('fee'); }; # dont crash if server hasn't announced
}

## returns an integer for easier comparisons
sub ver { my ($mes)= @_; my ($ver)=($mes->ns('fee')=~m/-\d.(\d+)$/); return $ver; }

####################################################################################################
## 0.11 stuff

sub fee_set_build_11
{
  my ($rp)=@_;
  Net::DRI::Exception::usererr_insufficient_parameters('For "fee" key parameter the value must be a ref hash with key action, and optionally currency and duration') unless (ref $rp eq 'HASH') && Net::DRI::Util::has_key($rp,'action');
  Net::DRI::Exception::usererr_invalid_parameters('fee currency should be 3 letters ISO-4217 code') if exists $rp->{currency} && $rp->{currency} !~ m/^[A-Z]{3}$/; # No longer required field
  Net::DRI::Exception::usererr_invalid_parameters('fee action should be: create, transfer, renew or restore') if exists $rp->{action} && $rp->{action} !~ m/^(?:create|transfer|renew|restore)$/;

  my (@n,$name,$lp);
  $lp->{phase} = $rp->{phase} if exists $rp->{phase};
  $lp->{subphase} = $rp->{sub_phase} if exists $rp->{sub_phase};
  push @n,['fee:command',$lp,$rp->{action}];
  push @n,['fee:currency',$rp->{currency}] if exists $rp->{currency};

  if (exists $rp->{duration}) {
    Net::DRI::Exception::usererr_invalid_parameters('duration should be a DateTime::Duration object') unless Net::DRI::Util::is_class($rp->{duration},'DateTime::Duration');
    my $rj=Net::DRI::Protocol::EPP::Util::build_period($rp->{duration});
    push @n,['fee:period',$rj->[1],$rj->[2]];
  }
  push @n,['fee:class', $rp->{class}] if exists $rp->{class};
  return @n;
}

####################################################################################################
## Build / Parse helpers for 0.5 to 0.8

## MH: TODO: Fix this parser to ADD fees togother, but still make each fee an individual element in an array with its attributes
##           This upgrade from 0.5-0.6-0.8 works, but the extension needs to be reviewed now that we have a few different active implementations

sub fee_set_parse
{
  my ($version,$start) = @_;
  return unless $start;
  my $set = {};

  $set->{price_avail} = $start->getAttribute('avail') if $start->hasAttribute('avail'); # since 0.11
  foreach my $el (Net::DRI::Util::xml_list_children($start))
  {
    my ($name,$content)=@$el;
    if ($name eq 'name') { # 0.5 - 0.8 use <fee:name>
      $set->{'domain'} = $content->textContent();
      $set->{'premium'} = ($content->hasAttribute('premium') && Net::DRI::Util::xml_parse_boolean($content->getAttribute('premium'))) ? 1 : 0;
    }
    elsif ($name eq 'objID') # in 0.9 we can have an objId with element
    {
      my $element = $content->hasAttribute('element') ? $content->getAttribute('element') : 'name';
      $set->{'element'} = $element;
      $set->{'domain'} = $content->textContent(); # we don' support other types at the moment
      $set->{'premium'} = 0; # actually this was only in 0.6, but this sort of keeps things going in the same vain implementation wise
    }
    elsif ($name eq 'object') # in 0.11 we can have an object with element for domain:name
    {
      # TODO. This could theoretically not be a domain...
      foreach my $el2 (Net::DRI::Util::xml_list_children($content))
      {
        my ($name2,$content2)=@$el2;
        $set->{'domain'} = $content2->textContent() if $name2 eq 'name';
      }
      $set->{'premium'} = 0;
    }
    elsif ($name eq 'command')
    {
      $set->{'action'} = $content->textContent();
      $set->{'phase'} = $content->getAttribute('phase') if $content->hasAttribute('phase');
      $set->{'sub_phase'} = $content->getAttribute('subphase') if $content->hasAttribute('subphase');
    } elsif ($name eq 'currency')
    {
      $set->{'currency'} = $content->textContent();
    } elsif ($name eq 'period')
    {
      my $unit={y=>'years',m=>'months'}->{$content->getAttribute('unit')};
      $set->{'duration'} = DateTime::Duration->new($unit => 0+$content->textContent());
    } elsif ($name eq 'fee')
    # Fees are kind of loosely defined based on free text description field with refundable also possible. This will total it up and concat the description and refundable fields but its only human readable
    {
      $set->{fee} = 0 unless exists $set->{fee};
      $set->{fee} += $content->textContent();
      $set->{description} = '' unless exists $set->{description};
      if ($content->hasAttribute('description'))
      {
        $set->{description} = "\n" . $content->getAttribute('description');
        my $d = lc $content->getAttribute('description');
        $d =~ s/ /_/g;
        $d = 'early_access_fee' if $d =~ m/early_access/;
        $set->{"fee_$d"} = 0 + $content->textContent();
      }
      if ($content->hasAttribute('refundable') && $content->getAttribute('refundable') eq '1') {
        $set->{description} .= "Refundable"; #TODO remove in regext-fee (0.12?), the description shold not contain these
        $set->{refundable} = 1;
      }
      if ($content->hasAttribute('grace-period')) {
        $set->{description} .= "(Grace=>" . $content->getAttribute('grace-period') . ")"; #TODO remove in regext-fee (0.12?), the description shold not contain these
        $set->{grace_period} = $content->getAttribute('grace-period');
      }
      if ($content->hasAttribute('applied') && $content->getAttribute('applied')=~m/^(?:immediate|delayed)$/) {
        $set->{description} .= "(Applied=>" . $content->getAttribute('applied') . ")"; #TODO remove in regext-fee (0.12?), the description shold not contain these
        $set->{applied} = $content->getAttribute('applied');
      }
    } elsif ($name eq 'class')
    {
      $set->{class} = $content->textContent();
      $set->{'premium'} = 1 && $set->{class} =~ m/(premium|tier.|non-standard)/i;
    } elsif ($name eq 'reason')
    {
      $set->{reason} = $content->textContent();
    }
  }
  chomp $set->{description} if $set->{description};
  return $set;
}

sub fee_set_build
{
  my ($version,$rp,$cmd,$domain)=@_;
  Net::DRI::Exception::usererr_insufficient_parameters('For "fee" key parameter the value must be a ref hash with key action, and optionally currency and duration') unless (ref $rp eq 'HASH') && Net::DRI::Util::has_key($rp,'action');
  Net::DRI::Exception::usererr_invalid_parameters('fee currency should be 3 letters ISO-4217 code') if exists $rp->{currency} && $rp->{currency} !~ m/^[A-Z]{3}$/; # No longer required field
  Net::DRI::Exception::usererr_invalid_parameters('fee action should be: create, transfer, renew or restore') if exists $rp->{action} && $rp->{action} !~ m/^(?:create|transfer|renew|restore)$/;
  Net::DRI::Exception::usererr_invalid_parameters('fee action phase') if (exists $rp->{phase} && $rp->{phase}  !~ m/\w+/);
  Net::DRI::Exception::usererr_invalid_parameters('fee action subphase') if (exists $rp->{sub_phase} && $rp->{sub_phase}  !~ m/\w+/);

  my (@n,$name,$lp);
  $name = $rp->{domain} if exists $rp->{domain};
  $name = $domain if !$name && $domain && ref $domain ne 'ARRAY';
  $name = $domain->[0] if !$name && $domain && ref $domain eq 'ARRAY';
  if ($version eq '0.9') # 0.9 uses fee:objID
  {
    push @n,['fee:objID',$name] if $name && !$rp->{element};
    push @n,['fee:objID',{'element' => $rp->{element}}, $name] if $name && $rp->{element};
  }
  else
  {
    push @n,['fee:name',$name] if $name;
  }

  push @n,['fee:currency',$rp->{currency}] if exists $rp->{currency};

  $lp->{phase} = $rp->{phase} if exists $rp->{phase};
  $lp->{subphase} = $rp->{sub_phase} if exists $rp->{sub_phase};
  push @n, ['fee:command',$lp,$rp->{action}];

  if (exists $rp->{duration}) {
    Net::DRI::Exception::usererr_invalid_parameters('duration should be a DateTime::Duration object') unless Net::DRI::Util::is_class($rp->{duration},'DateTime::Duration');
    my $rj=Net::DRI::Protocol::EPP::Util::build_period($rp->{duration});
    push @n,['fee:period',$rj->[1],$rj->[2]];
  }

  return @n unless $cmd && $cmd eq 'check';
  # in 0.9, the default objURI is domain,but you can selct other objects but we dont support this.
  # for the purpose of proof of principle and passing the test, we will use domain objURI when the element object is also provided (which is also optional
  return ['fee:object', {'objURI' => 'urn:ietf:params:xml:ns:domain-1.0'}, @n] if $version eq '0.9' && exists $rp->{element};
  return ['fee:object', @n] if $version eq '0.9'; # 0.9
  return ['fee:domain',@n]; # for 0.5 through 0.8 if was <fee:domain>
}

####################################################################################################
## LEGACY Build / Parse helpers for 0.4


sub fee_set_parse_legacy
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

sub fee_set_build_legacy
{
  my ($rp,$domain)=@_;
  Net::DRI::Exception::usererr_insufficient_parameters('For "fee" key parameter the value must be a ref hash with keys: currency, action, duration') unless (ref $rp eq 'HASH') && Net::DRI::Util::has_key($rp,'currency') && Net::DRI::Util::has_key($rp,'action') && Net::DRI::Util::has_key($rp,'duration');
  Net::DRI::Exception::usererr_invalid_parameters('currency should be 3 letters ISO-4217 code') unless $rp->{currency}=~m/^[A-Z]{3}$/;
  Net::DRI::Exception::usererr_invalid_parameters('action should be: create, transfer, renew or restore') unless $rp->{action}=~m/^(?:create|transfer|renew|restore)$/;
  Net::DRI::Exception::usererr_invalid_parameters('fee action') unless (exists $rp->{action} && $rp->{action}  =~ m/\w+/);
  Net::DRI::Exception::usererr_invalid_parameters('fee action phase') if (exists $rp->{phase} && $rp->{phase}  !~ m/\w+/);
  Net::DRI::Exception::usererr_invalid_parameters('fee action subphase') if (exists $rp->{sub_phase} && $rp->{sub_phase}  !~ m/\w+/);

  my @n;
  if ($rp->{domain}) {
    push @n,['fee:domain',$rp->{domain}];
  }
  elsif ($domain && ref $domain ne 'ARRAY') {
    push @n,['fee:domain',$domain];
  }
  elsif ($domain) {
    push @n,['fee:domain',$domain->[0]];
  }
  push @n,['fee:currency',$rp->{currency}];

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

  return @n;

}

####################################################################################################
## Price Standardisation

sub set_premium_values {
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 return unless exists $rinfo->{domain}->{$oname}->{fee} && (ref $rinfo->{domain}->{$oname}->{fee} eq 'ARRAY');
 foreach my $ch (@{$rinfo->{domain}->{$oname}->{fee}})
 {
  $rinfo->{domain}->{$oname}->{is_premium} = $ch->{premium} unless $rinfo->{domain}->{$oname}->{is_premium};
  $rinfo->{domain}->{$oname}->{price_category} = $ch->{class};
  $rinfo->{domain}->{$oname}->{price_currency} = $ch->{currency};
  $rinfo->{domain}->{$oname}->{price_duration} = $ch->{duration};
  $rinfo->{domain}->{$oname}->{$ch->{action} .'_price'} = $ch->{fee}; # action can be create/renew/transfer/restore. extension only returns what was requested
  $rinfo->{domain}->{$oname}->{eap_price} = $ch->{fee_early_access_fee} if exists $ch->{fee_early_access_fee};
 }
 return;
}

####################################################################################################

sub check
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
  return unless Net::DRI::Util::has_key($rd,'fee');
  my $version = (($mes->ns('fee')=~m!fee-(\d\.\d+)!)) ? "$1" : '0.4';
  my (@n,@fees,@fee_set);
  @fees = ($rd->{fee}) if ref $rd->{fee} eq 'HASH';
  @fees = @{$rd->{fee}} if ref $rd->{fee} eq 'ARRAY';

  if ($version eq '0.4')
  {
   foreach my $fee_set (@fees)
   {
     @n = fee_set_build_legacy($fee_set,$domain);
     my $eid=$mes->command_extension_register('fee','check');
     $mes->command_extension($eid,\@n);
   }
  }
  elsif (ver($mes) >= 11)
  {
   my $eid=$mes->command_extension_register('fee','check');
   $mes->command_extension($eid, [fee_set_build_11($fees[0])]);
  }
  else # 0.5+
  {
   foreach my $fee_set (@fees)
   {
     @n = fee_set_build($version, $fee_set,'check',$domain);
     push @fee_set,@n if @n;
   }
   return unless @fee_set;
   my $eid=$mes->command_extension_register('fee','check');
   $mes->command_extension($eid,\@fee_set);
  }
  return;

}

sub check_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success;
  my $version = (($mes->ns('fee')=~m!fee-(\d\.\d+)!)) ? "$1" : '0.4';

  my $chkdata=$mes->node_extension if ($version eq '0.4');
  $chkdata=$mes->get_extension($mes->ns('fee'),'chkData') if ($version eq '0.5' || $version eq '0.6' || $version eq '0.7' || $version eq '0.8' || $version eq '0.9' || $version eq '0.11');
  return unless defined $chkdata;

  foreach my $el (Net::DRI::Util::xml_list_children($chkdata))
  {
    my ($name,$content)=@$el;
    if ($name =~ m/^(chkData|cd)$/) # chkData for 0.4, cd for 0.5 & 0.6 & 0.7 & 0.8
    {
      my $dn = '';
      if ($version eq '0.11') {
       $dn = Net::DRI::Util::xml_traverse($content, $mes->ns('fee'), qw/object name/);
       $dn = $dn->textContent() if defined $dn;
      } else {
       foreach my $el2 (Net::DRI::Util::xml_list_children($content))
       {
         my ($name2,$content2)=@$el2;
         $dn = $content2->textContent() if $name2 =~ m/^(domain|name|objID)$/; # domain for 0.4, name for 0.5 & 0.6 & 0.7 & 0.8, and objID for 0.9
       }
      }
      next unless $dn;
      my $fee_set = ($version eq '0.4') ? fee_set_parse_legacy($content) : fee_set_parse($version, $content);
      if ($fee_set)
      {
        push @{$rinfo->{domain}->{$dn}->{fee}},$fee_set;
        set_premium_values($po,$otype,$oaction,$dn,$rinfo);
      }
    }
  }
  return;
}

sub info
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
  return unless Net::DRI::Util::has_key($rd,'fee');
  my $version = (($mes->ns('fee')=~m!fee-(\d\.\d+)!)) ? "$1" : '0.4';
  return unless $version+0 < 0.9; # as of 0.6 (draft -05) info is no longer supported. Returning an exception will do more harm then good, so just ignore

  my (@n,@fees);
  @fees = ($rd->{fee}) if ref $rd->{fee} eq 'HASH';
  @fees = @{$rd->{fee}} if ref $rd->{fee} eq 'ARRAY';
  foreach my $fee_set (@fees)
  {
    @n = fee_set_build_legacy($fee_set) if ($version eq '0.4');
    @n = fee_set_build($version, $fee_set) if ($version ne '0.4');
    my $eid=$mes->command_extension_register('fee','info');
    $mes->command_extension($eid,\@n);
  }
  return;
}

sub info_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  my $version = (($mes->ns('fee')=~m!fee-(\d\.\d+)!)) ? "$1" : '0.4';

  my $infdata=$mes->get_extension($mes->ns('fee'),'infData');
  return unless defined $infdata;

  my $fee_set = fee_set_parse_legacy($infdata) if ($version eq '0.4');
  $fee_set = fee_set_parse($version, $infdata) if ($version ne '0.4');
  if ($fee_set)
  {
    @{$rinfo->{domain}->{$oname}->{fee}} = $fee_set;
    set_premium_values($po,$otype,$oaction,$oname,$rinfo);
  }
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
      if ($name eq 'currency')
      {
        $p{'currency'}=$content->textContent();
      } elsif ($name =~ m/^(fee|balance|creditLimit)/)
      {
        my $k= ($1 eq 'creditLimit') ? 'credit_limit' : $1;
        $p{$k}=0+$content->textContent();
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
  my $version = (($mes->ns('fee')=~m!fee-(\d\.\d+)!)) ? "$1" : '0.4';

  Net::DRI::Exception::usererr_insufficient_parameters('For "fee" key parameter the value must be a ref hash with keys: currency, fee') unless Net::DRI::Util::has_key($rd->{fee},'currency') && Net::DRI::Util::has_key($rd->{fee},'fee');
  my $rp=$rd->{fee};
  Net::DRI::Exception::usererr_invalid_parameters('currency should be 3 letters ISO-4217 code') unless $rp->{currency}=~m/^[A-Z]{3}$/;

  my @n;
  $rp = ref $rd->{fee} eq 'ARRAY' ? $rd->{fee}->[0] : $rd->{fee};
  push @n,['fee:currency',$rp->{currency}];
  push @n,['fee:fee',$rp->{fee}];

  my $eid=$mes->command_extension_register('fee',$cmd);
  $mes->command_extension($eid,\@n);
  return;
}

sub create { return transform_build(@_,'create'); }
sub renew { return transform_build(@_,'renew'); }
sub transfer { return transform_build(@_,'transfer'); }

sub update
{
  my ($epp,$domain,$todo)=@_;
  return unless my $ch=$todo->set('fee');
  return transform_build($epp,$domain,{'fee' => $ch},'update');
}

####################################################################################################
1;
