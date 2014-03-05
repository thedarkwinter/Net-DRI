## Domain Registry Interface, .NO Result extension
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

package Net::DRI::Protocol::EPP::Extensions::NO::Result;

use strict;
use warnings;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NO::Result - .NO Result Condition EPP Mapping for Net::DRI

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
Trond Haugen, E<lt>info@norid.noE<gt>
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

        check            => [ undef, \&condition_parse ],
        info             => [ undef, \&condition_parse ],
        create           => [ undef, \&condition_parse ],
        delete           => [ undef, \&condition_parse ],
        transfer_request => [ undef, \&condition_parse ],
        transfer_query   => [ undef, \&condition_parse ],
        transfer_cancel  => [ undef, \&condition_parse ],
        transfer_execute => [ undef, \&condition_parse ],
        update           => [ undef, \&condition_parse ],
        renew            => [ undef, \&condition_parse ],
        withdraw         => [ undef, \&condition_parse ],
        nocommand        => [ undef, \&condition_parse ],
    );

    return {
        'domain'  => \%tmp,
        'contact' => \%tmp,
        'host'    => \%tmp,
	'session' => { 'login' => [ undef, \&condition_parse ] },
    };
}

sub condition_parse {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();

    my $condata = $mes->get_extension( 'no_result', 'conditions' );
    return unless $condata;

    parse( $mes, $otype, $oname, $rinfo, $condata );
    return 1;
}

sub parse {
    my ( $mes, $otype, $oname, $rinfo, $node ) = @_;
    my $NS = $mes->ns('no_result');
    my @conditions;

    foreach my $el ( $node->getElementsByTagNameNS( $NS, 'condition' ) ) {
        my %con;
        my $c = $el->getFirstChild();

        $con{code} = $el->getAttribute('code') if $el->getAttribute('code');
        $con{severity} = $el->getAttribute('severity')
            if $el->getAttribute('severity');

        while ($c) {
            my $name = $c->localname() || $c->nodeName();
            next unless $name;
            if ( $name =~ m/^(msg|details)$/mx ) {
                $con{$1} = $c->getFirstChild()->getData();
            } elsif ( $name =~ m/^attributes$/mx ) {
                foreach my $attr ( $c->getChildrenByTagNameNS( $NS, 'attr' ) )
                {
                    my $attrname = $attr->getAttribute('name');
                    $con{ "attr " . $attrname }
                        = $attr->getFirstChild()->getData();
                }
            }
            $c = $c->getNextSibling();
        }
        push @conditions, \%con;
        $mes->add_to_extra_info({from=>'no',type=>'text',message => $con{msg}, %con});
    }

    # Extension results can be returned in all 3 object types
    $rinfo->{$otype}->{$oname}->{conditions} = \@conditions;

    return;
}
##############################################################################
1;
