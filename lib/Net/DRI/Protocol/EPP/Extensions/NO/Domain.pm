## Domain Registry Interface, .NO Domain extensions
##
## Copyright (c) 2008-2010,2013 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
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

package Net::DRI::Protocol::EPP::Extensions::NO::Domain;

use strict;
use warnings;

use Net::DRI::DRD::NO;
use Net::DRI::Protocol::EPP::Core::Domain;
use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Protocol::EPP::Extensions::NO::Host;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NO::Domain - .NO EPP Domain extension commands for Net::DRI

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

Copyright (c) 2008-2010,2013 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
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
       check            => [ \&facet, undef ],
       info             => [ \&facet, \&parse_info ],
        transfer_cancel  => [ \&facet, undef ],
       transfer_query   => [ \&facet, undef ],
       renew            => [ \&facet, undef ],

       create           => [ \&create, undef ],
       update           => [ \&update, undef ],
        delete           => [ \&delete,           undef ],
        transfer_request => [ \&transfer_request, undef ],
        transfer_execute => [
            \&transfer_execute,
            \&Net::DRI::Protocol::EPP::Core::Domain::transfer_parse
        ],
        withdraw         => [ \&withdraw, undef ],
    );
    return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension {
    my ( $mes, $epp, $tag, $no_version ) = @_;

    if ($no_version && $no_version eq "1.1") {
       return $mes->command_extension_register(
           $tag,
           sprintf(
               'xmlns:no-ext-domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('no_domain_1_1')
           )
           );
    } else {

    return $mes->command_extension_register(
        $tag,
        sprintf(
            'xmlns:no-ext-domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('no_domain')
        )
    );
    }
}

sub facet {
    my ( $epp, $o, $rd ) = @_;

    return Net::DRI::Protocol::EPP::Extensions::NO::Host::build_facets( $epp, $rd );
}

sub applicant_dataset {
    my ( $epp, $command, $rd ) = @_;

    my @e;
    my $eid;

    return unless ( $rd && defined($rd->{applicantdataset}) && keys(%{$rd->{applicantdataset}}) );

    return unless ($command eq 'create' || $command eq 'update');

    my $r = $rd->{applicantdataset};

    # Check precense of all mandatory elements.
    # All fields except registrarref are required to have a value.
    foreach my $el ( qw / versionnumber acceptname acceptdate /) {
        unless ( $r->{$el} ) {
            Net::DRI::Exception->die(0,'protocol/EPP',1,"applicantdataset is missing a mandatory element: $el");
        }
    }

    my $versionnumber = $r->{versionnumber};
    my $acceptname    = $r->{acceptname};
    my $acceptdate    = $r->{acceptdate};

    my $mes = $epp->message();

    $eid = build_command_extension( $mes, $epp, 'no-ext-domain:' . $command, '1.1' );

    my @te;
    push @te, [ "no-ext-domain:versionNumber", $versionnumber ];
    push @te, [ "no-ext-domain:acceptName"   , $acceptname ];
    push @te, [ "no-ext-domain:acceptDate"   , $acceptdate ];

    if ($command eq 'create') {
        push @e, [ 'no-ext-domain:applicantDataset', @te ];
    } elsif ($command eq 'update') {
        push @e, [ 'no-ext-domain:chg', [ 'no-ext-domain:applicantDataset', @te ] ];
    }
    return $mes->command_extension( $eid, \@e );
}

sub parse_info {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();
    return unless $mes->is_success();

    my $NS = $mes->ns('no_domain_1_1');

    my $c = $rinfo->{domain}->{$oname}->{self};

    my $adata = $mes->get_extension('no_domain_1_1','infData');

    return unless $adata;

    for my $t ('versionNumber', 'acceptName', 'acceptDate', 'updateClientID', 'updateDate') {
        my $el = $adata->getElementsByTagNameNS( $NS, $t );
        my $v = $el ? $el->get_node(1)->getFirstChild()->getData() : undef;
        # Transform the dates to date objects
        if (defined $v && $v && ($t eq 'acceptDate' || $t eq 'updateDate')) {
            $v = $po->parse_iso8601($v);
        }
        $rinfo->{domain}->{$oname}->{applicantDataset}->{$t} = $v;
    }
    return;
}

