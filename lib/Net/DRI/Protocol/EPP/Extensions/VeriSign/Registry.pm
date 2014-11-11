## Domain Registry Interface, VeriSign EPP Registry Zone Command Extension
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::Registry;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::Registry - VeriSign EPP Registry zone extension commands for Net::DRI

=head1 DESCRIPTION

Add a Domain Name Registry Mapping, referred to as Registry Mapping, for the Extensible Protocol EPP [RFC5730]. A Domain Name Registry can service one or more zones (e.g. top-level domains). This extension enables the provisioning of the zones in the Domain Name Registry. A Domain Name Registry MAY support a subset of all of the commands defined in this mapping.

VeriSign Registry extension is defined in http://www.verisigninc.com/assets/epp-sdk/verisign_epp-extension_premium-domain_v00.html

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>.
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
            check       => [ \&check, \&check_parse ],
            create      => [ \&create, \&transform_parse ],
            delete      => [ \&delete, undef ],
            info        => [ \&info, \&transform_parse ],
            update      => [ \&update, undef ],
  );
  $tmp{check_multi}=$tmp{check}; # check multiple domains
  return { 'registry' => \%tmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->ns({ 'registry' => [ 'http://www.verisign.com/epp/registry-1.0','registry-1.0.xsd' ] });
 $po->capabilities('domain_update','charge',['set']);
}

####################################################################################################

sub check
{
  my ($epp,$registry,$rd)=@_;
  my $mes=$epp->message();
  my @r=registry_build_command($mes,'check',$registry);
  $mes->command_body(\@r);
  return;
}


sub check_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  my $chkdata=$mes->get_response('registry','chkData');
  return unless defined $chkdata;

  foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('registry'),'cd'))
  {
    my $registry;
    foreach my $el (Net::DRI::Util::xml_list_children($cd))
    {
      my ($n,$c)=@$el;
      if ($n eq 'name')
      {
        $registry=lc($c->textContent());
        $rinfo->{registry}->{$registry}->{action}='check';
        $rinfo->{registry}->{$registry}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
      } elsif ($n eq 'reason')
      {
        $rinfo->{registry}->{$registry}->{reason}=$c->textContent();
      }
    }
  }
  return;
}


sub info
{
  my ($epp,$registry,$rd)=@_;
  my $mes=$epp->message();
  my @d=registry_build_command($mes,'info',$registry);
  $mes->command_body(\@d);
  return;
}

sub create
{
  transform_build(@_,'create');
}


sub delete
{
  transform_build(@_,undef,'delete');
}


sub update
{
  transform_build(@_,'update');
}


sub transform_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  my (@rel);
  my $resdata;
  foreach my $res (qw/infData creData/)
  {
    next unless $resdata=$mes->get_response($mes->ns('registry'),$res);
    my %p;
    my @registry_phase;
    foreach my $el (Net::DRI::Util::xml_list_children($resdata))
    {
      my ($n,$c)=@$el;
      if ($n eq 'zone')
      {
        foreach my $el2 (Net::DRI::Util::xml_list_children($c))
        {
          my ($n2,$c2)=@$el2;
          $rinfo->{registry}->{$oname}->{$n2}=$c2->textContent() if $n2 =~ m/^(name|group|subProduct|crID|upID)$/; # plain text
          $rinfo->{registry}->{$oname}->{$n2}=$po->parse_iso8601($c2->textContent()) if $n2 =~ m/^(crDate|upDate)$/; # dates
          if ($n2 eq 'related')
          {
            $rinfo->{registry}->{$oname}->{$n2}=_parse_related($po,$otype,$oaction,$oname,$rinfo,$c2);
          }
          elsif ($n2 eq 'phase')
          {
            push @registry_phase,_parse_phase($po,$otype,$oaction,$oname,$rinfo,$c2);
            $rinfo->{registry}->{$oname}->{$n2}=\@registry_phase;
          }
          elsif ($n2 eq 'services')
          {
            $rinfo->{registry}->{$oname}->{$n2}=_parse_services($po,$otype,$oaction,$oname,$rinfo,$c2);
          }
          elsif ($n2 eq 'slaInfo')
          {
            $rinfo->{registry}->{$oname}->{$n2}=_parse_slainfo($po,$otype,$oaction,$oname,$rinfo,$c2);
          }
          elsif ($n2 eq 'domain')
          {
            $rinfo->{registry}->{$oname}->{$n2}=_parse_domain($po,$otype,$oaction,$oname,$rinfo,$c2);
          }
          elsif ($n2 eq 'host')
          {
            $rinfo->{registry}->{$oname}->{$n2}=_parse_host($po,$otype,$oaction,$oname,$rinfo,$c2);
          }
          elsif ($n2 eq 'contact')
          {
            $rinfo->{registry}->{$oname}->{$n2}=_parse_contact($po,$otype,$oaction,$oname,$rinfo,$c2);
          }
        }
      }
      elsif ($n eq 'zoneList')
      {
        foreach my $el2 (Net::DRI::Util::xml_list_children($c))
        {
          my ($n2,$c2)=@$el2;
          my @zone=();
          if ($n2 eq 'zone')
          {
            foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
            {
              my ($n3,$c3)=@$el3;
              my $name=$c3->textContent() if $n3 eq 'name';
              push @zone,$name;
              $rinfo->{registry}->{$zone[0]}->{$n3}=$c3->textContent() if $n3 =~ m/^(name)$/; # plain text
              $rinfo->{registry}->{$zone[0]}->{$n3}=$po->parse_iso8601($c3->textContent()) if $n3 =~ m/^(crDate|upDate)$/; # dates
            }
          }
        }
      }
      $rinfo->{registry}->{$oname}->{$n}=$c->textContent() if $n eq 'name';
      $rinfo->{registry}->{$oname}->{$n}=$po->parse_iso8601($c->textContent()) if $n eq 'crDate';
    }
  }
  return;
}

# TODO: protect date fields with date and implement attr restrictions...
sub transform_build
{
  my ($epp,$registry,$rd,$cmd)=@_;
  my $mes=$epp->message();
  my @r=registry_build_command($mes,$cmd,$registry);
  push @r,['registry:group',$rd->{group}] if defined $rd->{group};
  push @r,['registry:subProduct',$rd->{sub_product}] if defined $rd->{sub_product};
  push @r, _build_related($rd->{related}) if defined $rd->{related};
  push @r, _build_phase($rd->{phase}) if defined $rd->{phase}; # FIXME: registry:phase attributes type and name switching if name exists...
  push @r, _build_service($rd->{service}) if defined $rd->{service};
  push @r, _build_slainfo($rd->{sla_info}) if defined $rd->{sla_info};
  push @r,['registry:crID',$rd->{cr_id}] if defined $rd->{cr_id};
  push @r,['registry:crDate',$rd->{cr_date}] if defined $rd->{cr_date};
  push @r,['registry:upID',$rd->{up_id}] if defined $rd->{up_id};
  push @r,['registry:upDate',$rd->{up_date}] if defined $rd->{up_date}; 
  push @r,_build_domain($rd->{domain}) if defined $rd->{domain};
  push @r,_build_host($rd->{host}) if defined $rd->{host};
  push @r,_build_contact($rd->{contact}) if defined $rd->{contact};

  @r=['registry:zone',@r] if $cmd =~ m/^(create|update)$/; # add xml zone node

  $mes->command_body(\@r);
  return;
}


