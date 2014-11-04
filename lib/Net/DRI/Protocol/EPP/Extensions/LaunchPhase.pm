## Domain Registry Interface, EPP LaunchPhase Extensions (draft-ietf-eppext-launchphase-02)
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013-2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## LaunchPhase ext based on IETF draft 02 : http://tools.ietf.org/html/draft-ietf-eppext-launchphase-02
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::LaunchPhase;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LaunchPhase - EPP LaunchPhase commands (draft-ietf-eppext-launchphase-02) for Net::DRI

=head1 DESCRIPTION

LaunchPhase Extensions for L<NET::DRI>

=head1 SYNOPSIS

To utilize this extension, an additional hash 'lp' must be used with domain commands. Results will contain the hash called $lp, so a LaunchPhase results should be obtained by callind $lp = $dri->get_info('lp');

=head1 LaunchPhase Phase overview

The LaunchPhase hash always includes a 'phase', as well as additional data for different commands.

The standard phases are sunrise, landrush, claims, open. Any other value will automatically put it through as a custom phase. Subphases can be used where required. See the following examples

 $lp_eg1 = {'phase'=>'sunrise'}; # sunrise phases
 $lp_eg2 = {'phase'=>'custom','sub_phase'=>'idn-sunrise'}; # a custom phase with a sub_phase name
 $lp_eg3 = {'phase'=>'idn-sunrise'}; # technically a custom phase, this extension will automatically detect that, and produce the same result as $lp_eg2
 $lp_eg4 = {'phase'=>'claims','sub_phase'=>'landrush'}; # using the standard phase 'claims' with a sub_phase 'landrush'
 
=head1 Commands

The LaunchPhase extension is used in  domain check, info, create, update, and delete commands.  
 
=head2 check

=item type (either 'claims' or 'avail')

=item phase (phase will be set to 'claims' if type is claims)

  $rc = $dri->domain_check('example1.tld',{lp => {'type'=>'claims'}});
  print "exists" if $dri->get_info('exist'); # for domain_check, exist can be called directly (without get_info('lp')). This will indicate its LP exist result.
  $rc = $dri->domain_check('example1.tld','example2.tld',{lp => {'type'=>'avail','phase'=>'sunrise'}});
  $lp = $dri->get_info('lp','domain','example2.tld');
  # note: check for validator_id as its optional but required when using claims_create
  
  ## LaunchPhase-02 introduced the possibility of having multiple claims key elements, but since we used a hash in this module we don't wont to break previous implementations.
  # $lp->{claims_key} and $lp->{validator_id} still exist but if there are more than one then it will be the last claim key only.
  # $lp->{claims} (array of hashes containting claims_key and validators) and $lp->{claims_count} (integer) have been added.
  
=head2 info

=item include_mark (set to a true value to include mark information)

=item phase 

=item application_id (optional)

  $rc = $dri->domain_info(example1.tld',{phase => 'sunrise','application_id'=>'abc123','include_mark'=>'true'});
  $lp = $dri->get_info('lp');
  print "Launch status is " . $lp->status();

  # this might well change:
  @marks = @{$lpres->{'marks'}};
  my $m = shift @marks;
  print "mark name is " . $m->{mark_name};

=head2 create

These two parameters can be used in all forms of create described below.

=item type (application or registration), optional. NOTE: I'm not yet sure what the difference is here!

=item phase

=head2 Different forms of create

There are 4 forms of domain_create: Sunrise, Claims, General, Mixed. Additionally, there are 5 different models for Sunrise Creates. See the tests files for exampl more details and examples.

=head3 Sunrise form

=item B<Code / Mark / Code with Mark Validation Model> - code_marks is an array of codes and/or marks with an optional validator_id. mark can be either a mark hashref (see L<Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark>) *OR* XML::LibXML::Element root

  $rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>{'code_marks'=>[ {code=>'123',validator_id=>'abc_validator'},{code=>456}] }});
  $rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>{'code_marks'=>[ {mark =>$mark },{code=>456}] }});

=item B<Signed Mark Validation Model>: signed_marks is an array of signed marks; these must be XML::LibXML::Element root objects

  $rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=> {phase => 'sunrise','signed_marks'=>[ $root ] });

