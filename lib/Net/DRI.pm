## Domain Registry Interface, Main entry point
##
## Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI;

use strict;
use warnings;

use Net::DRI::Cache;
use Net::DRI::Registry;
use Net::DRI::Util;
use Net::DRI::Exception;

use base qw(Class::Accessor::Chained::Fast Net::DRI::BaseClass);
__PACKAGE__->mk_ro_accessors(qw/trid_factory logging cache/);

our $AUTOLOAD;
our $VERSION='0.96_05';
our $RUNNING_POE=(exists($INC{'POE.pm'}))? $POE::Kernel::poe_kernel : undef;

=pod

=head1 NAME

Net::DRI - Interface to Domain Name Registries/Registrars/Resellers

=head1 VERSION

This documentation refers to Net::DRI version 0.96_05

=head1 SYNOPSIS

	use Net::DRI;
	my $dri=Net::DRI->new({ cache_ttl => 10, trid_factory => ..., logging => .... });

	... various operations ...

	$dri->end();

=head1 DESCRIPTION

Net::DRI is a Perl library to access services offered by domain name
providers, such as registries or registrars. DRI stands for
Domain Registration Interface and it aims to be
for domain name registries/registrars/resellers what DBI is for databases:
an abstraction over multiple providers, with multiple policies, transports
and protocols all used through a uniform API.

It is an object-oriented framework implementing RRP (RFC 2832/3632),
EPP (core EPP in RFC 5730/5731/5732/5733/5734 aka STD69, extensions in
RFC 3915/4114/4310/5076 and various extensions of ccTLDs/gTLDs
- currently more than 60 TLDs are directly supported with extensions),
RRI (.DE registration protocol), Whois, DAS (Domain Availability Service used by .BE, .EU, .AU, .NL),
IRIS (RFC3981) DCHK (RFC5144) over LWZ (RFC4993) for .DE currently and XCP (RFC4992),
.FR/.RE email and webservices interface, and resellers interface of some registrars
(Gandi, OpenSRS, etc.).
It has transports for connecting with UDP/TCP/TLS, HTTP/HTTPS, 
Web Services (XML-RPC and SOAP with/without WSDL),
or SMTP-based registries/registrars.

It is not limited to handling of domain names, it can be easily extended.
For example, it supports ENUM registrations and validations, or DNSSEC provisioning.

A shell is included for easy prototyping and debugging, see L<Net::DRI::Shell>.
Caching and logging features are also included by default.

Please see the included README file for full details.

=head1 EXAMPLES

Please see the C<eg/> subdirectory of the distribution, it contains various
examples. Please also see all unit tests under C<t/>, they show all parts of the API.

=head1 SUBROUTINES/METHODS

After having used Net::DRI (which is the only module you should need to C<use> from
this distribution), you create an object as instance of this class,
and every operation will be carried through it.

=head2 trid_factory()

This is an accessor to the trid factory (code reference) used to generate client
transaction identificators, that are useful for logging and asynchronous operations.

During the C<new()> call, a C<trid_factory()> is initialized to a default safe value
(being Net::DRI::Util::create_trid_1).

You need to call this method only if you wish to use another function to generate transaction identificators.

All other objects (registry profiles and transports) 
created after that will inherit this value. If you call again C<trid_factory()>
the change will only apply to new objects (registry profiles and transports) created after the change,
it will not apply to already existing objects (registry profiles and transports).

=head2 logging()

This is an accessor to the underlying Logging object. During the C<new()> call you can
provide the object, or just a string ("null", "stderr", "files" or "syslog" which are the
current logging modules available in Net::DRI), or a reference to an array
with the first parameter a string (same as previously) and the second parameter a reference to
an hash with data needed by the logging class used (see for example L<Net::DRI::Logging::Files>).

If you want to log the application data (what is exchanged with remote server, such as EPP XML streams),
you need to use logging level of 'notice', or higher.

=head2 cache()

This is an accessor to the underlying Cache object. See L<Net::DRI::Cache>.
This object has a C<ttl()> method to access and change the current time to live
for cached data.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

L<http://www.dotandco.com/services/software/Net-DRI/>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>
and various contributors (see Changes file and web page above)

