## Domain Registry Interface, local global cache
##
## Copyright (c) 2005,2008,2009,2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Cache;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_accessors(qw/ttl/);

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Cache - Local cache for Net::DRI

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

Copyright (c) 2005,2008,2009,2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($c,$ttl)=@_;

 my $self={
           ttl  => $ttl, ## if negative, never use cache
           data => {},
          };

 bless($self,$c);
 return $self;
}

sub set
{
 my ($self,$regname,$type,$key,$data,$ttl)=@_;
 Net::DRI::Exception::err_insufficient_parameters() unless Net::DRI::Util::all_valid($regname,$type,$key);

 my $now=Net::DRI::Util::microtime();
 $ttl=$self->{ttl} unless defined($ttl);
 my $until=($ttl==0)? 0 : $now+1000000*$ttl;
 my %c=(_on    => $now,
        _from  => $regname,
        _until => $until,
       );

 if ($data && (ref $data eq 'HASH'))
 {
  while(my ($k,$v)=each(%$data))
  {
   $c{$k}=$v;
  }
 }

 if ($self->{ttl} >= 0) ## we really store something
 {
  $self->{data}->{$type}={} unless exists $self->{data}->{$type};
 ## We store only the last version of a given key, so start from scratch
  $self->{data}->{$type}->{$key}=\%c;
 }

 return \%c;
}

sub set_result_from_cache
{
 my ($self,$type,$key)=@_;
 Net::DRI::Exception::err_insufficient_parameters() unless Net::DRI::Util::all_valid($type,$key);
 return unless exists $self->{data}->{$type};
 $self->{data}->{$type}->{$key}->{result_from_cache}=1;
 return;
}

sub get
{
 my ($self,$type,$key,$data,$from)=@_;

 return if ($self->{ttl} < 0);
 Net::DRI::Exception::err_insufficient_parameters() unless Net::DRI::Util::all_valid($type,$key);
 ($type,$key)=Net::DRI::Util::normalize_name($type,$key);
 return unless exists $self->{data}->{$type};
 return unless exists $self->{data}->{$type}->{$key};

 my $c=$self->{data}->{$type}->{$key};

 if ($c->{_until} > 0 && (Net::DRI::Util::microtime() > $c->{_until}))
 {
  delete $self->{data}->{$type}->{$key};
  return;
 }

 return if (defined $from && ($c->{_from} ne $from));

 if (defined $data)
 {
  return $c->{$data} if exists $c->{$data};
 } else
 {
  return $c;
 }

 return;
}

sub delete_expired
{
 my $self=shift;
 my $now=Net::DRI::Util::microtime();
 my $c=$self->{data};
 while(my ($type,$c1)=each(%$c))
 {
  while(my ($key,$c2)=each(%{$c1}))
  {
   delete $c->{$type}->{$key} if ($c2->{_until} > 0 && ($now > $c2->{_until}));
  }
 }
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my $self=shift;
 $self->{data}={};
 return;
}

####################################################################################################
1;
