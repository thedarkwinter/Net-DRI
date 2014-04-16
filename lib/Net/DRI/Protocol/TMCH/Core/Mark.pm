## Domain Registry Interface, TMCH Mark commands
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

package Net::DRI::Protocol::TMCH::Core::Mark;

use utf8;
use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark;
use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::TMCH::Core::Mark - TMCH Mark commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005-2010,2012 Patrick Mevzek <netdri@dotandco.com>.
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
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           info_smd  => [ \&info_smd, \&info_parse ],
           info_enc => [ \&info_enc, \&info_parse ],
           info_file => [ \&info_file, \&info_parse ],
           create => [ \&create, \&create_parse ],
           renew => [ \&renew, \&renew_parse ],
           update => [ \&update ],
           validate => [ \&validate ], # internal validation only
         );

 $tmp{check_multi}=$tmp{check};
 return { 'mark' => \%tmp };
}

####################################################################################################
########### Build Helpers
sub _build_labels
{
  my $labels = shift;
  Net::DRI::Exception::usererr_insufficient_parameters('at least one label is required') unless $labels;

  my @labels;
  foreach my $l (@{$labels})
  {
    Net::DRI::Exception::usererr_insufficient_parameters('label data is not correct') unless $l->{a_label} =~ m/^[a-z0-9\-]{1,63}$/ && $l->{smd_inclusion}=~ m/^(0|1)$/ && $l->{claims_notify}=~ m/^(0|1)$/;
    my @l = ['aLabel',$l->{a_label}];
    #push @l, ['uLabel',$l->{u_label}] if $l->{u_label}; # this breaks it??
    push @l,['smdInclusion', {'enable' => $l->{smd_inclusion}}];
    push @l,['claimsNotify', {'enable' => $l->{claims_notify}}];
    push @labels,['label',@l];
  }
  return @labels;
}

sub _build_docs
{
  my  $documents = shift;
  return unless $documents;
  my  @docs;
  foreach my $d (@{$documents})
  {
    my @d;
    Net::DRI::Exception::usererr_invalid_parameters('document type must be one of tmLicenseeDecl, tmAssigneeDecl, tmOther, declProofOfUseOneSample, proofOfUseOther, copyOfCourtOrder') unless $d->{doc_type} =~ m/^(tmLicenseeDecl|tmAssigneeDecl|tmOther|declProofOfUseOneSample|proofOfUseOther|copyOfCourtOrder)$/;
    Net::DRI::Exception::usererr_invalid_parameters('document file type must be one of pdf,jpg') unless lc($d->{file_type}) =~ m/^(jpg|pdf)$/;
    foreach my $a (qw/doc_type file_name file_type file_content/) { push @d, [Net::DRI::Util::perl2xml($a),$d->{$a}] if $d->{$a}; }
    push @docs,['document',@d];
   }
   return @docs;
}

####################################################################################################
########### Parse Helpers

sub _parse_doc
{
 my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
 my $mes=$po->message();
 return unless $root;
 my $d = {};
 my @s;
 foreach my $el (Net::DRI::Util::xml_list_children($root)) {
  my ($n,$c)=@$el;
  $d->{ Net::DRI::Util::xml2perl($n) } = $c->textContent() unless $n eq 'status';
  push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c) if $n eq 'status';
 }
 $d->{status}=$po->create_local_object('status')->add(@s) if @s;
 return $d;
}

sub _parse_label
{
 my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
 my $mes=$po->message();
 return unless $root;
 my $l = {};
 my @s;
 foreach my $el (Net::DRI::Util::xml_list_children($root)) {
  my ($n,$c)=@$el;
  $l->{Net::DRI::Util::xml2perl($n)} = $c->textContent() if $n =~ m/Label$/;
  $l->{Net::DRI::Util::xml2perl($n)} = $c->getAttribute('enable') if $c->hasAttribute('enable');
  push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c) if $n eq 'status';
 }
 $l->{status}=$po->create_local_object('status')->add(@s) if @s;
 return $l;
}

