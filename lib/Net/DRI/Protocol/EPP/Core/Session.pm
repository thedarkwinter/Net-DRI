## Domain Registry Interface, EPP Session commands (RFC5730)
##
## Copyright (c) 2005-2007,2010-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::EPP::Core::Session;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::Session - EPP Session commands (RFC5730) for Net::DRI

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

Copyright (c) 2005-2007,2010-2013 Patrick Mevzek <netdri@dotandco.com>.
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
           'connect' => [ undef , \&parse_greeting ],
           login     => [ \&login ],
           logout    => [ \&logout ],
           noop      => [ \&hello, \&parse_greeting ], ## for keepalives
         );

 return { 'session' => \%tmp };
}

sub hello ## should trigger a greeting from server, allowed at any time
{
 my ($epp)=@_;
 my $mes=$epp->message();
 $mes->command(['hello']);
 return;
}

## Most of this was previously in EPP/Message
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
  } elsif ($n eq 'svcMenu')
  {
   foreach my $sel (Net::DRI::Util::xml_list_children($c))
   {
    my ($nn,$cc)=@$sel;
    if ($nn=~m/^(?:version|lang)$/)
    {
     push @{$tmp{$nn}},$cc->textContent();
    } elsif ($nn eq 'objURI')
    {
     push @{$tmp{objects}},$cc->textContent();
    } elsif ($nn eq 'svcExtension')
    {
     push @{$tmp{extensions_announced}},map { $_->textContent() } grep { $_->getName() eq 'extURI' } $cc->getChildNodes();
    }
   }
  } elsif ($n eq 'dcp') ## Does anyone really use this data ??
  {
   $tmp{dcp}=$c->cloneNode(1);
   my $s=substr(substr($c->toString(),5),0,-6); ## we remove <dcp> and </dcp>
   $s=~s/\s+//g;
   $tmp{dcp_string}=$s;
  }
 }

 my %ctxlog=(action=>'greeting',direction=>'in',trid=>$mes->cltrid());

 $po->log_output('info','protocol',{%ctxlog,message=>'EPP lang announced by server: '.join(' ',@{$tmp{lang}})});
 if (exists $tmp{version})
 {
  $po->log_output('warning','procotol',{%ctxlog,message=>'Server announced more than one EPP version: '.join(' ',@{$tmp{version}})}) if @{$tmp{version}} > 1;
  $po->log_output('error','protocol',{%ctxlog,message=>sprintf('Mismatch between EPP server version(s) announced ("%s") and locally supported version "%s"',join(' ',@{$tmp{version}}),$po->version())}) unless grep { $po->version() eq $_ } @{$tmp{version}};
 } else ## .PRO server does not seem to send a version info
 {
  $po->log_output('warning','protocol',{%ctxlog,message=>'Server did not announce any EPP version contrary to specifications; switching to default local version value of '.$po->version()});
  $tmp{version}=[$po->version()];
 }

 ## By default, we will use all extensions announced by server;
 ## EPP extension modules are expected to tweak that depending on their own needs
 ## and users can do so too, with the extensions and extensions_filter attributes
 $tmp{extensions_selected}=$tmp{extensions_announced};

 $po->log_output('info','protocol',{%ctxlog,message=>'EPP extensions announced by server: '.join(' ',@{$tmp{extensions_announced}})});
 my %ext=map { $_ => 1 } (@{$tmp{extensions_announced}},@{$tmp{objects}});
 my %ns=map { $_->[0] => 1 } values %{$mes->ns()};
 delete $ns{$mes->ns('_main')};
 foreach my $ns (keys %ext)
 {
  next if exists $ns{$ns};
  $po->log_output('warning','protocol',{%ctxlog,message=>sprintf('EPP extension "%s" is announced by server but not locally enabled (extension module not loaded or lack of support?)',$ns)});
 }
 foreach my $ns (keys %ns)
 {
  next if exists $ext{$ns};
  $po->log_output('warning','protocol',{%ctxlog,message=>sprintf('EPP extension "%s" is locally enabled but not announced by server (registry policy change?)',$ns)});
 }

 $po->default_parameters()->{server}=\%tmp;
 $rinfo->{session}->{server}=\%tmp;
 return;
}

