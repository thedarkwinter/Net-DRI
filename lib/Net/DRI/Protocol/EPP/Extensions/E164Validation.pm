## Domain Registry Interface, EPP E.164 Validation (RFC5076)
##
## Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::E164Validation;

use utf8;
use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

our $NS='urn:ietf:params:xml:ns:e164val-1.0';
our @VALIDATION_MODULES=qw/RFC5076/; ## modules to handle validation information, override this variable to use other validation modules

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::E164Validation - EPP E.164 Validation (RFC5076) for Net::DRI

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

Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           info   => [ undef, \&info_parse ],
           create => [ \&create, undef ],
           renew => [ \&renew, undef ],
           transfer_request => [ \&transfer_request, undef ],
           update => [ \&update, undef ],
         );

 load_validation_modules();

 return { 'domain' => \%tmp };
}

sub capabilities_add { return ('domain_update','e164_validation_information',['add','del','set']); }

our %VAL;
sub load_validation_modules ## §4.4 §4.5
{
 foreach my $mod (@VALIDATION_MODULES)
 {
  my $class=($mod=~m/::/)? $mod : 'Net::DRI::Protocol::EPP::Extensions::E164Validation::'.$mod;
  Net::DRI::Util::load_module($class,'protocol/epp_e164validation');
  my ($uri)=$class->load();
  $VAL{$uri}=$class;
 }
 return;
}

####################################################################################################

sub format_validation
{
 my ($e,$what,$top)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('Each validation information must be a reference to an array with 3 elements : 2 strings (id & uri) and a reference of an hash') unless (ref($e) eq 'ARRAY' && @$e==3 && !ref($e->[0]) && length $e->[0] && !ref($e->[1]) && length $e->[1] && (ref($e->[2]) eq 'HASH') && keys(%{$e->[2]}));
 Net::DRI::Exception::usererr_invalid_parameters('Id is syntaxically invalid: '.$e->[0]) unless Net::DRI::Util::xml_is_ncname($e->[0]);
 Net::DRI::Exception::usererr_insufficient_parameters('No validation information module found for URI='.$e->[1]) unless exists($VAL{$e->[1]});
 Net::DRI::Exception::usererr_invalid_parameters(sprintf('Validation module %s for URI %s must a have a %s method',$VAL{$e->[1]},$e->[1],$what)) unless $VAL{$e->[1]}->can($what);
 my @c=$VAL{$e->[1]}->$what($e->[2]);
 return [$top,{id=>$e->[0]},['e164val:validationInfo',@c]];
}

sub add_validation_information
{
 my ($epp,$domain,$rd,$action,$top)=@_;
 return unless (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{e164_validation_information}) && (ref($rd->{e164_validation_information}) eq 'ARRAY') && @{$rd->{e164_validation_information}});

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('e164val:'.$action,'xmlns:e164val="'.$NS.'"');
 my @n=map { format_validation($_,$action,$top) } as_array($rd->{e164_validation_information});
 $mes->command_extension($eid,\@n);
 return;
}

sub as_array
{
 my $ra=shift;
 if (grep { !ref($_) } @$ra)
 {
  return ($ra);
 } else
 {
  return @$ra;
 }
}

####################################################################################################
########### Query commands

sub info_parse ## §5.1.2
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension($NS,'infData');
 return unless defined $infdata;

 my @val;
 foreach my $el ($infdata->getChildrenByTagNameNS($NS,'inf'))
 {
  my $id=$el->getAttribute('id');
  my $r=($el->getChildrenByTagNameNS($NS,'validationInfo'))[0];
  $r=$r->getFirstChild();
  while( $r->nodeType()!=1) { $r=$r->getNextSibling(); }
  my $uri=$r->namespaceURI();
  Net::DRI::Exception::usererr_insufficient_parameters('No validation information module found for URI='.$uri) unless exists($VAL{$uri});
  push @val,[$id,$uri,$VAL{$uri}->info_parse($po,$r)];
 }

 $rinfo->{domain}->{$oname}->{e164_validation_information}=\@val;
 return;
}

####################################################################################################
############ Transform commands

sub create ## §5.2.1
{
 my ($epp,$domain,$rd)=@_;
 add_validation_information($epp,$domain,$rd,'create','e164val:add');
 return;
}

sub renew ## §5.2.3
{
 my ($epp,$domain,$rd)=@_;
 add_validation_information($epp,$domain,$rd,'renew','e164val:add');
 return;
}

sub transfer_request ## §5.2.4
{
 my ($epp,$domain,$rd)=@_;
 add_validation_information($epp,$domain,$rd,'transfer','e164val:add');
 return;
}

sub update ## §5.2.5
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $toadd=$todo->add('e164_validation_information');
 my $todel=$todo->del('e164_validation_information');
 my $toset=$todo->set('e164_validation_information');
 return unless (defined($toadd) || defined($todel) || defined($toset));

 my @n;
 push @n,map { format_validation($_,'update','e164val:add') } as_array($toadd) if (defined($toadd) && (ref($toadd) eq 'ARRAY'));
 push @n,map { ['e164val:rem',{id=>(ref($_) eq 'ARRAY')? $_->[0] : $_->[0]}] } as_array($todel) if (defined($todel) && (ref($todel) eq 'ARRAY'));
 push @n,map { format_validation($_,'update','e164val:chg') } (ref($toset) eq 'ARRAY')? @$toset : ($toset) if (defined($toset));
 return unless @n;

 my $eid=$mes->command_extension_register('e164val:update','xmlns:e164val="'.$NS.'"');
 $mes->command_extension($eid,\@n);
 return;
}

####################################################################################################
1;