sub create {
    my ( $epp, $domain, $rd ) = @_;

    my $fs  = $rd->{facets};
    my $ds  = $rd->{applicantdataset};

    return unless ( defined($fs) && $fs || defined($ds) && $ds );

    my $r;

    if (defined($ds) && $ds) {
        $r = applicant_dataset($epp, 'create', $rd);
    }

    if ($fs) {
        my $rd;
        $rd->{facets} = $fs;
        $r = facet($epp, $domain, $rd);
    }
    return $r;
}


sub update {
    my ( $epp, $domain, $todo ) = @_;

    my $fs = $todo->set('facets');
    my $ds = $todo->set('applicantdataset');

    return unless ( defined($fs) && $fs || defined($ds) && $ds );

    my $r;

    if (defined($ds) && $ds) {
       my $rd;
       $rd->{applicantdataset} = $ds;
       $r = applicant_dataset($epp, 'update', $rd);
    }

    if ($fs) {
    my $rd;
    $rd->{facets} = $fs;
       $r = facet($epp, $domain, $rd);
    }
    return $r;
}


sub delete { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ( $epp, $domain, $rd ) = @_;
    my $mes = $epp->message();

    my $ddate = $rd->{deleteDate};
    my $dfd = $rd->{deletefromdns};
    my $dfr = $rd->{deletefromregistry};
    my $fs  = $rd->{facets};

    return unless ( ( defined($dfd) || defined($dfr) || defined($fs) ) && ( $dfd || $dfr || $fs ) );

    if (defined($dfd) && ref($dfd)) { 
         Net::DRI::Util::check_isa($dfd,'DateTime');
         $dfd = $dfd->set_time_zone('CET')->strftime('%Y-%m-%d'); 
    }
    if (defined($dfr) && ref($dfr)) { 
       Net::DRI::Util::check_isa($dfr,'DateTime'); 
       $dfr = $dfr->set_time_zone('CET')->strftime('%Y-%m-%d'); 
    }
    if (defined($ddate)) {
       if (ref($ddate)) {
         Net::DRI::Util::check_isa($ddate,'DateTime'); 
         $ddate = $ddate->set_time_zone('CET')->strftime('%Y-%m-%d'); 
       }
       $dfd = $ddate if !$dfd;
       $dfr = $ddate if !$dfr;
    }

    my $r;
    if ( $dfd || $dfr ) {
       my $eid = build_command_extension( $mes, $epp, 'no-ext-domain:delete', '1.1' );
       my @e;
       push @e, [ 'no-ext-domain:deleteFromDNS', $dfd ] if ( defined($dfd) && $dfd );
       push @e, [ 'no-ext-domain:deleteFromRegistry', $dfr ] if ( defined($dfr) && $dfr );

       $r = $mes->command_extension( $eid, \@e ) if (@e);
    }
    if ($fs) {
       $r = facet($epp, $domain, $rd);
    }
    return $r;

}


sub transfer_request {
    my ( $epp, $domain, $rd ) = @_;
    my $mes = $epp->message();

    my $mp = $rd->{mobilephone};
    my $em = $rd->{email};
    my $fs = $rd->{facets};

    return unless ( ( defined($mp) || defined($em) || defined($fs) ) && ( $mp || $em || $fs) );

    my $r;
    if ($mp || $em) {
       my $eid = build_command_extension( $mes, $epp, 'no-ext-domain:transfer', '1.1' );

       my @d;
       push @d,
        Net::DRI::Protocol::EPP::Util::build_tel(
           'no-ext-domain:mobilePhone', $mp )
            if ( defined($mp) && $mp );
       push @d, [ 'no-ext-domain:email', $em ] if ( defined($em) && $em );

       my @e;
       push @e, [ 'no-ext-domain:notify', @d ];
       $r = $mes->command_extension( $eid, \@e );

    }
    if ($fs) {
       $r = facet($epp, $domain, $rd);
    }

    return $r;

}


