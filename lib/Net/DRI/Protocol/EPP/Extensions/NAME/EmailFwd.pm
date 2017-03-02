## Domain Registry Interface, EPP Email forwarding extension commands
## (based on .NAME Technical Accreditation Guide v3.03)
##
## Copyright (c) 2007,2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>
## Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>
## All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NAME::EmailFwd;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Contact;
use Net::DRI::Data::ContactSet;
use DateTime::Format::ISO8601;
use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NAME::EmailFwd - EPP EmailFwd extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> or
E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands {
  my ( $class, $version ) = @_;
  my %tmp = ( create           => [ \&create,           \&create_parse ],
              check            => [ \&check,            \&check_parse ],
              info             => [ \&info,             \&info_parse ],
              delete           => [ \&delete ],
              update           => [ \&update ],
              renew            => [ \&renew,            \&renew_parse ],
              transfer_query   => [ \&transfer_query,   \&transfer_parse ],
              transfer_request => [ \&transfer_request, \&transfer_parse ],
              transfer_cancel  => [ \&transfer_cancel,  \&transfer_parse ],
              transfer_answer  => [ \&transfer_answer,  \&transfer_parse ] );

  $tmp{check_multi} = $tmp{check};

  return { 'emailfwd' => \%tmp };
}

sub setup {
  my ( $class, $po, $version ) = @_;
  $po->ns( { emailFwd => [ 'http://www.nic.name/epp/emailFwd-1.0', 'emailFwd-1.0' ] } );
  $po->capabilities( 'emailfwd_update', 'info', ['set'] );
  return;
}

####################################################################################################
########### Helpers

sub _parse_emailfwd {
  my ( $po, $otype, $oaction, $oname, $rinfo, $child ) = @_;
  my $mes = $po->message();
  return unless $mes->is_success();

  my $ns = $mes->ns('emailFwd');
  my $infdata = $mes->get_response( $ns, $child );
  return unless $infdata;

  my $nm;
  my $cs = $po->create_local_object('contactset');
  my @s;
  my $info  = {};
  my $ginfo = {};

  my $c = $infdata->getFirstChild();
  while ($c) {
    next unless ( $c->nodeType() == 1 );    ## only for element nodes
    my $name = $c->localname() || $c->nodeName();
    next unless $name;

    if ( $name eq 'name' ) {
      $ginfo->{$name} = $nm = $c->getFirstChild()->getData();
    } elsif ( $name eq 'roid' ) {
      $ginfo->{$name} = $c->getFirstChild()->getData();
    } elsif ( $name eq 'status' ) {
      push @s, Net::DRI::Protocol::EPP::Util::parse_node_status($c);
    } elsif ( $name eq 'fwdTo' ) {
      $ginfo->{$name} = $c->getFirstChild()->getData();
    } elsif (
      grep {
        $_ eq $name
      } qw/clID crID upID reID acID tm tmCountry trStatus/
        ) {
      $ginfo->{$name} = $c->getFirstChild()->getData();
    } elsif (
      grep {
        $_ eq $name
      } qw/crDate upDate trDate exDate tmDate acDate reDate/
        ) {
      $ginfo->{$name} = DateTime::Format::ISO8601->new()->parse_datetime( $c->getFirstChild()->getData() );
    } elsif (
      grep {
        $_ eq $name
      } qw/registrant contact/
        ) {
      my $type = $c->getAttribute('type') || 'registrant';
      $cs->add( Net::DRI::Data::Contact->new()->srid( $c->getFirstChild()->getData() ), $type );
    } elsif ( $name eq 'authInfo' ) {
      my $pw = ( $c->getElementsByTagNameNS( $mes->ns('emailFwd'), 'pw' ) )[0];
      $ginfo->{auth} = { pw => ( defined($pw) && $pw->hasChildNodes() ? $pw->getFirstChild->getData() : undef ) };
    }
  } continue {
    $c = $c->getNextSibling();
  }

  $ginfo->{contact}         = $cs;
  $ginfo->{exist}           = defined($nm);
  $ginfo->{action}          = $oaction;
  $ginfo->{self}            = $info;
  $ginfo->{status}          = $po->create_local_object('status')->add(@s);
  $rinfo->{emailfwd}->{$nm} = $ginfo;

  return;
}

sub _build_transfer {
  my ( $epp, $mail, $rd, $op ) = @_;
  my $mes = $epp->message();
  Net::DRI::Exception->die( 1, 'protocol/EPP', 2, 'emailFwd name needed' ) unless ( defined($mail) );
  $mes->command( [ 'transfer', { 'op' => $op } ],
                 'emailFwd:transfer', sprintf( 'xmlns:emailFwd="%s" xsi:schemaLocation="%s %s"', $mes->nsattrs('emailFwd') ) );
  my @d;
  push @d, [ 'emailFwd:name', $mail ];
  push @d, Net::DRI::Protocol::EPP::Util::build_period( $rd->{duration}, 'emailFwd' ) if Net::DRI::Util::has_duration($rd);
  push @d, [ 'emailFwd:authInfo', [ 'emailFwd:pw', $rd->{auth}->{pw}, exists( $rd->{auth}->{roid} ) ? { 'roid' => $rd->{auth}->{roid} } : undef ] ]
      if exists $rd->{auth};
  $mes->command_body( \@d );
  return;
}