sub _parse_case
{
 my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
 my $mes=$po->message();
 return unless $root;
 my $case = {};
 my (@s,@labels,@docs);
 foreach my $el (Net::DRI::Util::xml_list_children($root)) {
  my ($n,$c)=@$el;
  if ($n =~ m/^(?:id|court|comment)$/)
  {
   $case->{$n} = $c->textContent() if $n =~ m/^(?:id|court|comment)$/;
  } elsif ($n eq 'upDate')
  {
   $case->{'updated_date'}=$po->parse_iso8601($c->textContent());
  } elsif ($n eq 'status')
  {
   push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c);
  } elsif ($n eq 'udrp') {
   foreach my $el2 (Net::DRI::Util::xml_list_children($c)) {
    my ($n2,$c2)=@$el2;
     $case->{udrp}->{case_number} = $c2->textContent() if $n2 eq 'caseNo';
     $case->{udrp}->{language} = $c2->textContent() if $n2 eq 'caseLang';
     $case->{udrp}->{provider} = $c2->textContent() if $n2 eq 'udrpProvider';
    }
  } elsif ($n eq 'label')
  {
   push @labels,_parse_label($po,$otype,$oaction,$oname,$rinfo,$c);
   #my $label;
   #foreach my $el2 (Net::DRI::Util::xml_list_children($c)) {
   # my ($n2,$c2)=@$el2;
   # $label->{a_label} = $c2->textContent() if $n2 eq 'aLabel';
   # $label->{status} = Net::DRI::Protocol::EPP::Util::parse_node_status($c) if $n eq 'status';
   # push @labels,$label;
   #}
  } elsif ($n eq 'document')
  {
   push @docs,_parse_doc($po,$otype,$oaction,$oname,$rinfo,$c);
  }
 }
 $case->{status}=$po->create_local_object('status')->add(@s) if @s;
 $case->{labels} = \@labels if @labels;
 $case->{documents} = \@docs if @docs;
 #print Dumper $case;
 return $case;
}

sub _parse_balance
{
 my ($po,$otype,$oaction,$oname,$rinfo,$root)=@_;
 my $mes=$po->message();
 return unless $root;
 my $balance = {};
 foreach my $el (Net::DRI::Util::xml_list_children($root))
 {
  my ($n,$c)=@$el;
  $balance->{Net::DRI::Util::xml2perl($n)} = $c->textContent() if $n =~ m/^(amount|statusPoints)$/;
  $balance->{currency} = $c->getAttribute('currency') if $c->hasAttribute('currency');
 }
 return $balance;
}


####################################################################################################
########### Query commands

sub check
{
 my ($tmch,$mark,$rd)=@_;
 my $mes=$tmch->message();
 my @mk=ref $mark ? @$mark : ($mark);
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Mark id needed') unless @mk;
 foreach my $d (@mk) {
  Net::DRI::Exception->die(1,'protocol/EPP',2,'Mark id needed') unless defined $d && $d;
 }
 $mes->command(['check']);

 my @d=map { ['id',$_] } @mk;
 $mes->command_body(\@d);
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->node_resdata()->getChildrenByTagName('chkData')->shift();
 return unless defined $chkdata;
 $otype = 'mark';
 foreach my $cd ($chkdata->getChildrenByTagName('cd'))
 {
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'id')
   {
    $oname=lc($c->textContent());
    $rinfo->{mark}->{$oname}->{action}='check';
    $rinfo->{mark}->{$oname}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   } elsif ($n eq 'reason')
   {
    $rinfo->{mark}->{$oname}->{exist_reason}=$c->textContent();
   }
  }
 }
}

sub info_smd { my ($tmch,$mark) = @_; info($tmch,$mark,{'type'=>'smd'}); }
sub info_enc { my ($tmch,$mark) = @_; info($tmch,$mark,{'type'=>'enc'}); }
sub info_file { my ($tmch,$mark) = @_; info($tmch,$mark,{'type'=>'file'}); }