sub withdraw {
    my ( $epp, $domain, $rd ) = @_;
    my $mes = $epp->message();

    my $transaction;
    $transaction = $rd->{transactionname} if $rd->{transactionname};

    my $fs = $rd->{facets};

    return unless ( $transaction && $transaction eq 'withdraw');

    Net::DRI::Exception::usererr_insufficient_parameters(
        'Witdraw command requires a domain name')
        unless ( defined($domain) && $domain );

    my $r;

    my (undef,$NS,$NSX)=$mes->nsattrs('no_domain_1_1');
    my (undef,$ExtNS,$ExtNSX)=$mes->nsattrs('no_epp');

    my $eid = $mes->command_extension_register( 'command',
              'xmlns="' 
            . $ExtNS
            . '" xsi:schemaLocation="'
            . $ExtNS
            . " $ExtNSX"
            . '"' );

    my $cltrid=$mes->cltrid();

    my %domns;
    $domns{'xmlns:domain'}       = $NS;
    $domns{'xsi:schemaLocation'} = $NS . " $NSX";

    $r=$mes->command_extension(
        $eid,
        [   [   'withdraw',
                [   'domain:withdraw', [ 'domain:name', $domain ],
                    \%domns, \%domns
                ]
            ],
            [ 'clTRID', $cltrid ]
        ]
       );

    if ( defined($fs) && $fs ) {
       $r = facet($epp, $domain, $rd);
    }

    return $r;

}

sub transfer_execute {
    my ( $epp, $domain, $rd ) = @_;
    my $mes = $epp->message();

    my $transaction;
    $transaction = $rd->{transactionname} if $rd->{transactionname};

    return unless ( $transaction && $transaction eq 'transfer_execute' );

    my (undef,$NS,$NSX)=$mes->nsattrs('no_domain_1_1');
    my (undef,$ExtNS,$ExtNSX)=$mes->nsattrs('no_epp');

    my ( $auth, $du, $token, $fs );
    $auth  = $rd->{auth}     if Net::DRI::Util::has_key($rd,'auth');
    $du    = $rd->{duration} if Net::DRI::Util::has_key($rd,'duration');
    $token = $rd->{token}    if Net::DRI::Util::has_key($rd,'token');
    $fs    = $rd->{facets}   if Net::DRI::Util::has_key($rd,'facets');

    # Duration is optional
    my $dur;
    if (   defined($du)
        && $du
        && Net::DRI::Util::has_duration( $rd )
        )
    {
        Net::DRI::Util::check_isa( $du, 'DateTime::Duration' );

        Net::DRI::Exception->die( 0, 'DRD::NO', 3, 'Invalid duration' )
            if Net::DRI::DRD::NO->verify_duration_renew(undef, $du, $domain ); ## TODO: this test should be done in Net::DRI::DRD::NO directly !
        $dur = Net::DRI::Protocol::EPP::Util::build_period($du);
    }

    my $eid = $mes->command_extension_register( 'command',
              'xmlns="' 
            . $ExtNS
            . '" xsi:schemaLocation="'
            . $ExtNS
            . " $ExtNSX"
            . '"' );


    my $cltrid=$mes->cltrid();

    my %domns;
    $domns{'xmlns:domain'} = 'urn:ietf:params:xml:ns:domain-1.0';
    $domns{'xsi:schemaLocation'}
        = 'urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd';

    my %domns2;
    $domns2{'xmlns:no-ext-domain'} = $NS;
    $domns2{'xsi:schemaLocation'}  = $NS . " $NSX";

    my $r;

    if ( Net::DRI::Util::has_auth( $rd )
        && ( ref( $rd->{auth} ) eq 'HASH' ) )
    {
        $r=$mes->command_extension(
            $eid,
            [   [   'transfer',
                    { 'op' => 'execute' },
                    [   'domain:transfer',
                        \%domns,
                        [ 'domain:name', $domain ],
                        $dur,
                        Net::DRI::Protocol::EPP::Util::domain_build_authinfo(
                            $epp, $rd->{auth}
                        ),
                    ],
                ],
                [ 'clTRID', $cltrid ]
            ]
        );
    } elsif ($token) {
        $r=$mes->command_extension(
            $eid,
            [   [   'transfer',
                    { 'op' => 'execute' },
                    [   'domain:transfer', \%domns,
                        [ 'domain:name', $domain ], $dur,
                    ],
                ],
                [   'extension',
                    [   'no-ext-domain:transfer', \%domns2,
                        [ 'no-ext-domain:token', $token ]
                    ]
                ],
                [ 'clTRID', $cltrid ]
            ]
        );
   } else {
       $r=$mes->command_extension(
            $eid,
            [   [   'transfer',
                    { 'op' => 'execute' },
                    [   'domain:transfer', \%domns,
                        [ 'domain:name', $domain ], $dur,
                    ],
                ],
                [ 'clTRID', $cltrid ]
            ]
        );
    }

    if ( defined($fs) && $fs ) {
       $r = facet($epp, $domain, $rd);
    }

    return $r;

}

####################################################################################################
1;
