## Domain Registry Interface, .NO Host extensions
##
## Copyright (c) 2008,2010,2013 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
##                    Trond Haugen E<lt>info@norid.noE<gt>
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

package Net::DRI::Protocol::EPP::Extensions::NO::Host;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NO::Host - .NO Host Extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Trond Haugen, E<lt>info@norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2010,2013 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
Trond Haugen E<lt>info@norid.noE<gt>
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
    my %tmp = (
        create => [ \&create, undef ],
        update => [ \&update, undef ],
        delete => [ \&facet, undef ],
       check  => [ \&facet, undef ],
        info   => [ \&info,   \&parse_info ],
    );

    return { 'host' => \%tmp };
}

####################################################################################################

#####
# Facets
#

sub _build_facet_extension {
    my ( $mes, $epp, $tag ) = @_;

    return $mes->command_extension_register(
        $tag,
        sprintf(
            'xmlns:no-ext-epp="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('no_epp')
        )
    );
}

##
# This facet method is generic and can be called from all object operations
#
sub build_facets {
    my ( $epp, $rd ) = @_;

    my @e;
    my $eid;

    my $mes = $epp->message();
    if (exists($rd->{facets}) && defined($rd->{facets})) {
       $eid = _build_facet_extension( $mes, $epp, 'no-ext-epp:extended' );
       foreach my $fkey (sort { $a cmp $b } keys(%{$rd->{facets}})) {
           push @e, [ 'no-ext-epp:facet', { name => $fkey }, $rd->{facets}->{$fkey} ];
       }
    }
    return $mes->command_extension( $eid, \@e ) if (@e);
    return;
}


sub facet {
    my ( $epp, $o, $rd ) = @_;

    return build_facets( $epp, $rd );
}


sub parse_info {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();
    return unless $mes->is_success();

    my $NS = $mes->ns('no_host');

    my $condata = $mes->get_extension('no_host','infData');
    return unless $condata;

    my @e = $condata->getElementsByTagNameNS( $NS, 'contact' );
    return unless @e;

    # Contact is optional, may be single or multiple,
    # return the contactIDs in an ARRAY 
    my @hc;
    foreach my $el ( @e)
    {
        my $c = $el->getFirstChild();
        my $v;
        $v = $c->getData() if ($c);
        push @hc, $v if ($v);
    }
    if ( @hc > 0 ) {
       # multiple, return array
       push @{$rinfo->{host}->{$oname}->{contact}}, @hc;
    }
    return;
}

sub build_command_extension {
    my ( $mes, $epp, $tag ) = @_;

    return $mes->command_extension_register(
        $tag,
        sprintf(
            'xmlns:no-ext-host="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('no_host')
        )
    );
}



sub info {
    my ( $epp, $ho, $rd ) = @_;
    my $mes = $epp->message();

    my $si;
    $si = $rd->{sponsoringclientid} if (exists($rd->{sponsoringclientid}));
    my $fs;
    $fs = $rd->{facets} if (exists($rd->{facets}));

    return unless ( $si || $fs );

    my $r;

    if ($si) {
       my $eid = build_command_extension( $mes, $epp, 'no-ext-host:info' );
       my @e;
       push @e, [ 'no-ext-host:sponsoringClientID', $si ];
       $r = $mes->command_extension( $eid, \@e );
    }
    if ($fs) {
       $r = facet( $epp, $ho, $rd );
    }
       
    return $r;
}

