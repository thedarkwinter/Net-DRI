## Domain Registry Interface, EPP ARI IDN+Variant Extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ARI::IDNVariant;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ARI::IDNVariant - IDN+Variant Extensions for ARI : L<http://ausregistry.github.io/doc/idn-1.0/idn-1.0.html>, L<http://ausregistry.github.io/doc/variant-1.1/variant-1.1.html>

=head1 DESCRIPTION

Adds the IDN (urn:ar:params:xml:ns:idn-1.0) and Variant (urn:ar:params:xml:ns:variant-1.1) extensions to domain commands. The extension is built by adding the following data to the create, and update commands. This information is also returned from an info command. Using the L<Net::DRI::Data::IDN> object, the IDN tag must be specified create the command, and variants can be specified in create and update commands. Note, ARI supports IDNs and Variants using two different extensions, but the same IDN object should be used for both which is why this module combines the two.

=item idn tag (RFC 5646 currectly accepts : ISO 639-1 or 15924, but will be updated with the IDN object)

=item idn variants

 eg. 
 $idn = $dri->local_object('idn')->autodetect('xn--sdcdc.tld','und-Zyyy')->variants(['xn--sdcsdc.tld']);
 $rc = $dri->domain_create('domain.tld',{... idn => $idn } );
 
 $idn = $dri->local_object('idn');
 $toc->add('idn',$idn->clone()->variants(['xn--sdcsdccs.tld]));
 $rc = $dri->domain_update('domain.tld',$toc);
 
=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
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
           info   => [ undef, \&parse ],
           create => [ \&create, \&parse ],
           update => [ \&update, undef ],
         );
 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'idn' => [ 'urn:ar:params:xml:ns:idn-1.0','idn-1.0.xsd' ],
                       'variant' => [ 'urn:ar:params:xml:ns:variant-1.1','variant-1.1.xsd' ] });
 return;
}

sub capabilities_add { return ('domain_update','idn',['add','del']); }

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $idn_infData=$mes->get_extension($mes->ns('idn'),'infData');
 my $var_infData=$mes->get_extension($mes->ns('variant'),'infData');
 my $var_creData=$mes->get_extension($mes->ns('variant'),'creData');
 return unless ($idn_infData || $var_infData || $var_creData);
 
 ## IDN
 my ($idn,$tag);
 if ($idn_infData) {
  foreach my $el (Net::DRI::Util::xml_list_children($idn_infData))
  {
    my ($n,$c)=@$el;
    $tag = $c->textContent() if $n eq 'languageTag';
   }
 }
 $idn = $po->create_local_object('idn')->autodetect($oname,$tag);

 ## Variants 
 my $var_Data = defined ($var_creData) ? $var_creData : $var_infData;
 if ($var_Data)
 {
  my @v;
  foreach my $el (Net::DRI::Util::xml_list_children($var_Data))
  {
   my ($n,$c)=@$el;
   push @v,$c->textContent() if $n eq 'variant';
  }
  $idn->variants(\@v);
 }
 
 $rinfo->{$otype}->{$oname}->{idn}=$idn;
 return;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'idn');
 Net::DRI::Exception::usererr_invalid_parameters('Value for "idn" key must be a Net::DRI::Data::IDN object') unless UNIVERSAL::isa($rd->{idn},'Net::DRI::Data::IDN');
 Net::DRI::Exception::usererr_insufficient_parameters('IDN object hash must have a ISO 639-1/2 or 15924 language tag') unless (defined $rd->{idn}->iso639_1() || $rd->{idn}->iso639_2() || defined $rd->{idn}->iso15924());

 # determin best tag
 my $tag = defined $rd->{idn}->iso639_1() ? $rd->{idn}->iso639_1() : $rd->{idn}->iso639_2();
 if (defined $rd->{idn}->iso15924()) {
   $tag = (defined $tag) ? "$tag-".$rd->{idn}->iso15924() : $rd->{idn}->iso15924();
 }

 ## IDN
 my @n = ['idn:languageTag',$tag]; 
 my $eid=$mes->command_extension_register('idn','create');
 $mes->command_extension($eid,\@n);

 ## Variants
 if ($rd->{idn}->variants())
 {
  my @v = map { ['variant:variant',$_]; } @{$rd->{idn}->variants()};
  my $eid=$mes->command_extension_register('variant','create');
  $mes->command_extension($eid,\@v);
 }

 return;
}

# update is variants only
sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $add = $todo->add('idn');
 my $del = $todo->del('idn');
 return unless ( ($add && UNIVERSAL::isa($add,'Net::DRI::Data::IDN') && $add->variants()) 
                                  || ($del && UNIVERSAL::isa($del,'Net::DRI::Data::IDN') && $del->variants()) );
 
 my @toadd = @{$add->{variants}} if $add->variants();
 my @todel = @{$del->{variants}} if $del->variants();
 return unless (@toadd || @todel);

 my @add = map { ['variant:variant',$_] } @toadd;
 my @del = map { ['variant:variant',$_] } @todel;
 my (@n);
 push @n, ['variant:add',@add] if @add;
 push @n, ['variant:rem',@del] if @del;

 my $eid=$mes->command_extension_register('variant','update');
 $mes->command_extension($eid,\@n);
 return;
}

####################################################################################################
1;