=item B<Encoded Signed Mark Validation Model>: encoded_signed_marks is an array of encoded signed marks; and these can be plain text (base64 encoded) *OR* XML::LibXML::Element root

  $rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp => { phase => 'sunrise','encoded_signed_marks'=>[ $enc ] } );

=head3 Claims form : 

And array of hashes A hash containing three or four keys

=item id

=item not_after_date

=item accepted_date

=item validator_id (optional validator_id returned with claims_check if required. the default when not set is the  ICANN assigned TMCH)

  $lp = {phase => 'claims', notices => [ {'id'=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ] };

=head3 General form

Used for landrush or other phases

  $lp = { phase => 'landrush' } ;

=head3 Mixed form (Mixes Sunrise and Claims forms)

  $lp = { phase => 'landrush' , encoded_signed_marks'>[ $enc ] , notices => {...} } ;
  
=head2 Multiple Launch Extensions

You can create with multiple launch extensions by using an array reference

  my $lp1 = { phase => 'landrush','type' =>'application' };
  my $lp2 = { type=>'registration', phase => 'claims',notices => [ {'id'=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ]  };
  $rc=$dri->domain_create('example4.com',{pure_create=>1,auth=>{pw=>'2fooBAR'}, lp => [$lp1,$lp2] );

=head2 update & delete

=item phase

=item application_id (required)

  $rc = $dri->domain_update(example1.tld',{phase => 'sunrise','application_id'=>'abc123'});
  $rc = $dri->domain_delete(example1.tld',{phase => 'sunrise','application_id'=>'abc123'});

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>,
(c) 2013-2014 Michael Holloway <michael@thedarkwinter.com>.
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
 my %d=(
        check   => [ \&check, \&check_parse ],
        check_multi  => [ \&check, \&check_parse ],
        info      => [ \&info, \&info_parse ],
        create    => [ \&create, \&create_parse ],
        update    => [ \&update_delete ],
        delete   => [ \&update_delete],
       );

 return { 'domain' => \%d };
}

sub capabilities_add { return (['domain_update','lp',['set']]); }

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'launch' => [ 'urn:ietf:params:xml:ns:launch-1.0','launch-1.0.xsd' ] });
 return;
}

####################################################################################################
########### Some validators (?)

sub _build_idContainerType
{
 my $lp = shift;
 my @n;
 unless ($lp->{phase} =~ m/^(sunrise|landrush|claims|open|custom)$/) # autodetect custom
 {
   $lp->{sub_phase} = $lp->{phase};
   $lp->{phase} = 'custom';
 }
 push @n, ['launch:phase',$lp->{phase}] if ((exists $lp->{phase}) and (not exists $lp->{sub_phase}));
 push @n, ['launch:phase',{name=>$lp->{sub_phase}},$lp->{phase}] if exists $lp->{sub_phase};
 push @n, ['launch:applicationID',$lp->{application_id}] if exists $lp->{application_id};
 return @n;
}

####################################################################################################
########### Query commands

# Check
# type [claims, phase]
# phase [phaseType]
sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'lp');

 my $lp = $rd->{'lp'};
 Net::DRI::Exception::usererr_invalid_parameters('type must be claims or avail') if exists $lp->{type} && $lp->{type}  !~ m/^(claims|avail)$/;
 # according to RFC draft, phase *should* be set claims when the type is claims, but we will not change it if the user has set something else so it can auto/custom it.
 $lp->{phase} = 'claims' if exists $lp->{type} && $lp->{type} eq 'claims' && (!exists $lp->{phase} || !$lp->{phase});
 Net::DRI::Exception::usererr_insufficient_parameters('phase') unless exists $lp->{phase};
 delete $lp->{application_id} if exists $lp->{application_id};

 my $eid = (exists $lp->{type}) ? $mes->command_extension_register('launch','check',{type => $lp->{type}}) : undef;
 $eid=$mes->command_extension_register('launch','check') unless defined $eid;

 my @n = _build_idContainerType($lp);
 $mes->command_extension($eid,\@n);

 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_extension($mes->ns('launch'),'chkData');
 return unless defined $chkdata;

 my $phaseel = $chkdata->getChildrenByTagNameNS($mes->ns('launch'),'phase')->shift();
 my $phase = (defined $phaseel && $phaseel->textContent()) ? $phaseel->textContent() : 'wtf';
 my $type = ($chkdata->hasAttribute('type'))?$chkdata->getAttribute('type'):undef;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('launch'),'cd'))
 {
  my ($domain,@claims);
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'name')
   {
    $domain=lc($c->textContent());
    $rinfo->{domain}->{$domain}->{action}='check';
    $rinfo->{domain}->{$domain}->{lp}->{exist} = $rinfo->{domain}->{$domain}->{exist} = Net::DRI::Util::xml_parse_boolean($c->getAttribute('exists'));
    $rinfo->{domain}->{$domain}->{lp}->{phase} = $phase;
    $rinfo->{domain}->{$domain}->{lp}->{type} = $type if defined $type;
   } elsif ($n eq 'claimKey')
   {
    # launchphase-02 can have multile claims with different validators (e.g. custom tmch and maybe in future govs etc)
    my $claim = { claim_key => $c->textContent() };
    $claim->{validator_id} = $c->getAttribute('validatorID') if $c->hasAttribute('validatorID');
    push @claims,$claim;
    
    # pre launchphase-02 we only had one, but removing this might break some implementations so will store the last claim_key (which is more than likely the only one!)
    $rinfo->{domain}->{$domain}->{lp}->{claim_key} = $c->textContent();
    $rinfo->{domain}->{$domain}->{lp}->{validator_id} = $c->getAttribute('validatorID') if $c->hasAttribute('validatorID');
   }
  }
  if (@claims) {
   $rinfo->{domain}->{$domain}->{lp}->{claims} = \@claims;
   $rinfo->{domain}->{$domain}->{lp}->{claims_count} = $#claims+1;
  }
 }
 return;
}