sub build_command {
  my ( $epp, $msg, $command, $info ) = @_;
  my $contacts = $info->{contact};
  my $authid   = $info->{auth};
  my @ret;
  my @auth;

  Net::DRI::Exception->die( 1, 'protocol/EPP', 2, 'emailFwd name needed' ) unless ( defined( $info->{name} ) );

  my @ns = $msg->nsattrs('emailFwd');
  @ns = qw(http://www.nic.name/epp/emailFwd-1.0 http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd) unless @ns;
  $msg->command( [ $command, 'emailFwd:' . $command, sprintf( 'xmlns:emailFwd="%s" xsi:schemaLocation="%s %s"', @ns ) ] );

  push( @ret, [ 'emailFwd:name',  $info->{name} ] )  if ( defined( $info->{name} ) );
  push( @ret, [ 'emailFwd:fwdTo', $info->{fwdTo} ] ) if ( defined( $info->{fwdTo} ) );
  push( @ret, [ 'emailFwd:curExpDate', $info->{curExpDate} ] )
      if ( defined( $info->{curExpDate} ) );

  # lets force duration to period in case the first one is used
  $info->{period} = $info->{duration} if $info->{duration};
  push( @ret, [ 'emailFwd:period', { unit => 'y' }, $info->{period}->in_units('years') ] ) if defined( $info->{period} );

  # handle contacts
  my $cs = $contacts;
  if ( defined($cs) ) {
    push( @ret, [ 'emailFwd:registrant', $cs->get('registrant')->srid() ] ) if $cs->has_type('registrant');

    # from xml schema => contactAttrType
    foreach (qw/admin billing tech/) {
      push( @ret, [ 'emailFwd:contact', { type => $_ }, $cs->get($_)->srid() ] ) if $cs->has_type($_);
    }
  }

  foreach my $auth ( sort { $a cmp $b } keys %$authid ) {
    push( @auth, [ 'emailFwd:' . $auth, $authid->{$auth} ] );
  }
  push( @ret, [ 'emailFwd:authInfo', @auth ] ) if (@auth);

  return @ret;
}

####################################################################################################
########### Query commands

sub check {
  my ( $epp, $mail, $rd ) = @_;
  my $mes = $epp->message();
  my (@d);
  if ( $mail && ref $mail ) {
    $mes->command( 'check', 'emailFwd:check', sprintf( 'xmlns:emailFwd="%s" xsi:schemaLocation="%s %s"', $mes->nsattrs('emailFwd') ) );
    foreach my $name ( @{$mail} ) {
      push( @d, [ 'emailFwd:name', {}, $name ] );
    }
  } else {
    @d = build_command( $epp, $mes, 'check', { name => $mail } );
  }

  $mes->command_body( \@d );
  return;
}

sub check_parse {
  my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
  my $mes = $po->message();
  return unless $mes->is_success();

  my $ns = $mes->ns('emailFwd');
  my $chkdata = $mes->get_response( $ns, 'chkData' );
  return unless $chkdata;
  foreach my $cd ( $chkdata->getElementsByTagNameNS( $ns, 'cd' ) ) {
    my $c = $cd->getFirstChild();
    my $fwd;

    while ($c) {
      next unless ( $c->nodeType() == 1 );    ## only for element nodes
      my $n = $c->localname() || $c->nodeName();
      if ( $n eq 'name' ) {
        $fwd                                 = $c->getFirstChild()->getData();
        $rinfo->{emailfwd}->{$fwd}->{exist}  = 1 - Net::DRI::Util::xml_parse_boolean( $c->getAttribute('avail') );
        $rinfo->{emailfwd}->{$fwd}->{action} = 'check';
      } elsif ( $n eq 'reason' ) {
        $rinfo->{emailfwd}->{$fwd}->{exist_reason} = $c->textContent();
      }
    } continue {
      $c = $c->getNextSibling();
    }
  }
  return;
}

sub info {
  my ( $epp, $mail, $rd ) = @_;
  my $mes = $epp->message();
  Net::DRI::Exception->die( 1, 'protocol/EPP', 2, 'emailFwd mail name needed' ) unless ( defined($mail) );
  my @d = build_command( $epp, $mes, 'info', { name => $mail } );
  push @d, [ 'emailFwd:authInfo', [ 'emailFwd:pw', $rd->{auth}->{pw}, exists( $rd->{auth}->{roid} ) ? { 'roid' => $rd->{auth}->{roid} } : undef ] ]
      if exists $rd->{auth};
  $mes->command_body( \@d );
  return;
}

sub info_parse {
  my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
  $oaction = 'info';
  return _parse_emailfwd( @_, 'infData' );
}

sub transfer_query { return _build_transfer( @_, 'query' ); }

sub transfer_parse {
  my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
  return _parse_emailfwd( @_, 'trnData' );
}

############ Transform commands

sub create {
  my ( $epp, $mail, $info ) = @_;
  my $mes = $epp->message();
  my @d;
  $info->{name} = $mail;
  @d = build_command( $epp, $mes, 'create', $info );
  $mes->command_body( \@d );
  return;
}

sub create_parse {
  my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
  return _parse_emailfwd( @_, 'creData' );
}

sub delete    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
  my ( $epp, $mail ) = @_;
  my $mes = $epp->message();
  my @d = build_command( $epp, $mes, 'delete', { name => $mail } );
  $mes->command_body( \@d );
  return;
}

