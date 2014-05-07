## Domain Registry Interface, TMCH Message
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

package Net::DRI::Protocol::TMCH::Message;

use utf8;
use strict;
use warnings;

use DateTime::Format::ISO8601 ();
use DateTime ();
use XML::LibXML ();

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Util;

use base qw /Net::DRI::Protocol::EPP::Message/;
__PACKAGE__->mk_accessors(qw(version command command_body cltrid svtrid msg_id msg_content node_resdata node_extension node_msg node_greeting));


####################################################################################################


sub result_status
{
 my ($self)=@_;
 my @rs;

 foreach my $result (@{$self->{results}})
 {
  my $rs=Net::DRI::Protocol::ResultStatus->new('tmch',$result->{code},undef,_is_success($result->{code}),$result->{message},$result->{lang},$result->{extra_info});
  $rs->_set_trid([ $self->cltrid(),$self->svtrid() ]);
  push @rs,$rs;
 }
 return Net::DRI::Util::link_rs(@rs);
}

sub command_extension_register
{
 my ($self,$ocmd,$ons,$otherattrs)=@_;

 $self->{extension}=[] unless exists $self->{extension};
 my $eid=1+$#{$self->{extension}};
 if (defined $ons && $ons!~m/xmlns/) ## new interface, everything should switch to that (TODO)
 {
  my ($nss,$command)=($ocmd,$ons);
  $ocmd=(ref $nss eq 'ARRAY' ? $nss->[0] : $nss).':'.$command;
  $ons=$self->nsattrs($nss);
  ## This is used for other *generic* attributes, not for xmlns: ones !
  $ons.=' '.join(' ',map { sprintf('%s="%s"',$_,$otherattrs->{$_}) } keys %$otherattrs) if defined $otherattrs && ref $otherattrs;
 }
 $self->{extension}->[$eid]=[$ocmd,$ons,[]];
 return $eid;
}

sub is_success { return _is_success(shift->result_code()); }
sub _is_success { return (shift=~m/^1/)? 1 : 0; } ## 1XXX is for success, 2XXX for failures

# TMCH/Delloite can't hande when mark data is submitted as <mark:name>, it only accepts <name>, therefore we use this xml_write instead of Net::DRI::Util::xml_write to fix that
sub xml_write
{
 my $rd=shift;
 my @t;
 foreach my $d ((ref($rd->[0]))? @$rd : ($rd)) ## $d is a node=ref array
 {
  my @c; ## list of children nodes
  my %attr;
  foreach my $e (grep { defined } @$d)
  {
   if (ref($e) eq 'HASH')
   {
    while(my ($k,$v)=each(%$e)) { $attr{$k}=$v; }
   } else
   {
    push @c,$e;
   }
  }
  my $tag=shift(@c);
  $tag =~ s/^mark://;
  my $attr=keys(%attr)? ' '.join(' ',map { $_.'="'.$attr{$_}.'"' } sort(keys(%attr))) : '';
  if (!@c || (@c==1 && !ref($c[0]) && ($c[0] eq '')))
  {
   push @t,'<'.$tag.$attr.'/>';
  } else
  {
   push @t,'<'.$tag.$attr.'>';
   push @t,(@c==1 && !ref($c[0]))? Net::DRI::Util::xml_escape($c[0]) : xml_write(\@c);
   push @t,'</'.$tag.'>';
  }
 }
 return @t;
}

sub as_string
{
 my ($self,$protect)=@_;
 my @d;
 push @d,'<?xml version="1.0" encoding="UTF-8" standalone="no"?>';
 push @d,'<tmch '.sprintf('xmlns="%s" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="%s %s"',$self->nsattrs('_main')).'>';

 my ($cmd,$ocmd,$ons);
 my $rc=$self->command();
 ($cmd,$ocmd,$ons)=@$rc if (defined $rc && ref $rc);

 my $attr='';
 ($cmd,$attr)=($cmd->[0],' '.join(' ',map { $_.'="'.$cmd->[1]->{$_}.'"' } keys(%{$cmd->[1]}))) if (defined $cmd && ref $cmd);

 if (defined $cmd)
 {
  push @d,'<command>' if ($cmd ne 'hello');
  my $body=$self->command_body();

  if (!defined $ocmd && !defined $body)
  {
   push @d,'<'.$cmd.$attr.'/>';
  } else
  {
   push @d,'<'.$cmd.$attr.'>';
   if (defined $body && length $body)
   {
    push @d,(defined $ocmd && length $ocmd)? ('<'.$ocmd.' '.$ons.'>',xml_write($body),'</'.$ocmd.'>') : xml_write($body);
   } else
   {
    push @d,'<'.$ocmd.' '.$ons.'/>';
   }
   push @d,'</'.$cmd.'>';
  }
 }

 ## OPTIONAL extension
 my $ext=$self->{extension};
 if (defined $ext && ref $ext eq 'ARRAY' && @$ext)
 {
  push @d,'<extension>';
  foreach my $e (@$ext)
  {
   my ($ecmd,$ens,$rdata)=@$e;
   if ($ecmd && $ens)
   {
    if ((ref $rdata && @$rdata) || (! ref $rdata && $rdata ne ''))
    {
     push @d,'<'.$ecmd.' '.$ens.'>';
     push @d,ref($rdata)? Net::DRI::Util::xml_write($rdata) : Net::DRI::Util::xml_escape($rdata);
     push @d,'</'.$ecmd.'>';
    } else
    {
     push @d,'<'.$ecmd.' '.$ens.'/>';
    }
   } else
   {
    push @d,Net::DRI::Util::xml_escape(@$rdata);
   }
  }
  push @d,'</extension>';
 }

 ## OPTIONAL clTRID
 my $cltrid=$self->cltrid();
 if (defined $cmd && $cmd ne 'hello')
 {
  push @d,'<clTRID>'.$cltrid.'</clTRID>' if (defined $cltrid && Net::DRI::Util::xml_is_token($cltrid,3,64));
  push @d,'</command>';
 }
 push @d,'</tmch>';

 my $msg=join('',@d);

 if (defined $protect && ref $protect eq 'HASH')
 {
  if (exists $protect->{session_password} && $protect->{session_password})
  {
   $msg=~s#(?<=</clID>)<pw>(\S+?)</pw>#'<pw>'.('*' x length $1).'</pw>'#e;
   $msg=~s#(?<=</pw>)<newPW>(\S+?)</newPW>#'<newPW>'.('*' x length $1).'</newPW>'#e;
  }
 }

 return $msg;
}

