## Domain Registry Interface, NameAction Domain commands
##
## Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::NameAction::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use URI;

=pod

=head1 NAME

Net::DRI::Protocol::NameAction::Domain - NameAction Domain commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>paulo.s.castanheira@gmail.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 AUTHOR

Paulo Castanheira, E<lt>paulo.s.castanheira@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>.
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
          check => [\&check, \&parse ],
          create => [ \&create, \&parse ],
          renew => [ \&renew, \&parse ],
          update => [\&update, \&parse], # Modify
          transfer_request => [ \&transfer_request, \&parse ],
          trade_request => [ \&trade_request, \&parse ],
          delete => [ \&delete, \&parse ],
          info  => [\&info,  \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

sub check
{
 my ($nma,$domain,$rd)=@_;
 my $msg=$nma->message();
 my @attrs;
 push @attrs,_build_domain($domain);
 my $cmd = _build_command($msg,'check',\@attrs);
 $msg->command($cmd);
 return;
}

sub parse
{
 my ($nma,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$nma->message();
 return unless $mes->is_success();
 
#use Data::Dumper;print Dumper( $mes);
 $rinfo->{domain}->{$oname}->{action}=$oaction;
 $rinfo->{domain}->{$oname}->{exist}=$oaction eq 'check'?($mes->response_code() ? 0 : 1):1; 
 return;
}



sub create
{
 my ($nma,$domain,$rd)=@_;
 my @attrs;
 push @attrs,_build_domain($domain);
 
 Net::DRI::Exception::usererr_insufficient_parameters('duration is mandatory') unless Net::DRI::Util::has_duration($rd);
 push @attrs, _build_duration($rd->{duration}->years());
 
 Net::DRI::Exception::usererr_insufficient_parameters('contacts are mandatory') unless Net::DRI::Util::has_contact($rd);
 foreach my $type (qw/registrant admin tech/) 
 {
  my $co=$rd->{contact}->get($type);
  Net::DRI::Exception::usererr_insufficient_parameters($type . ' contact is mandatory') unless Net::DRI::Util::isa_contact($co);
  push @attrs,_build_contact($co,$type);
 }
 
 Net::DRI::Exception::usererr_insufficient_parameters('at least 2 nameservers are mandatory') unless Net::DRI::Util::isa_hosts($rd->{ns}) && $rd->{ns}->count()>=2; # Name servers are optional; if present must be >=2
 push @attrs, _build_all_ns($rd->{ns});

 if ( exists $rd->{info_pl} ) {
  push @attrs,_build_info_pl( $rd->{info_pl} );
 }
 
 my $msg=$nma->message();
 my $cmd = _build_command($msg,'create',\@attrs);
 $msg->command($cmd);
 return;
}

sub renew
{
 my ($nma,$domain,$rd)=@_;
 my @attrs;
 
 push @attrs,_build_domain($domain);
 
 Net::DRI::Exception::usererr_insufficient_parameters('duration is mandatory') unless Net::DRI::Util::has_duration($rd);
 push @attrs, _build_duration($rd->{duration}->years());
 
 my $msg=$nma->message();
 my $cmd = _build_command($msg,'renew',\@attrs);
 $msg->command($cmd);
 return;
}

sub update
{
 my ($nma,$domain,$rd)=@_;
 my @attrs;
 
 push @attrs,_build_domain($domain);
 
 Net::DRI::Exception::usererr_invalid_parameters($rd.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($rd);
 my $cs=$rd->set('contact');
 Net::DRI::Exception::usererr_invalid_parameters('contact changes for set must be a Net::DRI::Data::ContactSet') unless defined($cs) && Net::DRI::Util::isa_contactset($cs);
 
 foreach my $type (qw/registrant admin tech/) 
 {
  my $co=$cs->get($type);
  next if !$co;
  Net::DRI::Exception::usererr_insufficient_parameters($co.' is not a '.$type.' contact') unless Net::DRI::Util::isa_contact($co);
  push @attrs,_build_contact($co,$type);
 }
  
 if ( my $ns=$rd->set('ns') ) 
 {
  Net::DRI::Exception::usererr_invalid_parameters('ns changes for set must be a Net::DRI::Data::Hosts object') unless Net::DRI::Util::isa_hosts($ns);
  push @attrs, _build_all_ns($ns);
 }

 my $msg=$nma->message();
 my $cmd = _build_command($msg,'modify',\@attrs);
 $msg->command($cmd);
 return;
}

sub info
{
 my ($nma,$domain,$rd)=@_;
 my @attrs;
 
 push @attrs,_build_domain($domain);
 
 my $msg=$nma->message();
 my $cmd = _build_command($msg,'info',\@attrs);
 $msg->command($cmd);
 return;
}

sub info_parse 
{
 my ($nma,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$nma->message();
 return unless $mes->is_success();

 $rinfo->{domain}->{$oname}->{action}=$oaction;
 $rinfo->{domain}->{$oname}->{exist}=$mes->response_code() == 1000 ? 1 : 0;
 
 my $ra = $mes->response_attributes();
 my $cts=$ra->{contacts};
 if (defined($cts) && ref($cts) && keys(%$cts))
 {
  my $cs=$nma->create_local_object('contactset');
  foreach my $type (keys %$cts) {
   my $c=$nma->create_local_object('contact');
   $c->name($cts->{$type});
   $cs->add($c,$type);
  }
  $rinfo->{domain}->{$oname}->{contact}=$cs;
 }
 
 my $ns=$ra->{hosts};
 if (defined($ns) && ref($ns) && @$ns)
 {
  my $nso=$nma->create_local_object('hosts');
  foreach my $h (@$ns)
  {
   $nso->add($h->[0],[$h->[1]]);
  }
  $rinfo->{domain}->{$oname}->{ns}=$nso;
 }
 
 $rinfo->{domain}->{$oname}->{expirydate}=$ra->{expiry_date};
}

sub delete
{
 my ($nma,$domain,$rd)=@_;
 my @attrs;
 
 push @attrs,_build_domain($domain);
 
 my $msg=$nma->message();
 my $cmd = _build_command($msg,'delete',\@attrs);
 $msg->command($cmd);
 return;
}

sub transfer_request
{
 my ($nma,$domain,$rd)=@_;
 my @attrs;
 
 push @attrs,_build_type('management');
 push @attrs,_build_domain($domain);
 
 if (Net::DRI::Util::has_auth($rd)) {
  Net::DRI::Exception::usererr_insufficient_parameters('registrant contact is mandatory') unless Net::DRI::Util::has_key($rd->{auth},'pw');
  push @attrs, _build_auth($rd->{auth}{pw});
 }
 
 my $msg=$nma->message();
 my $cmd = _build_command($msg,'transfer',\@attrs);
 $msg->command($cmd);
 return;
}


sub trade_request
{
 my ($nma,$domain,$rd)=@_;
 my @attrs;
 
 push @attrs,_build_type('owner');
 push @attrs,_build_domain($domain);

 Net::DRI::Exception::usererr_insufficient_parameters('registrant contact is mandatory') unless Net::DRI::Util::has_contact($rd) && Net::DRI::Util::isa_contact($rd->{contact}->get('registrant'));
 
 foreach my $type (qw/registrant admin tech/) 
 {
  my $co=$rd->{contact}->get($type);
  next if !$co;
  Net::DRI::Exception::usererr_insufficient_parameters($co.' is not a '.$type.' contact') unless Net::DRI::Util::isa_contact($co);
  push @attrs,_build_contact($co,$type);
 }
 
  if ( Net::DRI::Util::has_ns($rd) ) 
 {
  push @attrs, _build_all_ns($rd->{ns});
 }
 
 my $msg=$nma->message();
 my $cmd = _build_command($msg,'transfer',\@attrs);
 $msg->command($cmd);
 return;
}

sub _build_domain 
{
 my ($domain) = @_;
 Net::DRI::Exception->die(1,'NameAction/Domain',2,'Domain name needed') unless $domain; #FIXME check is domain
 
 my ($sdl, $tld) = ($domain =~ /^([^\.]+)\.(.+)$/);
 return ( 'SLD'      => $sdl,
          'TLD'      => $tld
        );
}

sub _build_command 
{
  my ($mes,$action,$attrs) = @_;

  my @fragments = ( 'Command'  => ucfirst($action));
  push @fragments, @$attrs if defined $attrs && ref $attrs eq 'ARRAY';
  return \@fragments
}



sub _build_contact {
 my ($contact,$type) = @_;
 
 $contact->validate();
 
 my $add_ref = $contact->street();
 Net::DRI::Exception::usererr_insufficient_parameters('at least 1 line of address is needed') unless $add_ref && ref($add_ref) eq 'ARRAY' && @$add_ref && $add_ref->[0];
 
 my @fragments = ( 
  ucfirst($type).'Name'          => scalar($contact->name()),
  ucfirst($type).'Organization'  => scalar($contact->org()),
  ucfirst($type).'Address'       => join(' ', grep {$_} @$add_ref),
  ucfirst($type).'City'          => scalar($contact->city()),
  ucfirst($type).'CountryCode'   => scalar($contact->cc()),
  ucfirst($type).'PostalCode'    => scalar($contact->pc()),
  ucfirst($type).'Phone'         => $contact->voice(),
  ucfirst($type).'Email'         => $contact->email(),
 );

 return @fragments;
}

sub _build_all_ns
{
 my ($ns)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('max 6 nameservers exceeded') unless $ns->count()<=6;

 my (@hostnames,@ipv4);
 for (my $i = 1; $i <= $ns->count(); $i++) { # Net:DRI name server list starts at 1.
  my ($hostname, $ipv4) = $ns->get_details($i);
  
  Net::DRI::Exception::usererr_insufficient_parameters("invalid host $1 hostname") unless Net::DRI::Util::is_hostname($hostname);
  Net::DRI::Exception::usererr_insufficient_parameters("invalid host $1 ipv4") unless Net::DRI::Util::is_ipv4($ipv4->[0]);
  push @hostnames, ('NS'.$i => $hostname);
  
  push @ipv4, ('IP'.$i => $ipv4->[0]) ;
 }

 return @hostnames, @ipv4;
}

sub _build_duration
{
 my ($years) = @_;
  return ( Year => $years);
}

sub _build_info_pl 
{
  my ($info_pl) = @_;
  return ( InfoPL => $info_pl );
}


sub _build_auth
{
	my ($auth) = @_;
	return ( AuthCode => $auth );
}

sub _build_type
{
 my ($type) = @_;
 Net::DRI::Exception::usererr_insufficient_parameters('type must be owner/management') unless grep {/^$type$/} qw/owner management/;
 return (Type => ucfirst($type));
}

####################################################################################################
1;