sub logout
{
 my ($epp)=@_;
 my $mes=$epp->message();
 $mes->command(['logout']);
 return;
}

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

 if (Net::DRI::Util::has_key($rdata,'client_newpassword'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('client_newpassword') unless Net::DRI::Util::xml_is_token($rdata->{client_newpassword},6,16);
  push @d,['newPW',$rdata->{client_newpassword}];
 }

 my (@o,$tmp,@tmp);
 my $sdata=$po->default_parameters()->{server};

 $tmp=Net::DRI::Util::has_key($rdata,'version') ? $rdata->{version} : $sdata->{version};
 Net::DRI::Exception::usererr_insufficient_parameters('version') unless defined $tmp;
 @tmp=ref $tmp eq 'ARRAY' ? @$tmp : ($tmp);
 ($tmp)=(grep { defined && $_ eq $po->version() } @tmp)[0];
 Net::DRI::Exception::usererr_insufficient_parameters(sprintf('No compatible EPP version found: local version "%s" vs user or server provided "%s"',$po->version(),join(' ',@tmp))) unless defined $tmp;
 Net::DRI::Exception::usererr_invalid_parameters('version') unless $tmp=~m/^[1-9]+\.[0-9]+$/;
 push @o,['version',$tmp];

 ## TODO: allow choice of language if multiple choices (like fr+en in .CA) ?
 $tmp=Net::DRI::Util::has_key($rdata,'lang') ? $rdata->{lang} : $sdata->{lang};
 Net::DRI::Exception::usererr_insufficient_parameters('lang') unless defined $tmp;
 $tmp=$tmp->[0] if ref $tmp eq 'ARRAY';
 Net::DRI::Exception::usererr_invalid_parameters('lang') unless Net::DRI::Util::xml_is_language($tmp);
 push @o,['lang',$tmp];

 push @d,['options',@o];

 my @s;
 push @s,map { ['objURI',$_] } @{$sdata->{objects}}; ## this part is not optional

 my @exts=@{$sdata->{extensions_selected}}; ## we start with what we have computed, and then tweak the list depending on user instructions

 ## TODO : doing all the following do change what we send during login, but does not change really what modules are enabled or not,
 ## which may later kick in during some build/parse phases !
 if (Net::DRI::Util::has_key($rdata,'only_local_extensions') && $rdata->{only_local_extensions})
 {
  $po->log_output('info','protocol',{action=>'login',direction=>'out',trid=>$mes->cltrid(),message=>'Before using only local extensions, EPP extensions selected during login: '.join(' ',@exts)});
  my $rns=$po->ns();
  @exts=sort { $a cmp $b } grep { ! /^urn:ietf:params:xml:ns:(?:epp|domain|contact|host)-1\.0$/ } map { $_->[0] } values %$rns;
  $po->log_output('info','protocol',{action=>'login',direction=>'out',trid=>$mes->cltrid(),message=>'After using only local extensions, EPP extensions selected during login: '.join(' ',@exts)});
 }
 if (Net::DRI::Util::has_key($rdata,'extensions'))
 {
  $tmp=$rdata->{extensions};
  Net::DRI::Exception::usererr_invalid_parameters('extensions') unless ref $tmp eq 'ARRAY';
  $po->log_output('info','protocol',{action=>'login',direction=>'out',trid=>$mes->cltrid(),message=>'Before user setting, EPP extensions selected during login: '.join(' ',@exts)});
  if (grep { /^[-+]/ } @$tmp) ## add or substract from current list
  {
   foreach (@$tmp)
   {
    my $ext=$_; ## make a copy because we will change it
    if ($ext=~s/^-//)
    {
     @exts=grep { $ext ne $_ } @exts;
    } else
    {
     $ext=~s/^\+//;
     push @exts,$ext unless grep { $ext eq $_ } @exts;
    }
   }
  } else ## just set the list absolutely
  {
   @exts=@$tmp;
  }
  $po->log_output('info','protocol',{action=>'login',direction=>'out',trid=>$mes->cltrid(),message=>'After user setting, EPP extensions selected during login: '.join(' ',@exts)});
 }

 if (Net::DRI::Util::has_key($rdata,'extensions_filter'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('extensions_filter') unless ref $rdata->{extensions_filter} eq 'CODE';
  $po->log_output('info','protocol',{action=>'login',direction=>'out',trid=>$mes->cltrid(),message=>'Before user filtering, EPP extensions selected during login: '.join(' ',@exts)});
  @exts=$rdata->{extensions_filter}->(@exts);
  $po->log_output('info','protocol',{action=>'login',direction=>'out',trid=>$mes->cltrid(),message=>'After user filtering, EPP extensions selected during login: '.join(' ',@exts)});
 }

 if (@exts)
 {
  push @s,['svcExtension',map {['extURI',$_]} @exts];
  $po->log_output('notice','protocol',{action=>'login',direction=>'out',trid=>$mes->cltrid(),message=>'EPP extensions selected during login: '.join(' ',@exts)});
 } else
 {
  $po->log_output('notice','protocol',{action=>'login',direction=>'out',trid=>$mes->cltrid(),message=>'No EPP extensions selected during login'});
 }

 push @d,['svcs',@s];

 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;