####################################################################################################
########### Parse Helpers
sub _parse_related
{
  my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
  my $mes=$po->message();
  return unless $root;
  my $r={};
  my (@fields_field,@zone_member_type,@zone_member_name);
  foreach my $el (Net::DRI::Util::xml_list_children($root))
  {
    my ($n,$c)=@$el;
    if ($n eq 'fields')
    {
      $r->{fields_type} = $c->getAttribute('type') if ($c->hasAttribute('type') && $c->getAttribute('type') =~ m/^(shared|sync)$/);
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        push @fields_field,$c2->textContent() if $n2 eq 'field';
      }
    }
    elsif ($n eq 'zoneMember')
    {
      #$r->{type} = $c->getAttribute('type') if ($c->hasAttribute('type') && $c->getAttribute('type') =~ m/^(primary|alternate|primaryBasedOnCrDate|equal)$/);
      #$r->{zone_member} = $c->textContent() if $n eq 'zoneMember';
      push @zone_member_type,$c->getAttribute('type') if ($c->hasAttribute('type') && $c->getAttribute('type') =~ m/^(primary|alternate|primaryBasedOnCrDate|equal)$/);
      push @zone_member_name,$c->textContent() if $n eq 'zoneMember';
    }
  }
  $r->{fields} = \@fields_field if @fields_field;
  $r->{zone_member_type} = \@zone_member_type if @zone_member_type;
  $r->{zone_member_name} = \@zone_member_name if @zone_member_name;
  return $r;
}


sub _parse_phase
{
  my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
  my $mes=$po->message();
  return unless $root;
  my $p={};
  $p->{phase_type_attr} = $root->getAttribute('type') if $root->hasAttribute('type');
  $p->{phase_name_attr} = $root->getAttribute('name') if $root->hasAttribute('name');
  foreach my $el (Net::DRI::Util::xml_list_children($root))
  {
    my ($n,$c)=@$el;
    $p->{start_date} = $c->textContent() if $n eq 'startDate';
    $p->{end_date} = $c->textContent() if $n eq 'endDate';
  }
  return $p;
}


sub _parse_services
{
  my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
  my $mes=$po->message();
  return unless $root;
  my $s={};
  my (@objuri_required,@objuri_name,@exturi_required,@exturi_name);
  foreach my $el (Net::DRI::Util::xml_list_children($root))
  {
    my ($n,$c)=@$el;
    if ($n eq 'objURI')
    {
      push @objuri_required,$c->getAttribute('required') if ($c->hasAttribute('required') && $c->getAttribute('required') =~ m/^(true|false)$/);
      push @objuri_name,$c->textContent() if $n eq 'objURI';
    }
    elsif ($n eq 'svcExtension')
    {
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        push @exturi_required,$c2->getAttribute('required') if ($c2->hasAttribute('required') && $c2->getAttribute('required') =~ m/^(true|false)$/);
        push @exturi_name,$c2->textContent() if $n2 eq 'extURI';
      }
    }
  }
  $s->{objuri_required} = \@objuri_required if @objuri_required;
  $s->{objuri_name} = \@objuri_name if @objuri_name;
  $s->{exturi_required} = \@exturi_required if @exturi_required;
  $s->{exturi_name} = \@exturi_name if @exturi_name;
  return $s;
}


sub _parse_slainfo
{
  my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
  my $mes=$po->message();
  return unless $root;
  my $s={};
  my (@sla_time,@sla_type,@sla_subtype,@sla_command,@sla_unit);
  foreach my $el (Net::DRI::Util::xml_list_children($root))
  {
    my ($n,$c)=@$el;
    if ($n eq 'sla')
    {
      push @sla_type,$c->getAttribute('type') if $c->hasAttribute('type');
      push @sla_subtype,$c->getAttribute('subtype') if $c->hasAttribute('subtype');
      push @sla_command,$c->getAttribute('command') if $c->hasAttribute('command');
      push @sla_unit,$c->getAttribute('unit') if $c->hasAttribute('unit');
      push @sla_time,$c->textContent();
    }
  }
  $s->{sla_type} = \@sla_type if @sla_type;
  $s->{sla_subtype} = \@sla_subtype if @sla_subtype;
  $s->{sla_command} = \@sla_command if @sla_command;
  $s->{sla_unit} = \@sla_unit if @sla_unit;
  $s->{sla_time} = \@sla_time if @sla_time;
  return $s;
}


