## Domain Registry Interface, Handling of contact data for .NO
##
## Copyright (c) 2008-2011,2014 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
##                    Trond Haugen E<lt>info@norid.noE<gt>.
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
###############################################################################

package Net::DRI::Data::Contact::NO;

use utf8;
use strict;
use warnings;
use base qw/Net::DRI::Data::Contact/;
use Email::Valid;
use Net::DRI::Util;
use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(type identity mobilephone organization rolecontact xemail xdisclose facets));

=pod

=encoding utf8

=head1 NAME

Net::DRI::Data::Contact::NO - Handle .NO contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.NO specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return 
the object itself.

=head2 type()

Mandatory, must be set for all contacts. Specify what type of contact to 
register. Value must be one of: 'person', 'organization' or 'role'.

Example: $co->type('organization')

=head2 identity()

Currently valid for type='organization' only.
Must then be set to specify the organization number in Brønnøysund,
the Norwegian Business Register.

Example: $co->identity({type=>'organizationNumber', value=>'987654321'});

=head2 mobilephone()

Optional. Set a mobile phone number for the contact.

Example: $co->mobilephone('+47.123456780')

=head2 organization()

Optional. Set one or more organization-elements which specify organizations 
which the contact belongs to. The value should be the local contact id 
of an organization object.

This element can only be used for role and person contacts.

$co->organization('EFA12O');

=head2 rolecontact()

Optional. Set one or more roleContact-elements which specify persons which 
belongs to a role contact. The value should be the local contact id of a 
person object.

This element can only be used for role contacts.

Example: $co->rolecontact(['JD12P', 'JD13P']);

=head2 xemail()

Optional. Set one or more email-elements which specify email addresses in 
addition to the mandatory email element in the standard contact create command.

Example: $co->xemail(['xtra1@example.no', 'xtra2@example.no']);

=head2 xdisclose()

Optional. A disclose-element which must contain the child element mobilePhone. 
This element notes the clients preference to allow or restrict disclosure of 
the mobile phone number. If not present, the servers stated data collection 
policy is used.

Example: $co->xdisclose({mobilePhone=>0});

=head2 facets()
Facets are some special control attributes that can be used to
implement a super registrar (admin registrar).

A super registrar can suppress certain checks and perform actions on behalf of a normal registrar.

Facets are key/values pairs.
Net::DRI will not try to enforce what key/value pairs that are possible,
but let the registry decide their validity.

Example: $co->facets( { 'skip-manual-review' => 1, 'ignores-exceptions' => 'reg123'} );


=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Trond Haugen, E<lt>info@norid.noE<gt>.

=head1 COPYRIGHT

