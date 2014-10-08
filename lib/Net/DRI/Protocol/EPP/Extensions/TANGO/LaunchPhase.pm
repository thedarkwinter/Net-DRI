## Domain Registry Interface, Tango-RS EPP LaunchPhase Extension for managing launch phases 
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::TANGO::LaunchPhase;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark;
use Net::DRI::Protocol::EPP::Extensions::LaunchPhase;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TANGO::LaunchPhase - LaunchPhase EPP Extension for Corenic 

=head1 DESCRIPTION

Adds the LaunchPhase EPP Extension (based on dotSCOT-TechDoc-20140710.pdf) for Corenic TLDs. The extension is built by adding new XML nodes (ext:augmentedMark and ext:applicationInfo) and items (intended_use, reference_url, trademark_id, trademark_issuer)

=item intended_use [mandatory for all phases]

=item reference_url [mandatory for the custom phase and accepted only with the following sub_phase(public-interest|local-entities)]

=item trademark_id [mandatory for the custom phase and accepted only with the following sub_phases(local-trademark)]

=item trademark_issuer [mandatory for the custom phase and accepted only with the following sub_phases(local-trademark)]

 domain_create('domain.tld',{... trademark_id=>'my-mark-123',trademark_issuer=>'Trademark Administration of Someplace',intended_use=>'fooBAR'})

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHORS

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>.

(c) 2014 Michael Holloway <michael@thedarkwinter.com>.