sub _parse_domain
{
  my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
  my $mes=$po->message();
  return unless $root;
  my $d={};
  my (@dom_name,@dom_contact,@dom_period,@dom_grace_period,@dom_supported_status);
  foreach my $el (Net::DRI::Util::xml_list_children($root))
  {
    my ($n,$c)=@$el;
    if ($n eq 'domainName')
    {
      $d->{dom_level_attr} = $c->getAttribute('level') if $c->hasAttribute('level');
      my (@dom_regex);
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        $d->{dom_min_len}=$c2->textContent() if $n2 eq 'minLength';
        $d->{dom_max_len}=$c2->textContent() if $n2 eq 'maxLength';
        $d->{dom_alp_start}=$c2->textContent() if $n2 eq 'alphaNumStart';
        $d->{dom_alp_end}=$c2->textContent() if $n2 eq 'alphaNumEnd';
        $d->{dom_dns_chars}=$c2->textContent() if $n2 eq 'onlyDnsChars';
        # regex
        if ($n2 eq 'regex')
        {
          my $regex = {};
          foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
          {
            my ($n3,$c3)=@$el3;
            $regex->{$n3} = $c3->textContent() if $n3 =~ /^(expression|explanation)$/;
          }
          push @dom_regex,$regex;
        }
        @{$d->{regex}}=@dom_regex;
        # reservedNames
        if ($n2 eq 'reservedNames')
        {
          my (@res_name,@res_uri);
          foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
          {
            my ($n3,$c3)=@$el3;
            $d->{reserved_names}->{$n3} = $c3->textContent() if $n3 =~ /^(reservedName|reservedNameURI)$/;
          }
        }
      }
    }
    elsif ($n eq 'idn')
    {
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        my (@idn_lang);
        $d->{idn_idnversion}=$c2->textContent() if $n2 eq 'idnVersion';
        $d->{idn_idnaversion}=$c2->textContent() if $n2 eq 'idnaVersion';
        $d->{idn_unicodeversion}=$c2->textContent() if $n2 eq 'unicodeVersion';
        $d->{idn_encoding}=$c2->textContent() if $n2 eq 'encoding';
        $d->{idn_commingleallowed}=$c2->textContent() if $n2 eq 'commingleAllowed';
        if ($n2 eq 'language')
        {
          my $language = {};
          $d->{idn_language_attr}=$c2->getAttribute('code') if $c2->hasAttribute('code');
          foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
          {
            my ($n3,$c3)=@$el3;
            $language->{table}=$c3->textContent() if $n3 eq 'table';
            $language->{variant_strategy}=$c3->textContent() if $n3 eq 'variantStrategy';
          }
          push @idn_lang,$language;
        }
        @{$d->{idn_language}}=@idn_lang;
      }
    }
    elsif ($n eq 'premiumSupport')
    {
      $d->{premium_support} = $c->textContent() if $n eq 'premiumSupport';
    } 
    elsif ($n eq 'contactsSupported')
    {
      $d->{contacts_supported}=$c->textContent() if $n eq 'contactsSupported';
    }
    elsif ($n eq 'contact')
    {
      my $contact = {};
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        $contact->{contact_type_attr}=$c->getAttribute('type') if $c->hasAttribute('type');
        $contact->{$n2}=$c2->textContent() if $n2 =~ /^(min|max)$/;
      }
      push @dom_contact,$contact;
    }
    elsif ($n =~ /^(ns|childHost)$/)
    {
      $n = 'child_host' if $n eq 'childHost';
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        $d->{$n}->{$n2} = $c2->textContent() if $n2 =~ /^(min|max)$/;
      }
    }
    elsif ($n eq 'period')
    {
      my $period = {};
      my @dom_period_length;
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        $period->{period_command_attr} = $c->getAttribute('command') if $c->hasAttribute('command');
        my $period_length = {};
        foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
        {
          my ($n3,$c3)=@$el3;
          $period_length->{unit_attr} = $c3->getAttribute('unit') if $c3->hasAttribute('unit');
          $period_length->{$n3} = $c3->textContent() if $n3 =~ /^(min|max|default)$/;
        }
        push @dom_period_length,$period_length;
      }
      push @dom_period,[$period,\@dom_period_length];
    }
    elsif ($n eq 'transferHoldPeriod')
    {
      $d->{transfer_hold_period_attr} = $c->getAttribute('unit') if $c->hasAttribute('unit');
      $d->{transfer_hold_period} = $c->textContent() if $n eq 'transferHoldPeriod';
    }
    elsif ($n eq 'gracePeriod')
    {
      my $grace_period = {};
      $grace_period->{grace_period_command_attr} = $c->getAttribute('command') if $c->hasAttribute('command');
      $grace_period->{grace_period_unit_attr} = $c->getAttribute('unit') if $c->hasAttribute('unit');
      $grace_period->{grace_period} = $c->textContent() if $n eq 'gracePeriod';
      push @dom_grace_period,[$grace_period];
    }
    elsif ($n eq 'rgp')
    {
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        $d->{rgp}->{redemption_period_attr}=$c2->getAttribute('unit') if $c2->hasAttribute('unit');
        $d->{rgp}->{redemption_period}=$c2->textContent() if $n2 eq 'redemptionPeriod';
        $d->{rgp}->{pending_restore_attr}=$c2->getAttribute('unit') if $c2->hasAttribute('unit');
        $d->{rgp}->{pending_restore}=$c2->textContent() if $n2 eq 'pendingRestore';
        $d->{rgp}->{pending_delete_attr}=$c2->getAttribute('unit') if $c2->hasAttribute('unit');
        $d->{rgp}->{pending_delete}=$c2->textContent() if $n2 eq 'pendingDelete';
      }
    }
    elsif ($n eq 'dnssec')
    {
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        $n2 = 'ds_data_interface' if $n2 eq 'dsDataInterface';
        $n2 = 'key_data_interface' if $n2 eq 'keyDataInterface';
        $n2 = 'max_sig_life' if $n2 eq 'maxSigLife';
        foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
        {
          my ($n3,$c3)=@$el3;
          $n3 = 'digest_type' if $n3 eq 'digestType';
          $n3 = 'client_defined' if $n3 eq 'clientDefined';
          if ($n2 eq 'ds_data_interface' && $n3 =~ m/^(min|max|alg|digest_type)$/)
          {
            $d->{dnssec}->{$n2}->{$1} = $c3->textContent();
          }
          elsif ($n2 eq 'key_data_interface' && $n3 =~ m/^(min|max|alg)$/)
          {
            $d->{dnssec}->{$n2}->{$1} = $c3->textContent();
          }
          elsif ($n2 eq 'max_sig_life' && $n3 =~ m/^(client_defined|default|min|max)$/)
          {
            $d->{dnssec}->{$n2}->{$1} = $c3->textContent();
          }
        }
        $d->{dnssec}->{urgent} = $c2->textContent() if $n2 eq 'urgent';
      }
    }
    elsif ($n eq 'maxCheckDomain')
    {
      $d->{max_check_domain} = $c->textContent() if $n eq 'maxCheckDomain';
    }
    elsif ($n eq 'supportedStatus')
    {
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        my $supported_status = {};
        if ($n2 eq 'status')
        {
          $supported_status->{$n2} = $c2->textContent();
          push @dom_supported_status,$supported_status;
        }
      }
    } elsif ($n eq 'authInfoRegex')
    {
      foreach my $el2 (Net::DRI::Util::xml_list_children($c))
      {
        my ($n2,$c2)=@$el2;
        $d->{auth_info_regex}->{expression} = $c2->textContent() if $n2 eq 'expression';
      }
    }
    # TODO: <registry:clientDisclosureSupported> | <registry:supportedStatus> | <registry:transferHoldPeriod> | <registry:customData>
  }
  @{$d->{contact}}=@dom_contact;
  @{$d->{period}}=@dom_period;
  @{$d->{grace_period}}=@dom_grace_period;
  @{$d->{supported_status}}=@dom_supported_status;
  return $d;
}


