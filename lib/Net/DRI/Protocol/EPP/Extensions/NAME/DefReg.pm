## Domain Registry Interface, EPP Defensive registration extension commands
## (based on https://www.verisign.com/assets/defensive-registration-mapping.pdf)
##
## Copyright (c) 2007,2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>
## Copyright (c) 2016 Michael Holloway <michael@thedarkwinter.com>
## All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NAME::DefReg;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Contact;
use Net::DRI::Data::ContactSet;
use DateTime::Format::ISO8601;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NAME::DefReg - EPP DefReg extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> or
E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
Copyright (c) 2016 Michael Holloway <michael@thedarkwinter.com>
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
 my %tmp1=( create => [ \&create ],
            check  => [ \&check, \&check_parse ],
            info   => [ \&info, \&info_parse ],
            info   => [ \&info, \&info_parse ],
            delete => [ \&delete ],
	          update => [ \&update ],
	          renew  => [ \&renew ],
            transfer_query => [ \&transfer_query, \&transfer_parse ],
            transfer_request => [ \&transfer_request, \&transfer_parse ],
            transfer_cancel => [ \&transfer_cancel, \&transfer_parse ],
            transfer_answer => [ \&transfer_answer, \&transfer_parse ],
          );

 $tmp1{check_multi}=$tmp1{check};

 return { 'defreg' => \%tmp1 };
}

####################################################################################################
########### Helpers