sub info
{
 my ($tmch,$mark,$rd)=@_;
 my $mes=$tmch->message();
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Mark id needed') unless $mark;
 my @cmd = ['info'];
 @cmd = [ ['info',{'type' => $rd->{type}}] ] if $rd->{type} && $rd->{type} =~ m/^(?:smd|enc|file)$/;
 $mes->command(@cmd);
 $mes->command_body(['id',$mark]);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 
 my $infdata = $mes->node_resdata()->getChildrenByTagName('infData')->shift();
 #$infdata = $mes->node_resdata()->getChildrenByTagName('smdData')->shift() unless $infdata; # smd

 return unless defined $infdata;
 $otype = 'mark';
 my (@s,@pouS,@docs,@labels,@comments,@cases);
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  if ($n eq 'id')
  {
   #$oname=$c->textContent(); # Checl??, depending on query type this could be the mark_id OR tmch handled id thing... ?? So we ignore this and stick to the handle we already have
   $rinfo->{mark}->{$oname}->{action}='info';
   $rinfo->{mark}->{$oname}->{exist}=1;
  } elsif ($n eq 'authCode')
  {
   $rinfo->{mark}->{$oname}->{auth} = { pw => $c->textContent() };
  } elsif ($n eq 'status')
  {
   push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c);
  } elsif ($n eq 'pouStatus')
  {
   push @pouS,Net::DRI::Protocol::EPP::Util::parse_node_status($c);
  } elsif ($n eq 'mark')
  {
     $rinfo->{mark}->{$oname}->{mark} = shift @{Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_mark($po,$c)};
  } elsif ($n eq 'signedMark')
  {
   my $mk = Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_signed_mark($po,$c);
   $rinfo->{mark}->{$oname}->{signed_mark} = $mk;
   $rinfo->{mark}->{$oname}->{mark} = $rinfo->{mark}->{$oname}->{signed_mark}->{mark} = shift @{$mk->{'mark'}};
   $rinfo->{mark}->{$oname}->{signature} = $mk->{'signature'};
  } elsif ($n eq 'encodedSignedMark')
  {
   my $mk = Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_encoded_signed_mark($po,$c);
   $rinfo->{mark}->{$oname}->{signed_mark} = $mk;
   $rinfo->{mark}->{$oname}->{mark} = $rinfo->{mark}->{$oname}->{signed_mark}->{mark} = shift @{$mk->{'mark'}};
   $rinfo->{mark}->{$oname}->{signature} = $mk->{'signature'};
   $rinfo->{mark}->{$oname}->{encoded_signed_mark} = $c->textContent();
  } elsif ($n=~m/^(crDate|upDate|trDate|exDate|pouExDate|correctBefore)$/)
  {
   $rinfo->{mark}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  } elsif ($n eq 'document')
  {
   push @docs, _parse_doc($po,$otype,$oaction,$oname,$rinfo,$c);
  } elsif ($n eq 'label')
  {
   push @labels, _parse_label($po,$otype,$oaction,$oname,$rinfo,$c);
  } elsif ($n eq 'case')
  {
   push @cases, _parse_case($po,$otype,$oaction,$oname,$rinfo,$c);
  } elsif ($n eq 'comment')
  {
   push @comments,$c->textContent();
  }
 }
 $rinfo->{mark}->{$oname}->{status}=$po->create_local_object('status')->add(@s) if @s;
 $rinfo->{mark}->{$oname}->{pou_status}=$po->create_local_object('status')->add(@pouS) if @pouS;
 $rinfo->{mark}->{$oname}->{documents} = \@docs if @docs;
 $rinfo->{mark}->{$oname}->{labels} = \@labels if @labels;
 $rinfo->{mark}->{$oname}->{cases}=\@cases if @cases;
 $rinfo->{mark}->{$oname}->{comments}=\@comments if @comments;
 #print Dumper $rinfo->{mark}->{$oname}; exit;
 return;
}



############ Transform commands

