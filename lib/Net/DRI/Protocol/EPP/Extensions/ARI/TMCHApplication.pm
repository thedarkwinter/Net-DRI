## Domain Registry Interface, EPP ARI TMCH + Application Extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ARI::TMCHApplication;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ARI::TMCHApplication - TMCH L<http://ausregistry.github.io/doc/tmch-1.0/tmch-1.0.html> And Application Extension for ARI : L<http://ausregistry.github.io/doc/application-1.0/application-1.0.html>

=head1 DESCRIPTION

Adds the TMCH (urn:ar:params:xml:ns:tmch-1.0) and Application (urn:ar:params:xml:ns:application-1.0) Extensions to domain commands. Given that these two combined effectively replace the LaunchPhase extension, I have merged in these two files and will attempt to keep the syntax as close as possible to the LaunchPhase extension.

=head1 SYNOPSIS

To utilize this extension, an additional hash 'lp' must be used with domain commands. Results will contain the hash called $lp, so results should be obtained by callind $lp = $dri->get_info('lp');

=head2 check

=item type (claims only)

  to do a claims check
 $rc = $dri->domain_check('example1.tld',{lp => {'type'=>'claims'}});
 $lp = $dri->get_info('lp');
 print $lp->{'claim_key'} if $lp->{exist};
 
=head2 info

=item include_mark (set to a true value to include mark information - will return an encoded_signed_mark)