sub build_command
{
 my ($epp,$msg,$command,$info)=@_;
 my $contacts = $info->{contact};
 my $authid = $info->{auth};
 my @ret;
 my @auth;

 delete $info->{contact};
 delete $info->{auth};

 Net::DRI::Exception->die(1,'protocol/EPP',2,'defReg name needed') unless (defined($info->{name}));
 $msg->command([$command,'defReg:'.$command,sprintf('xmlns:defReg="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('defReg'))]);

 # @ret = map { ['defReg:' . $_, $info->{$_}] } keys(%{$info});
 push(@ret, ['defReg:name', {level => ($info->{level} ? 'premium' : 'standard') }, $info->{name}]) if (defined($info->{name}));
 push(@ret, ['defReg:fwdTo', $info->{fwdTo}]) if (defined($info->{fwdTo}));
 push(@ret, ['defReg:curExpDate', $info->{curExpDate}])
 	if (defined($info->{curExpDate}));
 push(@ret, ['defReg:period', { unit => 'y' },
  	$info->{period}->in_units('years')]) if (defined($info->{period}));
 push(@ret, ['defReg:registrant', $info->{registrant}]) if (defined($info->{registrant}));
 foreach my $type (sort { $a cmp $b } keys %$contacts)
 {
  push(@ret, ['defReg:contact', {type => $type}, $contacts->{$type}]);
 }

 foreach my $auth (sort { $a cmp $b } keys %$authid)
 {
  push(@auth, ['defReg:' . $auth, $authid->{$auth}]);
 }
 push(@ret, ['defReg:authInfo', @auth]) if (@auth);

 return @ret;
}

sub _build_transfer
{
 my ($epp,$roid,$rd,$op)=@_;
 my $mes = $epp->message();
 Net::DRI::Exception->die(1,'protocol/EPP',2,'defReg roid needed') unless (defined($roid));
 $mes->command(['transfer',{'op'=>$op}],'defReg:transfer',sprintf('xmlns:defReg="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('defReg')));
 my @d;
 push @d, ['defReg:roid', $roid ];
 push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{duration},'defReg') if Net::DRI::Util::has_duration($rd);
 push @d, ['defReg:authInfo', ['defReg:pw', $rd->{auth}->{pw}, exists($rd->{auth}->{roid})? { 'roid' => $rd->{auth}->{roid} } : undef]] if exists $rd->{auth};
 $mes->command_body(\@d);
 return;
}

sub _parse_defref
{
  my ($po,$otype,$oaction,$oname,$rinfo,$section)=@_;

  my $mes=$po->message();
  return unless $mes->is_success();

  my $ns = $mes->ns('defReg');
  my $data=$mes->get_response($ns, $section);
  return unless $data;

  my $cs = $po->create_local_object('contactset');
  my @s;
  my $info = {};

  my $c=$data->getFirstChild();
  while ($c)
  {
   next unless ($c->nodeType() == 1); ## only for element nodes
   my $name=$c->localname() || $c->nodeName();
   next unless $name;

   if ($name eq 'roid')
   {
     $oname = $info->{object_id} = $info->{roid} = $c->getFirstChild()->getData();
   }
   elsif ($name eq 'name')
   {
    $info->{name} = $c->getFirstChild()->getData();
    $info->{level} = $c->getAttribute('level') if $c->hasAttribute('level');
   }
   elsif ($name eq 'status')
   {
    push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c);
   }
   elsif (grep { $_ eq $name } qw/clID crID upID reID acID tm tmCountry trStatus/)
   {
    $info->{$name} = $c->getFirstChild()->getData();
   }
   elsif (grep { $_ eq $name } qw/crDate upDate trDate exDate tmDate acDate reDate/)
   {
    $info->{$name} = $po->parse_iso8601($c->getFirstChild()->getData());
   }
   elsif (grep { $_ eq $name } qw/registrant adminContact/)
   {
    my $type = $name eq 'adminContact' ? 'admin' : 'registrant';
    $cs->add($po->create_local_object('contact')->srid($c->getFirstChild()->getData()), $type);
   }
   elsif ($name eq 'authInfo')
   {
    my $pw = ($c->getElementsByTagNameNS($mes->ns('defReg'),'pw'))[0];
    $info->{auth} = { pw => (defined($pw) && $pw->hasChildNodes() ? $pw->getFirstChild->getData() : undef) };
   }
  } continue { $c=$c->getNextSibling(); }

  $info->{contact} = $cs;
  $info->{status} = $po->create_local_object('status')->add(@s);
  $info->{exist} = 1;
  $otype = $info->{object_type} = 'defreg';
  $info->{action} = $oaction;
  $otype = 'defreg';
  $rinfo->{defreg}->{$oname} = $info;

  return;
}

####################################################################################################
########### Query commands

sub check
{
 my ($epp, $names, $rd) = @_;
 my $mes=$epp->message();
 $mes->command('check','defReg:check',sprintf('xmlns:defReg="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('defReg')));
 my (@d,$level);
 foreach my $name (@{$names}) {
  $level = exists($rd->{"level_$name"}) ? $rd->{"level_$name"} : exists($rd->{level}) ? $rd->{level} : 'standard' ;
  push(@d, ['defReg:name', { level => $level }, $name]);
 }
 $mes->command_body(\@d);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $ns = $mes->ns('defReg');
 my $chkdata=$mes->get_response($ns, 'chkData');
 return unless $chkdata;
 foreach my $cd ($chkdata->getElementsByTagNameNS($ns,'cd'))
 {
  my $c = $cd->getFirstChild();
  my $name;

  while($c)
  {
   next unless ($c->nodeType() == 1); ## only for element nodes
   my $n=$c->localname() || $c->nodeName();
   if ($n eq 'name')
   {
    $name = $c->getFirstChild()->getData();
    $rinfo->{defreg}->{$name}->{exist} = 1 -
    	Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
    $rinfo->{defreg}->{$name}->{action} = 'check';
   } elsif ($n eq 'reason') {
    $rinfo->{defreg}->{$name}->{exist_reason} = $c->textContent();
   }
  } continue { $c = $c->getNextSibling(); }
 }
 #use Data::Dumper; print Dumper $rinfo;
 return;
}

sub info
{
 my ($epp,$roid,$rd)=@_;
 my $mes = $epp->message();
 Net::DRI::Exception->die(1,'protocol/EPP',2,'defReg roid needed') unless (defined($roid));
 $mes->command('info','defReg:info',sprintf('xmlns:defReg="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('defReg')));
 my @d;
 push @d, ['defReg:roid', $roid ];
 push @d, ['defReg:authInfo', ['defReg:pw', $rd->{auth}->{pw}, exists($rd->{auth}->{roid})? { 'roid' => $rd->{auth}->{roid} } : undef]] if exists $rd->{auth};
 $mes->command_body(\@d);
 return;
}



sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 $oaction = 'info';
 return _parse_defref(@_,'infData');
}

sub transfer_query { return _build_transfer(@_,'query'); }

sub transfer_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 return _parse_defref(@_,'trnData');
}

####################################################################################################
########### Transform commands

sub transfer_request { return _build_transfer(@_,'request'); }
sub transfer_cancel { return _build_transfer(@_,'cancel'); }
sub transfer_answer { return _build_transfer(@_, @_[2]->{approve} ? 'approve' : 'reject'); }




sub create
{
 my ($epp,$mail,$info)=@_;
 my $mes = $epp->message();
 my @d;
 $info->{name} = $mail;
 @d = build_command($epp,$mes,'create',$info);
 $mes->command_body(\@d);
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$mail)=@_;
 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'delete',{ name => $mail });
 $mes->command_body(\@d);
 return;
}

sub update
{
 my ($epp,$hosts,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 if ((grep { ! /^(?:ns)$/ } $todo->types()) || (grep { ! /^(?:set)$/ } $todo->types('ns') ))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only ns set available for nsgroup');
 }

 my $ns=$todo->set('ns');
 my @d=build_command($epp,$mes,'update',$hosts);
 push @d,add_nsname($ns);
 $mes->command_body(\@d);
 return;
}

sub renew
{
 my ($epp,$mail,$period,$curexp)=@_;
 my $mes = $epp->message();

 Net::DRI::Util::check_isa($curexp,'DateTime');
 Net::DRI::Util::check_isa($period,'DateTime::Duration');

 my $info = {
  name => $mail,
  curExpDate => $curexp->ymd,
  period => $period
 };

 my @d = build_command($epp,$mes,'renew',$info);
 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;