sub _parse_host
{
  my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
  my $mes=$po->message();
  return unless $root;
  my (@host_name_regex,@host_supported_status);
  my $h={};
  foreach my $el (Net::DRI::Util::xml_list_children($root))
  {
    my ($n,$c)=@$el;
    foreach my $el2 (Net::DRI::Util::xml_list_children($c))
    {
      my ($n2,$c2)=@$el2;
      if ($n =~ /^(internal|external)$/)
      {
        $h->{$n}->{min_ip} = $c2->textContent() if $n2 eq 'minIP';
        $h->{$n}->{max_ip} = $c2->textContent() if $n2 eq 'maxIP';
        $h->{$n}->{share_policy} = $c2->textContent() if $n2 eq 'sharePolicy' && $c2->textContent() =~ /^(perZone|perSystem)$/;
      }
      elsif ($n eq 'nameRegex')
      {
        push @host_name_regex, $c2->textContent() if $n2 eq 'expression';
      }
      elsif ($n eq 'supportedStatus')
      {
        my $supported_status = {};
        if ($n2 eq 'status')
        {
          $supported_status->{$n2} = $c2->textContent();
          push @host_supported_status,$supported_status;
        }
      }
    }
    $h->{max_check_host} = $c->textContent() if $n eq 'maxCheckHost';
  }
  $h->{name_regex}->{expression}=\@host_name_regex;
  @{$h->{supported_status}}=@host_supported_status;
  return $h;
}


sub _parse_contact
{
  my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
  my $mes=$po->message();
  return unless $root;
  my (@contact_supported_status,@contact_email_regex);
  my $contact={};
  foreach my $el (Net::DRI::Util::xml_list_children($root))
  {
    my ($n,$c)=@$el;
    $contact->{share_policy}=$c->textContent() if $n eq 'sharePolicy' && $c->textContent() =~ /^(perZone|perSystem)$/;
    $contact->{int_support}=$c->textContent() if $n eq 'intSupport';
    $contact->{loc_support}=$c->textContent() if $n eq 'locSupport';
    $contact->{max_check_contact}=$c->textContent() if $n eq 'maxCheckContact';
    $contact->{client_disclosure_supported}=$c->textContent() if $n eq 'clientDisclosureSupported';
    $contact->{transfer_hold_period}=$c->textContent() if $n eq 'transferHoldPeriod';
    $contact->{transfer_hold_period_attr}=$c->getAttribute('unit') if ($n eq 'transferHoldPeriod' && $c->hasAttribute('unit') && $c->getAttribute('unit') =~ /^(y|m|d)$/);
    foreach my $el2 (Net::DRI::Util::xml_list_children($c))
    {
      my ($n2,$c2)=@$el2;
      if ($n eq 'contactIdRegex')
      {
        $contact->{contact_id_regex}->{expression}=$c2->textContent() if $n2 eq 'expression';
      }
      elsif ($n eq 'authInfoRegex')
      {
        $contact->{auth_info_regex}->{expression}=$c2->textContent() if $n2 eq 'expression';
      } elsif ($n eq 'supportedStatus')
      {
        my $supported_status={};
        if ($n2 eq 'status')
        {
          $supported_status->{$n2}=$c2->textContent();
          push @contact_supported_status, $supported_status;
        }
      }
      elsif ($n eq 'postalInfo')
      {
        my $email_regex={};
        foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
        {
          my ($n3,$c3)=@$el3;
          $n2 = 'voice_ext' if $n2 eq 'voiceExt';
          $n2 = 'fax_ext' if $n2 eq 'faxExt';
          if ($n2 =~ /^(name|org|voice_ext|fax_ext)$/)
          {
            $contact->{postal_info}->{$n2}->{min_length}=$c3->textContent() if $n3 eq 'minLength';
            $contact->{postal_info}->{$n2}->{max_length}=$c3->textContent() if $n3 eq 'maxLength';
          }
          elsif ($n2 eq 'emailRegex')
          {
            $email_regex->{$n3}=$c3->textContent();
            push @contact_email_regex, $email_regex;
          }
          elsif ($n2 eq 'address')
          {
            foreach my $el4 (Net::DRI::Util::xml_list_children($c3))
            {
              my ($n4,$c4)=@$el4;
              if ($n3 =~ /^(street|city|sp|pc)$/)
              {
                $contact->{postal_info}->{$n2}->{$n3}->{min_length}=$c4->textContent() if $n4 eq 'minLength';
                $contact->{postal_info}->{$n2}->{$n3}->{max_length}=$c4->textContent() if $n4 eq 'maxLength';
                $contact->{postal_info}->{$n2}->{$n3}->{min_entry}=$c4->textContent() if $n4 eq 'minEntry';
                $contact->{postal_info}->{$n2}->{$n3}->{max_entry}=$c4->textContent() if $n4 eq 'maxEntry';
              }
            }
          }
        }
        @{$contact->{postal_info}->{email_regex}}=@contact_email_regex;
        $contact->{postal_info}->{voice_required}=$c2->textContent() if $n2 eq 'voiceRequired';
      }
    }
  }
  @{$contact->{supported_status}}=@contact_supported_status;
  return $contact;
}


sub _build_related
{
  my $related = shift;
  return unless $related && ref $related eq 'ARRAY';
  my @rel;
  my @r;
  foreach my $r (@{$related})
  {
    foreach my $r2 (@{$r})
    {
      my @a_fields;
      foreach my $a (@{$r2->{fields}})
      {
        push @a_fields, ['registry:field', $a];
      }
      push @r,['registry:fields', {'type' => $r2->{fields_attr}},@a_fields] if exists $r2->{fields_attr} && $r2->{fields};
      push @r,['registry:zoneMember', {'type' => $r2->{zone_member_type_attr}},$r2->{zone_member}] if exists $r2->{zone_member_type_attr} && $r2->{zone_member};
    }
  }
  push @rel,['registry:related',@r];
  return @rel;
}

sub _build_phase
{
  my $phase = shift;
  return unless $phase && ref $phase eq 'ARRAY';
  my (@pha,@p);
  foreach my $p (@{$phase})
  {
    my ($d_start,$d_end);
    $d_start = ['registry:startDate', $p->{start_date}];
    $d_end = ['registry:endDate', $p->{end_date}] if $p->{end_date};
    @p = ($d_start,$d_end);
    push @pha,['registry:phase',{'type'=>$p->{p_type_attr}},@p] if (exists $p->{p_type_attr}) && ((not exists $p->{p_name_attr}) || ($p->{p_name_attr} eq ""));
    push @pha,['registry:phase',{'type'=>$p->{p_type_attr}, 'name'=>$p->{p_name_attr}},@p] if exists $p->{p_type_attr} && $p->{p_name_attr};
  }
  return @pha;
}

sub _build_service
{
  my $service = shift;
  return unless $service && ref $service eq 'ARRAY';
  my (@serv,@serv2,@serv3);
  my ($ext_uri, $ext_uri_attr);
  foreach my $s (@{$service})
  {
    foreach my $s2 (@{$s})
    {
      push @serv2, ['registry:objURI', {'required'=>$s2->{obj_uri_attr}},$s2->{obj_uri}] if exists $s2->{obj_uri} && $s2->{obj_uri_attr};
      foreach my $a (qw/ext_uri ext_uri_attr/)
      {
        if (exists $s2->{$a})
        {
          if ($a eq 'ext_uri')
          {
            $ext_uri = $s2->{$a};
          }
          elsif ($a eq 'ext_uri_attr')
          {
            $ext_uri_attr = $s2->{$a};
          }
        }
      }
      push @serv3, ['registry:extURI',{'required'=>$ext_uri_attr},$ext_uri] if exists $s2->{ext_uri} && $s2->{ext_uri_attr};
    }
  }
  push @serv2, ['registry:svcExtension',@serv3];
  return @serv, ['registry:services',@serv2];
}

