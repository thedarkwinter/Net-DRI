## Domain Registry Interface, PIR EPP Validation Extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2014 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Afilias::Validation;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Extensions::LaunchPhase;
use Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark;

sub register_commands
{
  my ($class,$version)=@_;
  my %tmp=(
            create  => [ undef, \&parse ],
            update  => [ \&update, \&parse ],
        	);
  return { 'domain' => \%tmp };
}

sub setup
{
  my ($class,$po,$version)=@_;
  $po->ns({validation => ['urn:afilias:params:xml:ns:validation-1.0','validation-1.0.xsd']});
  $po->capabilities('domain_update','validation',['set']);
  return;
}

####################################################################################################
# parse validation extension from create and updare responses
sub parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  my $resdata;
  foreach my $ex (qw/creData updData/)
  {
    next unless $resdata=$mes->get_extension($mes->ns('validation'),$ex);
    foreach my $el (Net::DRI::Util::xml_list_children($resdata))
    {
      my ($name,$content)=@$el;
      $rinfo->{domain}->{$oname}->{validation} = {claim_id => $content->textContent()} if ($name=~m/^(claimID)$/);
    }
  }
  return;
}

####################################################################################################
# update (change of ownership)
sub update
{
  my ($epp,$domain,$todo)=@_;
  return unless my $ch=$todo->set('validation');
  return unless $ch;

  my $mes=$epp->message();
  my $eid=$mes->command_extension_register('validation','update');
  my @n = ['validation:chg',['validation:ownership','']];
  $mes->command_extension($eid,\@n);

  return;
}

####################################################################################################
1;
