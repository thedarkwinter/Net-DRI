## Domain Registry Interface, OpenSRS XCP Message
##
## Copyright (c) 2008-2010,2012-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::OpenSRS::XCP::Message;

use strict;
use warnings;

use XML::LibXML ();

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;
use Net::DRI::Util;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version client_auth command command_attributes response_attributes response_code response_text response_is_success));

=pod

=head1 NAME

Net::DRI::Protocol::OpenSRS::XCP::Message - OpenSRS XCP Message for Net::DRI

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

Copyright (c) 2008-2010,2012-2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my ($class,$trid)=@_;
 my $self={ results => [], _body => '', command => {}};
 bless($self,$class);

 $self->version('0.9');
 return $self;
}

our %CODES=( 200 => 1000,
             210 => 2303,
             211 => 2302,
             212 => 1000,
             221 => 2302,
             250 => 1001,
             300 => 1001,
             310 => 2502,
             350 => 2502, ## A maximum of 100 commands can be sent through one connection/session. After 100 commands have been submitted, the connection is closed and a new connection must be opened to submit outstanding requests.
             400 => 2400,
             404 => 2400,
             405 => 2400,
             410 => 2200,
             415 => 2200,
             430 => 2000,
             435 => 2201,
             436 => 2400,
             437 => 2304,
             440 => 2201,
             445 => 2201,
             447 => 2201,
             460 => 2003,
             465 => 2005,
             480 => 2306,
             485 => 2302,
             486 => 2304,
             487 => 2106,
             541 => 2004,
             552 => 2304,
             555 => 2306,
             557 => 2305,
             705 => 2400,
           );

sub result_status
{
 my $self=shift;
 return Net::DRI::Protocol::ResultStatus->new_success($self->response_text()) if $self->response_is_success();
 my $code=$self->response_code();
 my $eppcode=(defined $code && exists $CODES{$code})? $CODES{$code} : 'COMMAND_FAILED';
 return Net::DRI::Protocol::ResultStatus->new('opensrs_xcp',$code,$eppcode,$self->response_is_success(),$self->response_text(),'en');
}

sub is_success { return shift->response_is_success(); }
sub as_string  { return shift->get_body(); }

sub get_body
{
 my ($self)=@_;
 return $self->{_body} if length($self->{_body});
 my @d;
 push @d,q{<?xml version='1.0' encoding='UTF-8' standalone='no' ?>};
 push @d,q{<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>};
 push @d,'<OPS_envelope>';
 push @d,'<header><version>',$self->version(),'</version></header>';
 push @d,'<body>';
 push @d,'<data_block>';
 push @d,'<dt_assoc>';
 my $d=$self->command(); ## ref hash with at least action & object keys, maybe more (such as cookie)
 $d->{protocol}='XCP';
 foreach my $k (sort(keys(%$d)))
 {
  push @d,'<item key="',$k,'">',$d->{$k},'</item>';
 }
 push @d,'<item key="attributes">',_obj2dt($self->command_attributes()),'</item>' if defined($self->command_attributes());
 push @d,'</dt_assoc>';
 push @d,'</data_block>';
 push @d,'</body>';
 push @d,'</OPS_envelope>';

 $self->{_body}=join('',@d);
 return $self->{_body};
}