=head1 COPYRIGHT

Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my ($class,$rh)=@_;

 my $self={ cache            => Net::DRI::Cache->new(Net::DRI::Util::has_key($rh,'cache_ttl') ? $rh->{cache_ttl} : 0),
            current_registry => undef, ## registry name (key of following hash)
            registries       => {}, ## registry name => Net::DRI::Registry object
            tlds             => {}, ## tld => [ registries name ]
            time_created     => time(),
            trid_factory     => (Net::DRI::Util::has_key($rh,'trid_factory') && ref $rh->{trid_factory} eq 'CODE')? $rh->{trid_factory} : \&Net::DRI::Util::create_trid_1,
          };

 my ($logname,@logdata);
 if (Net::DRI::Util::has_key($rh,'logging'))
 {
  ($logname,@logdata)=ref $rh->{logging} eq 'ARRAY' ? @{$rh->{logging}} : ($rh->{logging});
 } else
 {
  $logname='null';
 }
 if ($logname !~ s/^\+//) { $logname='Net::DRI::Logging::'.ucfirst($logname); }
 Net::DRI::Util::load_module($logname,'DRI');
 $self->{logging}=$logname->new(@logdata);

 bless($self,$class);
 $self->logging()->setup_channel(__PACKAGE__,'core');
 $self->log_output('notice','core','Successfully created Net::DRI object with logging='.$logname);
 return $self;
}

sub add_current_registry
{
 my ($self,@p)=@_;
 $self->add_registry(@p);
 $self->target($self->{last_registry});
 return $self;
}

sub add_registry
{
 my ($self,$reg,@data)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('add_registry needs a registry name') unless Net::DRI::Util::all_valid($reg);
 $reg='Net::DRI::DRD::'.$reg unless $reg=~m/^\+/;
 Net::DRI::Util::load_module($reg,'DRI');

 my $drd=$reg->new(@data);
 Net::DRI::Exception->die(1,'DRI',9,'Failed to initialize registry '.$reg) unless ($drd && ref $drd);

 Net::DRI::Exception::method_not_implemented('name',$reg) unless $drd->can('name');
 my $regname=$drd->name();
 Net::DRI::Exception->die(1,'DRI',10,'No dot allowed in registry name: '.$regname) unless index($regname,'.') == -1;
 Net::DRI::Exception->die(1,'DRI',11,'New registry name already in use') if exists $self->{registries}->{$regname};

 my $ndr=Net::DRI::Registry->new($regname,$drd,$self->{cache},$self->{trid_factory},$self->{logging});
 Net::DRI::Exception::method_not_implemented('tlds',$reg) unless $drd->can('tlds');
 foreach my $tld ($drd->tlds())
 {
  $tld=lc($tld);
  $self->{tlds}->{$tld}=[] unless exists $self->{tlds}->{$tld};
  push @{$self->{tlds}->{$tld}},$regname;
 }

 $self->log_output('notice','core','Successfully added registry "'.$regname.'"');
 $self->{registries}->{$regname}=$ndr;
 $self->{last_registry}=$regname;
 return $self;
}

sub del_registry
{
 my ($self,$name)=@_;
 if (defined $name)
 {
  err_registry_name_does_not_exist($name) unless exists $self->{registries}->{$name};
 } else
 {
  err_no_current_registry() unless defined $self->{current_registry};
  $name=$self->{current_registry};
 }
 $self->{registries}->{$name}->end();
 delete($self->{registries}->{$name});
 $self->{current_registry}=undef if $self->{current_registry} eq $name;
 $self->log_output('notice','core','Successfully deleted registry "'.$name.'"');
 return $self;
}

####################################################################################################

sub err_no_current_registry          { Net::DRI::Exception->die(0,'DRI',1,'No current registry available'); } ## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)
sub err_registry_name_does_not_exist { Net::DRI::Exception->die(0,'DRI',2,'Registry name '.$_[0].' does not exist'); } ## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)

####################################################################################################
## Accessor functions

sub available_registries { my ($self)=@_; my @r=sort { $a cmp $b } keys %{$self->{registries}}; return @r; }
sub available_registries_profiles
{
 my ($self,$full)=@_;
 my %r;
 foreach my $reg (keys(%{$self->{registries}}))
 {
  $r{$reg}=[ $self->{registries}->{$reg}->available_profiles($full) ];
 }
 return \%r;
}
sub registry_name { return shift->{current_registry}; }

sub registry
{
 my ($self)=@_;
 my $regname=$self->registry_name();
 err_no_current_registry()                  unless (defined($regname) && $regname);
 err_registry_name_does_not_exist($regname) unless (exists($self->{registries}->{$regname}));
 my $ndr=$self->{registries}->{$regname};
 return wantarray? ($regname,$ndr) : $ndr;
}

