## Domain Registry Interface, EPP Status
##
## Copyright (c) 2005,2007,2008,2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Core::Status;

use base qw!Net::DRI::Data::StatusList!;

use utf8;
use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::Status - EPP Status for Net::DRI

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

Copyright (c) 2005,2007,2008,2010 Patrick Mevzek <netdri@dotandco.com>.
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
 my $class=shift;
 my $self=$class->SUPER::new('epp','1.0');

 my %s=('delete'   => 'clientDeleteProhibited',
        'renew'    => 'clientRenewProhibited',
        'update'   => 'clientUpdateProhibited',
        'transfer' => 'clientTransferProhibited',
        'publish'  => 'clientHold',
       );
 $self->_register_pno(\%s);

 my $msg=shift;
 return $self unless defined $msg;
 Net::DRI::Exception::err_invalid_parameters() unless ref $msg eq 'ARRAY';
 $self->add(@$msg);
 return $self;
}

sub is_core_status
{
 return (shift=~m/^client(?:Hold|(?:Delete|Renew|Update|Transfer)Prohibited)$/);
}

sub build_xml
{
 my ($self,$name,$range)=@_;
 $range='core' unless defined($range);
 my @d;
 my $rd=$self->status_details();
 while(my ($k,$v)=each(%$rd))
 {
  next if (($range eq 'core') xor is_core_status($k));
  if ($v && ref $v && keys %$v)
  {
   my %tmp=(s => $k);
   $tmp{lang}=$v->{lang} if exists $v->{lang};
   push @d,[$name,$v->{msg} || '',\%tmp];
  } else
  {
   push @d,[$name,{s=>$k}];
  }
 }
 return @d;
}

sub is_active    { return shift->has_any('ok'); }
sub is_published { return shift->has_not(qw/clientHold serverHold inactive/); }
sub is_pending   { return shift->has_any(qw/pendingCreate pendingDelete pendingRenew pendingTransfer pendingUpdate/); }
sub is_linked    { return shift->has_any('linked'); }
sub is_grace     { return shift->has_any(qw/addPeriod autoRenewPeriod renewPeriod transferPeriod redemptionPeriod pendingRestore pendingDelete/); } ## defined in RFC3915 §3.1

sub can_delete   { my $self=shift; return (!$self->is_linked() && !$self->is_pending() && $self->has_not(qw/clientDeleteProhibited serverDeleteProhibited/))? 1 : 0; }
sub can_renew    { my $self=shift; return (!$self->is_pending() && $self->has_not(qw/clientRenewProhibited serverRenewProhibited/))? 1 : 0; }
sub can_update   { my $self=shift; return (!$self->is_pending() && $self->has_not(qw/clientUpdateProhibited serverUpdateProhibited/))? 1 : 0; }
sub can_transfer { my $self=shift; return (!$self->is_pending() && $self->has_not(qw/clientTransferProhibited serverTransferProhibited/))? 1 : 0; }

####################################################################################################
1;
