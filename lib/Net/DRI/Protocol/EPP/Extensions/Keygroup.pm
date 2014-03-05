## Domain Registry Interface, EURid/DNSBE Keygroup EPP Extension
##
## Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Keygroup;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( create => [ \&create, undef ],
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           delete => [ \&delete, undef ],
           update => [ \&update, undef ],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'keygroup' => \%tmp };
}

sub capabilities_add { return ('keygroup_update','keys',['set']); }

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'keygroup' => [ 'http://www.eurid.eu/xml/epp/keygroup-1.0','keygroup-1.0.xsd' ] });
 return;
}

sub build_command
{
 my ($epp,$msg,$command,$names)=@_;

 my @gn;
 foreach my $h ( grep { defined } (ref $names eq 'ARRAY')? @$names : ($names))
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid Keygroup name: '.$h) unless (defined $h && length $h && ! ref $h && Net::DRI::Util::xml_is_token($h,1,100));
  push @gn,$h;
 }

 Net::DRI::Exception->die(1,'protocol/EPP',2,'Keygroup name needed') unless @gn;

 $msg->command([$command,'keygroup:'.$command,sprintf('xmlns:keygroup="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('keygroup'))]);
 return map { ['keygroup:name',$_] } @gn;
}

## The hash keys names are modeled on those used for the secDNS extension.
sub format_key
{
 my $e=shift;

 my @mk=grep { ! Net::DRI::Util::has_key($e,$_) } qw/keyTag flags protocol alg pubKey/;
 Net::DRI::Exception::usererr_insufficient_parameters('Attributes missing: '.join(@mk)) if @mk;
 Net::DRI::Exception::usererr_invalid_parameters('keyTag must be 16-bit unsigned integer: '.$e->{keyTag}) unless Net::DRI::Util::verify_ushort($e->{keyTag});
 Net::DRI::Exception::usererr_invalid_parameters('flags mut be a 16-bit unsigned integer: '.$e->{flags}) unless Net::DRI::Util::verify_ushort($e->{flags});
 Net::DRI::Exception::usererr_invalid_parameters('protocol must be an unsigned byte: '.$e->{protocol}) unless Net::DRI::Util::verify_ubyte($e->{protocol});
 Net::DRI::Exception::usererr_invalid_parameters('alg must be an unsigned byte: '.$e->{alg}) unless Net::DRI::Util::verify_ubyte($e->{alg});
 Net::DRI::Exception::usererr_invalid_parameters('pubKey must be a non empty base64 string: '.$e->{pubKey}) unless Net::DRI::Util::verify_base64($e->{pubKey},1);

 my @c;
 push @c,['keygroup:keyTag',$e->{keyTag}];
 push @c,['keygroup:flags',$e->{flags}];
 push @c,['keygroup:protocol',$e->{protocol}];
 push @c,['keygroup:algorithm',$e->{alg}];
 push @c,['keygroup:pubKey',$e->{pubKey}];

 return @c;
}

####################################################################################################
########### Query commands

sub check
{
 my ($epp,$names)=@_;
 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'check',$names);
 $mes->command_body(\@d);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $ns=$mes->ns('keygroup');
 my $chkdata=$mes->get_response($ns,'chkData');
 return unless defined $chkdata;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($ns,'cd'))
 {
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'name')
   {
    my $kg=$c->textContent();
    $rinfo->{keygroup}->{$kg}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
    $rinfo->{keygroup}->{$kg}->{action}='check';
   }
  }
 }
 return;
}

sub info
{
 my ($epp,$name)=@_;
 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'info',$name);
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $ns=$mes->ns('keygroup');
 my $infdata=$mes->get_response($ns,'infData');
 return unless defined $infdata;

 my @k;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=$c->textContent();
   $rinfo->{keygroup}->{$oname}->{exist}=1;
   $rinfo->{keygroup}->{$oname}->{action}='info';
  } elsif ($name eq 'key')
  {
   push @k,{ keyTag => Net::DRI::Util::xml_child_content($c,$ns,'keyTag'),
             flags => Net::DRI::Util::xml_child_content($c,$ns,'flags'),
             protocol =>Net::DRI::Util::xml_child_content($c,$ns,'protocol') ,
             alg => Net::DRI::Util::xml_child_content($c,$ns,'algorithm'),
             pubKey => Net::DRI::Util::xml_child_content($c,$ns,'pubKey'),
           };
  }
 }

 $rinfo->{keygroup}->{$oname}->{keys}=\@k;
 return;
}

############ Transform commands

sub create
{
 my ($epp,$name,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'create',$name);
 if (Net::DRI::Util::has_key($rd,'keys'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('secdns key must be a ref array') unless ref $rd->{'keys'} eq 'ARRAY';
  foreach my $k (@{$rd->{'keys'}})
  {
   push @d,['keygroup:key',format_key($k)];
  }
 }
 $mes->command_body(\@d);
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$name)=@_;
 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'delete',$name);
 $mes->command_body(\@d);
 return;
}

sub update
{
 my ($epp,$name,$todo,$rd)=@_;
 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 if ((grep { ! /^(?:keys)$/ } $todo->types()) || (grep { ! /^(?:set)$/ } $todo->types('keys') ))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only keys set available for keygroup');
 }

 my $mes=$epp->message();
 my @d=build_command($epp,$mes,'update',$name);
 foreach my $k (@{$todo->set('keys')})
 {
  push @d,['keygroup:key',format_key($k)];
 }
 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Keygroup - EURid/DNSBE Keygroup EPP Extension for Net::DRI

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

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