###############

# Info - <launch:infoType> is the same as <launch:idContainerType> but adds includeMark
# phase [phaseType]
# applicationID [applicationIDType]
#  includeMark / boolean
sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'lp');
 my $lp = $rd->{'lp'};

 Net::DRI::Exception::usererr_insufficient_parameters('phase') unless exists $lp->{phase};
 Net::DRI::Exception::usererr_invalid_parameters('application_id') if (exists $lp->{application_id} && $lp->{application_id} eq '');
 
 my $eid = (exists $lp->{include_mark} && $lp->{include_mark} && $lp->{include_mark} !~ m/^(no|false)$/) ? $mes->command_extension_register('launch','info',{includeMark => 'true'}) : undef;
 $eid=$mes->command_extension_register('launch','info') unless defined $eid;

 my @n = _build_idContainerType($lp);
 $mes->command_extension($eid,\@n);

 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 
 my $infdata=$mes->get_extension($mes->ns('launch'),'infData');
 return unless defined $infdata;
 
 my @marks;
 my $lp = {}; # since poll parsing doesn't allways have a domain name, we put this into a hashref first
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
    my ($n,$c)=@$el;
    $lp->{phase}=$c->textContent() if $n eq 'phase';
    $lp->{application_id}=$c->textContent() if $n eq 'applicationID';
    $lp->{status}=$c->getAttribute('s') if $n eq 'status'; # Note: IN draft 01 the wording was changed to indicate only one status, but some previous implementations may have more than one (?)
    ## FIXME - THERE COULD BE MARK DATA HERE
    if ($n eq 'mark')
    {
      $lp->{marks} = () unless exists $lp->{marks};
      foreach my $m (@{Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_mark($po,$c)})
      {
        push @{$lp->{marks}}, $m;
      }
    }
  }
 if (defined $oname) { # this is a response to domain_info
  $rinfo->{domain}->{$oname}->{lp} = $lp;
 } else { # this is a response to message_retrieve *without* a domain name, so we use the application_id as the the $oname, and put the data in {message} instead of {domain}
  $oname = exists $lp->{application_id} ? $lp->{application_id} : 'unknown_application';
  $rinfo->{message}->{$oname}->{lp} = $lp;
 }
 return;
}

############ Transform commands