=item application_id (optional)

  $rc = $dri->domain_info(example1.tld',{'application_id'=>'abc123','include_mark'=>'true'});
  $lp = $dri->get_info('lp');
  print "Launch status is " . $lp->status();
  
  # this might well change:
  @marks = @{$lpres->{'marks'}};
  my $m = shift @marks;
  print "mark name is " . $m->{mark_name};

=head2 create

This differs somewhat from LaunchPhase, but there are four different create commands (Sunrise Create,Claims Create, Application Create, Application Allocate ). Its possible they can be used in combination; to look into. In the mean time extenion will try build combinations anyway.

=head3 Sunrise Create (The same syntax as LaunchPhase Sunrise Encoded Signed Mark Validation Model)

  $rc=$dri->domain_create('example4.tld',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp => { phase => 'sunrise','encoded_signed_marks'=>[ $enc ] } );
  print "application Id is: " . $dri->get_info('lp')->{application_id};
  
=head3 Claims Create (The same syntax as LaunchPhase Claims Create). Additionally (untested), you can add the encoded_signed_mark to simulate the LaunchPhase mixed create (Sunrise + Claims)

  $lp = {phase => 'claims', notices => [ {'id'=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ] }; # claims
  $lp = {phase => 'claims', 'encoded_signed_marks'=>[ $enc ] , notices => [ {'id'=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ] }; # mixed sunrise+claims
  $rc = $dri->domain_create(example4.tld',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp => $lp } );

=head3 Application Create  (The same sytax as LaunchPhase General form)

Used for landrush or other (?) phases

  $lp = { phase => 'landrush' } ;
  $rc = $dri->domain_create(example4.tld',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp => $lp } );

=head3 Application Allocate (Not actually sure what this is for, but requires phase and application_id)

Used for landrush or other (?) phases

  $lp = { phase => 'landrush' ,'application_id'=> ' my-app-id'} ;
  $rc = $dri->domain_create(example4.tld',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp => $lp } );

=head2 update & delete

=item phase (optional ?)

=item application_id (required)

  $rc = $dri->domain_update(example4.tld',{phase => 'sunrise','application_id'=>'abc123'});
  $rc = $dri->domain_delete(example4.tld',{phase => 'sunrise','application_id'=>'abc123'});

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
(c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
     check  =>  [ \&check, \&check_parse ],
     info   =>     [ \&info, \&info_parse ],
     create =>  [ \&create, \&create_parse ], # not sure if there is a create_response!
     delete =>  [ \&update_delete, undef ],
     update =>  [ \&update_delete, undef ],
     );
 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'application' => [ 'urn:ar:params:xml:ns:application-1.0','application-1.0.xsd' ],
                       'tmch' => [ 'urn:ar:params:xml:ns:tmch-1.0','tmch-1.0.xsd' ]});
 return;
}

sub capabilities_add { return (['domain_update','lp',['set']]); }

####################################################################################################

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'lp');
 my $lp = $rd->{'lp'};
 Net::DRI::Exception::usererr_invalid_parameters('lp type must be claims') if exists $lp->{type} && $lp->{type}  ne 'claims';
 my $eid=$mes->command_extension_register('tmch','check');
 $mes->command_extension($eid,[]);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $chkdata=$mes->get_extension($mes->ns('tmch'),'chkData');
 return unless defined $chkdata;
 
 foreach my $el (Net::DRI::Util::xml_list_children($chkdata))
 {
   my ($n,$c)=@$el;
   if ($n eq 'cd')
   {
    my $dn = '';
    foreach my $el2 (Net::DRI::Util::xml_list_children($c))
    {
     my ($n2,$c2)=@$el2;
     if ($n2 eq 'name')
     {
      $dn = $c2->textContent();
      $rinfo->{domain}->{$dn}->{action}='check';
      $rinfo->{domain}->{$dn}->{lp}->{exist} = $rinfo->{domain}->{$dn}->{exist} = Net::DRI::Util::xml_parse_boolean($c2->getAttribute('claim'));
      $rinfo->{domain}->{$dn}->{lp}->{type} = $rinfo->{domain}->{$dn}->{lp}->{phase} = 'claims';
     }
     $rinfo->{domain}->{$dn}->{lp}->{claim_key} = $c2->textContent() if $n2 eq 'key';
    }
   }
 }
  return;
}

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'lp');
 my $lp = $rd->{'lp'};

 ## Application
 if (exists $lp->{application_id})
 {
   my $eid=$mes->command_extension_register('application','info');
   $mes->command_extension($eid,(['application:id',$lp->{'application_id'}]));
 }

 ## Tmch
 if (exists $lp->{include_mark} && $lp->{include_mark} && $lp->{include_mark} !~ m/^(no|false)$/)
 {
   my $eid=$mes->command_extension_register('tmch','info');
   $mes->command_extension($eid,[]);
 }
 
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $app_infData=$mes->get_extension($mes->ns('application'),'infData');
 my $tmch_infData=$mes->get_extension($mes->ns('tmch'),'infData');
 
 if ($app_infData)
 {
  foreach my $el (Net::DRI::Util::xml_list_children($app_infData))
  {
   my ($n,$c)=@$el;
   $rinfo->{domain}->{$oname}->{lp}->{phase}=$c->textContent() if $n eq 'phase';
   $rinfo->{domain}->{$oname}->{lp}->{application_id}=$c->textContent() if $n eq 'id';
   $rinfo->{domain}->{$oname}->{lp}->{status}=$c->getAttribute('s') if $n eq 'status';
  }
 }
 
 if ($tmch_infData)
 {
  foreach my $el (Net::DRI::Util::xml_list_children($tmch_infData))
  {
   my ($n,$c)=@$el;
   if ($n eq 'smd')
   {
    $rinfo->{domain}->{$oname}->{lp}->{marks} = ();
    my $mark = Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_encoded_signed_mark($po,$c);
    push @{$rinfo->{domain}->{$oname}->{lp}->{marks}}, shift $mark->{'mark'} if $mark;
   }
  }
 }
 return;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'lp');

 my $lp = $rd->{'lp'};
 my @n;
 Net::DRI::Exception::usererr_insufficient_parameters('phase not specified in launchphase extension') unless defined $lp->{phase};

 ## Application
 my $a_eid=$mes->command_extension_register('application','create');
 push @n,['application:id',$lp->{'application_id'}] if exists $lp->{application_id};
 push @n,['application:phase',$lp->{'phase'}];
 $mes->command_extension($a_eid,\@n);


 ## TMCH 
 if (exists $lp->{phase} && (exists $lp->{notices} || exists $lp->{encoded_signed_marks}) ) 
 {
  @n=();
  
  # Sunrise or Mixed (Claims+Sunrise) : Add SMD
  Net::DRI::Exception::usererr_insufficient_parameters('encoded_signed_marks')  if ($lp->{phase} eq 'sunrise' && !exists $lp->{encoded_signed_marks});
  if (exists $lp->{encoded_signed_marks})
  {
   foreach my $em (@{$lp->{encoded_signed_marks}})
   {
     if (ref $em eq 'XML::LibXML::Element')
     {
      push @n, ['tmch:smd',$em->textContent()];
     } elsif ($em =~ m!<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">\s*?(.*)</smd:encodedSignedMark>!s || $em =~ m!-----BEGIN ENCODED SMD-----\s*?(.*)\s*?-----END!s)
     {
      push @n,['tmch:smd', $1] if $1;
     } elsif ($em =~ m!^[A-Za-z0-9\+/\=\s]+$!s) # aleady base64 string
     {
      push @n,['tmch:smd', $em];
     } else
     {
      Net::DRI::Exception::usererr_invalid_parameters('encodedSignedMark must ve a valid XML root element OR a string (e.g. imported from an Encoded SMD file)');
     }
   }
  }

   # Claims Notices
  if (exists $lp->{notices})
  {
   my $nt = (ref $lp->{notices} eq 'ARRAY') ? shift @{$lp->{notices}} : $lp->{notices};
   Net::DRI::Exception::usererr_invalid_parameters('notice id') unless defined $nt->{id};
   Net::DRI::Exception::usererr_invalid_parameters('notice not_after_date must be a Date::Time object') if exists $nt->{not_after_date} && !Net::DRI::Util::is_class($nt->{not_after_date},'DateTime');
   Net::DRI::Exception::usererr_invalid_parameters('notice accepted_date must be a Date::Time object') if exists $nt->{accepted_date} && !Net::DRI::Util::is_class($nt->{accepted_date},'DateTime');
   push @n,['tmch:noticeID',$nt->{id}];
   push @n,['tmch:notAfter',Net::DRI::Util::dto2zstring($nt->{not_after_date})] if exists $nt->{not_after_date};
   push @n,['tmch:accepted',Net::DRI::Util::dto2zstring($nt->{accepted_date})] if exists $nt->{accepted_date};
  }
  if (@n)
  {
   my $eid=$mes->command_extension_register('tmch','create');
   $mes->command_extension($eid,\@n);
  }
 }
 
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $creData=$mes->get_extension($mes->ns('application'),'creData');
 return unless $creData;
 foreach my $el (Net::DRI::Util::xml_list_children($creData))
 {
  my ($n,$c)=@$el;
  $rinfo->{domain}->{$oname}->{lp}->{phase}=$c->textContent() if $n eq 'phase';
  $rinfo->{domain}->{$oname}->{lp}->{application_id}=$c->textContent() if $n eq 'id';
 }
 return; 
}

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
 
 #Net::DRI::Exception::usererr_insufficient_parameters('phase') unless exists $lp->{phase}; # seems to be optional
 Net::DRI::Exception::usererr_insufficient_parameters('application_id') unless exists $lp->{application_id};

 my $eid=$mes->command_extension_register('application',$cmd);
 my @n;
 push @n,['application:id',$lp->{'application_id'}] if exists $lp->{application_id};
 push @n,['application:phase',$lp->{'phase'}] if exists $lp->{phase};
 $mes->command_extension($eid,\@n);

 return;
}

####################################################################################################
1;
