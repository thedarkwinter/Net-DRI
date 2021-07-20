## MZB Registry Interface, GoDaddy EPP MZB Extension
##
## Copyright (c) 2021 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::GoDaddy::MZB;

use strict;
use warnings;
use Net::DRI::Protocol;
use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::GoDaddy::MZB - MZB  xtension for GoDaddy

=head1 DESCRIPTION

Adds GoDaddy MZB extension. MZB is a GoDaddy serviTeri Hatcher designed for registrar partners.

=head1 SYNOPSIS

 # mzb check => is used to lookup among the client-sponsored MZB objects to see if one or more of them include the provided labels.
 my $rc = $dri->mzb_check(qw/example/);

 # mzb info => is used to retrieve information associated with an MZB object
 my $rc = $dri->mzb_info('roid');

 # mzb exempt => is used to check if a label is exempt of validation
 my $rc = $dri->mzb_exempt(qw/test-validate foobar-validate/);

 # mzb create => is use to create a MZB object
 $rc = $dri->mzb_create(qw/test-andvalidate test-validate/, { {duration => DateTime::Duration->new(years=>1), registrant => ("contact-clid"), iprid => ("1234567890"), auth=>{pw=>"abcd1234"}} });

 # mzb update => is used to update registrant/pw linked to a Repository Object IDentifier (roid) assigned to the mzb object when it was created
 $todo = $dri->local_object('changes');
 $todo->set('registrant',$dri->local_object('contact')->srid('reg_a_cntct'));
 $todo->set('auth',{pw=>'password'});
 $rc=$dri->mzb_update('my_roid', $todo);

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2021 Paulo Jorge <paullojorgge@gmail.com>.
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
            check    => [ \&check, \&check_parse],
            exempt   => [ \&exempt, \&exempt_parse],
            create   => [ \&create, \&info_parse],
            delete   => [ \&delete, undef],
            renew    => [ \&renew, \&info_parse],
            update   => [ \&update, \&info_parse ],
            info     => [ \&info, \&info_parse ],
            transfer_request => [ \&transfer_request, \&info_parse], # only op="request" is supported for MZB objects
            release_create  => [ \&release_create, \&info_parse],
            release_delete  => [ \&release_delete, \&info_parse],
         );
  $tmp{check_multi}=$tmp{check};
  $tmp{exempt_multi}=$tmp{exempt};
  return { 'mzb' => \%tmp };
}

sub setup
{
  my ($self,$po) = @_;
  $po->ns( { 'mzb' => ['urn:gdreg:params:xml:ns:mzb-1.0','mzb-1.0.xsd']} );
  return;
}

####################################################################################################
sub check
{
  my ($epp,$mzb,$todo)=@_;
  my $mes=$epp->message();
  my @m=mzb_build_command($mes,'check',$mzb,$todo);
  $mes->command_body(\@m);

  return;
}

sub check_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  my $chkdata=$mes->get_response('mzb','chkData');
  return unless defined $chkdata;

  foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('mzb'),'cd'))
  {
    my $mzb;
    foreach my $el (Net::DRI::Util::xml_list_children($cd))
    {
      my ($name,$content)=@$el;
      if ($name eq 'label')
      {
        $mzb=$content->textContent();
      } elsif ($name eq 'roids')
      {
        foreach my $el2 (Net::DRI::Util::xml_list_children($content))
        {
          my ($name2,$content2)=@$el2;
          push @{$rinfo->{mzb}->{$mzb}->{roids}}, $content2->textContent() if $name2 eq 'roid';
        }
      }
    }
  }

  return;
}

sub info
{
  my ($epp,$mzb,$rd)=@_;
  my $mes=$epp->message();
  my @m=mzb_build_command($mes,'info',$mzb,$rd);
  push @m,['mzb:authInfo',['mzb:pw',$rd->{auth}->{pw}]] if $rd->{auth}->{pw};
  $mes->command_body(\@m);

  return;
}


