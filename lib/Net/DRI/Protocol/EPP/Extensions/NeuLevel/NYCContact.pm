## Domain Registry Interface, Neulevel EPP NYC Contact Extension
##
## Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NeuLevel::NYCContact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NeuLevel::NYCContact - NeuLevel EPP NYCContact extension for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

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
           create => [ \&create, undef ],
           update => [ \&update, undef ],
           info   => [ undef , \&parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('neulevel','extension');
 return unless defined $infdata;
 my $s=$rinfo->{contact}->{$oname}->{self};
 
 my $unspec;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  next unless $n eq 'unspec';
  foreach my $kv (split(/ /,$c->textContent()))
  {
   my ($k,$v) = split(/=/,$kv);
   next unless $k =~ m/^(?:EXTContact|NexusCategory)$/;
   $s->nexus_category($v) if $k eq 'NexusCategory';
   $s->ext_contact($v)   if $k eq 'EXTContact';
  }
 }

 return;
}

sub create
{
 my ($epp,$c)=@_;
 return unless $c->nexus_category();
 my $unspec = 'EXTContact=' . ($c->ext_contact() && $c->ext_contact() eq 'N' ? 'N':'Y') . ' NexusCategory=' . uc($c->nexus_category());
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('neulevel','extension');
 $mes->command_extension($eid,['neulevel:unspec', $unspec]);
 return;
}

sub update
{
 my ($epp,$oldc,$todo)=@_;
 my $c=$todo->set('info');
 return unless $c->nexus_category();
 my $unspec = 'EXTContact=' . ($c->ext_contact() && $c->ext_contact() eq 'N' ? 'N':'Y') . ' NexusCategory=' . uc($c->nexus_category());
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('neulevel','extension');
 $mes->command_extension($eid,['neulevel:unspec', $unspec]);
 return;
}

1;