sub create
{
 my ($tmch,$mark,$rd)=@_;
 my $mes=$tmch->message();
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Mark id needed') unless $mark;
 $mes->command(['create']);
 my @body;
 my @mark = Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::build_mark($rd->{mark});
 push @body,[ 'mark', {xmlns => 'urn:ietf:params:xml:ns:mark-1.0'},@mark];
 push @body,['period',{'unit'=>'y'},$rd->{duration}->in_units('years')] if $rd->{duration};
 push @body, _build_docs($rd->{documents}) if defined $rd->{documents}; # DOCUMENTS
 push @body, _build_labels($rd->{labels}) if defined $rd->{labels}; # LABELS
 $mes->command_body(\@body);
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 
 my $credata = $mes->node_resdata()->getChildrenByTagName('creData')->shift();
 return unless defined $credata;
 $otype = 'mark';
 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
  my ($n,$c)=@$el;
  if ($n eq 'id')
  {
   $oname=lc($c->textContent());
   $rinfo->{mark}->{$oname}->{action}='create';
   $rinfo->{mark}->{$oname}->{exist}=1;
  } elsif ($n=~m/^(crDate|exDate)$/)
  {
   $rinfo->{mark}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
  elsif ($n eq 'balance') { # should this be put in $rinfo->{message} along with poll?
   $rinfo->{mark}->{$oname}->{balance} = _parse_balance($po,$otype,$oaction,$oname,$rinfo,$c);
   print Dumper $rinfo->{mark}->{$oname}->{balance};
  }
 }
}

sub update
{
 my ($epp,$mark,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 my $m = $todo->set('mark') if $todo->set('mark');
 my $addlabels= $todo->add('labels') if $todo->add('labels');
 my $adddocs = $todo->add('documents') if $todo->add('documents');
 my $dellabels= $todo->del('labels') if $todo->del('labels');

 return unless ($mark || $addlabels || $adddocs || $dellabels);

 my (@chg,@add,@del);
 $mes->command(['update']);
 
 if (defined $m) {
    my @mark = Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::build_mark($m);
    push @chg,[ 'mark', {xmlns => 'urn:ietf:params:xml:ns:mark-1.0'},@mark] if @mark;
 }
 
 push @add, _build_docs($adddocs) if $adddocs;
 push @add, _build_labels($addlabels) if $addlabels;
 push @del, _build_labels($dellabels) if $dellabels;

 my @body = ['id',$mark];
 push @body, ['add',@add] if @add;
 push @body, ['rem',@del] if @del;
 push @body, ['chg',@chg] if @chg;

 $mes->command_body(\@body);
}

sub renew
{
 my ($tmch,$mark,$rd)=@_;
 my $curexp=Net::DRI::Util::has_key($rd,'current_expiration')? $rd->{current_expiration} : undef;
 Net::DRI::Exception::usererr_insufficient_parameters('current expiration date') unless defined($curexp);
 $curexp=$curexp->set_time_zone('UTC')->strftime('%Y-%m-%d') if (ref($curexp) && Net::DRI::Util::check_isa($curexp,'DateTime'));
 Net::DRI::Exception::usererr_invalid_parameters('current expiration date must be YYYY-MM-DD') unless $curexp=~m/^\d{4}-\d{2}-\d{2}$/;
  
 my $mes=$tmch->message();
 my @d;
 push @d,['id',$mark];
 push @d,['curExpDate',$curexp];
 push @d,['period',{'unit'=>'y'},$rd->{duration}->in_units('years')] if $rd->{duration};
 $mes->command(['renew']);
 $mes->command_body(\@d);
}

sub renew_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $rendata = $mes->node_resdata()->getChildrenByTagName('renData')->shift();
 return unless defined $rendata;
 $otype = 'mark';
 foreach my $el (Net::DRI::Util::xml_list_children($rendata))
 {
  my ($n,$c)=@$el;
  if ($n eq 'id')
  {
   $oname=lc($c->textContent());
   $rinfo->{mark}->{$oname}->{object_id}=$oname;
   $rinfo->{mark}->{$oname}->{action}='renew';
   $rinfo->{mark}->{$oname}->{exist}=1;
  } elsif ($n eq 'markName') 
  {
   $rinfo->{mark}->{$oname}->{mark_name}=$c->textContent();
  }
  elsif ($n=~m/^(crDate|exDate)$/)
  {
   $rinfo->{mark}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
}

####################################################################################################
1;