sub info_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  my $resdata;
  return unless $mes->is_success();

  $oname = 'mzb' unless defined $oname;
  foreach my $res (qw/creData upData infData renData trnData/)
  {
    next unless $resdata=$mes->get_response($mes->ns('mzb'),$res);
    foreach my $el (Net::DRI::Util::xml_list_children($resdata))
    {
      my ($name,$content)=@$el;
      $rinfo->{mzb}->{$oname}->{$name}=$content->textContent() if $name =~ m/^(roid|registrant|status|clID|crID|upID|reID|acID|name|trStatus)$/; # plain text
      $rinfo->{mzb}->{$oname}->{$name}=$po->parse_iso8601($content->textContent()) if $name =~ m/^(crDate|upDate|exDate|trDate|reDate|acDate)$/; # date fields
      if ($name eq 'labels')
      {
        $rinfo->{mzb}->{$oname}->{labels}=_m_label_type($content);
      } elsif ($name eq 'releases') {
        $rinfo->{mzb}->{$oname}->{releases}=_releases_inf_type($content);
      } elsif ($name eq 'authInfo') {
        $rinfo->{mzb}->{$oname}->{auth}={pw => Net::DRI::Util::xml_child_content($content,$mes->ns('mzb'),'pw')};
      }
    }
    $rinfo->{mzb}->{$oname}->{action}=$oaction;
    $rinfo->{mzb}->{$oname}->{type}='mzb';
  }

  return;
}

sub exempt
{
  my ($epp,$mzb,$rd)=@_;
  my $mes=$epp->message();
  my @m=mzb_build_command($mes,'exempt',$mzb,$rd);
  $mes->command_body(\@m);

  return;
}


sub exempt_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  my $resdata;
  return unless $mes->is_success();

  foreach my $res (qw/empData/)
  {
    next unless $resdata=$mes->get_response($mes->ns('mzb'),$res);
    $oname = 'mzb' unless defined $oname;
    foreach my $el (Net::DRI::Util::xml_list_children($resdata))
    {
      my ($name,$content)=@$el;
      if ($name eq 'ed')
      {
        $rinfo->{mzb}->{$oname}=_ed_type($content);
      }
    }
    $rinfo->{mzb}->{$oname}->{action}=$oaction;
    $rinfo->{mzb}->{$oname}->{type}='mzb';
  }

  return;
}


sub create
{
  my ($epp,$mzb,$rd)=@_;
  my $mes=$epp->message();
  my @d=mzb_build_command($mes,'create',$mzb,$rd);

  ## Period
  Net::DRI::Exception::usererr_insufficient_parameters('period/duration is mandatory') unless $rd->{duration};
  push @d,_build_period_mzb($rd->{duration}) if Net::DRI::Util::has_duration($rd);

  ## Registrant
  Net::DRI::Exception::usererr_insufficient_parameters('registrant is mandatory') unless $rd->{registrant};
  push @d, ['mzb:registrant',$rd->{registrant}];

  ## iprID (optional) - intellectual property rights identifier for the provided labels
  push @d, ['mzb:iprID',$rd->{iprid}] if $rd->{iprid};

  ## AuthInfo
  Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
  push @d,_build_authinfo_mzb($epp,$rd->{auth});

  ## LaunchPhase extension: if the specified labels are not exempt of a SMD file validation the
  # extension draft-ietf-eppext-launchphase MUST be included in the command
  push @d, Net::DRI::Protocol::EPP::Extensions::LaunchPhase::create($epp,$mzb,$rd) if Net::DRI::Util::has_key($rd,'lp');

  $mes->command_body(\@d);

  return;
}

sub delete
{
  my ($epp,$mzb,$rd)=@_;
  my $mes=$epp->message();
  my @m=mzb_build_command($mes,'delete',$mzb,$rd);
  $mes->command_body(\@m);

  return;
}

sub renew
{
  my ($epp,$mzb,$rd)=@_;
  my $mes=$epp->message();
  my @m=mzb_build_command($mes,'renew',$mzb,$rd);

  ## curExpDate
  my $curexp=Net::DRI::Util::has_key($rd,'current_expiration') ? $rd->{current_expiration} : undef;
  Net::DRI::Exception::usererr_insufficient_parameters('current expiration date') unless defined($curexp);
  $curexp=$curexp->clone()->set_time_zone('UTC')->strftime('%Y-%m-%d') if (ref($curexp) && Net::DRI::Util::check_isa($curexp,'DateTime'));
  Net::DRI::Exception::usererr_invalid_parameters('current expiration date must be YYYY-MM-DD') unless $curexp=~m/^\d{4}-\d{2}-\d{2}$/;
  push @m,['mzb:curExpDate',$curexp];

  ## Period
  Net::DRI::Exception::usererr_insufficient_parameters('period/duration is mandatory') unless $rd->{duration};
  push @m,_build_period_mzb($rd->{duration}) if Net::DRI::Util::has_duration($rd);

  $mes->command_body(\@m);

  return;
}

