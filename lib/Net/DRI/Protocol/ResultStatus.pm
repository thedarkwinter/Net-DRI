## Domain Registry Interface, Encapsulating result status, standardized on EPP codes
##
## Copyright (c) 2005,2006,2008-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::ResultStatus;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_ro_accessors(qw(native_code code message lang next count));

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::ResultStatus - Encapsulate Details of an Operation Result (with Standardization on EPP) for Net::DRI

=head1 DESCRIPTION

An object of this class represents all details of an operation result as given back from the registry,
with standardization on EPP as much as possible, for error codes and list of fields available.

One object may contain one or more operation results. The object is in fact a list, starting with the
chronologically first/top operation result, and then using the C<next()> call progressing toward other
operation results, if available (each call to next gives an object of this class). The last operation result
can be retrieved with C<last()>.

When an operation is done, data retrieved from the registry is also stored inside the ResultStatus object
(besides being available through C<< $dri->get_info() >>). It can be queried using the C<get_data()> and
C<get_data_collection()> methods as explained below. The data is stored as a ref hash with 3 levels:
the first keys have as values a reference to another hash where keys are again associated with values
being a reference to another hash where the content (keys and values) depends on the registry, the operation
attempted, and the result.

Some data will always be there: a "session" first key, with a "exchange" subkey, will have a reference to
an hash with the following keys:

=over

=item duration_seconds

the duration of the exchange with registry, in a floating point number of seconds

=item raw_command

the message sent to the registry, as string

=item raw_reply

the message received from the registry, as string

=item result_from_cache

either 0 or 1 if these results were retrieved from L<Net::DRI> Cache object or not

=item object_action

name of the action that has been done to achieve these results (ex: "info")

=item object_name

name (or ID) of the object on which the action has been performed (not necessarily always defined)

=item object_type

type of object on which this operation has been done (ex: "domain")

=item registry, profile, transport, protocol

registry name, profile name, transport name+version, protocol name+version used for this exchange

=item trid

transaction ID of this exchange

=back

=head1 METHODS

=head2 is_success()

returns 1 if the operation was a success

=head2 code()

returns the EPP code corresponding to the native code (which depends on the registry)
for this operation (see RFC for full list and source of this file for local extensions)

=head2 native_code()

gives the true status code we got back from registry (this breaks the encapsulation provided by Net::DRI, you should not use it if possible)

=head2 message()

gives the message attached to the the status code we got back from registry

=head2 lang()

gives the language in which the message above is written

=head2 get_extended_results()

gives back an array with additionnal result information from registry, especially in case of errors. If no data, an empty array is returned.

This method was previously called info(), before C<Net::DRI> version 0.92_01

=head2 get_data()

See explanation of data stored in L</"DESCRIPTION">. Can be called with one or three parameters and always returns a single value (or undef if failure).

With three parameters, it returns the value associated to the three keys/subkeys passed. Example: C<get_data("domain","example.com","exist")> will return
0 or 1 depending if the domain exists or not, after a domain check or domain info operation.

With only one parameter, it will verify there is only one branch (besides session/exchange and message/info), and if so returns the data associated
to the parameter passed used as the third key. Otherwise will return undef.

Please note that the input API is I<not> the same as the one used for C<$dri->get_info()>.

You should not try to modify the data returned in any way, but just read it.

=head2 get_data_collection()

See explanation of data stored in L</"DESCRIPTION">. Can be called with either zero, one or two parameters and may return a list or a single value
depending on calling context (and respectively an empty list or undef in case of failure).

With no parameter, it returns the whole data as reference to an hash with 2 levels beneath as explained in L</"DESCRIPTION"> in scalar context, or
the list of keys of this hash in list context.

With one parameter, it returns the hash referenced by the key given as argument at first level in scalar context,
or the list of keys of this hash in list context.

With two parameters, it walks down two level of the hash using the two parameters as key and subkey and returns the bottom hash referenced
in scalar context, or the list of keys of this hash in list context.

Please note that in all cases you are given references to the data itself, not copies. You should not try to modify it in any way, but just read it.

=head2 as_string()

returns a string with all details, with the extended_results part if passed a true value

=head2 print()

