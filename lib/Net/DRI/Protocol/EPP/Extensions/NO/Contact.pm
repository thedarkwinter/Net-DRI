## Domain Registry Interface, .NO Contact extensions
##
## Copyright (c) 2008,2010 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
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

package Net::DRI::Protocol::EPP::Extensions::NO::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Protocol::EPP::Extensions::NO::Host;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NO::Contact - .NO Contact Extensions for Net::DRI

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

Copyright (c) 2008,2010 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
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
        check  => [ \&facet,  undef ],
        info   => [ \&facet,  \&parse_info ],
       delete => [ \&facet,  undef ],
        create => [ \&create, undef ],
        update => [ \&update, undef ],

    );

    return { 'contact' => \%tmp };
}

####################################################################################################
# parsing by XML::LibXML::Element methods

sub parse_xdisclose {
    my $c = shift;

    my $flag = Net::DRI::Util::xml_parse_boolean( $c->getAttribute('flag') );

    my %tmp;
    my $n = $c->getFirstChild();
    while ($n) {
        next unless ( $n->nodeType() == 1 );
        my $name = $n->localname() || $n->nodeName();
        next unless $name;
        if ( $name =~ m/^(mobilePhone)$/mx ) {
            $tmp{$1} = $flag;
        }
    } continue {
        $n = $n->getNextSibling();
    }
    return \%tmp;
}

sub parse_info {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();
    return unless $mes->is_success();

    my $NS = $mes->ns('no_contact');

    my $c = $rinfo->{contact}->{$oname}->{self};

# This method is called also on a message_retrieve, so make sure we have a contact info
# before checking the email value.
    $c->email(undef)
        if ( $otype eq 'contact'
        && $oaction    eq 'info'
        && $c->email() eq 'n/a' );

    my $condata = $mes->get_extension('no_contact','infData');
    return unless $condata;

    # type
    my $el = $condata->getElementsByTagNameNS( $NS, 'type' )
        ;    # XML::LibXML::NodeList back
    my $type = $el ? $el->get_node(1)->getFirstChild()->getData() : undef;
    $c->type($type) if ( defined($type) && $type );
    $rinfo->{contact}->{$oname}->{type} = $c->type();

    # identity, type and value
    my @e = $condata->getElementsByTagNameNS( $NS, 'identity' );
    if ( @e && $e[0] ) {
        my $t  = $e[0];
        my $tv = $t->getAttribute('type');
        $c->identity(
            { type => $tv, value => $t->getFirstChild()->getData() } );
        $rinfo->{contact}->{$oname}->{identity} = $c->identity();
    }

    # mobilePhone
    @e = $condata->getElementsByTagNameNS( $NS, 'mobilePhone' );
    if ( @e && $e[0] ) {
        $c->mobilephone(
            Net::DRI::Protocol::EPP::Util::parse_tel( $e[0] ) );
        $rinfo->{contact}->{$oname}->{identity} = $c->mobilephone();
    }

    ############
    my @ema;
    foreach my $el ( $condata->getElementsByTagNameNS( $NS, 'email' ) ) {
        my $c = $el->getFirstChild();

        my $v;
        $v = $c->getData() if ($c);
        push @ema, $v if ($v);
    }
    if ( @ema > 0 ) {
        $c->xemail( \@ema );
        $rinfo->{contact}->{$oname}->{xemail} = $c->xemail();
    }

    # organization
    my @oa;
    foreach my $el ( $condata->getElementsByTagNameNS( $NS, 'organization' ) )
    {
        my $c = $el->getFirstChild();
        my $v;
        $v = $c->getData() if ($c);
        push @oa, $v if ($v);
    }
    if ( @oa > 0 ) {
        $c->organization( \@oa );
        $rinfo->{contact}->{$oname}->{organization} = $c->organization();
    }

    # roleContact
    my @rca;
    foreach my $el ( $condata->getElementsByTagNameNS( $NS, 'roleContact' ) )
    {
        my $c = $el->getFirstChild();
        my $v;
        $v = $c->getData() if ($c);
        push @rca, $v if ($v);
    }
    if ( @rca > 0 ) {
        $c->rolecontact( \@rca );
        $rinfo->{contact}->{$oname}->{rolecontact} = $c->rolecontact();
    }

    ########
    # xtra, disclose flag for mobilephone
    @e = ();
    @e = $condata->getElementsByTagNameNS( $NS, 'disclose' );
    if ( @e && $e[0] ) {
        my $t = $e[0];
        $c->xdisclose( parse_xdisclose($t) );
        $rinfo->{contact}->{$oname}->{xdisclose} = $c->xdisclose();
    }
    return;
}

