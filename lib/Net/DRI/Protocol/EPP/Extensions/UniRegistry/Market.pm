## Domain Registry Interface, UniRegistry EPP Market Extension
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::UniRegistry::Market;

use strict;
use warnings;
use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::UniRegistry::Market - Market Extension for UniRegistry

=head1 DESCRIPTION

Adds the Uniregistry Market extension. Uniregistry Market is a Uniregistry service designed for registrar partners. It provides the ability to check for object availability, create, cancel, and approve inquiries as well as the ability to buy objects in real time using the EPP protocol.

=head1 SYNOPSIS

 # market check => used to determine if an object is available in the Uniregistry Market
 my $rc = $dri->market_check(qw/example1.tld example2.tld/, { 'type_attr'=>'domain', 'suggestions_attr'=>'true'});

 # market info => check for the status of orders placed on the Uniregistry Market
 my $rc = $dri->market_info('my_order_id');

 # market create => used in the Uniregistry Market to place an order ("bin" or "offer"). The operation is processed in real time.
 $contact = { 'fname'=>'John', 'lname'=>'Doe', 'email'=>'jdoe@example.com', 'voice'=>'+1.123456789' };
 $rc = $dri->market_create('example.tld', { 'order_type'=>'offer', 'amount'=>15000, 'contact'=>$contact });

 # market update => is used to complete an order that has "accepted" on the Uniregistry Market
 $rc=$dri->market_update('my_order_id', { 'order'=>'complete' });

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
(c) 2015 Michael Holloway <michael@thedarkwinter.com>.
(c) 2015 Paulo Jorge <paullojorgge@gmail.com>.
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
            check    => [ \&check, \&check_parse],
            create   => [ \&create, \&info_parse],
            info     => [ \&info, \&info_parse ],
            update   => [ \&update, \&info_parse ],
         );
  $tmp{check_multi}=$tmp{check};
  return { 'market' => \%tmp };
}

sub setup
{
  my ($self,$po) = @_;
  $po->ns( { 'market' => ['http://ns.uniregistry.net/market-1.0','market-1.0.xsd']} );
  return;
}

####################################################################################################
sub check
{
  my ($epp,$market,$todo)=@_;
  my $mes=$epp->message();
  my @m=market_build_command($mes,'check',$market,$todo);
  $mes->command_body(\@m);
  return;
}

sub check_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  my $chkdata=$mes->get_response('market','chkData');
  return unless defined $chkdata;

  foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('market'),'cd'))
  {
    my $market;
    my @suggestions=();
    foreach my $el (Net::DRI::Util::xml_list_children($cd))
    {
      my ($name,$content)=@$el;
      if ($name eq 'name')
      {
        $market=lc($content->textContent());
        $rinfo->{market}->{$market}->{action}='check';
        $rinfo->{market}->{$market}->{exist}=1-Net::DRI::Util::xml_parse_boolean($content->getAttribute('avail')); # attribute whose value indicate whether the object is available or not on the Uniregistry Market at the time of processing
        $rinfo->{market}->{$market}->{bin}=1-Net::DRI::Util::xml_parse_boolean($content->getAttribute('bin')) if $content->getAttribute('bin'); # attribute whose value indicate whether object is available for "Buy It Now"
        $rinfo->{market}->{$market}->{offer}=1-Net::DRI::Util::xml_parse_boolean($content->getAttribute('offer')) if $content->getAttribute('offer'); # attribute whose value indicate whether object is available for "Inquiries"
      } elsif ($name eq 'suggestion')
      {
        my $suggestion={};
        foreach my $el2 (Net::DRI::Util::xml_list_children($content))
        {
          my ($name2,$content2)=@$el2;
          if ($name2 eq 'name')
          {
            $suggestion->{name}=$content2->textContent();
            $suggestion->{bin}=1-Net::DRI::Util::xml_parse_boolean($content2->getAttribute('bin')); # attribute whose value indicate whether object is available for "Buy It Now"
            $suggestion->{offer}=1-Net::DRI::Util::xml_parse_boolean($content2->getAttribute('offer')); # attribute whose value indicate whether object is available for "Inquiries"
          }
          $suggestion->{price}=$content2->textContent() if $name2 eq 'price';
        }
        push @suggestions, $suggestion;
      }
      $rinfo->{market}->{$market}->{price}=$content->textContent() if $name eq 'price';
    }
    @{$rinfo->{market}->{$market}->{suggestion}}=@suggestions if @suggestions;
  }
  return;
}

sub create
{
  my ($epp,$market,$rd)=@_;
  my $mes=$epp->message();
  my @m=market_build_command($mes,'create',$market,$rd);
  Net::DRI::Exception::usererr_invalid_parameters('Invalid order_type. Should be: "offer", "bin" or "hold" ') unless $rd->{order_type}=~m/^(offer|bin|hold)$/;
  Net::DRI::Exception::usererr_insufficient_parameters('Amount is mandatory for type "bin"') if !($rd->{amount}) && $rd->{order_type} eq 'bin';
  push @m, ['market:amount',$rd->{amount}] if defined $rd->{amount};
  push @m, _build_contact($rd->{contact}) if defined $rd->{contact};
  $mes->command_body(\@m);
  return;
}