sub _build_slainfo
{
  my $slainfo = shift;
  return unless $slainfo && ref $slainfo eq 'ARRAY';
  my (@sla,@sla2);
  foreach my $s (@{$slainfo})
  {
    if (exists $s->{sla_type_attr} && $s->{sla_subtype_attr} && $s->{sla_command_attr} && $s->{sla_unit_attr})
    {
      push @sla2, ['registry:sla', {'type'=>$s->{sla_type_attr}, 'subtype'=>$s->{sla_subtype_attr}, 'command'=>$s->{sla_command_attr}, 'unit'=>$s->{sla_unit_attr}}, $s->{sla}];
    }
    elsif (exists $s->{sla_type_attr} && $s->{sla_subtype_attr} && $s->{sla_command_attr})
    {
      push @sla2, ['registry:sla', {'type'=>$s->{sla_type_attr}, 'subtype'=>$s->{sla_subtype_attr}, 'command'=>$s->{sla_command_attr}}, $s->{sla}];
    }
    elsif (exists $s->{sla_type_attr} && $s->{sla_subtype_attr})
    {
      push @sla2, ['registry:sla', {'type'=>$s->{sla_type_attr}, 'subtype'=>$s->{sla_subtype_attr}}, $s->{sla}];
    }
    elsif (exists $s->{sla_type_attr} && $s->{sla_command_attr} && $s->{sla_unit_attr})
    {
      push @sla2, ['registry:sla', {'type'=>$s->{sla_type_attr}, 'command'=>$s->{sla_command_attr}, 'unit'=>$s->{sla_unit_attr}}, $s->{sla}];
    }
    elsif (exists $s->{sla_type_attr} && $s->{sla_command_attr})
    {
      push @sla2, ['registry:sla', {'type'=>$s->{sla_type_attr}, 'command'=>$s->{sla_command_attr}}, $s->{sla}];
    }
    elsif (exists $s->{sla_type_attr} && $s->{sla_unit_attr})
    {
      push @sla2, ['registry:sla', {'type'=>$s->{sla_type_attr}, 'unit'=>$s->{sla_unit_attr}}, $s->{sla}];
    }
    else
    {
      push @sla2, ['registry:sla', {'type'=>$s->{sla_type_attr}}, $s->{sla}];
    }
  }
  return @sla, ['registry:slaInfo',@sla2];
}

sub _build_domain
{
  my $domain = shift;
  return unless $domain && ref $domain eq 'ARRAY';
  my @domain;
  foreach my $d (@{$domain})
  {
    push @domain, __build_domain_name($d->{dom_name}) if $d->{dom_name};
    push @domain, __build_domain_idn($d->{dom_idn}) if $d->{dom_idn};
    push @domain, ['registry:premiumSupport', $d->{dom_premium_support}] if $d->{dom_premium_support};
    push @domain, ['registry:contactsSupported', $d->{dom_contacts_supported}] if $d->{dom_contacts_supported};
    push @domain, __build_domain_contact($d->{dom_contact}) if $d->{dom_contact};
    push @domain, __build_domain_ns($d->{dom_ns}) if $d->{dom_ns};
    push @domain, __build_domain_child_host($d->{dom_child_host}) if $d->{dom_child_host};
    push @domain, __build_domain_period($d->{dom_period}) if $d->{dom_period};
    push @domain, __build_domain_transfer_hold_period($d->{dom_transfer_hold_period}) if $d->{dom_transfer_hold_period};
    push @domain, __build_domain_grace_period($d->{dom_grace_period}) if $d->{dom_grace_period};
    push @domain, __build_domain_rgp($d->{dom_rgp}) if $d->{dom_rgp};
    push @domain, __build_domain_dnssec($d->{dom_dnssec}) if $d->{dom_dnssec};
    push @domain, ['registry:maxCheckDomain', $d->{dom_max_check_domain}] if $d->{dom_max_check_domain};
    push @domain, build_supported_status($d->{dom_supported_status}) if $d->{dom_supported_status};
    push @domain, __build_domain_auth_info_regex($d->{dom_auth_info_regex}) if $d->{dom_auth_info_regex};
    # TODO: domain <registry:customData> - an example would be very helpful...
  }
  @domain = ['registry:domain',@domain];
  return @domain;
}

sub _build_host
{
  my $host = shift;
  return unless $host && ref $host eq 'ARRAY';
  my @host;
  foreach my $h (@{$host})
  {
    push @host, __build_host_ip($h->{host_internal},'internal') if $h->{host_internal};
    push @host, __build_host_ip($h->{host_external},'external') if $h->{host_external};
    push @host, build_regex_type_multi($h->{host_name_regex},'nameRegex') if $h->{host_name_regex};
    push @host, ['registry:maxCheckHost', $h->{host_max_check_host}];
    push @host, build_supported_status($h->{host_supported_status}) if $h->{host_supported_status};
    # TODO: host <registry:customData> - an example would be very helpful...
  }
  @host = ['registry:host',@host];
  return @host;
}

sub _build_contact
{
  my $contact = shift;
  return unless $contact && ref $contact eq 'ARRAY';
  my @contact;
  foreach my $c (@{$contact})
  {
    push @contact, build_regex_type($c->{contact_id_regex},'contactIdRegex') if $c->{contact_id_regex};
    Net::DRI::Exception::usererr_invalid_parameters('sharePolicy values need to be: perZone or perSystem') unless ( $c->{contact_share_policy} =~ m/^(perZone|perSystem)$/ );
    push @contact, ['registry:sharePolicy',$c->{contact_share_policy}] if $c->{contact_share_policy};
    push @contact, ['registry:intSupport',$c->{contact_int_support}] if $c->{contact_int_support};
    push @contact, ['registry:locSupport',$c->{contact_loc_support}] if $c->{contact_loc_support};
    push @contact, __build_contact_postal_info($c->{contact_postal_info}) if $c->{contact_postal_info};
    push @contact, ['registry:maxCheckContact',$c->{contact_max_check_contact}] if $c->{contact_max_check_contact};
    push @contact, build_regex_type($c->{contact_auth_info_regex},'authInfoRegex') if $c->{contact_auth_info_regex};
    push @contact, ['registry:clientDisclosureSupported',$c->{contact_client_disclosure_supported}] if $c->{contact_client_disclosure_supported};
    push @contact, build_supported_status($c->{contact_supported_status}) if $c->{contact_supported_status};
    if ($c->{contact_transfer_hold_period})
    {
      Net::DRI::Exception::usererr_invalid_parameters('transferHoldPeriod attribute need to be: y(year), m(month), d(day)') unless ( $c->{contact_transfer_hold_period_attr} =~ m/^(y|m|d)$/ );
      push @contact, ['registry:transferHoldPeriod',{ 'unit'=>$c->{contact_transfer_hold_period_attr} }, $c->{contact_transfer_hold_period}];
    }
    # TODO: contact <registry:customData> - an example would be very helpful...
  }
  @contact = ['registry:contact',@contact];
  return @contact;
}