sub transfer_request
{
  my ($epp,$mzb,$rd)=@_;
  my $mes=$epp->message();
  my @m=mzb_build_command($mes,['transfer',{'op'=>'request'}],$mzb,$rd);
  ## AuthInfo
  Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
  push @m,_build_authinfo_mzb($epp,$rd->{auth});

  $mes->command_body(\@m);

  return;
}

sub update
{
  my ($epp,$mzb,$todo)=@_;
  my $mes=$epp->message();

  Net::DRI::Exception::usererr_insufficient_parameters($todo.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);
  my @m=mzb_build_command($mes,'update',$mzb);

  # chg elements
  my @chg;
  my $chg=$todo->set('registrant');
  push @chg,['mzb:registrant',$chg->srid()] if Net::DRI::Util::isa_contact($chg);
  $chg=$todo->set('auth');
  push @chg,_build_authinfo_mzb($epp,$chg) if ($chg && (ref $chg eq 'HASH') && exists $chg->{pw});
  push @m,['mzb:chg',@chg] if @chg;

  $mes->command_body(\@m);

  return;
}

sub release_create
{
  my ($epp,$mzb,$rd)=@_;
  my $mes=$epp->message();
  my @d=mzb_build_command($mes,'release_create',$mzb,$rd);

  ## Name: element that contains the fully qualified name of the domain object for which the password will be set
  Net::DRI::Exception::usererr_insufficient_parameters('name is mandatory') unless $rd->{name};
  push @d, ['mzb:name',$rd->{name}];

  ## AuthInfo
  Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
  push @d,_build_authinfo_mzb($epp,$rd->{auth});

  $mes->command_body(\@d);

  return;
}

sub release_delete
{
  my ($epp,$mzb,$rd)=@_;
  my $mes=$epp->message();
  my @d=mzb_build_command($mes,'release_delete',$mzb,$rd);

  ## Name: element that contains the fully qualified name of the domain object for which the password will be set
  Net::DRI::Exception::usererr_insufficient_parameters('name is mandatory') unless $rd->{name};
  push @d, ['mzb:name',$rd->{name}];

  $mes->command_body(\@d);

  return;
}