sub facet {
    my ( $epp, $o, $rd ) = @_;

    return Net::DRI::Protocol::EPP::Extensions::NO::Host::build_facets( $epp, $rd );
}

sub build_command_extension {
    my ( $mes, $epp, $tag ) = @_;

    return $mes->command_extension_register(
        $tag,
        sprintf(
            'xmlns:no-ext-contact="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('no_contact')
        )
    );
}

sub add_no_extensions {
    my ( $epp, $contact, $op ) = @_;
    my $mes = $epp->message();

    my $ty  = $contact->type();
    my $id  = $contact->identity();
    my $mp  = $contact->mobilephone();
    my $org = $contact->organization();
    my $rc  = $contact->rolecontact();
    my $aem = $contact->xemail();
    my $xd  = $contact->xdisclose();
    my $fs  = $contact->facets();

    return
        unless ( defined($ty)
        || defined($id)
        || defined($mp)
        || defined($org)
        || defined($rc)
        || defined($aem)
       || defined($fs)
       );


    my $eid = build_command_extension( $mes, $epp, 'no-ext-contact:' . $op );
    my @e;

    push @e, [ 'no-ext-contact:type', $ty ] if ( defined($ty) && $ty );

    # Add identity extension if present.
    if (   defined($id) && ($id) 
        && ( ref($id) eq 'HASH' )
        && exists( $id->{type} )
        && exists( $id->{value} ) )
    {
        push @e,
            [
            'no-ext-contact:identity', { type => $id->{type} },
            $id->{value}
            ];
    }

    #mobile is an e164 number
    push @e,
        Net::DRI::Protocol::EPP::Util::build_tel(
        'no-ext-contact:mobilePhone', $mp )
        if defined($mp);

    # email
    if ( defined($aem) && $aem ) {
	if (ref($aem) eq 'ARRAY' ) {
	    foreach my $c (@$aem) {
		push @e, [ 'no-ext-contact:email', $c ];
	    }
	} else {
	    
	    # scalar
	    push @e, [ 'no-ext-contact:email', $aem ];
	}
    }

    #organization is a clID
    if ( defined($org) && $org ) {
	if ( ref($org) eq 'ARRAY' ) {
	    foreach my $c (@$org) {
		push @e, [ 'no-ext-contact:organization', $c ];
	    }
	} else {

	    # scalar
	    push @e, [ 'no-ext-contact:organization', $org ];

	}
    }

    #roleContact is a clID
    if ( defined($rc) && $rc ) {
	if ( ref($rc) eq 'ARRAY' ) {
	    foreach my $c (@$rc) {
		push @e, [ 'no-ext-contact:roleContact', $c ];
	    }
	} else {
	    
	    # scalar
	    push @e, [ 'no-ext-contact:roleContact', $rc ];
	    
	}
    }

    # xdisclose
    if ( defined ($xd) && $xd && (ref($xd) eq 'HASH') && exists( $xd->{mobilePhone} ) ) {
	my @d;
	my %v = map { $_ => 1 } values(%$xd);
	if (keys(%v) == 1) {
	    ## 1 or 0 as values, not both at same time
	    push @d, ['no-ext-contact:mobilePhone'];

	    push @e,
            [ 'no-ext-contact:disclose', @d, { flag => ( keys(%v) )[0] } ];
	}
    }
    my $r = $mes->command_extension( $eid, \@e );

    # Add facet if any is set
    if ($fs) {
       my $rd;
       $rd->{facets} = $fs;
       $r = facet($epp, $contact, $rd);
    }

    return $r;
}

sub create {
    my ( $epp, $contact ) = @_;
    return add_no_extensions( $epp, $contact, 'create' );
}

