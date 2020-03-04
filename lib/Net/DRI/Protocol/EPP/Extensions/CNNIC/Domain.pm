## Domain Registry Interface, CNNIC Domain EPP Extension
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

package Net::DRI::Protocol::EPP::Extensions::CNNIC::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CNNIC::Domain - CN Domain Extension

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

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->ns({ 'cnnic-domain' => 'urn:ietf:params:xml:ns:cnnic-domain-1.0' });

 return;
}

####################################################################################################

sub build_cnnic_domain
{
 my ($rd) = shift;
 my @n;
 my @extdom=('type','purveyor'); # domain extension fields

 Net::DRI::Exception::usererr_invalid_parameters('Invalid domain type. Should be: I (individual) or E (enterprise)" ') if ( exists $rd->{'type'} && $rd->{'type'} !~ m/^(I|E)$/ ); # Only E type domain can be registered according to CNNIC’s policy.
 foreach (@extdom) {
   push @n,['cnnic-domain:'.$_, $rd->{$_}] if $rd->{$_};
 }

 return @n;
}

####################################################################################################
## Parsing

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless my $data=$mes->get_extension($mes->ns('cnnic-domain'),'infData');
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($n,$c)=@$el;
  foreach my $el2(qw/type purveyor/) {
   $rinfo->{domain}->{$oname}->{$el2} = $c->textContent() if $n eq $el2;
  }
 }

 return;
}

####################################################################################################
## Building

sub create
{
 my ($epp,$domain,$rd)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('purveyor extension field is mandatory for domain create!') unless $rd->{purveyor};
 Net::DRI::Exception::usererr_invalid_parameters('purveyor extension field must be a token between: 3-16!') unless $rd->{purveyor} && Net::DRI::Util::xml_is_token($rd->{purveyor},3,16);
 my @n=build_cnnic_domain($rd);
 return unless @n;
 $epp->message()->command_extension('cnnic-domain',['create',@n]);

 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my (@n,@nextdom);
 my @extdom=('type','purveyor');

 return unless( $todo->set('type') || $todo->set('purveyor') );
 Net::DRI::Exception::usererr_invalid_parameters('Invalid domain type. Should be: I (individual) or E (enterprise)" ') if ( $todo->set('type') !~ m/^(I|E)$/ ); # Only E type domain can be registered according to CNNIC’s policy.
 Net::DRI::Exception::usererr_invalid_parameters('purveyor extension field must be a token between: 3-16!') if !Net::DRI::Util::xml_is_token($todo->set('purveyor'),3,16);

 # add / del
 # by their XSD comments:
 # Child elements of <cnnic-domain:update> command
 # Cannot be added or removed, only change is allowed
 # At least one element should be present

 # chg
 foreach (@extdom)
 {
  push @nextdom, ['cnnic-domain:'.$_,$todo->set($_)] if $todo->set($_);
 }

 push @n,['cnnic-domain:chg',@nextdom];
 return unless @n;

 $epp->message()->command_extension('cnnic-domain',['update',@n]);

 return;
}

1;
