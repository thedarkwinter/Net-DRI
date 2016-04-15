## Domain Registry Interface, Reseller Extension Mapping for EPP
##
## Copyright (c) 2015,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ResellerInfo;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %dhc = ( info   => [ undef, \&info_parse ],
             create => [ \&create_build, undef ],
             update => [ \&update_build, undef ] );

 return { 'domain' => \%dhc, 'host' => \%dhc, 'contact' => \%dhc };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'resellerext' => [ 'urn:ietf:params:xml:ns:resellerext-1.0','resellerext-1.0.xsd' ] });
 return;
}

sub capabilities_add { return ('domain_update','reseller',[qw/add del set/]); }

sub implements { return 'https://tools.ietf.org/html/draft-zhou-eppext-reseller-03'; }

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension($mes->ns('resellerext'),'infData');
 return unless defined $data;

 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'id')
  {
   $rinfo->{$otype}->{$oname}->{reseller}=$node->textContent();
  }
 }

 return;
}

sub _add_id
{
 my ($id)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for reseller id: '.$id) unless Net::DRI::Util::xml_is_token($id,3,16);
 return (['resellerext:id',$id]);
}

sub create_build
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'reseller');
 my @d=_add_id($rd->{reseller});

 my $eid=$mes->command_extension_register('resellerext','create');
 $mes->command_extension($eid,\@d);

 return;
}

sub update_build
{
 my ($epp,$domain,$todo,$rp)=@_;

 my $add=$todo->add('reseller');
 my $del=$todo->del('reseller');
 my $set=$todo->set('reseller');

 return unless defined $add || defined $del || defined $set;
 Net::DRI::Exception::usererr_invalid_parameters('Incompatible changeset for reseller: only add or del or set') if 1 < grep { defined } ($add,$del,$set);

 my @n;
 push @n,['resellerext:add',_add_id($add)] if defined $add;
 push @n,['resellerext:rem',_add_id($del)] if defined $del;
 push @n,['resellerext:chg',_add_id($set)] if defined $set;

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('resellerext','update');
 $mes->command_extension($eid,\@n);
 return;
}


####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ResellerInfo - EPP Reseller Extension mapping (draft-zhou-eppext-reseller-03) for Net::DRI

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

Copyright (c) 2015,2016 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