sub update {
    my ( $epp, $co, $todo ) = @_;
    my $mes = $epp->message();

    my $r;
    my $mp = $todo->set('mobilephone');
    my $id = $todo->set('identity');
    my $xd = $todo->set('xdisclose');
    my $fs = $todo->set('facets');

    my $orgtoadd = $todo->add('organization');
    my $orgtodel = $todo->del('organization');

    my $rctoadd = $todo->add('rolecontact');
    my $rctodel = $todo->del('rolecontact');

    my $xetoadd = $todo->add('xemail');
    my $xetodel = $todo->del('xemail');

    return unless ( defined($mp)
                   || $id
                   || $orgtoadd
                   || $orgtodel
                   || $rctoadd
                   || $rctodel
                   || $xetoadd
                   || $xetodel
                   || $xd
                   || $fs);

    if ( defined($mp)
        || $id
        || $orgtoadd
        || $orgtodel
        || $rctoadd
        || $rctodel
        || $xetoadd
        || $xetodel
        || $xd) {

       my $eid = build_command_extension( $mes, $epp, 'no-ext-contact:update' );

       my ( @n, @s );

       if ( defined($mp) ) {
           push @s,
            Net::DRI::Protocol::EPP::Util::build_tel(
               'no-ext-contact:mobilePhone', $mp );
       }
       if (   defined($id)
              && ( ref($id) eq 'HASH' )
              && exists( $id->{type} )
              && exists( $id->{value} ) )
       {
           push @s,
            [
            'no-ext-contact:identity', { type => $id->{type} },
            $id->{value}
            ];
       }

       # xdisclose
       if ( ref($xd) && $xd ) {
           my @d;
           my %v = map { $_ => 1 } values(%$xd);
           push @d, ['no-ext-contact:mobilePhone']
               if exists( $xd->{mobilePhone} );
           push @s,
            [ 'no-ext-contact:disclose', @d, { flag => ( keys(%v) )[0] } ];
       }
       push @n, [ 'no-ext-contact:chg', @s ] if ( @s > 0 );

       @s = undef;
       if (   ( defined($orgtoadd) || defined($rctoadd) || defined($xetoadd) )
              && ( $rctoadd || $orgtoadd || $xetoadd ) )
       {
           push @s,
            map { [ 'no-ext-contact:email', $_ ] }
            ( ref($xetoadd) eq 'ARRAY' ) ? @$xetoadd : ($xetoadd)
               if ($xetoadd);
           push @s,
            map { [ 'no-ext-contact:organization', $_ ] }
            ( ref($orgtoadd) eq 'ARRAY' ) ? @$orgtoadd : ($orgtoadd)
               if ($orgtoadd);
           push @s,
            map { [ 'no-ext-contact:roleContact', $_ ] }
            ( ref($rctoadd) eq 'ARRAY' ) ? @$rctoadd : ($rctoadd)
               if ($rctoadd);
           push @n, [ 'no-ext-contact:add', @s ] if ( @s > 0 );
       }
       @s = undef;
       if (   defined($orgtodel)
              || defined( $rctodel || defined($xetoadd) )
              && ( $rctodel || $orgtodel || $xetodel ) )
       {
           push @s,
            map { [ 'no-ext-contact:email', $_ ] }
            ( ref($xetodel) eq 'ARRAY' ) ? @$xetodel : ($xetodel)
               if ($xetodel);
           push @s,
            map { [ 'no-ext-contact:organization', $_ ] }
            ( ref($orgtodel) eq 'ARRAY' ) ? @$orgtodel : ($orgtodel)
               if ($orgtodel);
           push @s,
            map { [ 'no-ext-contact:roleContact', $_ ] }
            ( ref($rctodel) eq 'ARRAY' ) ? @$rctodel : ($rctodel)
               if ($rctodel);
           push @n, [ 'no-ext-contact:rem', @s ] if ( @s > 0 );
       }
       $r = $mes->command_extension( $eid, \@n );
    }

    if ($fs) {
       my $rd;
       $rd->{facets} = $fs;
       $r = facet($epp, $co, $rd);
       
    }
    return $r;
}

####################################################################################################
1;
