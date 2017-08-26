## Domain Registry Interface, CentralNic EPP Fee extension
##
## Copyright (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Fee;

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

Net::DRI::Protocol::EPP::Extensions::Fee - RegExt EPP Fee extension commands for Net::DRI

=head1 DESCRIPTION

Adds the Regext EPP Fee Extension. Previously, this was CentralNIC::Fee (draft-brown-epp-fees-07), but this this module is for draft-ietf-regext-epp-fees-XX

Fee extension is defined in https://tools.ietf.org/html/draft-ietf-regext-epp-fees-00

=item currency* (3 letter currency code)

=item action* (create, transfer, renew or restore)

=item duration* (Datetime::Duration)

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
            #info  => [ \&info, \&info_parse ], # Info command support dropped in draft-05 (-0.8)
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
  # This means any commands called before greeting will use that version until its bumped to highest version
  my $v = $po->{brown_fee_version} // $po->{fee_version};
  print "loading version: $v\n";
  $v = '0.11' unless defined $v && $v =~ m/^\d.(\d+)$/;
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

## returns fee extension version number from a $mes for easy comparisons
sub ver {
 my ($mes)= @_;
 my ($ver)=($mes->ns('fee')=~m/-\d.(\d+)$/);
 return $ver;
}

####################################################################################################
## Build / Parse helpers for fee-0.11