# type [application,registration], 
# phase [phaseType], 
# (one or more of these!) codeMark / smd:abstractSignedMark / smd:encodedSignedMark
# notice [noticeID,noticeAfter,acceptedDate, registration]
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
  Net::DRI::Exception::usererr_insufficient_parameters('phase') unless exists $lp->{phase};
  Net::DRI::Exception::usererr_invalid_parameters('type') if exists $lp->{type} && $lp->{type}  !~ m/^(application|registration)$/;
  Net::DRI::Exception::usererr_invalid_parameters('For create sunrise: at least one code_marks, signed_marks, encoded_signed_marks is required') if $lp->{'phase'} eq 'sunrise' and !(exists $lp->{code_marks} || exists $lp->{signed_marks} || exists $lp->{encoded_signed_marks}); 

  my $eid = (exists $lp->{type}) ? $mes->command_extension_register('launch','create',{type => $lp->{type}}) : undef;
  $eid=$mes->command_extension_register('launch','create') unless defined $eid;
  my @n =_build_idContainerType($lp);
  
   # Code Marks
   if (exists $lp->{code_marks})
   {
    foreach my $cm (@{$lp->{code_marks}})
    {
      # FIXME validate each $cm ?
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
      push @n, ['launch:codeMark', @codemark];
    }
   }
   # Signed Marks # FIXME: I HAVE NO IDEA IF THIS WILL WORK!!!
   if (exists $lp->{signed_marks})
   {
    foreach my $sm (@{$lp->{signed_marks}})
    {
      # FIXME validate each $sm ?
      Net::DRI::Exception::usererr_invalid_parameters('signedMark must be a valid XML root elemnt (e.g. imported from an SMD file)') unless ref $sm eq 'XML::LibXML::Element';
      push @n,  [$sm];
    }
   }
   ## Encoded Signed Marks  # FIXME: I Am assuming the input will already be BASE64 encoded
   if (exists $lp->{encoded_signed_marks})
   {
    foreach my $em (@{$lp->{encoded_signed_marks}})
    {
      if (ref $em eq 'XML::LibXML::Element')
      {
       push @n, [$em];
      } elsif ($em =~ m!<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">\s*?(.*)</smd:encodedSignedMark>!s || $em =~ m!-----BEGIN ENCODED SMD-----\s*?(.*)\s*?-----END!s)
      {
       push @n,['smd:encodedSignedMark', {'xmlns:smd'=>'urn:ietf:params:xml:ns:signedMark-1.0'},$1] if $1;
      } elsif ($em =~ m!^[A-Za-z0-9\+/\=\s]+$!s) # aleady base64 string
      {
       push @n,['smd:encodedSignedMark', {'xmlns:smd'=>'urn:ietf:params:xml:ns:signedMark-1.0'},$em] if $em;
      } else
      {
       Net::DRI::Exception::usererr_invalid_parameters('encodedSignedMark must ve a valid XML root element OR a string (e.g. imported from an Encoded SMD file)');
      }
    }
   }
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
   
  $mes->command_extension($eid,\@n);
 }
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $credata=$mes->get_extension($mes->ns('launch'),'creData');
 return unless defined $credata;
  
 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
      my ($n,$c)=@$el;
      $rinfo->{domain}->{$oname}->{lp}->{phase}=$c->textContent() if $n eq 'phase';
      $rinfo->{domain}->{$oname}->{lp}->{application_id}=$c->textContent() if $n eq 'applicationID';
 }

 return;
}

# Update & Delete both use <launch:idContainerType>
# phase [phaseType]
# applicationID [applicationIDType]
sub update_delete
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my ($lp,$cmd);
 if (UNIVERSAL::isa($rd,'Net::DRI::Data::Changes')) {
   $cmd = 'update';
   $lp =$rd->set('lp');
   return unless $lp;
 }
 else {
  return unless Net::DRI::Util::has_key($rd,'lp');
  $cmd = 'delete';
  $lp = $rd->{'lp'};
 }
 
 Net::DRI::Exception::usererr_insufficient_parameters('phase') unless exists $lp->{phase};
 Net::DRI::Exception::usererr_insufficient_parameters('application_id') unless exists $lp->{application_id};

 my $eid=$mes->command_extension_register('launch',$cmd);
 my @n =_build_idContainerType($lp);

 $mes->command_extension($eid,\@n);

 return;
}

####################################################################################################
1;
