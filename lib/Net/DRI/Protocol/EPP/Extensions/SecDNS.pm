## Domain Registry Interface, EPP DNS Security Extensions (RFC4310 & RFC5910)
##
## Copyright (c) 2005-2010,2012-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::SecDNS;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SecDNS - EPP DNS Security Extensions (version 1.0 in RFC4310 & version 1.1 in RFC5910) for Net::DRI

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

Copyright (c) 2005-2010,2012-2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my %s=(
	'connect' => [ undef, \&parse_greeting ],
	 noop      => [ undef, \&parse_greeting ],
       );
 my %d=(
        info      => [ undef, \&info_parse ],
        create    => [ \&create, undef ],
        update    => [ \&update, undef ],
       );

 return { 'domain' => \%d, 'session' => \%s };
}

sub capabilities_add { return (['domain_update','secdns',['add','del','set']],['domain_update','secdns_urgent',['set']]); }

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'secDNS' => [ 'urn:ietf:params:xml:ns:secDNS-1.0','secDNS-1.0.xsd' ] }); ## this will get bumped to secDNS-1.1 after login if server supports it, until all registry servers have been upgraded to 1.1
 return;
}

####################################################################################################

sub format_dsdata
{
 my ($e,$nomsl)=@_;

 my @mk=grep { ! Net::DRI::Util::has_key($e,$_) } qw/keyTag alg digestType digest/;
 Net::DRI::Exception::usererr_insufficient_parameters('Attributes missing: '.join(' ',@mk)) if @mk;
 Net::DRI::Exception::usererr_invalid_parameters('keyTag must be 16-bit unsigned integer: '.$e->{keyTag}) unless Net::DRI::Util::verify_ushort($e->{keyTag});
 Net::DRI::Exception::usererr_invalid_parameters('alg must be an unsigned byte: '.$e->{alg}) unless Net::DRI::Util::verify_ubyte($e->{alg});
 Net::DRI::Exception::usererr_invalid_parameters('digestType must be an unsigned byte: '.$e->{digestType}) unless Net::DRI::Util::verify_ubyte($e->{digestType});
 Net::DRI::Exception::usererr_invalid_parameters('digest must be hexadecimal: '.$e->{digest}) unless Net::DRI::Util::verify_hex($e->{digest});

 my @c;
 push @c,['secDNS:keyTag',$e->{keyTag}];
 push @c,['secDNS:alg',$e->{alg}];
 push @c,['secDNS:digestType',$e->{digestType}];
 push @c,['secDNS:digest',$e->{digest}];

 if (exists $e->{maxSigLife} && ! $nomsl)
 {
  Net::DRI::Exception::usererr_invalid_parameters('maxSigLife must be a positive integer: '.$e->{maxSigLife}) unless Net::DRI::Util::verify_int($e->{maxSigLife},1);
  push @c,['secDNS:maxSigLife',$e->{maxSigLife}];
 }

 ## If one key attribute is provided, all of them should be (this is verified in format_keydata)
 if (exists $e->{key_flags} || exists $e->{key_protocol} || exists $e->{key_alg} || exists $e->{key_pubKey})
 {
  push @c,['secDNS:keyData',format_keydata($e)];
 }

 return @c;
}

sub format_keydata
{
 my ($e)=@_;

 my @mk=grep { ! Net::DRI::Util::has_key($e,$_) } qw/key_flags key_protocol key_alg key_pubKey/;
 Net::DRI::Exception::usererr_insufficient_parameters('Attributes missing: '.join(' ',@mk)) if @mk;

 Net::DRI::Exception::usererr_invalid_parameters('key_flags mut be a 16-bit unsigned integer: '.$e->{key_flags}) unless Net::DRI::Util::verify_ushort($e->{key_flags});
 Net::DRI::Exception::usererr_invalid_parameters('key_protocol must be an unsigned byte: '.$e->{key_protocol}) unless Net::DRI::Util::verify_ubyte($e->{key_protocol});
 Net::DRI::Exception::usererr_invalid_parameters('key_alg must be an unsigned byte: '.$e->{key_alg}) unless Net::DRI::Util::verify_ubyte($e->{key_alg});
 Net::DRI::Exception::usererr_invalid_parameters('key_pubKey must be a non empty base64 string: '.$e->{key_pubKey}) unless Net::DRI::Util::verify_base64($e->{key_pubKey},1);

 return (['secDNS:flags',$e->{key_flags}],['secDNS:protocol',$e->{key_protocol}],['secDNS:alg',$e->{key_alg}],['secDNS:pubKey',$e->{key_pubKey}]);
}

