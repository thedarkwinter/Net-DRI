## Domain Registry Interface, CNNIC Host EPP Extension
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CNNIC::Host;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CNNIC::Host - CN Host Extension

=head1 DESCRIPTION

Adds the EPP Registry extension

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
(c) 2015 Michael Holloway <michael@thedarkwinter.com>.
(c) 2015 Paulo Jorge <paullojorgge@gmail.com>.
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
           create   => [ \&create, undef ],
           update   => [ \&update, undef ],
           info     => [ undef, \&info_parse],
        );

 return { 'host' => \%tmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->ns({ 'cnnic-host' => 'urn:ietf:params:xml:ns:cnnic-host-1.0' });

 return;
}

####################################################################################################

sub build_cnnic_host
{
 my ($rh) = shift;
 my @n;
 my @exthost=('purveyor'); # host extension fields

 Net::DRI::Exception::usererr_invalid_parameters('purveyor extension field must be a token between: 3-16!') if !Net::DRI::Util::xml_is_token($rh->{purveyor},3,16);
 foreach (@exthost) {
   push @n,['cnnic-host:'.$_, $rh->{$_}] if $rh->{$_};
 }

 return @n;
}

####################################################################################################
## Parsing

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 return unless my $data=$mes->get_extension('cnnic-host','infData');
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($n,$c)=@$el;
  foreach my $el2(qw/purveyor/) {
   $rinfo->{host}->{$oname}->{$el2} = $c->textContent() if $n eq $el2;
  }
 }

 return;
}

####################################################################################################
## Building

sub create
{
 my ($epp,$host,$rh)=@_;

 return unless $rh->{'purveyor'};
 Net::DRI::Exception::usererr_invalid_parameters('purveyor extension field must be a token between: 3-16!') if !Net::DRI::Util::xml_is_token($rh->{'purveyor'},3,16);
 my @n=build_cnnic_host($rh);
 return unless @n;
 $epp->message()->command_extension('cnnic-host',['create',@n]);

 return;
}

sub update
{
 my ($epp,$host,$todo)=@_;
 my (@n,@nexthost);
 my @exthost=('purveyor');

 return unless( $todo->set('purveyor') );
 Net::DRI::Exception::usererr_invalid_parameters('purveyor extension field must be a token between: 3-16!') if !Net::DRI::Util::xml_is_token($todo->set('purveyor'),3,16);

 # add / del
 # by their XSD comments:
 # Child elements of <cnnic-host:update> command
 # Cannot be added or removed, only change is allowed
 # At least one element should be present

 # chg
 foreach (@exthost)
 {
  push @nexthost, ['cnnic-host:'.$_,$todo->set($_)] if $todo->set($_);
 }

 push @n,['cnnic-host:chg',@nexthost];
 return unless @n;

 $epp->message()->command_extension('cnnic-host',['update',@n]);

 return;
}

1;
