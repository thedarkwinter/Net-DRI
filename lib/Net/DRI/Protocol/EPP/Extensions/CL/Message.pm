## .CL message extensions

package Net::DRI::Protocol::EPP::Extensions::CL::Message;

use strict;
use warnings;

sub register_commands
{
  my ($class, $version) = @_;
  return { 'message' => { 'retrieve' => [ undef, \&parse_poll ] } };
}

####################################################################################################

sub parse_poll
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;

  my $mes=$po->message();
  return unless $mes->is_success();

  my $msgid=$mes->msg_id();
  my $resdata = $mes->node_resdata if $mes->node_resdata;
  return unless ((defined($msgid) && $msgid) && (defined($resdata) && $resdata));

  $oname = $msgid;
  $otype = $otype ? $otype : 'message';

  my %r = ();

  foreach my $el (Net::DRI::Util::xml_list_children($resdata))
  {
    my ($name,$content)=@$el;

    # this is only until v1.0.4
    $rinfo->{'message'}->{$msgid}->{pollryrr} = parse_pollryrr($po, $content) if $name && $name eq 'pollt';
    # on v1.0.5 they deprecated pollryrr and start to use clpoll - keeping both extending what we already have
    if ( $name && $name eq 'changeState' ) {
      $r{clpoll} = parse_clpoll($po, $content);
      $rinfo->{'domain'}->{$r{clpoll}->{'name'}} = $r{clpoll} if $r{clpoll}->{'name'};
    }
  }

  return $rinfo;
}

sub parse_pollryrr
{
  my ($po, $node_pollt) = @_;
  return unless $node_pollt;

  my $set_pollt = {};

  foreach my $el_pollt (Net::DRI::Util::xml_list_children($node_pollt))
  {
    my ($name_pollt,$content_pollt)=@$el_pollt;
    $set_pollt = __parse_pollryrr_changeState($po,$content_pollt) if $name_pollt && $name_pollt eq 'changeState';
    $set_pollt = __parse_pollryrr_changeStateTransfer($po,$content_pollt) if $name_pollt && $name_pollt eq 'changeStateTransfer';
    $set_pollt = __parse_pollryrr_mega($po,$content_pollt) if $name_pollt && $name_pollt eq 'mega';
  }

  return $set_pollt;
}

sub __parse_pollryrr_changeState
{
  my ( $po,$node_changeState ) = @_;
  return unless $node_changeState;

  my $set_changeState = {};
  my @status = ();

  foreach my $el_changeState (Net::DRI::Util::xml_list_children($node_changeState)) {
    my ( $name_changeState, $content_changeState ) = @$el_changeState;
    if ( $name_changeState =~ m/^(roid|name|stateInscription|stateConflict|reason)$/ ) {
      $set_changeState->{$1} = $content_changeState->textContent();
    } elsif ($name_changeState eq 'status') {
      push @status,Net::DRI::Protocol::EPP::Util::parse_node_status($content_changeState);
    }
  }

  $set_changeState->{'status'} = $po->create_local_object('status')->add(@status);

  return $set_changeState;
}

# by technical documentation this is deprecated. will keep it here since its defined on their schemas
sub __parse_pollryrr_changeStateTransfer
{
  my ( $po, $node_changeStateTransfer ) = @_;
  return unless $node_changeStateTransfer;

  my $set_changeStateTransfer = {};
  my @status = ();

  foreach my $el_changeStateTransfer (Net::DRI::Util::xml_list_children($node_changeStateTransfer)) {
    my ( $name_changeStateTransfer, $content_changeStateTransfer ) = @$el_changeStateTransfer;
    if ( $name_changeStateTransfer =~ m/^(roid|name|dominioIdRr|obs)$/ ) {
      $set_changeStateTransfer->{$1} = $content_changeStateTransfer->textContent();
    } elsif ( $name_changeStateTransfer eq 'status' ) {
      push @status,Net::DRI::Protocol::EPP::Util::parse_node_status($content_changeStateTransfer);
    } elsif ( $name_changeStateTransfer eq 'date' ) {
      $set_changeStateTransfer->{$1} = $po->parse_iso8601($content_changeStateTransfer->textContent()) if $content_changeStateTransfer->textContent();
    }
  }

  $set_changeStateTransfer->{'status'} = $po->create_local_object('status')->add(@status);

  return $set_changeStateTransfer;
}