sub __build_domain_name
{
  my $domain_name = shift;
  return unless $domain_name;
  my (@domain_name,@regex_expression,@regex_explanation,@reserved_name);
  my ($reserved_name,$reserved_name_uri);
  Net::DRI::Exception::usererr_invalid_parameters('domainName type attribute should be 2 or higher') if $domain_name->{dom_level_attr} < 2;
  push @domain_name, ['registry:minLength', $domain_name->{dom_min_len}] if $domain_name->{dom_min_len};
  push @domain_name, ['registry:maxLength', $domain_name->{dom_max_len}] if $domain_name->{dom_max_len};
  push @domain_name, ['registry:alphaNumStart', $domain_name->{dom_alp_start}] if $domain_name->{dom_alp_start};
  push @domain_name, ['registry:alphaNumEnd', $domain_name->{dom_alp_end}] if $domain_name->{dom_alp_end};
  push @domain_name, ['registry:onlyDnsChars', $domain_name->{dom_dns_chars}] if $domain_name->{dom_dns_chars};
  foreach my $r (@{$domain_name->{dom_regex}})
  {
    my ($regex_expression,$regex_explanation);
    $regex_expression = ['registry:expression', $r->{expression}];
    if ($r->{explanation} && $r->{explanation_lang_attr})
    {
      $regex_explanation = ['registry:explanation', {'lang'=>$r->{explanation_lang_attr}}, $r->{explanation}] if $r->{explanation};
    } elsif ($r->{explanation})
    {
      $regex_explanation = ['registry:explanation', $r->{explanation}] if $r->{explanation};
    }
    push @domain_name, ['registry:regex', $regex_expression, $regex_explanation];
  }
  foreach my $r (@{$domain_name->{dom_reserved_names}})
  {
    push @reserved_name, ['registry:reservedName', $r->{reserved_name}] if $r->{reserved_name};
    $reserved_name_uri = ['registry:reservedNameURI', $r->{reserved_name_uri}] if $r->{reserved_name_uri};
  }
  push @domain_name, ['registry:reservedNames', @reserved_name, $reserved_name_uri];
  @domain_name = ['registry:domainName', {'level'=>$domain_name->{dom_level_attr}}, @domain_name];
  return @domain_name;
}

sub __build_domain_idn
{
  my $domain_idn = shift;
  return unless $domain_idn;
  my (@domain_idn,@domain_idn2);
  push @domain_idn, ['registry:idnVersion', $domain_idn->{idn_version}] if $domain_idn->{idn_version};
  push @domain_idn, ['registry:idnaVersion', $domain_idn->{idna_version}] if $domain_idn->{idna_version};
  push @domain_idn, ['registry:unicodeVersion', $domain_idn->{unicode_version}] if $domain_idn->{unicode_version};
  push @domain_idn, ['registry:encoding', $domain_idn->{encoding}] if $domain_idn->{encoding};
  push @domain_idn, ['registry:commingleAllowed', $domain_idn->{commingle_allowed}] if $domain_idn->{commingle_allowed};
  foreach my $l (@{$domain_idn->{language}})
  {
    my ($code,$table,$strategy);
    Net::DRI::Exception::usererr_invalid_parameters('idn code attribute needs to be: blocked, restricted or open') unless $l->{idn_reg_variant_strategy} =~ m/^(blocked|restricted|open)$/;
    $code = $l->{idn_code_attr};
    $table = ['registry:table', $l->{idn_reg_table}] if $l->{idn_reg_table};
    $strategy = ['registry:variantStrategy', $l->{idn_reg_variant_strategy}] if $l->{idn_reg_variant_strategy};
    push @domain_idn, ['registry:language', {'code'=>$code}, $table, $strategy];
  }
  @domain_idn = ['registry:idn', @domain_idn];
  return @domain_idn;
}

sub __build_domain_contact
{
  my $domain_contact = shift;
  return unless $domain_contact && ref $domain_contact eq 'ARRAY';
  my (@domain_contact,@c);
  foreach my $c (@{$domain_contact})
  {
    my ($c_min,$c_max);
    Net::DRI::Exception::usererr_invalid_parameters('contact type attribute needs to be: blocked, restricted or open') unless $c->{contact_type_attr} =~ m/^(admin|tech|billing)$/;
    $c_min = ['registry:min', $c->{contact_min}];
    $c_max = ['registry:max', $c->{contact_max}] if $c->{contact_max};
    @c = ($c_min,$c_max);
    push @domain_contact, ['registry:contact', {'type'=>$c->{contact_type_attr}},@c] if exists $c->{contact_type_attr};
  }
  return @domain_contact;
}

sub __build_domain_ns
{
  my $domain_ns = shift;
  return unless $domain_ns && ref $domain_ns eq 'ARRAY';
  my (@domain_ns,@ns);
  foreach my $ns (@{$domain_ns})
  {
    my ($ns_min,$ns_max);
    $ns_min = ['registry:min', $ns->{ns_min}];
    $ns_max = ['registry:max', $ns->{ns_max}] if $ns->{ns_max};
    @ns = ($ns_min,$ns_max);
  }
  push @domain_ns, ['registry:ns', @ns];
  return @domain_ns;
}

sub __build_domain_child_host
{
  my $domain_child_host = shift;
  return unless $domain_child_host && ref $domain_child_host eq 'ARRAY';
  my (@domain_child_host,@ch);
  foreach my $ch (@{$domain_child_host})
  {
    my ($child_host_min,$child_host_max);
    $child_host_min = ['registry:min', $ch->{child_host_min}];
    $child_host_max = ['registry:max', $ch->{child_host_max}] if $ch->{ns_max};
    @ch = ($child_host_min,$child_host_max);
  }
  push @domain_child_host, ['registry:childHost', @ch];
  return @domain_child_host;
}

