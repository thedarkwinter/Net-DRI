## Domain Registry Interface, OpenSRS XCP Message
##
## Copyright (c) 2008-2010,2012-2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::NameAction::Message;

use strict;
use warnings;

use XML::LibXML ();
use URI;

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;
use Net::DRI::Util;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version client_auth command command_attributes response_code response_text response_command response_is_success));

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

Copyright (c) 2008-2010,2012-2014 Patrick Mevzek <netdri@dotandco.com>.
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
 my $self={ results => [], command => {}};
 bless($self,$class);

 $self->version('1.04');
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
sub as_string  {
  my $self=shift;
  my $uri = URI->new();
  $uri->query_form($self->{command});
  return $uri->query();
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
   foreach my $k (sort { $a cmp $b } keys %$el)
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

sub parse
{
 my ($self,$dr,$rinfo,$otype,$oaction,$msgsent)=@_;
 #use Data::Dumper; print Dumper(@_); 
 $self->command($msgsent->command()); ## Copy over for reference from message sent

 my $parser=XML::LibXML->new();
 my $doc=$parser->parse_string($dr->as_string());
 
 my $root=$doc->getDocumentElement();
 Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, root element is not "nck" but '.$root->getName()) unless ($root->getName() eq 'nck');

 my $resp = $root->getElementsByTagName('response');
 Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected only one "response" node below root, found '.$resp->size()) unless ($resp->size()==1);
 
 my $cmd = $resp->get_node(1)->getChildrenByTagName('command');
 Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected only one "command" node below responset, found '.$cmd->size()) unless ($cmd->size()==1);
 $self->response_command($cmd->get_node(0)->textContent());
 
 my $val = $resp->get_node(1)->getChildrenByTagName('value');
 Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected only one "value" node below responset, found '.$val->size()) unless ($val->size()==1);
 $self->response_code($val->get_node(0)->textContent());
 
 my $msg=$root->getElementsByTagName('message');
 Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected only one "message" node below root, found '.$msg->size()) unless ($msg->size()==1);
 $self->response_text($msg->get_node(0)->textContent());

 $self->response_is_success(1);
 return;
}

####################################################################################################
1;