sub mzb_build_command
{
  my ($msg,$command,$mzb,$mzbattr)=@_;
  my @m=ref $mzb ? @$mzb : $mzb;
  my @mzb;

  my $tcommand=ref $command ? $command->[0] : $command;

  if ($tcommand eq 'create')
  {
    Net::DRI::Exception->die(1,'protocol/EPP',2,'Label needed') unless @m;
    my @labels;
    foreach (@m)
    {
      push @labels, ['mzb:label', $_] unless ref $_ eq 'HASH';
    }
    ## Type is mandatory: standard or plus
    Net::DRI::Exception::usererr_invalid_parameters('type must be standard or plus') unless $mzbattr->{product_type} && $mzbattr->{product_type}  =~ m/^(standard|plus)$/;
    $msg->command([$command,'mzb:'.$tcommand,sprintf('xmlns:mzb="%s" xsi:schemaLocation="%s %s" type="'.$mzbattr->{product_type}.'"',$msg->nsattrs('mzb'))]);
    push @mzb, ['mzb:labels', @labels];
  } elsif ($tcommand =~ m/^(?:info|update|delete|renew|transfer|release_create|release_delete)$/)
  {
    Net::DRI::Exception::usererr_insufficient_parameters('roid missing') if $mzb eq '';
    @mzb=map { ['mzb:roid',$_] } @m;

    # tweak for release create|delete actions - ugly but does the job
    $tcommand='release' if ($tcommand =~ m/^(?:release_create|release_delete)$/);
    $command='create' if $command eq 'release_create';
    $command='delete' if $command eq 'release_delete';

    $msg->command([$command,'mzb:'.$tcommand,sprintf('xmlns:mzb="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('mzb'))]);
  } elsif ($tcommand eq 'check')
  {
    Net::DRI::Exception->die(1,'protocol/EPP',2,'Label needed') unless @m;
    foreach (@m)
    {
      push @mzb, ['mzb:label', $_] unless ref $_ eq 'HASH';
    }
    $msg->command([$command,'mzb:'.$tcommand,sprintf('xmlns:mzb="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('mzb'))]);
  } elsif ($tcommand eq 'exempt')
  {
    Net::DRI::Exception->die(1,'protocol/EPP',2,'Label needed') unless @m;
    foreach (@m)
    {
      push @mzb, ['mzb:label', $_] unless ref $_ eq 'HASH';
    }
    $msg->command(['check','mzb:'.$tcommand,sprintf('xmlns:mzb="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('mzb'))]);
  }
  return @mzb;
}

sub _releases_inf_type
{
  my ($releases)=@_;
  return unless $releases;
  my $releases_build={};

  foreach my $release (Net::DRI::Util::xml_list_children($releases))
  {
    my ($name,$content)=@$release;
    if ($name eq 'release')
    {
      push @{$releases_build->{release}}, _release_inf_type($content);
    }
  }

  return $releases_build;
}

sub _release_inf_type
{
  my ($release)=@_;
  return unless $release;
  my $release_build={};

  foreach my $release_element (Net::DRI::Util::xml_list_children($release))
  {
    my ($name,$content)=@$release_element;
    $release_build->{name}=$content->textContent() if ($name eq 'name');
    $release_build->{auth}={pw => $content->textContent()} if ($name eq 'authInfo');
    $release_build->{crDate}=$content->textContent() if ($name eq 'crDate');
  }

  return $release_build;
}

sub _ed_type
{
  my ($emp_data_type)=@_;
  return unless $emp_data_type;
  my $exempt_build={};

  foreach my $exempt_element (Net::DRI::Util::xml_list_children($emp_data_type))
  {
    my ($name,$content)=@$exempt_element;
    $exempt_build->{label}=$content->textContent() if ($name eq 'label');
    @{$exempt_build->{exemptions}}=_exemptions_type($content) if ($name eq 'exemptions');
  }

  return $exempt_build;
}

sub _exemptions_type
{
  my ($exemptions_type)=@_;
  return unless $exemptions_type;
  my @mxemptions;

  foreach my $exemptions_element (Net::DRI::Util::xml_list_children($exemptions_type))
  {
    my ($name,$content)=@$exemptions_element;
    if ($name eq 'exemption')
    {
      my $exemption = {};
      foreach my $exemption_element (Net::DRI::Util::xml_list_children($content))
      {
        my ($name2,$content2)=@$exemption_element;
        $exemption->{iprID}=$content2->textContent() if ($name2 eq 'iprID');
        $exemption->{labels}=_m_label_type($content2) if ($name2 eq 'labels');
      }
      push @mxemptions, $exemption;
    }
  }

  return @mxemptions;
}

# get multiple labels and parse into a array
sub _m_label_type
{
  my ($labels)=@_;
  return unless $labels;
  my @labels_build;

  foreach my $label (Net::DRI::Util::xml_list_children($labels))
  {
    my ($name,$content)=@$label;
    if ($name eq 'label')
    {
      push @labels_build, $content->textContent();
    }
  }

  return \@labels_build;
}

sub _build_period_mzb
{
  my $dtd=shift; ## DateTime::Duration
  my ($y,$m)=$dtd->in_units('years','months'); ## all values are integral, but may be negative
  ($y,$m)=(0,$m+12*$y) if ($y && $m);
  my ($v,$u);
  if ($y)
  {
    Net::DRI::Exception::usererr_invalid_parameters('years must be between 1 and 99') unless ($y >= 1 && $y <= 99);
    $v=$y;
    $u='y';
  } else
  {
    Net::DRI::Exception::usererr_invalid_parameters('months must be between 1 and 99') unless ($m >= 1 && $m <= 99);
    $v=$m;
    $u='m';
  }
  return ['mzb:period',$v,{}];
}

sub _build_authinfo_mzb
{
  my ($epp,$rauth,$isupdate)=@_;
  return ['mzb:authInfo',['mzb:null']] if ((! defined $rauth->{pw} || $rauth->{pw} eq '') && $epp->{usenullauth} && (defined($isupdate) && $isupdate));
  return ['mzb:authInfo',['mzb:pw',$rauth->{pw},exists($rauth->{roid})? { 'roid' => $rauth->{roid} } : undef]];
}

####################################################################################################


1;
