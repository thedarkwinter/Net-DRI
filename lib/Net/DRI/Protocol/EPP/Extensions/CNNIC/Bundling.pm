## Domain Registry Interface, Bundling Registration Extension Mapping for EPP
##
## Copyright (c) 2015-2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CNNIC::Bundling;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 state $rops = { 'domain' => { info             => [ undef,    \&info_parse ],
                               create           => [ \&create, \&create_parse ],
                               delete           => [ undef,    \&delete_parse ],
                               renew            => [ undef,    \&renew_parse ],
                               transfer_request => [ undef,    \&transfer_parse ],
                               transfer_cancel  => [ undef,    \&transfer_parse ],
                               transfer_answer  => [ undef,    \&transfer_parse ],
                               update           => [ undef,    \&update_parse ],
                             }
               };

 return $rops;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $ns = { 'b-dn' => [ 'urn:ietf:params:xml:ns:b-dn-1.0','b-dn-1.0.xsd' ] };
 $po->ns($ns);
 return;
}

sub implements { return 'https://tools.ietf.org/id/draft-kong-eppext-bundling-registration-02'; }

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo,$topname)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('b-dn',$topname);
 return unless defined $data;

 $data=Net::DRI::Util::xml_traverse($data,$mes->ns('b-dn'),'bundle');
 return unless defined $data;

 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name=~m/^(rdn|bdn)$/)
  {
   my %r=(alabel => $node->textContent());
   $r{ulabel}=$node->getAttribute('uLabel') if $node->hasAttribute('uLabel');
   $rinfo->{$otype}->{$oname}->{$name}=\%r;
  }
 }

 return;
}

sub info_parse     { return parse(@_,'infData'); } ## no critic (Subroutines::RequireArgUnpacking)
sub create_parse   { return parse(@_,'creData'); } ## no critic (Subroutines::RequireArgUnpacking)
sub delete_parse   { return parse(@_,'delData'); } ## no critic (Subroutines::RequireArgUnpacking)
sub renew_parse    { return parse(@_,'renData'); } ## no critic (Subroutines::RequireArgUnpacking)
sub transfer_parse { return parse(@_,'trnData'); } ## no critic (Subroutines::RequireArgUnpacking)
sub update_parse   { return parse(@_,'upData');  } ## no critic (Subroutines::RequireArgUnpacking)

sub create
{
 my ($epp,$domain,$rp)=@_;
 my $mes=$epp->message();

 my $eid=$mes->command_extension_register('b-dn','create');
 Net::DRI::Exception::usererr_invalid_parameters('ulabel property is mandatory for create with bundling extension') unless Net::DRI::Util::has_key($rp, 'ulabel');
 $mes->command_extension($eid, [ 'b-dn:rdn', { uLabel => $rp->{ulabel} }, $domain]);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CNNIC::Bundling - EPP Bundling Registration Extension mapping (draft-kong-eppext-bundling-registration-02) for Net::DRI

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

Copyright (c) 2015-2016 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