sub tld2reg
{
 my ($self,$tld)=@_;
 return unless defined($tld) && $tld;
 $tld=lc($tld);
 $tld=$1 if ($tld=~m/\.([a-z0-9]+)$/);
 return unless exists($self->{tlds}->{$tld});
 my @t=@{$self->{tlds}->{$tld}};
 return @t;
}

sub installed_registries
{
 return qw/AdamsNames AERO AFNIC AG ARNES ASIA AT AU BE BIZ BookMyName BR BZ CAT CentralNic CIRA CoCCA COOP COZA CZ DENIC EURid Gandi GL HN ICMRegistry ID IENUMAT IM INFO IRegistry ISPAPI IT LC LU ME MN MOBI NAME Nominet NO NU OpenSRS ORG OVH PL PRO PT SC SE SIDN SO SWITCH TCI Telnic TRAVEL UPU US VC VNDS WS/;
}

####################################################################################################

sub target
{
 my ($self,$driver,$profile)=@_;

 ## Try to convert if given a domain name or a tld instead of a driver's name
 if (defined $driver && ! exists $self->{registries}->{$driver})
 {
  my @t=$self->tld2reg($driver);
  Net::DRI::Exception->die(0,'DRI',7,'Registry not found for domain name/TLD '.$driver) unless (@t==1);
  $driver=$t[0];
 }

 $driver=$self->registry_name() unless defined $driver;
 err_registry_name_does_not_exist($driver) unless defined $driver && $driver;

 if (defined $profile)
 {
  $self->{registries}->{$driver}->target($profile);
 }

 $self->{current_registry}=$driver;
 return $self;
}

####################################################################################################
## The meat of everything
## See Cookbook, page 468
sub AUTOLOAD
{
 my ($self,@args)=@_;
 my $attr=$AUTOLOAD;
 $attr=~s/.*:://;
 return unless $attr=~m/[^A-Z]/; ## skip DESTROY and all-cap methods

 my ($name,$ndr)=$self->registry();
 Net::DRI::Exception::method_not_implemented($attr,$ndr) unless ref $ndr && $ndr->can($attr);
 $self->log_output('debug','core','Calling '.$attr.' from Net::DRI');
 return $ndr->$attr(@args); ## is goto beter here ?
}

sub end
{
 my $self=shift;
 while(my ($name,$v)=each(%{$self->{registries}}))
 {
  $v->end() if (ref($v) && $v->can('end'));
  $self->log_output('notice','core','Successfully ended registry "'.$name.'"');
  $v={};
 }
 $self->{tlds}={};
 $self->{registries}={};
 $self->{current_registry}=undef;
 if (defined $self->{logging})
 {
  $self->log_output('notice','core','Successfully ended Net::DRI object');
  $self->{logging}=undef;
 }

 return 1; ## this makes it easy to test if everything before was ok or not, if we are inside an eval {} and $dri->end() is the last operation inside the eval block
}

sub DESTROY { my $self=shift; return $self->end(); }

####################################################################################################

package Net::DRI::TrapExceptions; ## no critic (Modules::ProhibitMultiplePackages)

use base qw/Net::DRI/;

our $AUTOLOAD;

## Some methods may die in Net::DRI, we specifically trap them
sub add_registry { my ($self,@p)=@_; my $r; my $ok=eval { $r=$self->SUPER::add_registry(@p); 1; }; return $r if $ok; die(ref $@ ? $@->as_string() : $@); }
sub del_registry { my ($self,@p)=@_; my $r; my $ok=eval { $r=$self->SUPER::del_registry(@p); 1; }; return $r if $ok; die(ref $@ ? $@->as_string() : $@); }
sub registry     { my ($self,@p)=@_; my @r; my $ok=eval { @r=$self->SUPER::registry(@p); 1; }; if ($ok) { return wantarray ? @r : $r[0]; } die(ref $@ ? $@->as_string() : $@); }
sub target       { my ($self,@p)=@_; my $r; my $ok=eval { $r=$self->SUPER::target(@p); 1; }; return $r if $ok; die(ref $@ ? $@->as_string() : $@); }
sub end          { my ($self,@p)=@_; my $r; my $ok=eval { $r=$self->SUPER::end(@p); 1; }; return $r if $ok; die(ref $@ ? $@->as_string() : $@); }

sub AUTOLOAD
{
 my $self=shift;
 my @r;
 $Net::DRI::AUTOLOAD=$AUTOLOAD;
 my $ok=eval { @r=$self->SUPER::AUTOLOAD(@_); 1; };
 if (! $ok)
 {
  my $err=$@;
  die(ref $err ? $err->as_string() : $err);
 }
 return wantarray ? @r : $r[0];
}

####################################################################################################
1;