sub parse_greeting
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 return unless defined $mes->node_greeting(); ## only work here for true greeting reply handling, not for all polling responses !

 my $rs=$po->default_parameters()->{server};
 my @v=grep { m/^urn:ietf:params:xml:ns:secDNS-\S+$/ } @{$rs->{extensions_selected}};
 ##Net::DRI::Exception::err_invalid_parameters('Net::DRI::Protocol::EPP::Extensions::SecDNS was loaded but server does not support the secDNS extension!') unless @v;
 return unless @v;
 Net::DRI::Exception::err_invalid_parameters('Net::DRI::Protocol::EPP::Extensions::SecDNS supports only versions 1.0 or 1.1, but the server announced: '.join(' ',@v)) if grep { ! /^urn:ietf:params:xml:ns:secDNS-1\.[01]$/ } @v;

 ## If server supports secDNS-1.1 we switch to it completely
 if (grep { m/1\.1/ } @v)
 {
  $po->ns({ 'secDNS' => [ 'urn:ietf:params:xml:ns:secDNS-1.1','secDNS-1.1.xsd' ] });
  $rs->{extensions_selected}=[ grep { ! m/^urn:ietf:params:xml:ns:secDNS-1.0$/ } @{$rs->{extensions_selected}} ] if grep { m/1\.0/ } @v;
 } else
 {
  $po->ns({ 'secDNS' => [ 'urn:ietf:params:xml:ns:secDNS-1.0','secDNS-1.0.xsd' ] });
 }
 return;
}

####################################################################################################
########### Query commands

sub parse_dsdata
{
 my ($node)=@_;

 my %n;
 foreach my $sel (Net::DRI::Util::xml_list_children($node))
 {
  my ($name,$c)=@$sel;
  if ($name=~m/^(keyTag|alg|digestType|digest|maxSigLife)$/)
  {
   $n{$1}=$c->textContent();
  } elsif ($name eq 'keyData')
  {
   parse_keydata($c,\%n);
  }
 }
 return \%n;
}

sub parse_keydata
{
 my ($node,$rn)=@_;

 foreach my $el (Net::DRI::Util::xml_list_children($node))
 {
  my ($name,$c)=@$el;
  if ($name=~m/^(flags|protocol|alg|pubKey)$/)
  {
   $rn->{'key_'.$1}=$c->textContent();
  }
 }
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension($mes->ns('secDNS'),'infData');
 return unless defined $infdata;

 my @d;
 my $ns=$mes->ns('secDNS');

 if ($ns=~m/1\.0/)
 {
  @d=map { parse_dsdata($_) } ($infdata->getChildrenByTagNameNS($mes->ns('secDNS'),'dsData'));
 } else ## secDNS-1.1
 {
  my $msl;
  foreach my $el (Net::DRI::Util::xml_list_children($infdata))
  {
   my ($name,$c)=@$el;
   if ($name eq 'maxSigLife')
   {
    $msl=0+$c->textContent();
   } elsif ($name eq 'dsData')
   {
    my $rn=parse_dsdata($c);
    $rn->{maxSigLife}=$msl if defined $msl;
    push @d,$rn;
   } elsif ($name eq 'keyData')
   {
    my %n;
    parse_keydata($c,\%n);
    $n{maxSigLife}=$msl if defined $msl;
    push @d,\%n;
   }
  }
 }

 $rinfo->{domain}->{$oname}->{secdns}=\@d;
 return;
}

############ Transform commands

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'secdns');
 Net::DRI::Exception::usererr_invalid_parameters('secdns value must be an array reference with key data') unless ref $rd->{secdns} eq 'ARRAY';
 return unless @{$rd->{secdns}};

 my $eid=$mes->command_extension_register('secDNS','create');
 my @n;
 if ($mes->ns('secDNS')=~m/1\.0/)
 {
  @n=map { ['secDNS:dsData',format_dsdata($_,0)] } (@{$rd->{secdns}});
 } else ## secDNS-1.1
 {
  push @n,add_maxsiglife($rd->{secdns});
  push @n,add_interfaces($rd->{secdns});
 }
 $mes->command_extension($eid,\@n);
 return;
}

