## Domain Registry Interface, .AU Domain EPP extension commands
##
## Copyright (c) 2007,2008,2013 Distribute.IT Pty Ltd, www.distributeit.com.au, Rony Meyer <perl@spot-light.ch>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AU::Domain;

use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AU::Domain - .AU EPP Domain extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Rony Meyer, E<lt>perl@spot-light.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008,2013 Distribute.IT Pty Ltd, E<lt>http://www.distributeit.com.auE<gt>, Rony Meyer <perl@spot-light.ch>.
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
          create => [ \&create, undef ],
          info   => [ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:auext="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('auext')));
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('eligibility attribute is mandatory, as ref hash') 
         unless (exists($rd->{eligibility}) && (ref($rd->{eligibility}) eq 'HASH'));

 Net::DRI::Exception::usererr_insufficient_parameters('eligibility attribute missing key registrantName') 
         unless (exists($rd->{eligibility}->{registrantName}) && $rd->{eligibility}->{registrantName});
 Net::DRI::Exception::usererr_insufficient_parameters('eligibility attribute missing key policyReason') 
         unless (exists($rd->{eligibility}->{policyReason}) && $rd->{eligibility}->{policyReason});
 Net::DRI::Exception::usererr_insufficient_parameters('eligibility attribute missing key eligibilityType') 
         unless (exists($rd->{eligibility}->{eligibilityType}) && $rd->{eligibility}->{eligibilityType});

 my @n;
 push @n,['auext:registrantName',$rd->{eligibility}->{registrantName}];
 if (exists $rd->{eligibility}->{registrantID} && $rd->{eligibility}->{registrantID} &&
     exists $rd->{eligibility}->{registrantIDType} && $rd->{eligibility}->{registrantIDType}) {
   push @n,['auext:registrantID',$rd->{eligibility}->{registrantID},{'type'=> $rd->{eligibility}->{registrantIDType}}];
 }
 push @n,['auext:eligibilityType',$rd->{eligibility}->{eligibilityType}];
 push @n,['auext:eligibilityName',$rd->{eligibility}->{eligibilityName}] if exists $rd->{eligibility}->{eligibilityName} && $rd->{eligibility}->{eligibilityName};
 if (exists $rd->{eligibility}->{eligibilityID} && $rd->{eligibility}->{eligibilityID} &&
     exists $rd->{eligibility}->{eligibilityIDType} && $rd->{eligibility}->{eligibilityIDType}) {
   push @n,['auext:eligibilityID',$rd->{eligibility}->{eligibilityID},{'type'=> $rd->{eligibility}->{eligibilityIDType}}];
 }
 push @n,['auext:policyReason',$rd->{eligibility}->{policyReason}];

 my $eid=build_command_extension($mes,$epp,'auext:extensionAU');

 my @nn;
 push @nn, ['auext:create',@n];

 $mes->command_extension($eid,\@nn);
 return;
}


sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('auextnew','infData');
 return unless $infdata;

 my %ens;
 my $c=$infdata->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

	# if ($name eq 'info')
  if ($name eq 'auProperties')
  {
   my $cc=$c->getFirstChild();
   while($cc)
   {
    next unless ($cc->nodeType() == 1); ## only for element nodes
    my $name2=$cc->localname() || $cc->nodeName();
    next unless $name2;

    if ($name2 eq 'registrantName')
    {
     $ens{registrantName}=$cc->getFirstChild()->getData();
    } elsif ($name2 eq 'registrantID')
    {
     $ens{registrantID}=$cc->getFirstChild()->getData();
     $ens{registrantIDType}=$cc->getAttribute('type'); #registrantID
    } elsif ($name2 eq 'eligibilityType')
    {
     $ens{eligibilityType}=$cc->getFirstChild()->getData();
    } elsif ($name2 eq 'eligibilityName')
    {
     $ens{eligibilityName}=$cc->getFirstChild()->getData();
    } elsif ($name2 eq 'eligibilityID')
    {
     $ens{eligibilityID}=$cc->getFirstChild()->getData();
     $ens{eligibilityIDType}=$cc->getAttribute('type'); #eligibilityID
    } elsif ($name2 eq 'policyReason')
    {
     $ens{policyReason}=$cc->getFirstChild()->getData();
    }
   } continue { $cc=$cc->getNextSibling(); }
  }
 } continue { $c=$c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{eligibility}=\%ens;
 return;
}
####################################################################################################
1;
