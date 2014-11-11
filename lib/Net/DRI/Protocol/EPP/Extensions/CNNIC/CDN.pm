## Domain Registry Interface, CNNIC CDN (Chinese Domain Name) EPP Extension
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

package Net::DRI::Protocol::EPP::Extensions::CNNIC::CDN;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CNNIC::CDN - CNNIC CDN (Chinese Domain Name)

=head1 DESCRIPTION

Adds the EPP Extension for provisioning and management of Chinese Domain Names (CDNs), especially for variant CDNs.

Base on : http://tools.ietf.org/html/draft-kong-epp-cdn-mapping-00

=head1 SYNOPSIS

The CDN  structire is a hash containing the OCDN (original), CSDN (simplified), TCDN (traditional), and VCDNs (others) and is returned in the response from most commads such as domain_info in the below format with both ACE and IDNs.

 $rc=$dri->domain_info('xn--fsq270a.xn--fiqs8s'); 
 $dri->get_info('cdn');

 $cdn = {
  'ocdn' => {
    'ace' => 'xn--fsq270a.xn--fiqs8s',
    'idn' => "\x{5b9e}\x{4f8b}.\x{4e2d}\x{56fd}"
  }
  'scdn' => {
    'idn' => "\x{5b9e}\x{4f8b}.\x{4e2d}\x{56fd}",
    'ace' => 'xn--fsq270a.xn--fiqs8s'
  },
  'tcdn' => {
    'ace' => 'xn--fsqz41a.xn--fiqz9s',
    'idn' => "\x{5be6}\x{4f8b}.\x{4e2d}\x{570b}"
  },
  'vcdns' => [
       {
         'idn' => "\x{5b9f}\x{4f8b}.\x{4e2d}\x{570b}",
         'ace' => 'xn--fsq470a.xn--fiqz9s'
       }
     ],
 };


=head2 Commands

The only commands that require the $cnd are create and update.

=head3 create

Create only uses a list a VCDNs, but uses the same format as in the reponse structure. You can specify the ACE or IDN versions as you like.

 $rc=$dri->domain_create('xn--fsq270a.xn--fiqs8s',{
  ...
  cdn => { vcdns=> [ {idn=>'\x{5b9f}\x{4f8b}.\x{4e2d}\x{570b}'} ] }
  });

=head3 update

Update uses VCDN lists inn Add and Del methods, and SCDN and TCDN in the Set method.

 $toc=Net::DRI::Data::Changes->new();
 my $addcdn = { vcdns=> [ {idn=>'\x{5b9f}\x{4f8b}.\x{4e2d}\x{570b}'} ] };
 my $delcdn = { vcdns=> [ {idn=>'\x{5b9f}\x{4f8b}.\x{4e2d}\x{570b}'} ] };
 my $chgcdn = { tcdn => { ace=>'xn--fsqz41a.xn--fiqz9s' } };
 $toc->set('cdn',$chgcdn);
 $toc->add('cdn',$addcdn);
 $toc->del('cdn',$delcdn);
 $rc=$dri->domain_update('xn--fsq270a.xn--fiqs8s',$toc);
 

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
           info   => [ undef, \&parse],
           create => [ \&create, \&parse ],
           delete => [ undef, \&parse ],
           renew  => [ undef, \&parse ],
           update => [ \&update, \&parse ],
           transfer_query => [ undef, \&parse ],
           transfer_request => [ undef, \&parse ],
        );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->ns({'cdn' =>['urn:ietf:params:xml:ns:cdn-1.0','cdn-1.0.xsd']});
 $po->capabilities('domain_update','cdn',['add','del','set']);

}

####################################################################################################
## Parsing

