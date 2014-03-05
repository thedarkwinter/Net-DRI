## Domain Registry Interface, .XN--P1AI (РФ)/SU/RU policies
##
## Copyright (c) 2010-2011 Dmitry Belyavsky <beldmit@gmail.com>
##               2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::TCI;

use utf8;
use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use DateTime::Duration;

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); }
sub name     { return 'TCI'; }
sub tlds     { return ('xn--p1ai', 'su', 'ru'); }
sub object_types { return ('domain','contact','host'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::HTTP',{protocol_connection=>'Net::DRI::Protocol::EPP::Extensions::HTTP'},'Net::DRI::Protocol::EPP::Extensions::TCI',{}) if $type eq 'epp'; ## EPP is over HTTPS here
 return;
}

sub verify_duration_renew
{
 my ($self,$ndr,$duration,$domain,$curexp)=@_;
 ($duration,$domain,$curexp)=($ndr,$duration,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my @d=$self->periods();
 if (defined($duration) && @d)
 {
  my $ok=0;
  foreach my $d (@d)
  {
   next unless (0==Net::DRI::Util::compare_durations($d,$duration));
   $ok=1;
   last;
  }
  return 1 unless $ok;

  if (defined $curexp && Net::DRI::Util::is_class($curexp,'DateTime'))
  {
   my $maxdelta=$d[-1]+DateTime::Duration->new(days => 61);
   my $newexp=$curexp+$duration; ## New expiration
   my $now=DateTime->now(time_zone => $curexp->time_zone()->name());
   my $cmp=DateTime->compare($newexp,$now+$maxdelta);
   return 2 unless ($cmp == -1); ## we must have : curexp+duration < now + maxdelta
  }
 }

 return 0; ## everything ok
}

sub registrar_info
{
 my ($self,$ndr,$reg_id)=@_;
 my $rc=$ndr->process('registrar','info', [$reg_id]);
 return $rc;
}

sub registrar_update
{
 my ($self,$ndr,$reg_id, $toc)=@_;
 my $rc=$ndr->process('registrar','update', [$reg_id, $toc]);
 return $rc;
}

####################################################################################################
1;

=pod

=head1 NAME

Net::DRI::DRD::TCI - TCI (.SU/.RU/.XN--P1AI) Registry Driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Dmitry Belyavsky, E<lt>beldmit@gmail.comE<gt>
Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010-2011 Dmitry Belyavsky <beldmit@gmail.com>
Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
