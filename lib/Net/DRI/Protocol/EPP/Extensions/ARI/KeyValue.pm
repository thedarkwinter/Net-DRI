## Domain Registry Interface, EPP ARI Key Value Extension
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

package Net::DRI::Protocol::EPP::Extensions::ARI::KeyValue;
## NOTE, this is copied + modified from ARI::KeyValue, since the other extensions seem to differ I thought it probably worth keeping separete,

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ARI::KeyValue - EPP ARI Key Value commands for Net::DRI : L<http://ausregistry.github.io/doc/kv-1.0/kv-1.0.html>

=head1 DESCRIPTION

Adds the KeyValue Extension (urn:X-ar:params:xml:ns:kv-1.0) to domain commands. The extension is built by adding the following data to the create, and update commands. This information is also returned from an info command.

  $kv = { bn => { 'entityType' => 'Australian Private Company', 'abn' => '18 092 242 209' } };
  $rc = $dri->domain_create('domain.tld',{... keyvalue => $kv});

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

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           info   => [ undef         , \&info_parse ],
           create => [ \&create_build, undef ],
           update => [ \&update_build, undef ],
           renew  => [ \&renew_build, undef ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'kv' => [ 'urn:X-ar:params:xml:ns:kv-1.0','kv-1.0.xsd' ]});
 return;
}

sub capabilities_add { return ('domain_update','keyvalue',['set']); }

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('kv','infData');
 return unless defined $data;

 my %kvs;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'kvlist')
  {
   my $kvname=$node->getAttribute('name');
   my %kv;
   foreach my $kvel (Net::DRI::Util::xml_list_children($node))
   {
    my ($kvelname,$kvelnode)=@$kvel;
    if ($kvelname eq 'item')
    {
     $kv{$kvelnode->getAttribute('key')}=$kvelnode->textContent();
    }
   }
   $kvs{$kvname}=\%kv;
  }
 }

 $rinfo->{domain}->{$oname}->{keyvalue}=\%kvs;
 return;
}

sub build_kvlists
{
 my ($rd)=@_;
 Net::DRI::Exception::usererr_invalid_parameters(qq{keyvalue parameter must be ref hash, not: }.$rd) unless ref $rd eq 'HASH';
 my @kvs;
 foreach my $kvlistname (sort { $a cmp $b } keys %$rd)
 {
  Net::DRI::Exception::usererr_invalid_parameters(qq{kvlist name "$kvlistname" must be an XML token}) unless Net::DRI::Util::xml_is_token($kvlistname);
  Net::DRI::Exception::usererr_invalid_parameters(qq{value for kvlistname "$kvlistname" must be ref hash, not: }.$rd->{$kvlistname}) unless ref $rd->{$kvlistname} eq 'HASH';
  my @kv;
  foreach my $key (sort { $a cmp $b } keys %{$rd->{$kvlistname}})
  {
   Net::DRI::Exception::usererr_invalid_parameters(qq{item name "$key" (in kvlist name "$kvlistname") must be an XML token}) unless Net::DRI::Util::xml_is_token($key);
   my $v=$rd->{$kvlistname}->{$key};
   Net::DRI::Exception::usererr_invalid_parameters(qq{value "$v" for item name "$key" (in kvlist name "$kvlistname") must be an XML string}) unless Net::DRI::Util::xml_is_string($v);
   push @kv,['kv:item',{key => $key},$v];
  }
  push @kvs,['kv:kvlist',{name => $kvlistname},@kv];
 }
 return @kvs;
}

sub create_build
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'keyvalue');

 my $eid=$mes->command_extension_register('kv','create');
 $mes->command_extension($eid,[build_kvlists($rd->{keyvalue})]);

 return;
}

sub update_build
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $toset=$todo->set('keyvalue');
 return unless defined $toset;

 my $eid=$mes->command_extension_register('kv','update');
 $mes->command_extension($eid,[build_kvlists($toset)]);

 return;
}

sub renew_build
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'keyvalue');

 my $eid=$mes->command_extension_register('kv','renew');
 $mes->command_extension($eid,[build_kvlists($rd->{keyvalue})]);

 return;
}

####################################################################################################
1;
