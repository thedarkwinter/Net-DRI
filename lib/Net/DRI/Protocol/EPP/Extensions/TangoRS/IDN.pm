## Domain Registry Interface, EPP TangoRS (Knipp) IDN Extension
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::TangoRS::IDN;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TangoRS::IDN - IDN Extensions for TANGO

=head1 DESCRIPTION

Adds the IDN (http://xmlns.tango-rs.net/epp/idn-1.0)  extensions to domain commands. The extension is built by adding the following data to the check, create, and update commands. This information is also returned from an info command. Using the L<Net::DRI::Data::IDN> object, the IDN tag must be specified create the command, and variants can be specified in create and update commands.

=item idn language [ ISO 639-1 ]

=item idn script [ ISO 15924 ]

=item idn variants [ @list ]

=item idn variants

 eg.
 $idn = $dri->local_object('idn')->autodetect('xn--sdcdc.tld','de')->variants(['xn--sdcsdc.tld']);
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

Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>.
(c) 2014 Michael Holloway <michael@thedarkwinter.com>.
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
           check   => [ \&check, \&parse ],
           info   => [ undef, \&parse ],
           create => [ \&create, \&parse ],
           update => [ \&update, undef ],
         );
 return { 'domain' => \%tmp };
}

####################################################################################################

sub _build_idnContainerType
{
 my ($rd,$force_empty_variants) = @_;
 Net::DRI::Exception::usererr_invalid_parameters('Value for "idn" key must be a Net::DRI::Data::IDN object') unless UNIVERSAL::isa($rd->{idn},'Net::DRI::Data::IDN');
 Net::DRI::Exception::usererr_insufficient_parameters('IDN object hash must have a ISO 639-1/2 or 15924 language tag') unless (defined $rd->{idn}->iso639_1() || $rd->{idn}->iso639_2() || defined $rd->{idn}->iso15924());

 ## IDN
 my @n;
 if (defined $rd->{idn}->iso639_1())
 {
   push @n, ['idn:lang',$rd->{idn}->iso639_1()];
 } elsif (defined $rd->{idn}->iso15924())
 {
   push @n, ['idn:script',$rd->{idn}->iso15924()];
 } elsif (defined $rd->{idn}->iso639_2()) # i don't know if this is valid or not
 {
   push @n, ['idn:lang',$rd->{idn}->iso639_2()];
 }

 ## Variants
 my @v;
 if ($rd->{idn}->variants())
 {
  @v = map { ['idn:nameVariant',$_]; } @{$rd->{idn}->variants()};
 }
 push @n,['idn:variants',@v] if @v || $force_empty_variants;
 return @n;
}

sub _parse_idnContainerType
{
 my  ($po,$oname,$data) = @_;
 my ($idn,$tag,@v);
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($n,$c)=@$el;
  $tag = $c->textContent() if $n eq 'lang';
  $tag = $c->textContent() if $n eq 'script'; # choice element

  if ($n eq 'variants')
  {
   foreach my $el2 (Net::DRI::Util::xml_list_children($c))
   {
     my ($n2,$c2)=@$el2;
     push @v,$c2->textContent() if $n2 eq 'nameVariant';
   }
  }
 }
 return undef unless $tag;
 $idn = $po->create_local_object('idn')->autodetect($oname,$tag);
 $idn->variants(\@v);
 return $idn;
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 return unless my $infData=$mes->get_extension($mes->ns('idn'),'infData');
 return unless my $idn = _parse_idnContainerType($po,$oname,$infData);
 $rinfo->{$otype}->{$oname}->{idn}=$idn;
 return;
}

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'idn');
 return unless my @n = _build_idnContainerType($rd);
 my $eid=$mes->command_extension_register('idn','check');
 $mes->command_extension($eid,\@n);
 return;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'idn');
 return unless my @n = _build_idnContainerType($rd,1);
 my $eid=$mes->command_extension_register('idn','create');
 $mes->command_extension($eid,\@n);
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

 my @add = map { ['idn:nameVariant',$_] } @toadd;
 my @del = map { ['idn:nameVariant',$_] } @todel;
 my @n;
 push @n, ['idn:add',@add] if @add;
 push @n, ['idn:rem',@del] if @del;

 my $eid=$mes->command_extension_register('idn','update');
 $mes->command_extension($eid,\@n);
 return;
}

####################################################################################################
1;