sub __parse_pollryrr_mega
{
  my ( $po, $node_mega ) = @_;
  return unless $node_mega;

  my $set_mega = {};
  my @status = ();
  my @rgpstatus = ();
  my @domain = ();

  foreach my $el_mega (Net::DRI::Util::xml_list_children($node_mega)) {
    my ( $name_mega, $content_mega ) = @$el_mega;
    if ( $name_mega =~ m/^(stateInscription|stateConflict|reason)$/ ) {
      $set_mega->{$1} = $content_mega->textContent();
    } elsif ( $name_mega eq 'status' ) {
      push @status,Net::DRI::Protocol::EPP::Util::parse_node_status($content_mega);
    } elsif ( $name_mega eq 'RGPstatus' ) {
      push @rgpstatus,Net::DRI::Protocol::EPP::Util::parse_node_status($content_mega);
    } elsif ( $name_mega eq 'domain') {
      my ( $roid, $name ) = ();
      foreach my $el_domain (Net::DRI::Util::xml_list_children($content_mega)) {
        my ( $name_domain, $content_domain ) = @$el_domain;
        $roid = $content_domain->textContent() if $name_domain eq 'roid';
        $name = $content_domain->textContent() if $name_domain eq 'name';
      }
      push @domain, ( { 'roid' => $roid, 'name' => $name } );
    }
  }

  $set_mega->{'status'} = $po->create_local_object('status')->add(@status);
  $set_mega->{'RGPstatus'} = $po->create_local_object('status')->add(@rgpstatus);
  $set_mega->{'domain'} = \@domain;

  return $set_mega;
}

sub parse_clpoll
{
  my ($po, $node_clpoll_changeState) = @_;
  return unless $node_clpoll_changeState;

  my $set_clpoll_changeState = {};
  my @status = ();

  foreach my $el_clpoll_changeState (Net::DRI::Util::xml_list_children($node_clpoll_changeState))
  {
    my ($name_clpoll_changeState,$content_clpoll_changeState)=@$el_clpoll_changeState;
    if ($name_clpoll_changeState eq 'domain' ) {
      foreach my $el_clpoll_changeState_domain (Net::DRI::Util::xml_list_children($content_clpoll_changeState))
      {
        my ($name_domain_type, $content_domain_type) = @$el_clpoll_changeState_domain;
        $set_clpoll_changeState->{$name_domain_type} = $content_domain_type->textContent() if $name_domain_type;
      }
    } elsif ( $name_clpoll_changeState =~ m/^(rgpStatus|disputeStatus|reason)/ ) {
      $set_clpoll_changeState->{$1} = $content_clpoll_changeState->textContent();
      # get and set attribute for disputeStatus - if exists
      if ($name_clpoll_changeState eq 'disputeStatus' && $content_clpoll_changeState->hasAttribute('causeDisputeTermination') && $content_clpoll_changeState->getAttribute('causeDisputeTermination') =~ m/^(disputeDismissed|transferredToComplainant|keepsDomainName)$/) {
        $set_clpoll_changeState->{'causeDisputeTermination'} = $content_clpoll_changeState->getAttribute('causeDisputeTermination')
      }
    } elsif ( $name_clpoll_changeState eq 'status' ) {
      push @status,$content_clpoll_changeState->textContent();
    }
  }

  $set_clpoll_changeState->{'status'} = $po->create_local_object('status')->add(@status);

  return $set_clpoll_changeState;
}

1;