sub get_response  { my $self=shift; return $self->_get_content($self->node_resdata(),@_); }
sub get_extension { my $self=shift; return $self->_get_content($self->node_extension(),@_); }

sub _get_content
{
 my ($self,$node,$nstag,$nodename)=@_;
 return unless (defined $node && defined $nstag && length $nstag && defined $nodename && length $nodename);
 my $ns=$self->ns($nstag);
 $ns=$nstag unless defined $ns && $ns;
 my @tmp=$node->getChildrenByTagNameNS($ns,$nodename);
 return unless @tmp;
 return $tmp[0];
}

sub parse
{
 my ($self,$dc,$rinfo)=@_;
 my $NS=$self->ns('_main');
 my $parser=XML::LibXML->new();
 my $doc=$parser->parse_string($dc->as_string());
 my $root=$doc->getDocumentElement();
 Net::DRI::Exception->die(0,'protocol/TMCH',1,'Unsuccessfull parse, root element is not tmch') unless ($root->localname() eq 'tmch');

 if (my $g=$root->getChildrenByTagNameNS($NS,'greeting'))
 {
  push @{$self->{results}},{ code => 1000, message => 'Greeting message received', lang => 'en', extra_info => []}; ## fake an OK
  $self->node_greeting($g->get_node(1));
  return;
 }

 my $c=$root->getChildrenByTagNameNS($NS,'response');
 Net::DRI::Exception->die(0,'protocol/TMCH',1,'Unsuccessfull parse, expected exactly one response block') unless ($c->size()==1);
 ## result block(s)
 my $res=$c->get_node(1);
 foreach my $result ($res->getChildrenByTagNameNS($NS,'result')) ## one element if success, multiple elements if failure RFC5730 §2.6
 {
  push @{$self->{results}},Net::DRI::Protocol::EPP::Util::parse_node_result($result,$NS);
 }

 $rinfo->{message}->{info}={ count => 0, checked_on => DateTime->now() };
 $c=$res->getChildrenByTagNameNS($NS,'msgQ');
 if ($c->size()) ## OPTIONAL
 {
  my $msgq=$c->get_node(1);
  my $id=$msgq->getAttribute('id'); ## id of the message that has just been retrieved and dequeued (RFC5730/RFC4930) OR id of *next* available message (RFC3730)
  $rinfo->{message}->{info}->{id}=$id;
  $rinfo->{message}->{info}->{count}=$msgq->getAttribute('count');
  if ($msgq->hasChildNodes()) ## We will have childs only as a result of a poll request
  {
   my %d=( id => $id );
   $self->msg_id($id);

   my $qdate=Net::DRI::Util::xml_child_content($msgq,$NS,'qDate');
   $qdate =~ s/ /T/;
   $d{qdate}=DateTime::Format::ISO8601->new()->parse_datetime($qdate) if defined $qdate && length $qdate;
   my $msg=$msgq->getChildrenByTagNameNS($NS,'msg');
   if ($msg->size())
   {
    my $msgc=$msg->get_node(1);
    $d{lang}=$msgc->getAttribute('lang') || 'en';
    if (grep { $_->nodeType() == 1 } $msgc->childNodes())
    {
     $d{content}=$msgc->toString();
     $self->msg_content($msgc->toString());
     $self->node_msg($msgc);
    } else
    {
     $self->msg_content($msgc->textContent());
     $d{content}=$msgc->textContent();
    }
   }
   $rinfo->{message}->{$id}=\%d;
  }
 }

 $c=$res->getChildrenByTagNameNS($NS,'resData');
 $self->node_resdata($c->get_node(1)) if ($c->size()); ## OPTIONAL
 $c=$res->getChildrenByTagNameNS($NS,'extension');
 $self->node_extension($c->get_node(1)) if ($c->size()); ## OPTIONAL

 ## trID
 my $trid=$res->getChildrenByTagNameNS($NS,'trID')->get_node(1); ## we search only for <trID> as direct child of <response>, hence getChildren and not getElements !
 my $tmp=Net::DRI::Util::xml_child_content($trid,$NS,'clTRID');
 $self->cltrid($tmp) if defined $tmp;
 $tmp=Net::DRI::Util::xml_child_content($trid,$NS,'svTRID');
 $self->svtrid($tmp) if defined $tmp;
}

####################################################################################################
1;