same as CORE::print($rs->as_string(0)) or CORE::print($rs->as_string(1)) if passed a true value

=head2 trid()

in scalar context, gives the transaction id (our transaction id, that is the client part in EPP) which has generated this result,
in array context, gives the transaction id followed by other ids given by registry (example in EPP: server transaction id)

=head2 is_pending()

returns 1 if the operation was flagged as pending by registry (asynchronous handling)

=head2 is_closing()

returns 1 if the operation made the registry close the connection (should not happen often)

=head2 is(NAME)

if you really need to test some other codes (this should not happen often), you can using symbolic names
defined inside this module (see source).
Going that way makes sure you are not hardcoding numbers in your application, and you do not need
to import variables from this module to your application.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2006,2008-2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

our %EPP_CODES=(
                COMMAND_SUCCESSFUL => 1000,
                COMMAND_SUCCESSFUL_PENDING => 1001, ## needed for async registries when action done correctly on our side
                COMMAND_SUCCESSFUL_QUEUE_EMPTY => 1300,
                COMMAND_SUCCESSFUL_QUEUE_ACK => 1301,
                COMMAND_SUCCESSFUL_END => 1500, ## after logout

                UNKNOWN_COMMAND => 2000,
                COMMAND_SYNTAX_ERROR => 2001,
                COMMAND_USE_ERROR => 2002,
                REQUIRED_PARAMETER_MISSING => 2003,
                PARAMETER_VALUE_RANGE_ERROR => 2004,
                PARAMETER_VALUE_SYNTAX_ERROR => 2005,
                UNIMPLEMENTED_PROTOCOL_VERSION => 2100,
                UNIMPLEMENTED_COMMAND => 2101,
                UNIMPLEMENTED_OPTION => 2102,
                UNIMPLEMENTED_EXTENSION => 2103,
                BILLING_FAILURE => 2104,
                OBJECT_NOT_ELIGIBLE_FOR_RENEWAL => 2105,
                OBJECT_NOT_ELIGIBLE_FOR_TRANSFER => 2106,
                AUTHENTICATION_ERROR => 2200,
                AUTHORIZATION_ERROR => 2201,
                INVALID_AUTHORIZATION_INFO => 2202,
                OBJECT_PENDING_TRANSFER => 2300,
                OBJECT_NOT_PENDING_TRANSFER => 2301,
                OBJECT_EXISTS   => 2302,
                OBJECT_DOES_NOT_EXIST => 2303,
                OBJECT_STATUS_PROHIBITS_OPERATION => 2304,
                OBJECT_ASSOCIATION_PROHIBITS_OPERATION => 2305,
                PARAMETER_VALUE_POLICY_ERROR => 2306,
                UNIMPLEMENTED_OBJECT_SERVICE => 2307,
                DATA_MANAGEMENT_POLICY_VIOLATION => 2308,
                COMMAND_FAILED => 2400, ## Internal server error not related to the protocol
                COMMAND_FAILED_CLOSING => 2500, ## Same + connection dropped
                AUTHENTICATION_ERROR_CLOSING => 2501,
                SESSION_LIMIT_EXCEEDED_CLOSING => 2502,
               );

sub new
{
 my ($class,$type,$code,$eppcode,$is_success,$message,$lang,$info)=@_;
 my %s=(
        is_success  => (defined $is_success && $is_success)? 1 : 0,
        native_code => $code,
        message     => $message || '',
        type        => $type, ## rrp/epp/afnic/etc...
        lang        => $lang || '?',
       'next'	    => undef,
        data        => {},
        count	    => 0,
       );

 $s{code}=_eppcode($type,$code,$eppcode,$s{is_success});
 $s{info}=(defined $info && ref $info eq 'ARRAY')? $info : [];
 bless(\%s,$class);
 return \%s;
}

sub trid
{
 my $self=shift;
 return unless (exists($self->{trid}) && (ref($self->{trid}) eq 'ARRAY'));
 return wantarray()? @{$self->{trid}} : $self->{trid}->[0];
}

