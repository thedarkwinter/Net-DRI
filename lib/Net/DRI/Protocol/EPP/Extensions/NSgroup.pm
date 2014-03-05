## Domain Registry Interface, EPP NSgroup extension commands
## (based on .BE Registration_guidelines_v4_7_1)
##
## Copyright (c) 2005-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NSgroup;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NSgroup - EPP NSgroup extension commands for Net::DRI

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

Copyright (c) 2005-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
          );

 $tmp1{check_multi}=$tmp1{check};
 
 return { 'nsgroup' => \%tmp1 };
}

sub capabilities_add { return ('nsgroup_update','ns',['set']); }

sub ns
{
 my ($mes)=@_;
 my $ns=$mes->ns('nsgroup');
 return defined $ns? $ns : 'http://www.dns.be/xml/epp/nsgroup-1.0';
}

sub build_command
{
 my ($epp,$msg,$command,$hosts)=@_;

 my @gn;
 foreach my $h ( grep { defined } (ref $hosts eq 'ARRAY')? @$hosts : ($hosts))
 {
  my $gn=Net::DRI::Util::isa_nsgroup($h)? $h->name() : $h;
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid NSgroup name: '.$gn) unless (defined $gn && $gn && ! ref $gn && Net::DRI::Util::xml_is_normalizedstring($gn,1,100));
  push @gn,$gn;
 }

 Net::DRI::Exception->die(1,'protocol/EPP',2,'NSgroup name needed') unless @gn;
 $msg->command([$command,'nsgroup:'.$command,sprintf('xmlns:nsgroup="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('nsgroup'))]);
 return map { ['nsgroup:name',$_] } @gn;
}

sub add_nsname
{
 my ($ns)=@_;
 return () unless defined $ns;
 my @names;
 if (! ref $ns)
 {
  @names=($ns);
 } elsif (ref $ns eq 'ARRAY')
 {
  @names=@$ns;
 } elsif (Net::DRI::Util::isa_nsgroup($ns))
 {
  @names=$ns->get_names();
 }

 foreach my $n (@names)
 {
  next if Net::DRI::Util::is_hostname($n);
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid host name: '.$n);
 }

 return map { ['nsgroup:ns',$_] } @names;
}

####################################################################################################
########### Query commands

sub check
{
 my ($epp,@hosts)=@_;
 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'check',\@hosts);
 $mes->command_body(\@d);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $ns=$mes->ns('nsgroup');
 my $chkdata=$mes->get_response($ns,'chkData');
 return unless defined $chkdata;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($ns,'cd'))
 {
  my $nsgroup;
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'name')
   {
    $nsgroup=$c->textContent();
    $rinfo->{nsgroup}->{$nsgroup}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
    $rinfo->{nsgroup}->{$nsgroup}->{action}='check';
   }
  }
 }
 return;
}

sub info
{
 my ($epp,$hosts)=@_;
 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'info',$hosts);
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response($mes->ns('nsgroup'),'infData');
 return unless defined $infdata;

 my $ns=$po->create_local_object('hosts');
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=$c->textContent();
   $ns->name($oname);
   $rinfo->{nsgroup}->{$oname}->{exist}=1;
   $rinfo->{nsgroup}->{$oname}->{action}='info';
  } elsif ($name eq 'ns')
  {
   $ns->add($c->textContent());
  }
 }

 $rinfo->{nsgroup}->{$oname}->{self}=$ns;
 return;
}

############ Transform commands

sub create
{
 my ($epp,$hosts)=@_;
 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'create',$hosts);
 push @d,add_nsname($hosts);
 $mes->command_body(\@d);
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$hosts)=@_;
 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'delete',$hosts);
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

####################################################################################################
1;