sub create {
    my ( $epp, $ho, $rd ) = @_;
    my $mes = $epp->message();

    return unless ((exists($rd->{contact}) && defined($rd->{contact})) || (exists($rd->{facets}) && defined($rd->{facets})));

    my $r;

    if (exists($rd->{contact}) && defined($rd->{contact})) {
       my @e;
       my $eid = build_command_extension( $mes, $epp, 'no-ext-host:create' );
       my $c = $rd->{contact};
       my $srid;
 
       if ( ref($c) eq 'ARRAY' ) {
           foreach my $cn (@$c) {
               if (Net::DRI::Util::isa_contact($cn))
       {
        $srid = $cn->srid();
       } else {
                   $srid = $cn;
      }
       push @e, [ 'no-ext-host:contact', $srid ];
           }
       } else {
           # $c may be a contact set, contact object or a direct scalar
           my @contacts;
           if (Net::DRI::Util::isa_contactset($c)) { 
              foreach my $cn (keys %{ $$c{'c'} } ) { 
                   push @contacts, ${$$c{'c'}}{$cn}->[0]->srid(); 
               }
           } elsif (Net::DRI::Util::isa_contact($c)) { 
              @contacts = $c->srid(); 
           } else {
               @contacts = $c;
           }
           foreach my $srid (@contacts) { 
               push @e, [ 'no-ext-host:contact', $srid ]; 
           }
       }
       $r = $mes->command_extension( $eid, \@e );
    }

    # Add facet if any is set
    if (exists($rd->{facets}) && defined($rd->{facets})) {
       $r = facet( $epp, $ho, $rd );
    }

    return $r;
}

sub update {
    my ( $epp, $ho, $todo ) = @_;
    my $mes = $epp->message();

    my $ca = $todo->add('contact');
    my $cd = $todo->del('contact');
    my $fs = $todo->set('facets');

    return unless ( $ca || $cd || $fs);    # No updates asked

    my $r;

    if ( $ca || $cd ) {
       my $eid = build_command_extension( $mes, $epp, 'no-ext-host:update' );

       my ( @n, @e, $c, $srid );

       if ( defined($ca) && $ca ) {
       $c = $ca;
       if ( ref($c) eq 'ARRAY' ) {
           foreach my $cn (@$c) {
               if (Net::DRI::Util::isa_contact($cn)) 
               {
                   $srid = $cn->srid(); 
               } else {
                   $srid = $cn;
       }
               push @e, [ 'no-ext-host:contact', $srid ]; 
           }
       } else {
           # $c may be a contact set, contact object or a direct scalar
           my @contacts;
           if (Net::DRI::Util::isa_contactset($c)) { 
              foreach my $cn (keys %{ $$c{'c'} } ) { 
                   push @contacts, ${$$c{'c'}}{$cn}->[0]->srid(); 
               }
           } elsif (Net::DRI::Util::isa_contact($c)) { 
              @contacts = $c->srid(); 
           } else {
               @contacts = $c;
           }
           foreach my $srid (@contacts) { 
               push @e, [ 'no-ext-host:contact', $srid ]; 
           }
       }

          push @n, [ 'no-ext-host:add', @e ] if ( @e > 0 ); 
      }
      @e = undef;
       if ( defined($cd) && $cd ) {

       $c = $cd;
       if ( ref($c) eq 'ARRAY' ) {
           foreach my $cn (@$c) {
               if (Net::DRI::Util::isa_contact($cn)) 
               {
                   $srid = $cn->srid(); 
               } else {
                   $srid = $cn;
               }
               push @e, [ 'no-ext-host:contact', $srid ]; 
           }
       } else {
           # $c may be a contact set, contact object or a direct scalar
           my @contacts;
           if (Net::DRI::Util::isa_contactset($c)) { 
              foreach my $cn (keys %{ $$c{'c'} } ) { 
                   push @contacts, ${$$c{'c'}}{$cn}->[0]->srid(); 
               }
           } elsif (Net::DRI::Util::isa_contact($c)) { 
              @contacts = $c->srid(); 
           } else {
               @contacts = $c;
           }
           foreach my $srid (@contacts) { 
               push @e, [ 'no-ext-host:contact', $srid ]; 
           }
       }
          push @n, [ 'no-ext-host:rem', @e ] if ( @e > 0 );
       }
       $r = $mes->command_extension( $eid, \@n );
    }

    # Add facet if any is set
    if ($fs) {
       my $rd;
       $rd->{facets} = $fs;
       $r = facet( $epp, $ho, $rd );
    }
    return $r;
}

####################################################################################################
1;