sub update {
  my ( $epp, $mail, $todo ) = @_;
  my $mes = $epp->message();

  Net::DRI::Exception::usererr_invalid_parameters( $todo . ' must be a Net::DRI::Data::Changes object' ) unless Net::DRI::Util::isa_changes($todo);

  $mes->command( 'update', 'emailFwd:update', sprintf( 'xmlns:emailFwd="%s" xsi:schemaLocation="%s %s"', $mes->nsattrs('emailFwd') ) );
  my ( @d, @add, @del, @set );
  push @d, [ 'emailFwd:name', $mail ];

  # addRemType (add, del) => contactType(admin, billing and tech) AND status
  # add contactType
  my $cadd = $todo->add('contact');

  # del contactType
  my $cdel = $todo->del('contact');

  # based on Net::DRI::Protocol::EPP::Util::build_core_contacts() and tweaked for this case!
  my %r = map { $_ => 1 } $epp->core_contact_types();
  if ( Net::DRI::Util::isa_contactset($cdel) || Net::DRI::Util::isa_contactset($cadd) ) {
    foreach my $t ( sort( grep { exists( $r{$_} ) } $cadd->types() ) ) {
      my @oadd = $cadd->get($t);
      my @odel = $cdel->get($t);
      push @add, map { [ ( 'update', 'emailFwd' ) . ':contact', $_->srid(), { 'type' => $t } ] } @oadd;
      push @del, map { [ ( 'update', 'emailFwd' ) . ':contact', $_->srid(), { 'type' => $t } ] } @odel;    # print Dumper(\@d);
    }
  }

  # END: addRemType (add, del) => contactType(admin, billing and tech) AND status

  # add status
  my $sadd = $todo->add('status');
  push @add, $sadd->build_xml( 'emailFwd:status', 'core' ) if Net::DRI::Util::isa_statuslist($sadd);
  push @d, [ 'emailFwd:add', @add ] if @add;

  # del status
  my $sdel = $todo->del('status');
  push @del, $sdel->build_xml( 'emailFwd:status', 'core' ) if Net::DRI::Util::isa_statuslist($sdel);
  push @d, [ 'emailFwd:rem', @del ] if @del;

  # END addRemType (add, del) => contactType(admin, billing and tech) AND status

  my $cs   = $todo->set('contact');
  my $auth = $todo->set('auth');

  # chgType (set) => (fwdTo, registrant, authInfo )
  push( @set, [ 'emailFwd:fwdTo', $todo->set('fwdTo') ] ) if defined $todo->set('fwdTo');
  push( @set, [ 'emailFwd:registrant', $cs->get('registrant')->srid() ] ) if defined $cs && $cs->has_type('registrant');
  push @set, [ 'emailFwd:authInfo', [ 'emailFwd:pw', $auth->{pw} ] ] if defined $auth;

  push @d, [ 'emailFwd:chg', @set ] if @set;

  $mes->command_body( \@d );
  return;
}

sub renew {
  my ( $epp, $mail, $period, $curexp ) = @_;
  my $mes = $epp->message();

  Net::DRI::Util::check_isa( $curexp, 'DateTime' );
  Net::DRI::Util::check_isa( $period, 'DateTime::Duration' );

  my $info = { name       => $mail,
               curExpDate => $curexp->ymd,
               period     => $period
             };

  my @d = build_command( $epp, $mes, 'renew', $info );
  $mes->command_body( \@d );
  return;
}

sub renew_parse {
  my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
  return _parse_emailfwd( @_, 'renData' );
}

sub transfer_request { return _build_transfer( @_, 'request' ); }
sub transfer_cancel  { return _build_transfer( @_, 'cancel' ); }
sub transfer_answer  { return _build_transfer( @_, $_[2]->{approve} ? 'approve' : 'reject' ); }

####################################################################################################
1;
