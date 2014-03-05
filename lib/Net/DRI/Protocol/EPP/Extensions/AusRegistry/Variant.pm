## Domain Registry Interface, EPP AusRegistry Domain Variant Extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AusRegistry::Variant;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           info   => [ \&info_build, \&info_parse ],
           create => [ undef,        \&create_parse ],
           update => [ \&update_build, undef ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'variant' => [ 'urn:X-ar:params:xml:ns:variant-1.0','variant-1.0.xsd' ],
         });
 return;
}

sub capabilities_add { return ('domain_update','variants',['add','del']); }

####################################################################################################

## (This extension is mandatory)
## <extension>
##  <info xmlns="urn:X-ar:params:xml:ns:variant-1.0" variants="all"/>
## </extension>

sub info_build
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $variants='all'; ## default value
 $variants=$rd->{variants} if Net::DRI::Util::has_key($rd,'variants') && $rd->{variants}=~m/^(?:all|none)$/;

 my $eid=$mes->command_extension_register('variant','info',{variants => $variants});

 return;
}

## <extension>
##  <infData xmlns="urn:X-ar:params:xml:ns:variant-1.0">
##   <variant userForm="&#969;&#963;.example">xn--4xal.example</variant>
##  </infData>
## </extension>

sub parse_variant
{
 my ($rh,$data)=@_;

 my %variants;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'variant')
  {
   $variants{$node->textContent()}=$node->getAttribute('userForm'); ## A-label => U-label
  }
 }

 $rh->{variants}=\%variants;
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('variant','infData');
 return unless defined $data;

 parse_variant($rinfo->{domain}->{$oname},$data);
 return;
}

## <extension>
##  <creData xmlns="urn:X-ar:params:xml:ns:variant-1.0">
##   <variant userForm="&#969;&#963;.example">xn--4xal.example</variant>
##  </creData>
## </extension>

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('variant','creData');
 return unless defined $data;

 parse_variant($rinfo->{domain}->{$oname},$data);
 return;
}

## <extension>
##  <update xmlns="urn:X-ar:params:xml:ns:variant-1.0">
##   <add>
##    <variant userForm="&#969;&#963;.example">xn--4xal.example</variant>
##   </add>
##  </update>
## </extension>

## <extension>
##  <update xmlns="urn:X-ar:params:xml:ns:variant-1.0">
##   <rem>
##    <variant userForm="&#969;&#963;.example">xn--4xal.example</variant>
##   </rem>
##  </update>
## </extension>

sub build_variants
{
 my ($d)=@_;

 my @v;
 foreach my $alabel ( sort { $a cmp $b } keys %$d)
 {
  push @v,['variants:variant',{userForm => $d->{$alabel}},$alabel];
 }

 return @v;
}

sub update_build
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $toadd=$todo->add('variants');
 my $todel=$todo->del('variants');
 return unless defined $toadd || defined $todel;

 my $eid=$mes->command_extension_register('variants','update');
 my @v;

 if (defined $toadd)
 {
  Net::DRI::Exception::usererr_invalid_parameters(q{add variants value must be a ref hash, not: }.$toadd) unless ref $toadd eq 'HASH';
  push @v,['variants:add',build_variants($toadd)];
 }
 if (defined $todel)
 {
  Net::DRI::Exception::usererr_invalid_parameters(q{del variants value must be a ref hash, not: }.$todel) unless ref $todel eq 'HASH';
  push @v,['variants:rem',build_variants($todel)];
 }

 $mes->command_extension($eid,\@v);

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AusRegistry::Variant - EPP AusRegistry Domain Variant commands for Net::DRI

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

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