sub clone
{
 my ($self)=@_;
 my $new={ %$self };
 $new->{'next'}=$new->{'next'}->clone() if defined $new->{'next'};
 ## we do not clone "data" key as it is supposed to be used read-only anyway, otherwise use Net::DRI::Util::deepcopy
 bless($new,ref $self);
 return $new;
}

sub local_is_success { return shift->{is_success}; }

sub local_get_extended_results { return @{shift->{info}}; }

sub local_get_data
{
 my ($self,$k1,$k2,$k3)=@_;
 if (! defined $k1 || (defined $k3 xor defined $k2)) { Net::DRI::Exception::err_insufficient_parameters('get_data() expects one or three parameters'); }
 my $d=$self->{'data'};

 ## 3 parameters form, walk the whole references tree
 if (defined $k2 && defined $k3)
 {
  ($k1,$k2)=Net::DRI::Util::normalize_name($k1,$k2);
  if (! exists $d->{$k1})               { return; }
  if (! exists $d->{$k1}->{$k2})        { return; }
  if (! exists $d->{$k1}->{$k2}->{$k3}) { return; }
  return $d->{$k1}->{$k2}->{$k3};
 }

 ## 1 parameter form, go directly to leafs if not too much of them (we skip session/exchange + message/info)
 my @k=grep { $_ ne 'session' && $_ ne 'message' } keys %$d;
 if (@k != 1) { return; }
 $d=$d->{$k[0]};
 if ( keys(%$d) != 1 ) { return; }
 ($d)=values %$d;
 if (! exists $d->{$k1}) { return; }
 return $d->{$k1};
}

sub local_get_data_collection
{
 my ($self,$k1,$k2)=@_;
 my $d=$self->{'data'};

 if (! defined $k1)             { return wantarray ? keys %$d : $d; }
 ($k1,undef)=Net::DRI::Util::normalize_name($k1,'');
 if (! exists $d->{$k1})        { return; }
 if (! defined $k2)             { return wantarray ? keys %{$d->{$k1}} : $d->{$k1}; }
 ($k1,$k2)=Net::DRI::Util::normalize_name($k1,$k2);
 if (! exists $d->{$k1}->{$k2}) { return; }
 return wantarray ? keys %{$d->{$k1}->{$k2}} : $d->{$k1}->{$k2};
}

sub is_success
{
 my ($self)=@_;
 while (defined $self)
 {
  my $is=$self->local_is_success();
  return 0 unless $is;
 } continue { $self=$self->next(); }
 return 1;
}

sub get_extended_results
{
 my ($self)=@_;
 my @i;
 while (defined $self)
 {
  my @li=$self->local_get_extended_results();
  push @i,@li if @li;
 } continue { $self=$self->next(); }
 return @i;
}

sub get_data
{
 my ($self,$k1,$k2,$k3)=@_;
 my $r;
 while (defined $self)
 {
  my $lr=$self->local_get_data($k1,$k2,$k3);
  $r=$lr if defined $lr;
 } continue { $self=$self->next(); }
 return $r;
}

sub get_data_collection
{
 my ($self,$k1,$k2)=@_;
 if (wantarray)
 {
  my %r;
  while (defined $self)
  {
   foreach my $lr ($self->local_get_data_collection($k1,$k2)) { $r{$lr}=1; }
  } continue { $self=$self->next(); }
  return keys(%r);
 } else
 {
  my @r;
  my $deep=(defined $k1 ? 1 : 0)+(defined $k2 ? 1 : 0); ## 0,1,2
  while (defined $self)
  {
   my $lr=$self->local_get_data_collection($k1,$k2);
   push @r,$lr if defined $lr;
  } continue { $self=$self->next(); }
  return _merge($deep,@r);
 }
}

sub _merge
{
 my ($deep,@hashes)=@_;

 ## If we are "down below", just return the "last" set of values encountered (no merge)
 return $hashes[-1] if ($deep==2);

 my %r;
 my %tmp;
 foreach my $rh (@hashes)
 {
  foreach my $key (keys %$rh)
  {
   push @{$tmp{$key}},$rh->{$key};
  }
 }
 foreach my $key (keys %tmp)
 {
  $r{$key}=_merge($deep+1,@{$tmp{$key}});
 }
 return \%r;
}

