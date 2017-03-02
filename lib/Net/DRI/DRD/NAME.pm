## Domain Registry Interface, .NAME policies
##
## Copyright (c) 2007-2009,2011 HEXONET Support GmbH, www.hexonet.com,
##                    Alexander Biehl <info@hexonet.com>
##			and Patrick Mevzek <netdri@dotandco.com>.
##                    All rights reserved.
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

package Net::DRI::DRD::NAME;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
use Net::DRI::Util;
use DateTime::Duration;
use Data::Dumper;

=pod

=head1 NAME

Net::DRI::DRD::NAME - .NAME policies for Net::DRI

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

Copyright (c) 2007-2009,2011 HEXONET Support GmbH, E<lt>http://www.hexonet.comE<gt>,
Alexander Biehl <info@hexonet.com>
and Patrick Mevzek <netdri@dotandco.com>.
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
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  $self->{info}->{host_as_attr} = 0;
  $self->{info}->{contact_i18n} = 2;    ## INT only
  return $self;
}

sub periods { return map { DateTime::Duration->new( years => $_ ) } ( 1 .. 10 ); }
sub name          { return 'NAME'; }
sub tlds          { return ('name'); }
sub object_types  { return ( 'domain', 'contact', 'ns', 'defReg' ); }
sub profile_types { return qw/epp whois/; }

sub transport_protocol_default
{
  my ( $self, $type ) = @_;

  return ( 'Net::DRI::Transport::Socket', {}, 'Net::DRI::Protocol::EPP::Extensions::NAME', {} ) if $type eq 'epp';
  return ( 'Net::DRI::Transport::Socket', { remote_host => 'whois.nic.name' }, 'Net::DRI::Protocol::Whois', {} ) if $type eq 'whois';
  return;
}

####################################################################################################

sub verify_name_domain
{
  my ( $self, $ndr, $domain, $op ) = @_;
  return $self->_verify_name_rules(
    $domain, $op,
    { check_name        => 1,
      check_name_dots   => [ 1, 2 ],
      my_tld_not_strict => 1,          ## we need less strict checks because in X.Y.name domain names both X and Y are variables
      icann_reserved    => 1,
    } );
}

####################################################################################################

sub emailfwd_check
{
  my ( $self, $ndr, @p ) = @_;
  my ( @names, $rd );
  foreach my $p (@p) {
    if ( defined $p && ref $p eq 'HASH' ) {
      Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in email_check') if defined $rd;
      $rd = Net::DRI::Util::create_params( 'emailfwd_check', $p );
      next;
    }
    push @names, $p;
  }
  Net::DRI::Exception::usererr_invalid_parameters('emailfwd_check needs at leat one email to check') unless @names;
  $rd = {} unless defined $rd;

  my ( @rs,       @todo );
  my ( %seenmail, %seenrc );
  foreach my $mail (@names) {
    next if exists $seenmail{$mail};
    $seenmail{$mail} = 1;
    push @todo, $mail;
  }

  return Net::DRI::Util::link_rs(@rs) unless @todo;

  if ( @todo > 1 && $ndr->protocol()->has_action( 'emailfwd', 'check_multi' ) ) {
    my $l = $self->info('emailfwd_check_limit') ? $self->info('emailfwd_check_limit') : $self->info('check_limit');
    if ( !defined $l ) {
      $ndr->log_output( 'notice', 'core',
                        'No check_limit specified in driver, assuming 10 for domain_check action. Please report if you know the correct value' );
      $l = 10;
    }
    while (@todo) {
      my @lt = splice( @todo, 0, $l );
      push @rs, $ndr->process( 'emailfwd', 'check_multi', [ \@lt, $rd ] );
    }
  } else    ## either one mail only, or more than one but no check_multi available at protocol level
  {
    push @rs, map { $ndr->process( 'emailfwd', 'check', [ $_, $rd ] ); } @todo;
  }

  # print Dumper(\@rs); # debug/check array
  return Net::DRI::Util::link_rs(@rs);
}

sub emailfwd_exist    ## 1/0/undef
{
  my ( $self, $ndr, $email ) = @_;
  ## Technical syntax check of email object needed here
  my $rc = $ndr->emailfwd_check($email);
  return unless $rc->is_success();
  return $ndr->get_info('exist');
}

sub emailfwd_info
{
  my ( $self, $ndr, $email, $rd ) = @_;
  ## Technical syntax check of email object needed here
  my $rc = $ndr->try_restore_from_cache( 'emailfwd', $email, 'info' );
  if ( !defined $rc ) { $rc = $ndr->process( 'emailfwd', 'info', [ $email, $rd ] ); }
  return $rc;
}

