## Domain Registry Interface, EPP Email forwarding extension commands
## (based on .NAME Technical Accreditation Guide v3.03)
##
## Copyright (c) 2007,2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NAME::EmailFwd;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Contact;
use Net::DRI::Data::ContactSet;
use DateTime::Format::ISO8601;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NAME::EmailFwd - EPP EmailFwd extension commands for Net::DRI

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
            delete => [ \&delete ],
	    update => [ \&update ],
	    renew  => [ \&renew ]
          );

 $tmp1{check_multi}=$tmp1{check};
 
 return { 'emailfwd' => \%tmp1 };
}

sub ns
{
 my ($mes)=@_;
 my $ns=$mes->ns('emailFwd');
 return defined($ns)? $ns : 'http://www.nic.name/epp/emailFwd-1.0';
}

sub build_command
{
 my ($epp,$msg,$command,$info)=@_;
 my $contacts = $info->{contact};
 my $authid = $info->{auth};
 my @ret;
 my @auth;

 delete $info->{contact};
 delete $info->{auth};

 Net::DRI::Exception->die(1,'protocol/EPP',2,'emailFwd name needed') unless (defined($info->{name}));

 my @ns=$msg->nsattrs('emailFwd');
 @ns=qw(http://www.nic.name/epp/emailFwd-1.0 http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd) unless @ns;
 $msg->command([$command,'emailFwd:'.$command,sprintf('xmlns:emailFwd="%s" xsi:schemaLocation="%s %s"',@ns)]);

 # @ret = map { ['emailFwd:' . $_, $info->{$_}] } keys(%{$info});
 push(@ret, ['emailFwd:name', $info->{name}]) if (defined($info->{name}));
 push(@ret, ['emailFwd:fwdTo', $info->{fwdTo}]) if (defined($info->{fwdTo}));
 push(@ret, ['emailFwd:curExpDate', $info->{curExpDate}])
 	if (defined($info->{curExpDate}));
 push(@ret, ['emailFwd:period', { unit => 'y' },
  	$info->{period}->in_units('years')]) if (defined($info->{period}));
 push(@ret, ['emailFwd:registrant', $info->{registrant}]) if (defined($info->{registrant}));
 foreach my $type (keys %{$contacts})
 {
  push(@ret, ['emailFwd:contact', {type => $type}, $contacts->{$type}]);
 }

 foreach my $auth (keys %{$authid})
 {
  push(@auth, ['emailFwd:' . $auth, $authid->{$auth}]);
 }
 push(@ret, ['emailFwd:authInfo', @auth]) if (@auth);

 return @ret;
}

####################################################################################################
########### Query commands

sub check
{
 my $epp=shift;
 my $info=shift;
 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'check', { name => $info });
 $mes->command_body(\@d);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $ns=ns('emailFwd');
 my $chkdata=$mes->get_response($ns,'chkData');
 return unless $chkdata;
 foreach my $cd ($chkdata->getElementsByTagNameNS($ns,'cd'))
 {
  my $c = $cd->getFirstChild();
  my $fwd;

  while($c)
  {
   next unless ($c->nodeType() == 1); ## only for element nodes
   my $n=$c->localname() || $c->nodeName();
   if ($n eq 'name')
   {
    $fwd = $c->getFirstChild()->getData();
    $rinfo->{emailFwd}->{$fwd}->{exist} = 1 -
    	Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
    $rinfo->{emailFwd}->{$fwd}->{action} = 'check';
   }
  } continue { $c = $c->getNextSibling(); }
 }
 return;
}

sub info
{
 my ($epp,$mail)=@_;
 my $mes = $epp->message();
 my @d = build_command($epp,$mes,'info',{ name => $mail });
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response(ns($mes),'infData');
 return unless $infdata;

 my $nm;
 my $cs = Net::DRI::Data::ContactSet->new();
 my $info = {};
 my $ginfo = {};

 my $c=$infdata->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'name')
  {
   $info->{name} = $nm = $c->getFirstChild()->getData();
  }
  elsif ($name eq 'fwdTo')
  {
   $info->{$name} = $c->getFirstChild()->getData();
  }
  elsif (grep { $_ eq $name } qw/clID crID upID/)
  {
   $ginfo->{$name} = $c->getFirstChild()->getData();
  }
  elsif (grep { $_ eq $name } qw/crDate upDate trDate exDate/)
  {
   $ginfo->{$name} = DateTime::Format::ISO8601()->new()->
   	parse_datetime($c->getFirstChild()->getData());
  }
  elsif (grep { $_ eq $name } qw/registrant contact/)
  {
   my $type = $c->getAttribute('type') || 'registrant';
   $cs->add(Net::DRI::Data::Contact()->new()->
   	srid($c->getFirstChild()->getData()), $type);
  }
  elsif ($name eq 'authInfo')
  {
   my $pw = ($c->getElementsByTagNameNS($mes->ns('emailFwd'),'pw'))[0];
   $ginfo->{auth} = { pw => (defined($pw) && $pw->hasChildNodes() ?
	 $pw->getFirstChild->getData() : undef) };
  }
 } continue { $c=$c->getNextSibling(); }

 $info->{contact} = $cs;

 $ginfo->{exist} = defined($nm);
 $ginfo->{action} = 'info';
 $ginfo->{self} = $info;
 $rinfo->{emailFwd}->{$nm} = $ginfo;
 return;
}

############ Transform commands

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
