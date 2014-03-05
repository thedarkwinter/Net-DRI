## Domain Registry Interface, Implements a list of host (names+ip) with order preserved
##
## Copyright (c) 2005-2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Hosts;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast);

__PACKAGE__->mk_accessors(qw(name loid));

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Data::Hosts - Handle ordered list of nameservers (name, IPv4 addresses, IPv6 addresses) for Net::DRI

=head1 SYNOPSIS

 use Net::DRI::Data::Hosts;

 my $dh=Net::DRI::Data::Hosts->new();
 $dh->add('ns.example.foo',['1.2.3.4','1.2.3.5']);
 $dh->add('ns2.example.foo',['10.1.1.1']); ## Third element can be an array ref of IPv6 addresses
 ## ->add() returns the object itself, and thus can be chained

 ## Number of nameservers
 print $dh->count(); ## Gives 2

 ## List of names, either all without arguments, or the amount given by the argument
 my @a=$dh->get_names(2); ## Gives ('ns.example.foo','ns2.example.foo')

 ## Details for the nth nameserver (the list starts at 1 !)
 my @d=$dh->get_details(2); ## Gives ('ns2.example.foo',['10.1.1.1'])

 ## Details by name is possible also
 my @d=$dh->get_details('ns2.example.foo');

=head1 DESCRIPTION

Order of nameservers is preserved. Order of IP addresses is preserved, but no duplicate IP is allowed.

If you try to add a nameserver that is already in the list, the IP
addresses provided will be added to the existing IP addresses (without duplicates)

Hostnames are verified before being used with Net::DRI::Util::is_hostname().

IP addresses are verified with Net::DRI::Util::is_ipv4() and Net::DRI::Util::is_ipv6().

=head1 METHODS

=head2 new(...)

creates a new instance ; if parameters are given, add() is called with them all at once

=head2 new_set(...)

creates a new instance ; if parameters are given, add() is called once for each parameter

=head2 clear()

clears the current list of nameservers

=head2 set(...)

clears the current list of nameservers, and call add() once for each parameter passed

=head2 add(name,[ipv4],[ipv6])

adds a new nameserver with the given name and lists of IPv4 and IPv6 addresses

=head2 name()

name of this object (for example for registries having the notion of host groups) ;
this has nothing to do with the name(s) of the nameservers inside this object

=head2 loid()

local id of this object

=head2 get_names(limit)

returns a list of nameservers' names included in this object ; if limit is provided
we return only the number of names asked

=head2 count()

returns the number of nameservers currently stored in this object

=head2 is_empty()

returns 0 if this object has nameservers, 1 otherwise

=head2 get_details(pos_or_name)

given an integer (position in the list, we start to count at 1) or a name,
we return all details as a 3 element array in list context or only the first
element (the name) in scalar context for the nameserver stored at
the given position or with the given name ; returns undef if nothing found
at the position/with the name given.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005-2009,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my ($class,@args)=@_;
 my $self={ list => [] }; ## list=>[['',[ipv4],[ipv6],{}]+],options=>{}
 bless $self,$class;
 $self->add(@args) if @args;
 return $self;
}

sub new_set
{
 my ($class,@args)=@_;
 my $s=$class->new();
 foreach (@args) { $s->add($_); }
 return $s;
}

sub clear
{
 my $s=shift;
 $s->{list}=[];
 return;
}

sub set
{
 my ($s,@args)=@_;
 $s->{list}=[];
 foreach (@args) { $s->add($_); }
 return $s;
}

sub add
{
 my ($self,$in,$e1,$e2,$ipall,$rextra)=@_;
 ($ipall,$rextra)=(undef,$ipall)  if (defined($ipall) && ref($ipall));
 return unless (defined($in) && $in);

 if (ref $in eq 'ARRAY')
 {
  return $self->add(@$in);
 }

 if (defined $e2 && $e2)
 {
  $self->_push($in,$e1,$e2,$ipall,$rextra);
  return $self;
 }

 if (defined $e1 && $e1)
 {
  $self->_push($in,_separate_ips($e1,$ipall),$ipall,$rextra);
  return $self;
 }

 $self->_push($in,[],[],1,$rextra);
 return $self;
}