sub __build_domain_period
{
  my $domain_period = shift;
  return unless $domain_period && ref $domain_period eq 'ARRAY';
  my (@domain_period,@p);
  my ($period_min,$period_max,$period_default);
  foreach my $p (@{$domain_period})
  {
    Net::DRI::Exception::usererr_invalid_parameters('period command attribute needs to be: create, renew or transfer') unless $p->{period_command_attr} =~ m/^(create|renew|transfer)$/;
    $period_min = ['registry:min', {'unit'=>$p->{period_min_attr}}, $p->{period_min}] if $p->{period_min_attr} =~ m/^(m|y)$/;
    $period_max = ['registry:max', {'unit'=>$p->{period_max_attr}}, $p->{period_max}] if $p->{period_max_attr} =~ m/^(m|y)$/;
    $period_default = ['registry:default', {'unit'=>$p->{period_default_attr}}, $p->{period_default}] if $p->{period_default_attr} =~ m/^(m|y)$/;
    @p = ['registry:length', $period_min, $period_max, $period_default];
    #TODO: not sure what to do about if not <registry:length> THEN <registry:serverDecided>: WHERE the registration period is decided by the server based on the relationship to a related object that MUST have the same expiration date
    push @domain_period, ['registry:period', {'command'=>$p->{period_command_attr}}, @p];
  }
  return @domain_period;
}

sub __build_domain_transfer_hold_period
{
  my $domain_transfer_hold_period = shift;
  return unless $domain_transfer_hold_period && ref $domain_transfer_hold_period eq 'ARRAY';
  my @domain_transfer_hold_period;
  foreach my $p (@{$domain_transfer_hold_period})
  {
    Net::DRI::Exception::usererr_invalid_parameters('transfer hold command attribute needs to be: y (year), m (month) or d (day)') unless $p->{transfer_hold_period_attr} =~ m/^(y|m|d)$/;
    push @domain_transfer_hold_period, ['registry:transferHoldPeriod', {'unit'=>$p->{transfer_hold_period_attr}}, $p->{transfer_hold_period}] if $p->{transfer_hold_period};
  }
  return @domain_transfer_hold_period;
}

sub __build_domain_grace_period
{
  my $domain_grace_period = shift;
  return unless $domain_grace_period && ref $domain_grace_period eq 'ARRAY';
  my @domain_grace_period;
  foreach my $g (@{$domain_grace_period})
  {
    Net::DRI::Exception::usererr_invalid_parameters('grace period command attribute needs to be: create, renew, transfer or autoRenew') unless $g->{grace_period_command_attr} =~ m/^(create|renew|transfer|autoRenew)$/;
    Net::DRI::Exception::usererr_invalid_parameters('grace period unit attribute needs to be: d (day), h (hour) or m (minute)') unless $g->{grace_period_unit_attr} =~ m/^(d|h|m)$/;
    push @domain_grace_period, ['registry:gracePeriod', { 'command'=>$g->{grace_period_command_attr}, 'unit'=>$g->{grace_period_unit_attr} }, $g->{grace_period}];
  }
  return @domain_grace_period;
}

sub __build_domain_rgp
{
  my $domain_rgp = shift;
  return unless $domain_rgp && ref $domain_rgp eq 'ARRAY';
  my (@domain_rgp,@r);
  my ($redemption_period,$pending_restore,$pending_delete);
  foreach my $r (@{$domain_rgp})
  {
    Net::DRI::Exception::usererr_invalid_parameters('rgp unit attribute needs to be: y (year), m (month), d (day) or h (hour)') unless ( $r->{rgp_redemption_period_attr} =~ m/^(y|m|d|h)$/ && $r->{rgp_pending_restore_attr} =~ m/^(y|m|d|h)$/ && $r->{rgp_pending_delete_attr} =~ m/^(y|m|d|h)$/ );
    $redemption_period = ['registry:redemptionPeriod', {'unit'=>$r->{rgp_redemption_period_attr}}, $r->{rgp_redemption_period}];
    $pending_restore = ['registry:pendingRestore', {'unit'=>$r->{rgp_pending_restore_attr}}, $r->{rgp_pending_restore}];
    $pending_delete = ['registry:pendingDelete', {'unit'=>$r->{rgp_pending_delete_attr}}, $r->{rgp_pending_delete}];
  }
  @r = ($redemption_period, $pending_restore, $pending_delete);
  push @domain_rgp, ['registry:rgp', @r];
  return @domain_rgp;
}

sub __build_domain_dnssec
{
  my $domain_dnssec = shift;
  return unless $domain_dnssec && ref $domain_dnssec eq 'ARRAY';
  my (@domain_dnssec,@d,@d_ds,@d_key,@d_max,@d_tmp);
  my ($ds_data_interface,$key_data_interface,$max_sig_life,$urgent);
  foreach my $d (@{$domain_dnssec})
  {
    # <registry:dsDataInterface>
    push @d_ds, ['registry:min', $d->{dnssec_ds_data_min}];
    push @d_ds, ['registry:max', $d->{dnssec_ds_data_max}] if $d->{dnssec_ds_data_max};
    foreach (@{$d->{dnssec_ds_data_alg}}) { push @d_ds, ['registry:alg', $_] if $_; }
    foreach (@{$d->{dnssec_ds_data_digest}}) { push @d_ds, ['registry:digestType', $_] if $_; }
    $ds_data_interface = ['registry:dsDataInterface', @d_ds] if @d_ds;
    # <registry:keyDataInterface>
    push @d_key, ['registry:min', $d->{dnssec_key_data_min}] if $d->{dnssec_key_data_min};
    push @d_key, ['registry:max', $d->{dnssec_key_data_max}] if $d->{dnssec_key_data_max};
    foreach (@{$d->{dnssec_key_data_alg}}) { push @d_key, ['registry:alg', $_] if $_; }
    $key_data_interface = ['registry:keyDataInterface', @d_key] if @d_key;
    # <registry:maxSigLife>
    if ($d->{dnssec_max_sig_client} eq 'false')
    {
      push @d_max, ['registry:clientDefined', $d->{dnssec_max_sig_client}];
      push @d_max, ['registry:default', $d->{dnssec_max_sig_default}] if $d->{dnssec_max_sig_default};
    }
    else
    {
      push @d_max, ['registry:clientDefined', $d->{dnssec_max_sig_client}];
      push @d_max, ['registry:default', $d->{dnssec_max_sig_default}] if $d->{dnssec_max_sig_default};
      push @d_max, ['registry:min', $d->{dnssec_max_sig_min}] if $d->{dnssec_max_sig_min};
      push @d_max, ['registry:max', $d->{dnssec_max_sig_max}] if $d->{dnssec_max_sig_max};
    }
    $max_sig_life = ['registry:maxSigLife', @d_max] if @d_max;
    # <registry:urgent>
    $urgent = ['registry:urgent', $d->{dnssec_urgent}] if $d->{dnssec_urgent};
  }
  @d = ($ds_data_interface, $key_data_interface, $max_sig_life, $urgent);
  push @domain_dnssec, ['registry:dnssec', @d];
  return @domain_dnssec;
}