sub info
{
my ($epp,$market,$rd)=@_;
  my $mes=$epp->message();
  my @m=market_build_command($mes,'info',$market);
  $mes->command_body(\@m);
  return;
}

sub info_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  my $resdata;
  return unless $mes->is_success();
  foreach my $res (qw/creData upData infData/)
  {
    next unless $resdata=$mes->get_response($mes->ns('market'),$res);
    $oname = 'market' unless defined $oname;
    foreach my $el (Net::DRI::Util::xml_list_children($resdata))
    {
      my ($name,$content)=@$el;
      $name = 'order_id' if $name eq 'orderID';
      $rinfo->{market}->{$oname}->{$name}=$content->textContent() if $name =~ m/^(order_id|name|amount|status)$/; # plain text
      $rinfo->{market}->{$oname}->{'type_attr'}=$content->getAttribute('type') if $name eq 'name';
      $rinfo->{market}->{$oname}->{$name}=$po->parse_iso8601($content->textContent()) if $name =~ m/^(crDate|upDate)$/; # date fields
      if ($name eq 'transferInfo')
      {
        $rinfo->{market}->{$oname}->{'transfer_info'}={pw=>Net::DRI::Util::xml_child_content($content,$mes->ns('market'),'pw')};
      } elsif ($name eq 'holdExpiryDate')
      {
        $rinfo->{market}->{$oname}->{'hold_expiry_date'}=$po->parse_iso8601($content->textContent()) if $name eq 'holdExpiryDate';
      }
    }
    $rinfo->{market}->{$oname}->{action}=$oaction;
    $rinfo->{market}->{$oname}->{type}='market';
  }
  return;
}

sub update
{
  my ($epp,$market,$rd)=@_;
  my $mes=$epp->message();
  my @m=market_build_command($mes,'update',$market);
  Net::DRI::Exception::usererr_invalid_parameters('Invalid market order. Should be: "acknowledge", "cancel" or "complete" ') unless $rd->{order}=~m/^(acknowledge|cancel|complete)$/;
  push @m, ['market:'.$rd->{order}];
  $mes->command_body(\@m);
  return;
}

sub market_build_command
{
  my ($msg,$command,$market,$marketattr)=@_;
  my @m=ref $market ? @$market : $market;
  my @market;

  my $tcommand=ref $command ? $command->[0] : $command;

  if ($command eq 'create')
  {
    Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless @m;
    if ($marketattr->{name_type})
    {
      @market=map { ['market:name',$_,{'type'=>$marketattr->{name_type}}] } @m;
    } else
    {
      @market=map { ['market:name',$_,{'type'=>'domain'}] } @m;
    }
    $msg->command([$command,'market:'.$tcommand,sprintf('xmlns:market="%s" xsi:schemaLocation="%s %s" type="'.$marketattr->{order_type}.'"',$msg->nsattrs('market'))]);
  } elsif ($command =~ m/^(?:info|update)$/)
  {
    @market=map { ['market:orderID',$_,$marketattr] } @m;
    $msg->command([$command,'market:'.$tcommand,sprintf('xmlns:market="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('market'))]);
  } elsif ($command eq 'check')
  {
    Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless @m;
    foreach (@m)
    {
      push @market, ['market:name', $_] unless ref $_ eq 'HASH';
    }
    if ($marketattr->{type_attr} || $marketattr->{suggestions_attr})
    {
      $marketattr->{type_attr} = 'domain' unless defined $marketattr->{type_attr};
      $marketattr->{suggestions_attr} = 'false' unless defined $marketattr->{suggestions_attr};
      $msg->command([$command,'market:'.$tcommand,sprintf('xmlns:market="%s" xsi:schemaLocation="%s %s" type="'.$marketattr->{type_attr}.'" suggestions="'.$marketattr->{suggestions_attr}.'"',$msg->nsattrs('market'))]);
    } else {
      $msg->command([$command,'market:'.$tcommand,sprintf('xmlns:market="%s" xsi:schemaLocation="%s %s" type="domain" suggestions="false"',$msg->nsattrs('market'))]);
    }
  }
  return @market;
}

sub _build_contact
{
  my $contact = shift;
  return unless $contact && ref $contact eq 'HASH';
  my @contact;
  push @contact, ['market:firstName',$contact->{fname}] if $contact->{fname};
  push @contact, ['market:lastName',$contact->{lname}] if $contact->{lname};
  push @contact, ['market:email',$contact->{email}] if $contact->{email};
  push @contact, ['market:phone',$contact->{voice}] if $contact->{voice};
  @contact = ['market:contact',@contact];
  return @contact;
}

####################################################################################################


1;