sub _separate_ips
{
 my (@args)=@_;
 my (@ip4,@ip6);
 my $ipall=pop @args;
 $ipall=0 unless defined $ipall;
 foreach my $ip (map {ref($_)? @{$_} : $_} @args)
 {
  ## We keep only the public ips
  push @ip4,$ip if Net::DRI::Util::is_ipv4($ip,1-$ipall);
  push @ip6,$ip if Net::DRI::Util::is_ipv6($ip,1-$ipall);
 }
 return (\@ip4,\@ip6);
}

sub _push
{
 my ($self,$name,$ipv4,$ipv6,$ipall,$rextra)=@_;
 $ipall=0 unless defined $ipall;
 chop($name) if (defined $name && $name && $name=~m/\.$/);
 return unless Net::DRI::Util::is_hostname($name);
 $name=lc($name); ## by default, hostnames are case insensitive

 ## We keep only the public ips
 my @ipv4=grep { Net::DRI::Util::is_ipv4($_,1-$ipall) } ref $ipv4 ? @$ipv4 : ($ipv4);
 my @ipv6=grep { Net::DRI::Util::is_ipv6($_,1-$ipall) } ref $ipv6 ? @$ipv6 : ($ipv6);

 if ($self->count() && defined $self->get_details($name)) ## name already here, we append IP
 {
  foreach my $el (@{$self->{list}})
  {
   next unless ($el->[0] eq $name);
   unshift @ipv4,@{$el->[1]};
   unshift @ipv6,@{$el->[2]};
   $el->[1]=_remove_dups_ip(\@ipv4);
   $el->[2]=_remove_dups_ip(\@ipv6);
   if (defined $el->[3] || defined $rextra)
   {
    $el->[3]={ defined $el->[3] ? %{$el->[3]} : (), (defined $rextra && ref $rextra eq 'HASH')? %$rextra : () };
   }
   last;
  }
 } else
 {
  push @{$self->{list}},[$name,_remove_dups_ip(\@ipv4),_remove_dups_ip(\@ipv6),$rextra];
 }
 return;
}

sub _remove_dups_ip
{
 my $ip=shift;
 my @r;
 my %tmp;
 @r=ref($ip)? grep { ! $tmp{$_}++ } @$ip : ($ip) if defined $ip;
 return \@r;
}

## Give back an array of all hostnames, or up to a limit if provided
sub get_names
{
 my ($self,$limit)=@_;
 return unless (defined $self && ref $self);
 my $c=$self->count();
 $c=$limit if ($limit && ($limit <= $c));
 my @r;
 foreach (0..($c-1))
 {
  push @r,$self->{list}->[$_]->[0];
 }
 return @r;
}

sub count
{
 my $self=shift;
 return unless (defined $self && ref $self);
 return scalar(@{$self->{list}});
}

sub is_empty
{
 my $self=shift;
 my $c=$self->count();
 return (defined $c && ($c > 0))? 0 : 1;
}

sub get_details
{
 my ($self,$pos)=@_;
 return unless (defined $self && ref $self && defined $pos && $pos);
 my $c=$self->count();

 if ($pos=~m/^\d+$/)
 {
  return unless ($c && ($pos <= $c));
  my $el=$self->{list}->[$pos-1];
  return wantarray()? @$el : $el->[0];
 } else
 {
  $pos=lc($pos);
  foreach my $el (@{$self->{list}})
  {
   next unless ($el->[0] eq $pos);
   return wantarray()? @$el : $el->[0];
  }
  return;
 }
}

# Do not use this method for anything else than debugging. The output format is not guaranteed to remain stable
sub as_string
{
 my ($self)=shift;
 my @s;
 foreach my $el (@{$self->{list}})
 {
  my $s=$el->[0];
  my $ips=join(',',@{$el->[1]},@{$el->[2]});
  $s.=' ['.$ips.']' if $ips;
  $s.=' {'.join(' ',map { $_.'='.$el->[3]->{$_} } keys(%{$el->[3]})).'}' if (defined $el->[3] && %{$el->[3]});
  push @s,$s;
 }
 return join(' ',@s);
}

####################################################################################################
1;