Copyright (c) 2008-2010,2014 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
Trond Haugen E<lt>info@norid.noE<gt>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub validate {
    my ( $self, $change ) = @_;
    $change ||= 0;

    my @errs;

    if ( !$change ) {
        Net::DRI::Exception::usererr_insufficient_parameters(
            'Invalid contact information: name/city/cc/email/auth/srid mandatory'
            )
            unless $self->name()
            && $self->city()
            && $self->cc()
            && $self->email()
            && $self->auth()
            && $self->srid();
        Net::DRI::Exception::usererr_insufficient_parameters(
            'Invalid contact information: org is not allowed for .NO')
            if ( $self->org() );
        Net::DRI::Exception::usererr_insufficient_parameters(
            'Invalid contact information: type mandatory')
            unless ( $self->type() );
    }

    push @errs,'srid' if ($self->srid() && ! Net::DRI::Util::xml_is_token($self->srid(),3,16));
    push @errs, 'name'
        if ( $self->name()
        && grep { !Net::DRI::Util::xml_is_normalizedstring( $_, 1, 255 ) }
        ( $self->name() ) );
    push @errs, 'org'
        if ( $self->org()
        && grep { !Net::DRI::Util::xml_is_normalizedstring( $_, undef, 255 ) }
        ( $self->org() ) );

    my @rs = ( $self->street() );

    foreach my $i ( 0, 1 ) {
        next unless $rs[$i];
        push @errs, 'street'
            if (
            ( ref( $rs[$i] ) ne 'ARRAY' ) || ( @{ $rs[$i] } > 3 ) || (
                grep {
                    !Net::DRI::Util::xml_is_normalizedstring( $_, undef, 255 )
                } @{ $rs[$i] }
            )
            );
    }

    push @errs, 'city'
        if ( $self->city()
        && grep { !Net::DRI::Util::xml_is_normalizedstring( $_, 1, 255 ) }
        ( $self->city() ) );
    push @errs, 'sp'
        if ( $self->sp()
        && grep { !Net::DRI::Util::xml_is_normalizedstring( $_, undef, 255 ) }
        ( $self->sp() ) );
    push @errs, 'pc'
        if ( $self->pc()
        && grep { !Net::DRI::Util::xml_is_token( $_, undef, 16 ) }
        ( $self->pc() ) );
    push @errs, 'cc'
        if ( $self->cc() && grep { !Net::DRI::Util::xml_is_token( $_, 2, 2 ) }
        ( $self->cc() ) );
    push @errs, 'cc'
        if ( $self->cc()
        && grep { !exists( $Net::DRI::Util::CCA2{ uc($_) } ) }
        ( $self->cc() ) );

    push @errs, 'voice'
        if ( $self->voice()
        && !Net::DRI::Util::xml_is_token( $self->voice(), undef, 17 )
        && $self->voice() !~ m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/mx );
    push @errs, 'fax'
        if ( $self->fax()
        && !Net::DRI::Util::xml_is_token( $self->fax(), undef, 17 )
        && $self->fax() !~ m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/mx );
    push @errs, 'email'
        if (
        $self->email()
        && !(
            Net::DRI::Util::xml_is_token( $self->email(), 1, undef )
            && Email::Valid->rfc822( $self->email() )
        )
        );

    my $ra = $self->auth();
    push @errs, 'auth'
        if ( $ra
        && ( ref($ra) eq 'HASH' )
        && exists( $ra->{pw} )
        && !Net::DRI::Util::xml_is_normalizedstring( $ra->{pw} ) );

    # .NO
    my $t = $self->type();
    push @errs, 'type' if ( $t && $t !~ m/^(?:person|organization|role)$/mx );

    $t = $self->identity();

    if ($t) {
        my $ty = $t->{type};
        my $va = $t->{value};
        push @errs, 'identity type'
            if ( $ty
            && $ty
            !~ m/^(?:organizationNumber|localIdentity|nationalIdentityNumber|anonymousPersonIdentifier)$/mx
            );

        # let the server handle further validation of what identity syntax
        # and values are legal
    }
    $t = $self->mobilephone();
    push @errs, 'mobilephone'
        if ( $t
        && !Net::DRI::Util::xml_is_token( $t, undef, 17 )
        && $t !~ m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/mx );

    #
    foreach my $el ( 'organization', 'rolecontact', 'xemail' ) {
        if ( $t = $self->$el() ) {    # option, as scalar or array
            my @em;
            my $er;

            if ($change) {
                if ( ref($t) eq 'HASH' ) {
                    foreach my $s ( 'add', 'del' ) {
                        my $e = $t->{$s};
                        if ( ref($e) eq 'ARRAY' ) {
                            push @em, @$e if (@$e);
                        } else {
                            push @em, $e if ($e);
                        }
                    }
                } else {
                    $er .= ":update needs an add/del hash:";
                }
            } else {
                if ( ref($t) eq 'ARRAY' ) {
                    push @em, @$t if (@$t);
                } else {
                    push @em, $t if ($t);
                }
            }
            foreach my $e (@em) {
                if ( $el eq 'xemail' ) {
                    $er .= " $e "
                        if (
                        $e
                        && !(
                            Net::DRI::Util::xml_is_token( $e, 1, undef )
                            && Email::Valid->rfc822($e)
                        )
                        );
                } else {
                    $er .= " $e "
                        if ( $e
                        && !Net::DRI::Util::xml_is_token( $e, 3, 16 ) );
                }
                push @errs, "$el:$er" if ($er);
            }
        }
    }

    ## Check that xdisclose only contains mobilePhone
    if ( my $d = $self->xdisclose() ) {
        unless ( $d
            && ( ref($d) eq 'HASH' )
            && ( scalar( keys(%$d) ) == 1 )
            && ( $d->{mobilePhone} == 1 || $d->{mobilePhone} == 0 ) )
        {
            push @errs, 'xdisclose';
        }
    }
    Net::DRI::Exception::usererr_invalid_parameters(
        'Invalid contact information: ' . join( '/', @errs ) )
        if @errs;
    return 1;    ## everything ok.
}

sub init {
    my ( $self, $what, $ndr ) = @_;

    if ( $what eq 'create' ) {
        my $a = $self->auth();
        $self->auth( { pw => '' } )
            unless ( $a && ( ref($a) eq 'HASH' ) && exists( $a->{pw} ) )
            ;    ## Mandatory in EPP
        $self->srid('auto')
            unless defined( $self->srid() );    ## we can not choose the ID
    }
    return;
}

####################################################################################################
1;
