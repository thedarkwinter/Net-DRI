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

package Net::DRI::Protocol::EPP::Extensions::UNIREG::Market;

use strict;
use warnings;
use Net::DRI::Util;
use Net::DRI::Exception;
#use Net::DRI::Data::Contact::UNIREG;
use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::UNIREG::Market - Market Extension for UniRegistry

=head1 DESCRIPTION

Adds the UniRegistry Registrant Market Extension (http://ns.uniregistry.net/centric-1.0 ) to domain commands. This extensions is returned from the domain_info command, and used in domain_create and by adding contact type 'urc' to a contactset, and domain_update by setting the 'urc' with a contact object. The contact object should be created as a URC  L<Net::DRI::Data::Contact::UNIREG> contact,  and contains the below additional data. Note, the URC contact does not have a handle at the registry. You need to create / update using the acual contact data each time.

=item alt_email (valid email address)

=item mobile (valid phone number

=item challenge (array of hashes listing security questions and examples; min 3, max 5)

=head1 SYNPOSIS
 
 # domain info
 my $rc = $dri->domain_info('domain.tld');
 my $urc = $dri->get_info('contact')->get('urc');

 # setting urc contact data
 my $urc = $dri->local_object('urc_contact'); # urc_contact is object type!
 $urc->name('...')->org('..'); # starndard contact defailts
 $urc->alt_email('...');
 $urc->mobile('+1.6504231234');
 my @ch = ( {question => 'Question 1',answer=>'Answer 1'},{question => 'Question 2',answer=>'Answer 2'},{question => 'Question 3',answer=>'Answer 3'} );
 $urc->challenge(\@ch);

 # domain create
 my $cs=$dri->local_object('contactset');
 #$cs->set($c1,'registrant'); # whatever your other contacts are
 $cs->set($urc,'urc'); # set urc contact
 $rc = $dri->domain_create('domain.tld',{... contact => $cs} );

 # domain update
 $toc->set('urc',$urc); # Note, sending the contact not contactset
 $rc=$dri->domain_update('domain.tld',$toc);

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
            create   => [ \&create, \&create_parse],
            info     => [ \&info, \&info_parse ],
#            update   => [ \&update, \&parse_update ],
         );
  $tmp{check_multi}=$tmp{check};
  return { 'market' => \%tmp };
}

sub setup
{
  my ($self,$po) = @_;
  $po->ns( { 'market' => ['http://ns.uniregistry.net/market-1.0','market-1.0.xsd']} );
#  $po->capabilities('market_update','market',['set']);
  return;
}

####################################################################################################
sub check
{
  my ($epp,$market,$rd)=@_;
#  print Dumper($market);
#  print Dumper($rd);
  my $mes=$epp->message();
  
  my $market_attr;
  if (Net::DRI::Util::has_key($rd,'type'))
  {
    $market_attr=$rd->{'type'};
  } else 
  {
    $market_attr='domain';
  }
  return unless $market_attr;
  print Dumper($market_attr);
  my @m=market_build_command($mes,'check',$market);
  $mes->command_body(\@m);
  return;
}

#sub check
#{
#  my ($epp,$market,$rd)=@_;
#  print Dumper($market);
#  print Dumper($rd);
#  my $mes=$epp->message();
#  $mes->command(['check','market:check',sprintf('xmlns:market="%s" xsi:schemaLocation="%s %s" type="domain" suggestions="false"',$mes->nsattrs('market'))]);
#  return;
#}


sub check_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  
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

sub create_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  
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
  return unless $mes->is_success();

  my $infData=$mes->get_response('market','infData');
  return unless defined $infData;

  $oname = 'market' unless defined $oname;
  foreach my $el (Net::DRI::Util::xml_list_children($infData))
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
  $rinfo->{market}->{$oname}->{action}='info';
  $rinfo->{market}->{$oname}->{type}='market';
  return;
}

sub market_build_command
{
  my ($msg,$command,$market,$marketattr)=@_;
  my @m=ref $market ? @$market : $market;
  my @market;
  
  my $tcommand=ref $command ? $command->[0] : $command;
  
  if ($command =~ m/^(?:check|create)$/)
  {
    Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless @m;
#    foreach my $m (@m)
#    {
#    	print Dumper($m);
#      Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined $m && $m;
#      Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$m) unless Net::DRI::Util::xml_is_token($m,1,255);
#    }
    if ($marketattr->{name_type})
    {
      @market=map { ['market:name',$_,{'type'=>$marketattr->{name_type}}] } @m;
    } else
    {
      @market=map { ['market:name',$_,{'type'=>'domain'}] } @m;
    }
    $msg->command([$command,'market:'.$tcommand,sprintf('xmlns:market="%s" xsi:schemaLocation="%s %s" type="'.$marketattr->{order_type}.'"',$msg->nsattrs('market'))]);
  } elsif ($command eq 'info')
  {
    @market=map { ['market:orderID',$_,$marketattr] } @m;
    $msg->command([$command,'market:'.$tcommand,sprintf('xmlns:market="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('market'))]);
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