sub __build_domain_auth_info_regex
{
  my $domain_auth_info_regex = shift;
  return unless $domain_auth_info_regex && ref $domain_auth_info_regex eq 'ARRAY';
  my (@domain_auth_info_regex, @regex);
  foreach my $r (@{$domain_auth_info_regex})
  {
    push @regex, ['registry:expression', $r->{regex_expression}] if $r->{regex_expression};
    if (exists $r->{regex_explanation_attr})
    {
      push @regex, ['registry:explanation', {'lang'=>$r->{regex_explanation_attr}}, $r->{regex_explanation}] if $r->{regex_explanation};
    }
    else
    {
      push @regex, ['registry:explanation', {'lang'=>'en'}, $r->{regex_explanation}] if $r->{regex_explanation};
    }
  }
  push @domain_auth_info_regex, ['registry:authInfoRegex', @regex];
  return @domain_auth_info_regex;
}

sub __build_host_ip
{
  my ($ip,$type) = @_;
  return unless $ip;
  my (@ip,@i);
  foreach my $i ($ip)
  {
    push @i, ['registry:minIP', $i->{min_ip}];
    push @i, ['registry:maxIP', $i->{max_ip}];
    if ( $i->{share_policy} )
    {
      Net::DRI::Exception::usererr_invalid_parameters('sharePolicy values need to be: perZone or perSystem') unless ( $i->{share_policy} =~ m/^(perZone|perSystem)$/ );
      push @i, ['registry:sharePolicy', $i->{share_policy}];
    }
  }
  push @ip, ['registry:'.$type, @i];
  return @ip;
}

sub __build_contact_postal_info
{
  my $postal_info = shift;
  return unless $postal_info && ref $postal_info eq 'ARRAY';
  my (@postal_info,@p);
  my $tmp;
  foreach my $p (@{$postal_info})
  {
    push @p, ['registry:name', build_min_max_length($tmp->{min_length},$tmp->{max_length})] if ($tmp = $p->{contact_postal_info_name});
    push @p, ['registry:org', build_min_max_length($tmp->{min_length},$tmp->{max_length})] if ($tmp = $p->{contact_postal_info_org});
    push @p, ['registry:address', __build_contact_address_type($p->{contact_postal_info_address})] if $p->{contact_postal_info_address};
    push @p, ['registry:voiceRequired',$p->{contact_postal_info_voice_required}] if $p->{contact_postal_info_voice_required};
    push @p, ['registry:voiceExt', build_min_max_length($tmp->{min_length},$tmp->{max_length})] if ($tmp = $p->{contact_postal_info_voice_ext});
    push @p, ['registry:faxExt', build_min_max_length($tmp->{min_length},$tmp->{max_length})] if ($tmp = $p->{contact_postal_info_fax_ext});
    push @p, build_regex_type_multi($p->{contact_postal_info_email_regex},'emailRegex') if $p->{contact_postal_info_email_regex};
  }
  push @postal_info, ['registry:postalInfo', @p];
  return @postal_info;
}

sub __build_contact_address_type
{
  my $address = shift;
  return unless $address;
  my (@address);
  my $tmp;
  push @address, ['registry:street', build_min_max_length($tmp->{min_length},$tmp->{max_length}), build_min_max_entry($tmp->{min_entry},$tmp->{max_entry})] if ($tmp = $address->{street});
  push @address, ['registry:city', build_min_max_length($tmp->{min_length},$tmp->{max_length})] if ($tmp = $address->{city});
  push @address, ['registry:sp', build_min_max_length($tmp->{min_length},$tmp->{max_length})] if ($tmp = $address->{sp});
  push @address, ['registry:pc', build_min_max_length($tmp->{min_length},$tmp->{max_length})] if ($tmp = $address->{pc});
  return @address;
}

sub build_regex_type_multi
{
  my ($regex,$child_el) = @_;
  return unless $regex && ref $regex eq 'ARRAY';
  my (@regex,@r);
  foreach my $r (@{$regex})
  {
    push @r, ['registry:expression', $r->{regex_expression}] if $r->{regex_expression};
    if (exists $r->{regex_explanation_attr})
    {
      push @r, ['registry:explanation', {'lang'=>$r->{regex_explanation_attr}}, $r->{regex_explanation}] if $r->{regex_explanation};
    }
    else
    {
      push @r, ['registry:explanation', {'lang'=>'en'}, $r->{regex_explanation}] if $r->{regex_explanation};
    }
    push @regex, ['registry:'.$child_el, @r];
    @r = ();
  }
  return @regex;
}

sub build_supported_status
{
  my $supported_status = shift;
  return unless $supported_status && ref $supported_status eq 'ARRAY';
  my (@supported_status,@s);
  foreach my $s (@{$supported_status})
  {
    foreach (@{$s->{status}}) { push @s, ['registry:status', $_] if $_; } # TODO: confirm status based on http://tools.ietf.org/html/rfc5731#section-2.3
  }
  push @supported_status, ['registry:supportedStatus', @s];
  return @supported_status;
}

sub build_regex_type
{
  my ($regex,$child_el) = @_;
  return unless $regex;
  my (@regex, @r);
  foreach my $r ($regex)
  {
    push @r, ['registry:expression', $r->{regex_expression}] if $r->{regex_expression};
    if (exists $r->{regex_explanation_attr})
    {
      push @r, ['registry:explanation', {'lang'=>$r->{regex_explanation_attr}}, $r->{regex_explanation}] if $r->{regex_explanation};
    }
    else
    {
      push @r, ['registry:explanation', {'lang'=>'en'}, $r->{regex_explanation}] if $r->{regex_explanation};
    }
  }
  push @regex, ['registry:'.$child_el, @r];
  return @regex;
}

sub build_min_max_length
{
  my ($min,$max) = @_;
  return unless $min || $max;
  my (@min_max);
  push @min_max, ['registry:minLength', $min] if $min;
  push @min_max, ['registry:maxLength', $max] if $max;
  return @min_max;
}

sub build_min_max_entry
{
  my ($min,$max) = @_;
  return unless $min || $max;
  my (@min_max);
  push @min_max, ['registry:minEntry', $min] if $min;
  push @min_max, ['registry:maxEntry', $max] if $max;
  return @min_max;
}

sub registry_build_command
{
  my ($msg,$command,$registry,$registryattr)=@_;
  my @reg=ref $registry ? @$registry : ($registry);
  my $tcommand=ref $command ? $command->[0] : $command;
  $msg->command([$command,'registry:'.$tcommand,sprintf('xmlns:registry="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('registry'))]);
  my @r=();
  if (defined $registry)
  {
    @r=map { ['registry:name',$_,$registryattr] } @reg;
  }
  else
  {
    @r=map { ['registry:all',$_,$registryattr] } @reg;
  }
  return @r;
}

1;
