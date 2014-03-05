## Domain Registry Interface, TMDB commands
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::TMDB::Commands;
use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark;

####################################################################################################
sub register_commands
{
 my ($class,$version)=@_;
 my %s=( fetch_sig => [\&smdrl_pgp,\&smdrl_pgp_parse ], 
                     fetch => [\&smdrl_fetch, \&smdrl_parse ] ,
                    );
 my %c= ( lookup => [\&cnis_lookup, \&cnis_parse] );
 return { smdrl => \%s, cnis => \%c };
}

####################################################################################################
## SMD-RL

sub smdrl_pgp
{
 my ($tmdb,$fn)=@_;
 my $mes=$tmdb->message();
 $mes->command('smdrl_fetch');
 $mes->command_body('smdrl/smdrl-latest.sig');
 return;
}

sub smdrl_pgp_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 $rinfo->{$otype}->{$oname}->{action}=$oaction;
 $rinfo->{$otype}->{$oname}->{sig}=$mes->{message_body};
 return;
}

sub smdrl_fetch
{
 my ($tmdb,$fn)=@_;
 my $mes=$tmdb->message();
 $mes->command('smdrl_fetch');
 $mes->command_body('smdrl/smdrl-latest.csv');
 return;
}

sub smdrl_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

  my ($rl);
  my @list = split "\n", $mes->{message_body};
  my ($smd,$dt) = split ",", shift @list;
  $rl->{generated} = $po->parse_iso8601($dt);

  shift @list; # remove header
  foreach my $r ( @list ) {
    my ($smd,$dt) = split ",", $r;
    $rl->{$smd} = $po->parse_iso8601($dt);
    push @{$rl->{smdlist}},$smd;
  }

 $rinfo->{$otype}->{$oname}->{action}=$oaction;
 $rinfo->{$otype}->{$oname}->{raw} = $mes->{message_body};
 $rinfo->{$otype}->{$oname}->{self} = $rl;
 return;
}


####################################################################################################
## CNIS
sub cnis_lookup
{
 my ($tmdb,$key)=@_;
 my $mes=$tmdb->message();
 $mes->command('cnis_lookup');
 $mes->command_body('cnis/'.$key. '.xml');
 return;
}

sub cnis_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_; 
 my $mes=$po->message();
 return unless $mes->is_success();
 
 my $parser=XML::LibXML->new();
 my $doc=$parser->parse_string($mes->{message_body});
 my $root=$doc->getDocumentElement();
 Net::DRI::Exception->die(0,'protocol/TMCH',1,'Unsuccessfull CNIS parse, root element is not notice') unless ($root->localname() eq 'notice');
 
 $rinfo->{$otype}->{$oname}->{action}=$oaction;
 my @claims;
 foreach my $el (Net::DRI::Util::xml_list_children($root))
 {
  my ($name,$c)=@$el;
   $rinfo->{$otype}->{$oname}->{id} = $c->textContent() if $name eq 'id';
   $rinfo->{$otype}->{$oname}->{ Net::DRI::Util::xml2perl($name) } = $po->parse_iso8601($c->textContent()) if $name =~ m/^(notBefore|notAfter)$/;
   $rinfo->{$otype}->{$oname}->{label} = $c->textContent() if $name eq 'label';
   push @{$rinfo->{$otype}->{$oname}->{claim}},parse_claim($po,$c) if $name eq 'claim';
 }

 return;
}

####################################################################################################
## Claims parser - this utilises MarkSignedMark::parse_contact functions, but the tmNotice ns is quite different in the end

sub parse_claim
{
 my ($po,$start)=@_;
 return unless $start;
 
 my $m;
 my $cs=$po->create_local_object('contactset');
 my @nem;
 foreach my $el (Net::DRI::Util::xml_list_children($start))
 {
  my ($name,$c)=@$el;
  if ($name eq 'markName')
  {
   $m->{'mark_name'} = $c->textContent();
  } elsif ($name eq 'goodsAndServices')
  {
   $m->{'goods_services'} = $c->textContent(); 
   $m->{'goods_services'}=~s/\n +/ /g;
   $m->{'goods_services'}=~s/ +$//s;
  }
  elsif ($name eq 'holder')
  {
   my $type='holder_'.$c->getAttribute('entitlement'); ## owner, assignee, licensee
   $cs->add(Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_contact($po,$c),$type);
  } elsif ($name eq 'contact')
  {
   my $type='contact_'.$c->getAttribute('type'); ## owner, agent, thirdparty
   $cs->add(Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_contact($po,$c),$type);
  } elsif ($name eq 'jurDesc')
  {
   $m->{ 'jurisdiction'} = ( $c->textContent );
   $m->{'jurisdiction_cc'} = $c->getAttribute('jurCC') if $c->hasAttribute('jurCC');
  } elsif ($name eq 'classDesc')
  {
    push @{$m->{class}}, { 'number' => $c->getAttribute('classNum'), 'description' => $c->textContent() };
  } elsif ($name eq 'notExactMatch')
  {
   foreach my $el2 (Net::DRI::Util::xml_list_children($c))
   {
    my ($name2,$c2)=@$el2;
    if ($name2 =~ m/^(udrp|court)$/)
    {
     my $nem = { type => $name2};
      foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
      {
       my ($name3,$c3)=@$el3;
       $nem->{ Net::DRI::Util::xml2perl($name3)} = $c3->textContent();
      }
      push @nem,$nem;
    }
   }
  }
 }
 $m->{contact}=$cs;
 $m->{not_exact_match} = \@nem if @nem;
 return $m;
}

1;