sub emailfwd_transfer
{
  my ( $self, $ndr, $roid, $op, $rd ) = @_;

  $rd = {} unless $rd;
  $rd = Net::DRI::Util::create_params( 'domain_transfer', $rd );    # same as domain, really
  Net::DRI::Exception::usererr_invalid_parameters('Transfer operation must be start,stop,accept,refuse or query')
      unless ( $op =~ m/^(?:start|stop|query|accept|refuse)$/ );
  Net::DRI::Exception->die( 0, 'DRD', 3, 'Invalid duration' )
      if Net::DRI::Util::has_key( $rd, 'duration' ) && $self->verify_duration_transfer( $ndr, $rd->{duration}, $roid, $op );

  my $rc;
  if ( $op eq 'start' ) {
    $rc = $ndr->process( 'emailfwd', 'transfer_request', [ $roid, $rd ] );
  } elsif ( $op eq 'stop' ) {
    $rc = $ndr->process( 'emailfwd', 'transfer_cancel', [ $roid, $rd ] );
  } elsif ( $op eq 'query' ) {
    $rc = $ndr->process( 'emailfwd', 'transfer_query', [ $roid, $rd ] );
  } else    ## accept/refuse
  {
    $rd->{approve} = ( $op eq 'accept' ) ? 1 : 0;
    $rc = $ndr->process( 'emailfwd', 'transfer_answer', [ $roid, $rd ] );
  }

  return $rc;
}

sub emailfwd_transfer_start  { my ( $self, $ndr, $roid, $rd ) = @_; return $self->emailfwd_transfer( $ndr, $roid, 'start',  $rd ); }
sub emailfwd_transfer_stop   { my ( $self, $ndr, $roid, $rd ) = @_; return $self->emailfwd_transfer( $ndr, $roid, 'stop',   $rd ); }
sub emailfwd_transfer_query  { my ( $self, $ndr, $roid, $rd ) = @_; return $self->emailfwd_transfer( $ndr, $roid, 'query',  $rd ); }
sub emailfwd_transfer_accept { my ( $self, $ndr, $roid, $rd ) = @_; return $self->emailfwd_transfer( $ndr, $roid, 'accept', $rd ); }
sub emailfwd_transfer_refuse { my ( $self, $ndr, $roid, $rd ) = @_; return $self->emailfwd_transfer( $ndr, $roid, 'refuse', $rd ); }

sub emailfwd_create
{
  my ( $self, $ndr, $email, $rd ) = @_;
  ## Technical syntax check of email object needed here
  my $rc = $ndr->process( 'emailfwd', 'create', [ $email, $rd ] );
  return $rc;
}

sub emailfwd_delete
{
  my ( $self, $ndr, $email ) = @_;
  ## Technical syntax check of email object needed here
  my $rc = $ndr->process( 'emailfwd', 'delete', [$email] );
  return $rc;
}

sub emailfwd_update
{
  my ( $self, $ndr, $email, $tochange ) = @_;
  my $fp = $ndr->protocol->nameversion();

  ## Technical syntax check of email object needed here
  Net::DRI::Util::check_isa( $tochange, 'Net::DRI::Data::Changes' );

  my $rc = $ndr->process( 'emailfwd', 'update', [ $email, $tochange ] );
  return $rc;
}

sub emailfwd_renew
{
  my ( $self, $ndr, $email, $rd ) = @_;
  ## Technical syntax check of email object needed here
  Net::DRI::Util::check_isa( $rd->{duration},           'DateTime::Duration' ) if defined( $rd->{duration} );
  Net::DRI::Util::check_isa( $rd->{current_expiration}, 'DateTime' )           if defined( $rd->{current_expiration} );
  return $ndr->process( 'emailfwd', 'renew', [ $email, $rd->{duration}, $rd->{current_expiration} ] );
}

####################################################################################################

# based on domain_check
sub defreg_check
{
  my ( $self, $ndr, @p ) = @_;
  my ( @names, $rd );
  foreach my $p (@p) {
    if ( defined $p && ref $p eq 'HASH' ) {
      Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in defreg_check') if defined $rd;
      $rd = $p;
      next;
    }
    push @names, $p;
  }
  Net::DRI::Exception::usererr_insufficient_parameters('defreg_check needs at least one name to check') unless @names;
  $rd = {} unless defined $rd;

  my ( @rs,      @todo );
  my ( %seendom, %seenrc );
  foreach my $domain (@names) {
    next if exists $seendom{$domain};
    $seendom{$domain} = 1;
    my $rs = $ndr->try_restore_from_cache( 'defreg', $domain, 'check' );
    if ( !defined $rs ) {
      push @todo, $domain;
    } else {
      push @rs, $rs
          unless exists $seenrc{ ''
            . $rs
          }; ## Some ResultStatus may relate to multiple domain names (this is why we are doing this anyway !), so make sure not to use the same ResultStatus multiple times
      $seenrc{ '' . $rs } = 1;
    }
  }

  return Net::DRI::Util::link_rs(@rs) unless @todo;

  if ( @todo > 1 && $ndr->protocol()->has_action( 'defreg', 'check_multi' ) ) {
    my $l = $self->info('defreg_check_limit') ? $self->info('defReg_check_limit') : $self->info('check_limit');
    if ( !defined $l ) {
      $ndr->log_output( 'notice', 'core',
                        'No check_limit specified in driver, assuming 10 for defreg_check action. Please report if you know the correct value' );
      $l = 10;
    }
    while (@todo) {
      my @lt = splice( @todo, 0, $l );
      push @rs, $ndr->process( 'defreg', 'check_multi', [ \@lt, $rd ] );
    }
  } else    ## either one domain only, or more than one but no check_multi available at protocol level
  {
    push @rs, map { $ndr->process( 'defreg', 'check', [ $_, $rd ] ); } @todo;
  }

  return Net::DRI::Util::link_rs(@rs);
}