sub _obj2dt
{
 my ($in)=@_;
 my @r;
 foreach my $el ($in)
 {
  my $ref=ref($el);
  if (!$ref)
  {
   push @r,sprintf('<dt_scalar>%s</dt_scalar>',Net::DRI::Util::xml_escape($el));
  } elsif ($ref eq 'HASH')
  {
   my @c;
   foreach my $k (sort(keys(%$el)))
   {
    $k=~s/"/&quot;/g;
    my $v=$el->{$k};
    if (!defined($v)) {
     push @c,sprintf('<item key="%s" />',$k);
    } else {
     push @c,sprintf('<item key="%s">%s</item>',$k,ref($v)? _obj2dt($v) : Net::DRI::Util::xml_escape($v));
    }
   }
   push @r,sprintf('<dt_assoc>%s</dt_assoc>',join('',@c));
  } elsif ($ref eq 'ARRAY')
  {
   my @c;
   foreach my $i (0..$#$el)
   {
    push @c,sprintf('<item key="%d">%s</item>',$i,ref($el->[$i])? _obj2dt($el->[$i]) : Net::DRI::Util::xml_escape($el->[$i]));
   }
   push @r,sprintf('<dt_array>%s</dt_array>',join('',@c));
  } elsif ($ref eq 'SCALAR')
  {
   push @r,sprintf('<dt_scalarref>%s</dt_scalarref>',Net::DRI::Util::xml_escape($$el)); ## defined in specifications, but not really used ?
  } else
  {
   Net::DRI::Exception::err_assert('_obj2dt cannot deal with data '.$el);
  }
 }
 return @r;
}

sub _dt2obj ## no critic (Subroutines::RequireFinalReturn)
{
 my ($doc)=@_;
 my $c=$doc->getFirstChild();
 return unless defined($c);
 while (defined($c) && $c->nodeType()!=1) { $c=$c->getNextSibling(); }
 return $doc->textContent() unless (defined($c) && $c->nodeType()==1);
 my $n=$c->nodeName();
 if ($n eq 'dt_scalar')
 {
  return $c->textContent();
 } elsif ($n eq 'dt_assoc')
 {
  my %r;
  foreach my $item ($c->getChildrenByTagName('item'))
  {
   $r{$item->getAttribute('key')}=_dt2obj($item);
  }
  return \%r;
 } elsif ($n eq 'dt_array')
 {
  my @r;
  foreach my $item ($c->getChildrenByTagName('item'))
  {
   $r[$item->getAttribute('key')]=_dt2obj($item);
  }
  return \@r;
 }

 Net::DRI::Exception::err_assert('_dt2obj ca not deal with node name '.$n);
}

sub parse
{
 my ($self,$dr,$rinfo,$otype,$oaction,$msgsent)=@_;
 $self->command($msgsent->command()); ## Copy over for reference from message sent

 my $parser=XML::LibXML->new();
 my $doc=$parser->parse_string($dr->as_string());
 my $root=$doc->getDocumentElement();
 Net::DRI::Exception->die(0,'protocol/OpenSRS/XCP',1,'Unsuccessful parse, root element is not OPS_envelope but '.$root->getName()) unless ($root->getName() eq 'OPS_envelope');

 my $db=$root->getElementsByTagName('data_block');
 Net::DRI::Exception->die(0,'protocol/OpenSRS/XCP',1,'Unsuccessful parse, expected only one data_block node below root, found '.$db->size()) unless ($db->size()==1);
 $db=$db->get_node(1)->getChildrenByTagName('dt_assoc');
 Net::DRI::Exception->die(0,'protocol/OpenSRS/XCP',1,'Unsuccessful parse, expected one dt_assoc node directly below data_block, found '.$db->size()) unless ($db->size()==1);

 foreach my $item ($db->get_node(1)->getChildrenByTagName('item'))
 {
  my $key=$item->getAttribute('key');
  next if ($key eq 'protocol' || $key eq 'action' || $key eq 'object'); ## protocol is XCP, action is always REPLY, and we already have object in command()
  if ($key eq 'attributes') ## specific data about requested action, should always be an hash based on documentation
  {
   $self->response_attributes(_dt2obj($item));
   next;
  }
  if ($key eq 'response_code') ## meaning is action-specific
  {
   $self->response_code($item->textContent());
   next;
  }
  if ($key eq 'response_text') ## meaning is action-specific
  {
   $self->response_text($item->textContent());
   next;
  }
  if ($key eq 'is_success') ## 0 if not successful, 1 if action was successful
  {
   $self->response_is_success($item->textContent());
   next;
  }
 }
 return;
}

####################################################################################################
1;
