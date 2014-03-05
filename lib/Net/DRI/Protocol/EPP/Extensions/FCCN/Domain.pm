## Domain Registry Interface, .PT Domain EPP extension commands
##
## Copyright (c) 2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::FCCN::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FCCN::Domain - FCCN (.PT) EPP Domain extension commands for Net::DRI

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

Copyright (c) 2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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
          create => [ \&create, \&create_parse ],
          info   => [ \&info, \&info_parse ],
          update => [ \&update ],
          renew  => [ \&renew ],
          renounce => [ \&renounce ],
          delete => [ \&delete ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:ptdomain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ptdomain')));
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('Registrant contact required for .PT domain name creation') unless (Net::DRI::Util::has_contact($rd) && $rd->{contact}->has_type('registrant'));
 Net::DRI::Exception::usererr_insufficient_parameters('Tech contact required for .PT domain name creation') unless (Net::DRI::Util::has_contact($rd) && $rd->{contact}->has_type('tech'));

 foreach my $d (qw/legitimacy registration_basis add_period next_possible_registration auto_renew/)
 {
  Net::DRI::Exception::usererr_insufficient_parameters($d.' attribute is mandatory for .PT domain name creation') unless Net::DRI::Util::has_key($rd,$d);
 }
 Net::DRI::Exception::usererr_invalid_parameters('legitimacy attribute must be 0,1,2,3,4 or 5') unless ($rd->{legitimacy}=~m/^[01245]$/);
 Net::DRI::Exception::usererr_invalid_parameters('registration_basis attribute must be 010,020,030,040,050,060,070,080,090,100') unless ($rd->{registration_basis}=~m/^(?:0[123456789]0|100)$/);
 foreach my $d (qw/add_period next_possible_registration auto_renew/)
 {
  Net::DRI::Exception::usererr_invalid_parameters($d.' must be either 0 or 1 for .PT domain name creation') unless ($rd->{$d}==0 || $rd->{$d}==1);
 }

 my @n;
 push @n,['ptdomain:legitimacy',{type => $rd->{legitimacy}}];
 push @n,['ptdomain:registration_basis',{type => $rd->{registration_basis}}];
 push @n,['ptdomain:addPeriod',$rd->{add_period}];
 push @n,['ptdomain:nextPossibleRegistration',$rd->{next_possible_registration}];
 push @n,['ptdomain:autoRenew',$rd->{auto_renew}];
 my $eid=build_command_extension($mes,$epp,'ptdomain:create');
 $mes->command_extension($eid,\@n);
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_extension('ptdomain','creData');
 return unless $credata;

 my $c=$credata->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $n=$c->localname() || $c->nodeName();
  if ($n eq 'roid')
  {
   $rinfo->{domain}->{$oname}->{roid}=$c->getFirstChild()->getData();
  }
 } continue { $c=$c->getNextSibling(); }
 return;
}

sub add_roid
{
 my ($roid)=@_;
 return ['ptdomain:roid',$roid];
}

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('roid attribute required for .PT domain name info') unless (Net::DRI::Util::has_key($rd,'roid'));

 my $eid=build_command_extension($mes,$epp,'ptdomain:info');
 my @n=add_roid($rd->{roid});
 $mes->command_extension($eid,\@n);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('ptdomain','infData');
 return unless $infdata;

 my $c=$infdata->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name=~m/^(?:legitimacy|registration_basis)$/)
  {
   $rinfo->{domain}->{$oname}->{$name}=$c->getAttribute('type');
  } elsif ($name=~m/^(?:autoRenew|notRenew|nextPossibleRegistration|addPeriod|waitingRemoval)$/)
  {
   $rinfo->{domain}->{$oname}->{Net::DRI::Util::remcam($name)}=Net::DRI::Util::xml_parse_boolean($c->getFirstChild()->getData());
  } elsif ($name eq 'renew')
  {
   $rinfo->{domain}->{$oname}->{renew_period}=DateTime::Duration->new(years => $c->getAttribute('period'));
  }
 } continue { $c=$c->getNextSibling(); }
 return;
}

sub update
{
 my ($epp,$domain,$toc,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('roid attribute required for .PT domain name update') unless (Net::DRI::Util::has_key($rd,'roid'));

 my $eid=build_command_extension($mes,$epp,'ptdomain:update');
 my @n=add_roid($rd->{roid});
 $mes->command_extension($eid,\@n);
 return;
}

sub renew
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('roid attribute required for .PT domain name renew') unless (Net::DRI::Util::has_key($rd,'roid'));

 my $c=Net::DRI::Util::has_key($rd,'duration');
 foreach my $d (qw/auto_renew not_renew/)
 {
  next unless Net::DRI::Util::has_key($rd,$d);
  Net::DRI::Exception::usererr_invalid_parameters($d.' must be either 0 or 1 for .PT domain name creation') unless ($rd->{$d}==0 || $rd->{$d}==1);
  $c+=$rd->{$d};
 }
 Net::DRI::Exception::usererr_invalid_parameters('only one of duration, auto_renew and not_renew attributes can be set for .PT domain name renew') if $c > 1;

 my $eid=build_command_extension($mes,$epp,'ptdomain:renew');
 my @n=add_roid($rd->{roid});
 push @n,['ptdomain:autoRenew',$rd->{auto_renew}] if Net::DRI::Util::has_key($rd,'auto_renew');
 push @n,['ptdomain:notRenew',$rd->{not_renew}] if Net::DRI::Util::has_key($rd,'not_renew');
 $mes->command_extension($eid,\@n);
 return;
}

sub renounce
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('roid attribute required for .PT domain name renounce') unless (Net::DRI::Util::has_key($rd,'roid'));

 my $eid=build_command_extension($mes,$epp,'ptdomain:renounce');
 my @n=(['ptdomain:name',$domain]);
 push @n,add_roid($rd->{roid});
 push @n,['ptdomain:clTRID',$mes->cltrid()];
 $mes->command_extension($eid,\@n);
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('roid attribute required for .PT domain name delete') unless (Net::DRI::Util::has_key($rd,'roid'));

 my $eid=build_command_extension($mes,$epp,'ptdomain:delete');
 my @n=add_roid($rd->{roid});
 $mes->command_extension($eid,\@n);
 return;
}

####################################################################################################
1;
