## Domain Registry Interface, NameAction Message
##
## Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>. All rights reserved.
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
__PACKAGE__->mk_accessors(qw(version client_auth command command_attributes response_code response_text response_command response_attributes response_is_success));

=pod

=head1 NAME

Net::DRI::Protocol::NameAction::Message - NameAction Message for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Castanheira, E<lt>paulo.s.castanheira@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com.com>.
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

sub result_status
{
 my $self=shift;
 return Net::DRI::Protocol::ResultStatus->new_success($self->response_text()) if $self->response_is_success();
 my $code=$self->response_code();
 return Net::DRI::Protocol::ResultStatus->new('nameaction',$code,$code,$self->response_is_success(),$self->response_text(),'en');
}

sub is_success { return shift->response_is_success(); }
sub as_string  {
  my $self=shift;
  my $uri = URI->new();
  $uri->query_form($self->{command});
  return $uri->query();
}

sub parse
{
 my ($self,$dr,$rinfo,$otype,$oaction,$msgsent)=@_;
 $self->command($msgsent->command()); ## Copy over for reference from message sent

 my $parser=XML::LibXML->new();
 my $doc=$parser->parse_string($dr->as_string());
 
 my $root=$doc->getDocumentElement();
 Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, root element is not "nck" but '.$root->getName()) unless ($root->getName() eq 'nck');

 my $resp = $root->getElementsByTagName('response');
 Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "response" node below root, found '.$resp->size()) unless ($resp->size()==1);
 
 my $error = $resp->get_node(1)->getChildrenByTagName('error');
 if ( $error->size() ) 
 {
  my $code = $error->get_node(1)->getChildrenByTagName('code');
  Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "code" node below "error", found '.$code->size()) unless ($code->size()==1);
  $self->response_code($code->get_node(0)->textContent());
  
  my $msg = $error->get_node(1)->getChildrenByTagName('message');
  Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "message" node below "error", found '.$msg->size()) unless ($code->size()==1);
  $self->response_text($msg->get_node(0)->textContent());
  
  $self->response_is_success(0);
  return;
 }
 
 my $cmd = $resp->get_node(1)->getChildrenByTagName('command');
 Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "command" node below "response", found '.$cmd->size()) unless ($cmd->size()==1);
 $self->response_command($cmd->get_node(0)->textContent());
 
 my $val = $resp->get_node(1)->getChildrenByTagName('value');
 Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "value" node below "response", found '.$val->size()) unless ($val->size()==1);
 $self->response_code($val->get_node(0)->textContent());
 
 my $msg=$root->getElementsByTagName('message');
 Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "message" node below root, found '.$msg->size()) unless ($msg->size()==1);
 
 if ( $oaction ne 'info' ) {
  $self->response_text($msg->get_node(0)->textContent());
 }
 else 
 {
  my $details = $msg->get_node(1)->getChildrenByTagName('details');
  Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "details" node below "message", found '.$details->size()) unless ($details->size()==1);
  
  my $conts_tag = $details->get_node(1)->getChildrenByTagName('contacts');
  Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "contacts" node below "details", found '.$conts_tag->size()) unless ($conts_tag->size()==1);
  my $conts = $conts_tag->get_node(1)->getChildrenByTagName('*');
  Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected at least one contact node below "contacts", found '.$conts->size()) unless ($conts->size()>=1);
  my %contacts;
  foreach my $cont ($conts->get_nodelist()) {
   $contacts{$cont->nodeName()} = $cont->textContent();
  }
  
  my $hosts_tag = $details->get_node(1)->getChildrenByTagName('hosts');
  Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "hosts" node below "details", found '.$hosts_tag->size()) unless ($hosts_tag->size()==1);
  my $hosts = $hosts_tag->get_node(1)->getChildrenByTagName('*');
  Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected at least one host node below "hosts", found '.$hosts->size()) unless ($hosts->size()>=1);
  my @hosts = ();
  foreach my $node ($hosts->get_nodelist()) {
   my ($what,$index) = $node->nodeName() =~ /^(\w+)(\d)$/;
   if  ( $what eq 'ns' ) {
    $hosts[$index] = [$node->textContent()];
   } else { #IP
    $hosts[$index][1] = $node->textContent();
   }
  }
  
  my $exp_date = $details->get_node(1)->getChildrenByTagName('expirydate');
  Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "expirydate" node below "details", found '.$exp_date->size()) unless ($exp_date->size()==1);
  
  my $status = $details->get_node(1)->getChildrenByTagName('status');
  Net::DRI::Exception->die(0,'protocol/NameAction',1,'Unsuccessful parse, expected one "status" node below "details", found '.$status->size()) unless ($status->size()==1);
  
  $self->response_attributes({ contacts    => \%contacts, 
  	                           hosts       => \@hosts, 
  	                           expiry_date => $exp_date->get_node(0)->textContent(),
  	                           status      => $status->get_node(0)->textContent() 
  });
 }

 $self->response_is_success(1);
 return;
}

####################################################################################################
1;