sub fee_set_build
{
  my ($version,$rp)=@_;
  Net::DRI::Exception::usererr_insufficient_parameters('For "fee" key parameter the value must be a ref hash with key command, and optionally currency and duration') unless (ref $rp eq 'HASH') && (Net::DRI::Util::has_key($rp,'command') || Net::DRI::Util::has_key($rp,'action'));
  Net::DRI::Exception::usererr_invalid_parameters('fee currency should be 3 letters ISO-4217 code') if exists $rp->{currency} && $rp->{currency} !~ m/^[A-Z]{3}$/; # No longer required field
  Net::DRI::Exception::usererr_invalid_parameters('fee action should be: create, transfer, renew or restore') if exists $rp->{action} && $rp->{action} !~ m/^(?:create|transfer|renew|restore)$/;

  my (@n,$name,$lp);
  $lp->{phase} = $rp->{phase} if exists $rp->{phase};
  $lp->{subphase} = $rp->{sub_phase} if exists $rp->{sub_phase};
  if ($version == 11) {
    push @n,['fee:command',$lp,$rp->{action}];
    push @n,['fee:currency',$rp->{currency}] if exists $rp->{currency};
    if (exists $rp->{duration}) {
      Net::DRI::Exception::usererr_invalid_parameters('duration should be a DateTime::Duration object') unless Net::DRI::Util::is_class($rp->{duration},'DateTime::Duration');
      my $rj=Net::DRI::Protocol::EPP::Util::build_period($rp->{duration});
      push @n,['fee:period',$rj->[1],$rj->[2]];
    }
    push @n,['fee:class', $rp->{class}] if exists $rp->{class};
  }

  # !! somehow this all works. it could do with a cleanup and half, but it builds compatible domain_check commands (see fee-0.21.t)
  if ($version >= 21) {
    push @n,['fee:currency',$rp->{currency}] if exists $rp->{currency};
    my @commands = ($rp->{command} // $rp->{action}); # backwards compatible?

    foreach (@commands)
    {
      print ref $_ . "\n\n";
      if (ref $_ eq 'ARRAY')
      {
        foreach my $ar (@$_)
        {
          if (ref $ar eq 'HASH') {
            my $valid = {};
            foreach my $k (qw/name phase subphase/) {
              $valid->{$k} = $ar->{$k} if defined $ar->{$k};
            }
            if (exists $ar->{duration}) {
              Net::DRI::Exception::usererr_invalid_parameters('duration should be a DateTime::Duration object') unless Net::DRI::Util::is_class($ar->{duration},'DateTime::Duration');
              my $rj=Net::DRI::Protocol::EPP::Util::build_period($ar->{duration});
              push @n,['fee:command',$valid,['fee:period',$rj->[1],$rj->[2]]];
            } else {
              push @n,['fee:command',$valid];
            }
          } else {
            push @n,['fee:command',{name => $ar}];
          }
        }
      } else {
        push @n,['fee:command',{name => $_}];
      }
    }
  }

  return @n;
}

## MH: TODO: Fix this parser to ADD fees togother, but still make each fee an individual element in an array with its attributes
sub fee_element_parse
{
  my ($version,$content,$set) = @_;
  return unless $content;
  # Fees are kind of loosely defined based on free text description field with refundable also possible. This will total it up and concat the description and refundable fields but its only human readable
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
  #chomp $set->{description};
  return;
}

sub fee_set_parse
{
  my ($version,$start) = @_;
  return unless $start;
  my $set = {};

  $set->{price_avail} = $start->getAttribute('avail') if $start->hasAttribute('avail'); # since 0.11
  $set->{'premium'} = 0; # assume this unless we know better
  foreach my $el (Net::DRI::Util::xml_list_children($start))
  {
    my ($name,$content)=@$el;

    # Version 0.21+
    if ($name eq 'objID')
    {
      $set->{'domain'} = $content->textContent();
    } elsif ($name eq 'command' && $version >= 21)
    {
      my $cmd = $content->getAttribute('name') if $content->hasAttribute('name');
      $set->{command}->{$cmd} = {};
      $set->{'phase'} = $content->getAttribute('phase') if $content->hasAttribute('phase');
      $set->{'subphase'} = $content->getAttribute('subphase') if $content->hasAttribute('subphase');
      foreach my $el2 (Net::DRI::Util::xml_list_children($content))
      {
        my ($name2,$content2)=@$el2;
        if ($name2 eq 'period')
        {
          my $unit={y=>'years', m=>'months'}->{$content2->getAttribute('unit')};
          $set->{command}->{$cmd}->{'duration'} = DateTime::Duration->new($unit => 0+$content2->textContent());
        } elsif ($name2 eq 'reason')
        {
          $set->{reason} = $content2->textContent();
        } elsif ($name2 eq 'fee')
        {
          fee_element_parse($version,$content2,$set->{command}->{$cmd});

        }
      }

    # Version 0.11+
    } elsif ($name eq 'object')
    {
      # TODO. This could theoretically not be a domain...
      foreach my $el2 (Net::DRI::Util::xml_list_children($content))
      {
        my ($name2,$content2)=@$el2;
        $set->{'domain'} = $content2->textContent() if $name2 eq 'name';
      }
    } elsif ($name eq 'command' && $version == 11)
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
    {
      fee_element_parse($version,$content,$set);
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
  #print Dumper $set;
  return $set;
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
  $rinfo->{domain}->{$oname}->{$ch->{action} .'_price'} = $ch->{fee} if $ch->{action}; # action can be create/renew/transfer/restore. extension only returns what was requested
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

  my (@n,@fees,@fee_set);
  @fees = ($rd->{fee}) if ref $rd->{fee} eq 'HASH';
  @fees = @{$rd->{fee}} if ref $rd->{fee} eq 'ARRAY';

  my $eid=$mes->command_extension_register('fee','check');
  $mes->command_extension($eid, [fee_set_build(ver($mes),$fees[0])]);

  return;

}

sub check_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success;
  my $version = ver($mes);

  my $chkdata = $mes->get_extension($mes->ns('fee'),'chkData');
  return unless defined $chkdata;

  my ($currency);
  foreach my $el (Net::DRI::Util::xml_list_children($chkdata))
  {
    my ($name,$content)=@$el;
    if ($name eq 'currency') { # its here in 21, same currency across all
      $currency = $content->textContent();
    } elsif ($name =~ m/^cd$/)
    {
      my $dn = Net::DRI::Util::xml_traverse($content, $mes->ns('fee'), qw/object name/) if ($version == 11);
      $dn = Net::DRI::Util::xml_traverse($content, $mes->ns('fee'), qw/objID/) if ($version == 21);
      $dn = $dn->textContent() if defined $dn;
      my $fee_set = fee_set_parse($version,$content);
      if ($fee_set)
      {
        $fee_set->{'currency'} = $currency if defined $currency;
        push @{$rinfo->{domain}->{$dn}->{fee}},$fee_set;
        set_premium_values($po,$otype,$oaction,$dn,$rinfo);
      }
    }
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
      } elsif ($name =~ m/^(fee|balance|creditLimit|credit)/)
      {
        my $k= ($1 eq 'creditLimit') ? 'credit_limit' : $1;
        $p{$k}=0+$content->textContent();
        $p{'description'} = $content->getAttribute('description') if $content->hasAttribute('description');
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
