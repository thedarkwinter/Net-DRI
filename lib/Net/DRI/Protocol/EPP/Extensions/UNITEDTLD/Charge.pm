## Domain Registry Interface, United TLD EPP Charge Extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013-2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::UNITEDTLD::Charge;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::UNITEDTLD::Charge - Charge Extension for United TLD premium domains.

=head1 DESCRIPTION

Adds the Charge Extension (http://www.unitedtld.com/epp/charge-1.0) to domain commands. For a premium domain, domain_check will return a hash with the pricing information. This hash can be passed straight into the domain create command (indicating that you agree to the price). You could also build your own hash. You can call domain_info to get the price for a renewal/transfer, and then use that hash for the relevant command.

=item type [price / fee]

=item category [premium / earlyAccess / possible other values]

=item category_name [more of a description really but the looks of it]

=item create [price for create]

=item renew [price for renew]

=item transfer [price for transfer]

=item restore [price for restore]

 # check and create
 
 $rc = $dri->domain_check('premium.tld');
 my $ch = $dri->get_info('charge');
 if ($ch->{create} < '1000000000.00') { 
   $rc=$dri->domain_create('premium.tld',{pure_create=>1,auth=>{pw=>'2fooBAR'},......,'charge' => $ch}); 
 }
 
 # info and transfer
 $rc = $dri->domain_info('premium.tld');
 my $ch = $dri->get_info('charge');
 $rc=$dri->domain_transfer_start('premium.tld',{...,'charge' => $ch}); 
 
 # renew (manual hashref)
 $ch = { type => 'price', category =>'premium', category_name=>'super cool',renew=>'100.00' };
 $rc=$dri->domain_renew('premium.tld',{...,'charge' => $ch}); 
 
 # early access program combines two charge_sets, the extension will accept either a hashref or an arrayref
 $ch1 = { type => 'price', category =>'premium', category_name=>'super cool',create=>'100.00' };
 $ch2 = { type => 'fee', category =>'earlyAccess',create=>'10000' };
 $rc=$dri->domain_renew('premium.tld',{...,'charge' => [$ch1,$ch2]}); 
 

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
(c) 2013-2014 Michael Holloway <michael@thedarkwinter.com>.
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
           check => [ undef, \&check_parse],
           check_multi => [ undef, \&check_parse],
           info => [ undef, \&info_parse],
           create => [ \&create, \&transform_parse ],
           update => [ \&update, \&transform_parse ],
           transfer_request => [ \&transfer, \&transform_parse ],
           renew => [ \&renew, \&transform_parse ],
        );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->ns({ map { $_ => ['http://www.unitedtld.com/epp/'.$_.'-1.0',$_.'-1.0.xsd'] } qw/charge/ }); 
 $po->capabilities('domain_update','charge',['set']);
}

####################################################################################################
## Build / Parse helpers

sub charge_set_parse
{
 my $start = shift;
 return unless $start;
 my $set = {};
 foreach my $el (Net::DRI::Util::xml_list_children($start)) 
 {
  my ($n,$c)=@$el;
  if ($n eq 'category')
  {
    $set->{'category'} = $c->textContent();
    $set->{'category_name'} = $c->getAttribute('name') if $c->hasAttribute('name');
  } elsif ($n eq 'type')
  {
    $set->{'type'} = $c->textContent();
  } elsif ($n eq 'amount')
  {
    $set->{$c->getAttribute('command')} = $c->textContent() unless $c->hasAttribute('name');
    $set->{$c->getAttribute('name')} = $c->textContent() if $c->hasAttribute('name');
  }
 }
 return $set;
}

sub charge_set_build
{
  my ($rdr,$func) = @_;
  my @rds;
  if (ref $rdr eq 'ARRAY') 
  {
    @rds = @{$rdr};
  } else {
   @rds = ($rdr);
  }
  my @set;
  foreach my $rd (@rds)
  {
   Net::DRI::Exception::usererr_insufficient_parameters('charge type') unless exists $rd->{type} && $rd->{type}  =~ m/^(?:price|fee)$/;
   Net::DRI::Exception::usererr_insufficient_parameters('charge category') unless exists $rd->{category} && $rd->{category}  =~ m/\w+/;  # FIXME: don't know if this is an open text field
   Net::DRI::Exception::usererr_invalid_parameters('charge category name') if exists $rd->{category_name} && $rd->{category_name}  !~ m/\w+/;  # FIXME: sure this is an optional field?
   Net::DRI::Exception::usererr_invalid_parameters('charge category '.$func.' amount '.$rd->{$func}) unless exists $rd->{$func} && $rd->{$func}  =~ m/^\d+(\.\d*)?$/ ;  # numeric
   my @n;
   push @n, ['charge:category',{'name'=>$rd->{category_name} },$rd->{category} ] if defined $rd->{category_name};
   push @n, ['charge:category',$rd->{category} ] unless defined $rd->{category_name};
   push @n, ['charge:type',$rd->{type} ] ;
   push @n, ['charge:amount', {'command' => $func }, $rd->{$func} ] unless $func eq 'restore';
   push @n, ['charge:amount', {'command' => 'update', 'name' => $func }, $rd->{$func} ] if $func eq 'restore';
   push @set, ['charge:set', @n ];
  }
  return @set;
}