sub add_maxsiglife
{
 my ($ra)=@_;

 my %msl=map { 0+$_->{maxSigLife} => 1 } grep { exists $_->{maxSigLife} } @$ra;
 return unless %msl;

 Net::DRI::Exception::usererr_invalid_parameters('Multiple distinct maxSigLife provided') if keys(%msl) > 1;
 my $msl=(keys(%msl))[0];
 Net::DRI::Exception::usererr_invalid_parameters('maxSigLife must be a positive integer: '.$msl) unless Net::DRI::Util::verify_int($msl,1);
 return ['secDNS:maxSigLife',$msl];
}

sub add_interfaces
{
 my ($ra)=@_;

 my $cd=grep { exists $_->{keyTag} || exists $_->{alg} || exists $_->{digestType} || exists $_->{digest} } @$ra;
 my $ck=grep { (exists $_->{key_flags} || exists $_->{key_protocol} || exists $_->{key_alg} || exists $_->{key_pubKey}) && ! exists $_->{keyTag} && ! exists $_->{alg} && ! exists $_->{digestType} && ! exists $_->{digest} } @$ra;
 Net::DRI::Exception::usererr_invalid_parameters('Unknown secDNS data provided') unless $cd || $ck;
 Net::DRI::Exception::usererr_invalid_parameters('In secDNS-1.1 you can not mix dsData and keyData blocks') if $cd && $ck;
 return $cd ? map { ['secDNS:dsData',format_dsdata($_,1)] } @$ra : map { ['secDNS:keyData',format_keydata($_)] } @$ra;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $toadd=$todo->add('secdns');
 my $todel=$todo->del('secdns');
 my $toset=$todo->set('secdns');
 my $urgent=$todo->set('secdns_urgent');

 my @def=grep { defined } ($toadd,$todel,$toset);
 return unless @def; ## no updates asked

 my $ver=(grep { /-1\.1$/ } $mes->ns('secDNS'))? '1.1' : '1.0';
 Net::DRI::Exception::usererr_invalid_parameters('In SecDNS-1.0, only add or del or chg is possible, not more than one of them') if ($ver eq '1.0' && @def>1);

 my $urg=(defined $urgent && $urgent)? 'urgent="1" ' : '';
 my $eid=$mes->command_extension_register('secDNS','update',defined $urgent && $urgent ? { urgent => 1 } : {});

 my @n;

 if ($ver eq '1.0')
 {
  if (defined $todel)
  {
   my @nn;
   foreach my $e (ref $todel eq 'ARRAY' ? @$todel : ($todel))
   {
    $e=$e->{keyTag} if ref $e eq 'HASH';
    Net::DRI::Exception::usererr_invalid_parameters('keyTag must be 16-bit unsigned integer: '.$e) unless Net::DRI::Util::verify_ushort($e);
    push @nn,['secDNS:keyTag',$e];
   }
   push @n,['secDNS:rem',@nn];
  }
  push @n,['secDNS:add',map { ['secDNS:dsData',format_dsdata($_,0)] } (ref $toadd eq 'ARRAY')? @$toadd : ($toadd)] if defined $toadd;
  push @n,['secDNS:chg',map { ['secDNS:dsData',format_dsdata($_,0)] } (ref $toset eq 'ARRAY')? @$toset : ($toset)] if defined $toset;
 } else ## secDNS-1.1
 {
  if (defined $todel)
  {
   if (! ref $todel)
   {
    Net::DRI::Exception::usererr_invalid_parameters('In delete, only string allowed is "all", not: '.$todel) unless $todel eq 'all';
    push @n,['secDNS:rem',['secDNS:all','true']];
   } else
   {
    push @n,['secDNS:rem',add_interfaces(ref $todel eq 'ARRAY' ? $todel : [ $todel ] )];
   }
  }
  push @n,['secDNS:add',add_interfaces(ref $toadd eq 'ARRAY' ? $toadd : [ $toadd ] )]                                                 if defined $toadd;
  push @n,['secDNS:chg',add_maxsiglife(ref $toset eq 'ARRAY' ? $toset: (ref $toset eq 'HASH' ? [$toset] : [{ maxSigLife=>$toset }]))] if defined $toset;
 }

 $mes->command_extension($eid,\@n);
 return;
}

####################################################################################################
1;