(c) 2014 Paulo Jorge, <paullojorgge@gmail.com>.

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
        );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'lp');
 my $lpref = $rd->{'lp'};
 my @lps;
 Net::DRI::Exception::usererr_invalid_parameters('lp') unless ref($lpref) eq 'HASH' || ref($lpref) eq 'ARRAY';
 @lps = ($lpref) if ref($lpref) eq 'HASH';
 @lps = @{$lpref} if ref($lpref) eq 'ARRAY';

 foreach my $lp (@lps)
 {
  Net::DRI::Exception::usererr_insufficient_parameters('phase and intended_use mandatory') unless exists $lp->{phase} && $rd->{intended_use};  
  Net::DRI::Exception::usererr_invalid_parameters('type') if exists $lp->{type} && $lp->{type}  !~ m/^(application|registration)$/;
  Net::DRI::Exception::usererr_invalid_parameters('For create sunrise: at least one code_marks, signed_marks, encoded_signed_marks is required') if $lp->{'phase'} eq 'sunrise' and !(exists $lp->{code_marks} || exists $lp->{signed_marks} || exists $lp->{encoded_signed_marks}); 
  Net::DRI::Exception::usererr_invalid_parameters('Missing intended_use param') unless exists $rd->{intended_use};
  Net::DRI::Exception::usererr_insufficient_parameters('reference_url mandatory') if !exists $rd->{reference_url} && $lp->{phase} eq 'custom' && $lp->{sub_phase} =~ m/^(public-interest|local-entities)$/;
  Net::DRI::Exception::usererr_insufficient_parameters('trademark_id and trademark_issuer are mandatory') if !exists $rd->{trademark_id} && $lp->{phase} eq 'custom' && $lp->{sub_phase} =~ m/^(local-trademark)$/;

  my $eid = (exists $lp->{type}) ? $mes->command_extension_register('launch','create',{type => $lp->{type}}) : undef;
  $eid=$mes->command_extension_register('launch','create') unless defined $eid;
  my @n = Net::DRI::Protocol::EPP::Extensions::LaunchPhase::_build_idContainerType($lp);
  my @n2;
  
  # Code Marks
  if (exists $lp->{code_marks})
  {
   foreach my $cm (@{$lp->{code_marks}})
   {
     my @codemark;
     if (exists $cm->{code})
     {
      push @codemark,['launch:code',$cm->{code}] unless exists $cm->{validator_id};
      push @codemark,['launch:code', {'validatorID' => $cm->{validator_id} }, $cm->{code}] if exists $cm->{validator_id};
     }
     if (exists $cm->{mark})
     {
      push @codemark, [$cm->{mark}] if (ref $cm->{mark} eq 'XML::LibXML::Element');
      push @codemark, ['mark:mark', {'xmlns:mark'=>'urn:ietf:params:xml:ns:mark-1.0'}, Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::build_mark($cm->{mark})]  if ref $cm->{mark} eq 'HASH';
     }
   push @n2, ['launch:codeMark', @codemark];
   }
  }
  if (exists $lp->{signed_marks})
  {
   foreach my $sm (@{$lp->{signed_marks}})
   {
    Net::DRI::Exception::usererr_invalid_parameters('signedMark must be a valid XML root elemnt (e.g. imported from an SMD file)') unless ref $sm eq 'XML::LibXML::Element';
    push @n2,  [$sm];
   }
  }
  if (exists $lp->{encoded_signed_marks} && $rd->{intended_use})
  {
   foreach my $em (@{$lp->{encoded_signed_marks}})
   {
     if (ref $em eq 'XML::LibXML::Element')
     {
      push @n2, [$em];
     } elsif ($em =~ m!<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">\s*?(.*)</smd:encodedSignedMark>!s || $em =~ m!-----BEGIN ENCODED SMD-----\s*?(.*)\s*?-----END!s)
     {
      push @n2,['smd:encodedSignedMark', {'xmlns:smd'=>'urn:ietf:params:xml:ns:signedMark-1.0'},$1] if $1;       
     } elsif ($em =~ m!^[A-Za-z0-9\+/\=\s]+$!s) # aleady base64 string
     {
      push @n2,['smd:encodedSignedMark', {'xmlns:smd'=>'urn:ietf:params:xml:ns:signedMark-1.0'},$em] if $em;
     } else
     {
      Net::DRI::Exception::usererr_invalid_parameters('encodedSignedMark must ve a valid XML root element OR a string (e.g. imported from an Encoded SMD file)');
     }      
   }    
  }

  # augmented mark
  push @n2, ['ext:applicationInfo',{'type'=>'reference-url'},$rd->{reference_url} ] if $rd->{reference_url};
  push @n2, ['ext:applicationInfo',{'type'=>'trademark-id'},$rd->{trademark_id} ] if $rd->{trademark_id};
  push @n2, ['ext:applicationInfo',{'type'=>'trademark-issuer'},$rd->{trademark_issuer} ] if $rd->{trademark_issuer};
  push @n2, ['ext:applicationInfo',{'type'=>'intended-use'},$rd->{intended_use} ];
  push @n, ['ext:augmentedMark' , {'xmlns:ext'=>$mes->ns('mark-ext')},@n2] if @n2;


  # Claims  / Mixed
  if (exists $lp->{notices})
  {
   foreach my $nt (@{$lp->{notices}})
   {
    Net::DRI::Exception::usererr_invalid_parameters('notice id') unless defined $nt->{id};
    Net::DRI::Exception::usererr_invalid_parameters('notice not_after_date must be a Date::Time object') if exists $nt->{not_after_date} && !Net::DRI::Util::is_class($nt->{not_after_date},'DateTime');
    Net::DRI::Exception::usererr_invalid_parameters('notice accepted_date must be a Date::Time object') if exists $nt->{accepted_date} && !Net::DRI::Util::is_class($nt->{accepted_date},'DateTime');
    my @notice;
    push @notice,['launch:noticeID',$nt->{id}] unless exists $nt->{'validator_id'};
    push @notice,['launch:noticeID',{validatorID => $nt->{'validator_id'}},$nt->{id}] if exists $nt->{'validator_id'};
    push @notice,['launch:notAfter',Net::DRI::Util::dto2zstring($nt->{not_after_date})] if exists $nt->{not_after_date};
    push @notice,['launch:acceptedDate',Net::DRI::Util::dto2zstring($nt->{accepted_date})] if exists $nt->{accepted_date};
    push @n, ['launch:notice',@notice];
   }
  }
	
  shift $mes->command_extension($eid,\@n);
 }
 return;
}

####################################################################################################

1;
