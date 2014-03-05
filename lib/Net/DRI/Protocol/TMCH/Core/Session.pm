## Domain Registry Interface, TMCH Session commands
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::TMCH::Core::Session;
use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
            connect => [ undef , \&parse_greeting ],
            noop      => [ \&hello, \&parse_greeting ], ## for keepalives
            login     => [ \&login ],
            logout    => [ \&logout ],

          );

 return { 'session' => \%tmp };
}

sub hello ## should trigger a greeting from server, allowed at any time
{
 my ($tmch)=@_;
 my $mes=$tmch->message();
 $mes->command(['hello']);
}

# tmch greeting doesn't seem to return any useful information
sub parse_greeting
{
my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $g=$mes->node_greeting();
 return unless $mes->is_success() && defined $g; ## make sure we are not called for all parsing operations (after poll), just after true greeting

 my %tmp=(extensions_announced => []);
 foreach my $el (Net::DRI::Util::xml_list_children($g))
 {
  my ($n,$c)=@$el;
  if ($n eq 'svID')
  {
   $tmp{server_id}=$c->textContent();
  } elsif ($n eq 'svDate')
  {
   $tmp{date}=$po->parse_iso8601($c->textContent());
  }
 }
 
$tmp{version} = ['1.0'];
$tmp{lang} = ['en'];

 $po->default_parameters()->{server}=\%tmp;
 $rinfo->{session}->{server}=\%tmp;
}

sub logout
{
 my ($tmch)=@_;
 my $mes=$tmch->message();
 $mes->command(['logout']);
}

# tmch login doesn't seem to use extensions etc, or specify language
sub login
{
 my ($po,$login,$password,$rdata)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('login')    unless defined $login && length $login;
 Net::DRI::Exception::usererr_insufficient_parameters('password') unless defined $password && length $password;
 Net::DRI::Exception::usererr_invalid_parameters('login')         unless Net::DRI::Util::xml_is_token($login,3,16);
 Net::DRI::Exception::usererr_invalid_parameters('password')      unless Net::DRI::Util::xml_is_token($password,6,16);

 my $mes=$po->message();
 $mes->command(['login']);
 my @d;
 push @d,['clID',$login];
 push @d,['pw',$password];

 $mes->command_body(\@d);
}

1;
