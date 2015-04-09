## Domain Registry Interface, EPP ARI Block Extension
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ARI::Block;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ARI::Block - Block Extensions for ARI : L<http://ausregistry.github.io/doc/block-1.0/block-1.0.html>

=head1 DESCRIPTION

Adds the Block Extension (urn:ar:params:xml:ns:block-1.0) to domain commands. The extension is built by adding a hash to info, create, delete and renew commands.

 eg.
$rc=$dri->domain_info('example22.menu',{block_id => 'BLK-1'});
$rc=$dri->domain_create('example22.menu',{ ..., block_id => 'BLK-1'});
my $block_id = $dri->get_info('block_id');
 
=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
(c) 2015 Michael Holloway <michael@thedarkwinter.com>.
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
     create => [ \&create, \&parse, ],
     info   => [ \&info, \&parse, ],
     delete => [ \&delete, \&parse, ],
     renew  => [ \&renew, \&parse ],
     );
 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'block' => [ 'urn:ar:params:xml:ns:block-1.0','block-1.0.xsd' ]});
 return;
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my ($data,$dt);
 foreach my $dt (qw/creData infData renData/)
 {
  last if $data=$mes->get_extension($mes->ns('block'),$dt);
 }
 return unless defined $data;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
   my ($n,$c)=@$el;
   if ($n eq 'id')
   {
    $rinfo->{domain}->{$oname}->{block_id}=$c->textContent();
   }
 }
 return;
}

####################################################################################################

sub info { return build_block(@_,'info'); }
sub create { return build_block(@_,'create'); }
sub renew { return build_block(@_,'renew'); }
sub delete { return build_block(@_,'delete'); }

sub build_block
{
 my ($epp,$domain,$rd,$cmd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_key($rd,'block_id') && defined $cmd && $cmd =~ m/^(info|create|renew|delete)$/;

 my (@n);
 push @n, ['block:id', $rd->{block_id}];
 my $eid=$mes->command_extension_register('block',$cmd);
 $mes->command_extension($eid,\@n );

 return;
}

####################################################################################################
1;
