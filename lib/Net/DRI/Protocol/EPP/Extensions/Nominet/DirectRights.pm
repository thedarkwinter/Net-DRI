## Domain Registry Interface, .UK EPP DirectRights commands
##
## Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::DirectRights;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::DirectRights - .UK EPP DirectRights commands for Net::DRI

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

Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
		check => [ \&check, \&check_parse ],
    );
 return { 'domain' => \%tmp };
}

####################################################################################################
########### Query commands

sub check {
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless exists $rd->{registrant};
 my @n;
 my $eid=$mes->command_extension_register('nom-direct-rights','check',{'xmlns:contact'=>'urn:ietf:params:xml:ns:contact-1.0'});
 if (ref $rd->{registrant} eq '') {
  push @n,['nom-direct-rights:registrant',$rd->{registrant}];
 }
 elsif (ref $rd->{registrant} eq 'Net::DRI::Data::Contact::Nominet') {
  my $c = $rd->{registrant};
  push @n,['nom-direct-rights:registrant',$c->srid()] if $c->srid();
  if (!$c->srid()) {
   my (@d,@st,@ad);
   push @d,['contact:name',$c->name()] if $c->name();
   push @d,['contact:org',$c->org()] if $c->org();
   @st = $c->street();
   foreach (@st) { push @ad,['contact:street',$_->[0]] if $_; }
   foreach (qw/city sp pc cc/) { push @ad,['contact:'.$_,$c->$_()] if $c->$_(); }
   push @d,['contact:addr',@ad];
   push @n,['nom-direct-rights:postalInfo',@d,{type=>'loc'}];
   push @n,['nom-direct-rights:email',$c->email()] if $c->email();
  }
 }
 $mes->command_extension($eid,\@n);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkData=$mes->get_extension('nom-direct-rights','chkData');
 return unless $chkData;

 foreach my $el (Net::DRI::Util::xml_list_children($chkData))
 {
  my ($name,$c)=@$el;
  $rinfo->{domain}->{$oname}->{'right'} = $c->textContent() if $name eq 'ror';
 }
 return;
}

####################################################################################################
1;