sub _parse_cdn
{
 my $start = shift;
 return unless $start;
 my ($key,$cdn,$ace,$idn,$vcdn,@vcdns);
 foreach my $el (Net::DRI::Util::xml_list_children($start)) 
 {
  my ($n,$c)=@$el;
  if ($n =~ m/^([OST]CDN)/)
  {
   $key = substr $n,0,4;
   ($ace,$idn) = Net::DRI::Util::idn_get_ace_unicode($c->textContent());
   $cdn->{lc($1)}->{ace} = $ace;
   $cdn->{lc($1)}->{idn} = $idn;
  } elsif ($n eq 'VCDNList')
  {
   foreach my $el2 (Net::DRI::Util::xml_list_children($c)) 
   {
    my ($n2,$c2)=@$el2;
    next if $n2 ne 'VCDN';
    ($ace,$idn) = Net::DRI::Util::idn_get_ace_unicode($c2->textContent());
    $vcdn = { ace=>$ace,idn=>$idn};
    push @vcdns,$vcdn;
   }
   @{$cdn->{vcdns}} = @vcdns;
  }
  
 }
 return $cdn;
}

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 foreach my $ex (qw/infData creData upData delData renData trnData/)
 {
  next unless my $resdata=$mes->get_extension($mes->ns('cdn'),$ex);
  $rinfo->{domain}->{$oname}->{cdn} = _parse_cdn($resdata);
  return;
 }
 return;
}

####################################################################################################
## Building

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'cdn') && ref $rd->{cdn} eq 'HASH';
 Net::DRI::Exception::usererr_invalid_parameters('cdn should be hash with a vcdns list of hashes containing either ace or idn key') if (exists $rd->{cdn}->{vcdns} && ref $rd->{cdn}->{vcdns} ne 'ARRAY');
 return unless exists $rd->{cdn}->{vcdns};
 my (@n,@v,$ace,$idn);
 foreach my $vcdn (@{$rd->{cdn}->{vcdns}})
 {
  Net::DRI::Exception::usererr_invalid_parameters('vcdns list should containt hashes with either ace or idn key') unless exists $vcdn->{ace} || exists $vcdn->{idn};
  ($ace,$idn) = Net::DRI::Util::idn_get_ace_unicode( (exists $vcdn->{ace} ? $vcdn->{ace} : $vcdn->{idn}) );
  push @v, ['cdn:'.'VCDN',$idn] if $idn;
 }
 push @n, ['cdn:VCDNList',@v] if @v;
 return unless @n;
 my $eid=$mes->command_extension_register('cdn','create');
 $mes->command_extension($eid,\@n);
 return;
}

sub update {
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();
 my (@n,$ace,$idn);

 ## add/del : vcdns
 foreach my $func (qw /add del/) {
  next unless my $chg = $todo->$func('cdn');
  next unless exists $chg->{vcdns};
  my @f = ();
  foreach my $vcdn (@{$chg->{vcdns}})
  {
   Net::DRI::Exception::usererr_invalid_parameters($func. ' vcdns list should containt hashes with either ace or idn key') unless exists $vcdn->{ace} || exists $vcdn->{idn};
   ($ace,$idn) = Net::DRI::Util::idn_get_ace_unicode( (exists $vcdn->{ace} ? $vcdn->{ace} : $vcdn->{idn}) );
   push @f, ['cdn:'.'VCDN',$idn] if $idn;
  }
  push @n,['cdn:'.($func eq 'add'?'add':'rem'),@f] if @f;
 }

 ## set : scdn and tcdn
 if (my $chg = $todo->set('cdn'))
 {
  my @f = ();
  foreach my $key (qw/scdn tcdn/)
  {
   next unless exists $chg->{$key};
   Net::DRI::Exception::usererr_invalid_parameters($key . ' should be a hash with either ace or idn key') unless exists $chg->{$key}->{ace} || exists $chg->{$key}->{idn};
   ($ace,$idn) = Net::DRI::Util::idn_get_ace_unicode( (exists $chg->{$key}->{ace} ? $chg->{$key}->{ace} : $chg->{$key}->{idn}) );
   push @f, ['cdn:'.uc($key),$idn] if $idn;
  }
  push @n,['cdn:chg',@f] if @f;
 }

 return unless @n;
 my $eid=$mes->command_extension_register('cdn','update');
 $mes->command_extension($eid,\@n);
 return;
}

1;