sub defreg_exist    ## 1/0/undef
{
  my ( $self, $ndr, $roid ) = @_;
  my $rc = $ndr->defreg_check($roid);
  return unless $rc->is_success();
  return $ndr->get_info('exist');
}

sub defreg_info
{
  my ( $self, $ndr, $roid, $rd ) = @_;
  my $rc = $ndr->try_restore_from_cache( 'defreg', $roid, 'info' );
  if ( !defined $rc ) { $rc = $ndr->process( 'defreg', 'info', [ $roid, $rd ] ); }
  return $rc;
}

sub defreg_transfer
{
  my ( $self, $ndr, $roid, $op, $rd ) = @_;

  $rd = {} unless $rd;
  $rd = Net::DRI::Util::create_params( 'domain_transfer', $rd );    # same as domain, really
  Net::DRI::Exception::usererr_invalid_parameters('Transfer operation must be start,stop,accept,refuse or query')
      unless ( $op =~ m/^(?:start|stop|query|accept|refuse)$/ );
  Net::DRI::Exception->die( 0, 'DRD', 3, 'Invalid duration' )
      if Net::DRI::Util::has_key( $rd, 'duration' ) && $self->verify_duration_transfer( $ndr, $rd->{duration}, $roid, $op );

  my $rc;
  if ( $op eq 'start' ) {
    $rc = $ndr->process( 'defreg', 'transfer_request', [ $roid, $rd ] );
  } elsif ( $op eq 'stop' ) {
    $rc = $ndr->process( 'defreg', 'transfer_cancel', [ $roid, $rd ] );
  } elsif ( $op eq 'query' ) {
    $rc = $ndr->process( 'defreg', 'transfer_query', [ $roid, $rd ] );
  } else    ## accept/refuse
  {
    $rd->{approve} = ( $op eq 'accept' ) ? 1 : 0;
    $rc = $ndr->process( 'defreg', 'transfer_answer', [ $roid, $rd ] );
  }

  return $rc;
}

sub defreg_transfer_start  { my ( $self, $ndr, $roid, $rd ) = @_; return $self->defreg_transfer( $ndr, $roid, 'start',  $rd ); }
sub defreg_transfer_stop   { my ( $self, $ndr, $roid, $rd ) = @_; return $self->defreg_transfer( $ndr, $roid, 'stop',   $rd ); }
sub defreg_transfer_query  { my ( $self, $ndr, $roid, $rd ) = @_; return $self->defreg_transfer( $ndr, $roid, 'query',  $rd ); }
sub defreg_transfer_accept { my ( $self, $ndr, $roid, $rd ) = @_; return $self->defreg_transfer( $ndr, $roid, 'accept', $rd ); }
sub defreg_transfer_refuse { my ( $self, $ndr, $roid, $rd ) = @_; return $self->defreg_transfer( $ndr, $roid, 'refuse', $rd ); }

sub defreg_create
{
  my ( $self, $ndr, $name, $rd ) = @_;
  return $ndr->process( 'defreg', 'create', [ $name, $rd ] );
}

sub defreg_delete
{
  my ( $self, $ndr, $roid ) = @_;
  return $ndr->process( 'defreg', 'delete', [$roid] );
}

sub defreg_update
{
  my ( $self, $ndr, $roid, $tochange ) = @_;
  my $fp = $ndr->protocol->nameversion();

  Net::DRI::Util::check_isa( $tochange, 'Net::DRI::Data::Changes' );

  foreach my $t ( $tochange->types() ) {
    next if $ndr->protocol_capable( 'defreg_update', $t );
    Net::DRI::Exception->die( 0, 'DRD', 5, 'Protocol ' . $fp . ' is not capable of defreg_update/' . $t );
  }

  my $rc = $ndr->process( 'defreg', 'update', [ $roid, $tochange ] );
  return $rc;
}

sub defreg_renew
{
  my ( $self, $ndr, $roid, $rd ) = @_;
  return $ndr->process( 'defreg', 'renew', [ $roid, $rd->{duration}, $rd->{current_expiration} ] );
}

####################################################################################################

####################################################################################################
1;