sub last { my $self=shift; while ( defined $self->next() ) { $self=$self->next(); } return $self; } ## no critic (Subroutines::ProhibitBuiltinHomonyms)

## These methods are not public !
sub _set_trid { my ($self,$v)=@_; $self->{'trid'}=$v; return; }
sub _set_last { my ($self,$v)=@_; while ( defined $self->next() ) { $self->{'count'}++; $self=$self->next(); } $self->{'count'}++; $self->{'next'}=$v; return; }
sub _set_data { my ($self,$v)=@_; $self->{'data'}=$v; return; }
sub _eppcode
{
 my ($type,$code,$eppcode,$is_success)=@_;
 return $EPP_CODES{COMMAND_FAILED} unless defined $type && $type && defined $code;
 $eppcode=$code if (! defined $eppcode  && $type eq 'epp');
 return $is_success? $EPP_CODES{COMMAND_SUCCESSFUL} : $EPP_CODES{COMMAND_FAILED} unless defined $eppcode;
 return $eppcode if $eppcode=~m/^\d{4}$/;
 return exists $EPP_CODES{$eppcode} ? $EPP_CODES{$eppcode} : $EPP_CODES{COMMAND_FAILED};
}

## ($code,$msg,$lang,$ri) or ($msg,$lang,$ri)
sub new_success { my ($class,@p)=@_; return $class->new('epp',$EPP_CODES{(@p && defined $p[0] && $p[0]=~m/^[A-Z_]+$/ && exists $EPP_CODES{$p[0]})? shift(@p) : 'COMMAND_SUCCESSFUL'},undef,1,@p); }
sub new_error   { my ($class,$code,@p)=@_; return $class->new('epp',$code,undef,0,@p); }

sub local_as_string
{
 my ($self,$withinfo)=@_;
 my $b=sprintf('%s %d %s',$self->local_is_success()? 'SUCCESS' : 'ERROR',$self->code(),length $self->message() ? ($self->code() eq $self->native_code()? $self->message() : $self->message().' ['.$self->native_code().']') : '(No message given)');
 if (defined $withinfo && $withinfo)
 {
  my @i=$self->local_get_extended_results();
  $b.="\n".join("\n",map { my $rh=$_; "\t".(join(' ',map { $_.'='.(defined $rh->{$_} ? $rh->{$_} : '<undef>') } sort keys %$rh)) } @i) if @i;
 }
 return $b;
}

sub as_string
{
 my ($self,$withinfo)=@_;
 my @r;
 while (defined $self)
 {
  push @r,$self->local_as_string($withinfo);
 } continue { $self=$self->next(); }
 return wantarray ? @r : (@r==1 ? $r[0] : join("\n",map { sprintf('{%d} %s',1+$_,$r[$_]) } (0..$#r)));
}

sub print      { my ($self,$e)=@_; print $self->as_string(defined $e && $e ? 1 : 0); return; } ## no critic (Subroutines::ProhibitBuiltinHomonyms)

## Should these be global too ? if so, enhance is() with third parameter to know if walking is necessary or not
sub is_pending { my ($self)=@_; return $self->is('COMMAND_SUCCESSFUL_PENDING'); }
sub is_closing { my ($self)=@_; return $self->is('COMMAND_SUCCESSFUL_END') || $self->is('COMMAND_FAILED_CLOSING') || $self->is('AUTHENTICATION_ERROR_CLOSING') || $self->is('SESSION_LIMIT_EXCEEDED_CLOSING'); }

sub is
{
 my ($self,$symcode)=@_;
 Net::DRI::Exception::err_insufficient_parameters('Net::DRI::Protocol::ResultStatus->is() method expects a symbolic name') unless defined $symcode && length $symcode;
 Net::DRI::Exception::err_invalid_parameters('Symbolic name "'.$symcode.'" does not exist in Net::DRI::Protocol::ResultStatus') unless exists $EPP_CODES{$symcode};
 my $code=ref $self ? $self->code() : $self;
 Net::DRI::Exception::err_invalid_parameters('Undefined or malformed code') unless defined $code && $code=~m/^\d+$/;
 return ($code == $EPP_CODES{$symcode})? 1 : 0;
}

####################################################################################################
1;