####################################################################################################
## Price Standardisation

sub set_premium_values {
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 return unless $otype && $oaction && $oname;
 return unless exists $rinfo->{domain}->{$oname}->{charge} && (ref $rinfo->{domain}->{$oname}->{charge} eq 'ARRAY');
 foreach my $ch (@{$rinfo->{domain}->{$oname}->{charge}})
 {
  if ($ch->{category} eq 'premium') {
   $rinfo->{domain}->{$oname}->{is_premium} = 1;
   $rinfo->{domain}->{$oname}->{price_category} = $ch->{category_name};
   $rinfo->{domain}->{$oname}->{price_currency} = 'USD';
   $rinfo->{domain}->{$oname}->{price_duration} = DateTime::Duration->new(years=>1);
   $rinfo->{domain}->{$oname}->{create_price} = $ch->{create};
   $rinfo->{domain}->{$oname}->{renew_price} = $ch->{renew};
   $rinfo->{domain}->{$oname}->{restore_price} = $ch->{restore};
   $rinfo->{domain}->{$oname}->{transfer_price} = $ch->{transfer};
  } else {
   $rinfo->{domain}->{$oname}->{has_fee} = 1;
   $rinfo->{domain}->{$oname}->{fee_category} = $ch->{category};
   $rinfo->{domain}->{$oname}->{fee_price} = $ch->{create};
  }
 }
 return;
}

####################################################################################################
## Query Commands

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $chkdata=$mes->get_extension($mes->ns('charge'),'chkData');
 return unless defined $chkdata;
 foreach my $el (Net::DRI::Util::xml_list_children($chkdata))
 {
   my ($n,$c)=@$el;
   if ($n eq 'cd')
   {
    my $dn = '';
    foreach my $el2 (Net::DRI::Util::xml_list_children($c))
    {
     my ($n2,$c2)=@$el2;
     $dn = $c2->textContent() if $n2 eq 'name';
     push @{$rinfo->{domain}->{$dn}->{charge}},charge_set_parse($c2) if $n2 eq 'set';
    }
    set_premium_values($po,$otype,$oaction,$dn,$rinfo);
   }
 }
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_extension($mes->ns('charge'),'infData');
 return unless defined $infdata;
 
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($n,$c)=@$el;
   push @{$rinfo->{domain}->{$oname}->{charge}},charge_set_parse($c) if $n eq 'set';
 }
 set_premium_values($po,$otype,$oaction,$oname,$rinfo);
 return;
}

####################################################################################################
## Transform Commands

# the result extension is always the same for transfer commands, just the name (creData/upData etc) changes
sub transform_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $resdata;
 foreach my $ex (qw/creData upData trnData renData agreement/) # FIXME: add agreement for the dom_create General Avalability for zacr new gTLDs - added here instead of create a new file only for this small restriction.... 
 {
  next unless $resdata=$mes->get_extension($mes->ns('charge'),$ex);  
  foreach my $el (Net::DRI::Util::xml_list_children($resdata))
  {
    my ($n,$c)=@$el;
    push @{$rinfo->{domain}->{$oname}->{charge}},charge_set_parse($c) if $n eq 'set';
  }
 }
 set_premium_values($po,$otype,$oaction,$oname,$rinfo);
 return;
}

sub transform_build
{
 my ($epp,$domain,$rd,$cmd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'charge'); 
 my @n = charge_set_build($rd->{'charge'},$cmd);
 return unless @n;
 my $eid=$mes->command_extension_register('charge','agreement');
 $mes->command_extension($eid,\@n);
 return;
}

sub create { transform_build(@_,'create'); }
sub transfer { transform_build(@_,'transfer'); }
sub renew { transform_build(@_,'renew'); }

sub update {
   my ($epp,$domain,$todo)=@_;
   return unless my $ch = $todo->set('charge');
   transform_build($epp,$domain,{'charge' => $ch},'restore'); 
}

1;
