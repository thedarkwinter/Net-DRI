#!/usr/bin/perl
##
## Copyright (c) 2008,2011 .SE, <http://www.iis.se>,
##                    Jan Saell <jan@yask.se>
##                    All rights reserved.
##
## This program illustrate the usage of Net::DRI towards the .SE registry.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
##
##
##
## -----------------
##
## What is this: A Net::DRI based command line client for .SE
##
## Note that it is developed for test purposes, not to be a complete client.
##
## The -p argument is expected to carry a %p parameter hash argument string
## which can be eval'ed into a %p hash, like this for a host create operation:
## -o host -c create -p "%p=(name=>'ns1.suniswanted.no',v4=>'123.234.123.12')"
##
##  See POD section at the end for further details.
##
#######

use strict;
use warnings;

use Net::DRI;
use DateTime::Duration;
use Pod::Usage;
use POSIX qw(locale_h);
use Net::LibIDN ':all';

use Getopt::Std;

use Data::Dumper;
$Data::Dumper::Indent=1;

use encoding "utf-8";    # assume utf-8 encoded argument input

our $VERSION     = '0.90.se';
our $SVN_VERSION = do {
    my @r = ( q$Revision: 1.1 $ =~ /\d+/gxm );
    sprintf( "%d" . ".%02d" x $#r, @r );
};

# Format string for output of results
my $F = " %-15s: %s\n";

# All possible dri object methods
my @drim = ('id');

# All possible contact object methods
my @cm = (

    # standard DRI methods
    'loid', 'srid', 'id', 'roid', 'name',  'org',   'street',
    'city', 'sp',   'pc', 'cc',   'email', 'voice', 'fax',
    'auth', 'disclose',

    # .se extra methods
    'orgno', 'vatno', 'clientDelete',

    # Secdns extensions
    'secdns',
);

# args
use vars qw($opt_c $opt_o $opt_h $opt_p $opt_f $opt_P $opt_S
    $opt_L $opt_C $opt_W $opt_w $opt_F $opt_K);

# Operations
my %op = (
    'hello'            => 1,
    'create'           => 1,
    'update'           => 1,
    'delete'           => 1,
    'info'             => 1,
    'poll'             => 1,
    'check'            => 1,
    'renew'            => 1,
    'transfer'         => 1,

    # message operations
    'waiting'  => 1,
    'count'    => 1,
    'retrieve' => 1,

    # delete op is already defined

);

# Objects
my %obj = (
    'contact'      => 'contact',
    'person'       => 'contact',
    'organization' => 'contact',
    'role'         => 'contact',
    'host'         => 'host',
    'domain'       => 'domain',
    'message'      => 'message',
    'hello'        => 'hello',
);

# Hash to hold the EPP arguments
my %p;

&getopts("Lo:c:p:f:S:P:C:W:F:K:w:");

#server and port must be specified
my $socktype = 'tcp';
die "No server specified"    unless ($opt_S);
die "No port specified"      unless ($opt_P);
die "No client id specified" unless ($opt_C);
die "No password specified"  unless ($opt_W);
die "No client certificate specified"  unless ($opt_F);
die "No certificate password specified"  unless ($opt_w);
die "No command specified" unless ($opt_c);

my $server = $opt_S;
my $port   = $opt_P;
$socktype = 'ssl' if ($opt_L);

my $clid = $opt_C;
my $pass = $opt_W;
my $cert = $opt_F;
my $key  = $opt_K;
my $cpwd = $opt_w;

my $newpass;

unless ( $opt_c && $op{$opt_c} ) {
    pexit("Specify a valid command");
}
if ( $opt_c eq 'hello' ) {
   $opt_o = $opt_c;
} else {
    unless ( $opt_o && $obj{$opt_o} ) {
        pexit("Specify a valid object type");
    }
    unless ($opt_p) {
        pexit("Specify a parameter string");
    }

    #print "p: $opt_p \n";
    unless ( parse_params($opt_p) ) {
        pexit("Specify a valid parameter string");
    }
}

my $t1 = time();

my $logf = 'results-' . time() . '.log';
my $fh;
$logf = $opt_f if ($opt_f);
if ($opt_f) { open( my $fh, '>>', $logf ) || die $!; }

do_epp_operation(
    $obj{$opt_o}, $opt_c,  $clid, $pass, $newpass,
    $socktype,    $server, $port, $fh,   %p
);

my $t2 = time();

print "\nTime used: ", $t2 - $t1, "secs\n";

############
#
#  S U B S
#
###########

sub parse_params {
    my $p = shift;

    eval $opt_p;  # assume a Data::Dumper syntax, read pars with eval!

    if ($@) {

        # eval has failed, $@ tells us why
        pexit(    "Eval failed, specify a valid parameter string, msg: "
                . $@
                . "\n" );
    }
    return 1;
}

sub do_epp_operation {
    my ( $obj, $cmd, $clid, $pw, $newpw, $socktype, $server, $port, $fh, %p )
        = @_;

    my $res = 1;

    select($fh);
    $|++;
    select(STDOUT);

    #print "Dumping XML exchange to $logf\n";

    my ( $dri, $rc );

    eval {
        ( $dri, $rc )
            = init_reg_se( $clid, $pw, $newpw, $socktype, $server, $port,
            $fh );
        do_command( $obj, $cmd, $dri, $rc, %p );
    };
    if ($@) {
        print "\n\nAn EXCEPTION happened !\n";
        if ( ref($@) ) {
            print "FAILURE: Error descriptions: ", ref($@), "\n";
            $@->print();
            print "\n";
            dump_conditions($dri);
        } else {
            print "FAILURE: No extra info: ";
            print($@);
        }
        $res = 0;
    } else {
        print "\n\nSUCCESS";
    }
    print "\n";

    # Important not to call dri->end too early, because condition date may be
    # destroyed.
    $dri->end();
    close($fh);
    return $res;
}

sub pexit {
    print shift, "\n\n";    # The error text supplied
    pod2usage(
        {   -message => $0,
            -exitval => 0
        }
    );
    return;
}

sub print_result {
    my $dri = shift;
    my $rc  = shift;

    print "\n", " result_code    : ", $dri->result_code(), "\n",
        " native_code    : ", $dri->result_native_code(), "\n",
        " result_message : ", $dri->result_message(),     "\n",
        " language       : ", $dri->result_lang(),        "\n\n";

    if ( $dri->can('result_is_pending') ) {
        print " pending  : ", $dri->result_is_pending(), "\n";
    }
    if ( $dri->can('result_info') ) {
        print "info : ", $dri->result_info(), "\n";
    }
    if ( $dri->can('result_print') ) {
        print "result_print: ", $dri->result_print(), "\n";
    }
    if ( $dri->can('result_print_full') ) {
        print "result_print_full: ", $dri->result_print_full(), "\n";
    }
    if ($rc) {
        print_rc_result($rc);
    }
    foreach my $w (
        'action', 'exist', 'trStatus', 'reID',
        'reDate', 'acID',  'acDate',   'exDate'
        )
    {
        if ( my $v = $dri->get_info($w) ) {
            printf "$F", $w, $v;
        }
    }
    return 1;
}

sub print_rc_result {
    my $rc = shift;

    # Print rc-specific info, not found in $dri->result_*()

    if ( $rc->can('is_pending') ) {
        print "rcpending : ", $rc->is_pending(), "\n"
            if ( $rc->is_pending() );
    }
    if ( $rc->can('info') ) {
        print "rcinfo : ", $rc->info(), "\n" if ( $rc->info() );
    }

    my $F2 = " %-15s: %s%s\n";
    if ( $rc->can('trid') && $rc->trid() ) {

        # trid seems to be returned as an array with two values
        printf "$F2", 'trid', $rc->trid();
    }
    return 1;
}

sub contact_object_as_string {
    my ( $dri, $o, @om ) = @_;

    return unless $o;

    # Populate the loc-array values
    # $ci->int2loc();  # hmm, if int2loc is called, it overwrites the
    # localized data and destroys some of it

    my $s = "";

    foreach my $m (@om) {
        my $r;

        if ( $o->can($m) ) {
            if ( $m eq 'street' ) {

                # Is an array up to 3 elements
                $r = join ", ", @{ $o->$m };

            } elsif ( $m eq 'identity' ) {
                $r = "type  : " . $o->$m->{type}
                    if ( $o->$m && $o->$m->{type} );
                $r .= ", value: " . $o->$m->{value}
                    if ( $o->$m && $o->$m->{value} );

            } elsif ( $m eq 'xemail' || $m eq 'rolecontact' ) {

                # Is an array up to n elements
                $r = join ", ", @{ $o->$m } if ( $o->$m );
            } else {
                my @va;
                @va = $o->$m if ( $o->$m );
                foreach my $v (@va) {
                    if ( ref($v) && ( ref($v) ne 'SCALAR' ) ) {

                        # don't bother diving into it ... use a Dumper
                        $r .= sprintf Dumper $v;
                    } else {
                        $r .= $v if ($v);
                    }
                }
            }
            $s .= sprintf "$F", $m, $r if ($r);
        } else {
            $s .= "-- method $m not possible \n";
        }
    }
    foreach my $i ( 'roid', 'crDate', 'upDate', 'clID', 'crID', 'upID' ) {
        my $v = $dri->get_info($i);
        $v = '-' unless $v;
        $s .= sprintf "$F", $i, $v;
    }
    return $s;
}

sub host_object_as_string {
    my ($dri) = @_;

    my $s  = "";
    my $hi = $dri->get_info('self');

    foreach my $m ( 'loid', 'count' ) {
        my $v = '-';
        $v = $hi->$m if ( $hi->$m );
        $s .= sprintf "$F", $m, $v;
    }
    my @nms = $hi->get_names();
    $s .= sprintf "$F", 'names', @nms;

    foreach my $n (@nms) {
        my @d = $hi->get_details($n);

        # ip-addresses are optional
        my @v;
        @v = @{ $d[1] } if ( @{ $d[1] } );
        @v = ("-") unless (@v);
        $s .= sprintf "$F", 'v4 addresses', join( ", ", @v );

        @v = ();
        @v = @{ $d[2] } if ( @{ $d[2] } );
        @v = ("-") unless (@v);
        $s .= sprintf "$F", 'v6 addresses', join( ", ", @v );
    }

    # contact is a scalar

    my $ct = "-";
    if ( $ct = $dri->get_info('contact') ) {
        $s .= sprintf "$F", 'contact', $ct;
    }
    foreach my $i (
        'roid',   'exDate', 'crDate', 'upDate',
        'trDate', 'clID',   'crID',   'upID'
        )
    {
        my $v = $dri->get_info($i);
        $v = '-' unless $v;
        $s .= sprintf "$F", $i, $v;
    }
    return $s;
}

#You may use get_info with the following keys to get more information:
# - ns : a Net::DRI::Data::Hosts object representing the nameservers of the
#        domain
# - status : a Net::DRI::Data::StatusList object representing the current
#        status list of the domain queried
# - exDate, crDate, upDate, trDate : DateTime objects representing the
#        expiration, creation, last update, and transfer date for the domain
#        queried
# - clID, crID, upID : (strings) local registry ID of the current sponsoring
#        registrar, the registrar having created, and the registrar (or
#        registry) having last modified the domain queried

sub domain_object_as_string {
    my ($dri) = @_;

    my $s = "";

    ##
    # authInfo
    #
    $s .= sprintf "--- Auth info ---\n";
    my $au = $dri->get_info('auth');

    foreach my $i (
        'name', 'roid', 'exDate', 'crDate', 'upDate', 'trDate', 'delDate', 'deactDate',
        'clID', 'crID', 'upID',
        )
    {
        my $v = $dri->get_info($i);
        $v = '-' unless $v;
        $s .= sprintf "$F", $i, $v;
        if ( $i eq 'name' ) {

            # Also print the UTF-8 of an ACE
            my $idn
                = idn_to_unicode( $v, 'utf-8', IDNA_USE_STD3_ASCII_RULES );
            $s .= sprintf "$F", 'IDN-name', $idn;
        }

    }
    ##
    # name servers
    #
    my $v;
    my $ns = $dri->get_info('ns');
    if (defined ($ns) ) {
	    $s .= sprintf "--- Name servers ---\n";

	    $v = '-';
	    if ( ( $v = $ns->count() ) > 0 ) {
		$s .= sprintf "$F", 'ns count', $v;
	    }
	    foreach my $n ( $ns->get_names() ) {
		$s .= sprintf "$F", 'ns name', $n;
	    }
    }

    ####################
    # Contacts
    #
    # contact is an array ref.
    my $co = $dri->get_info('contact');

    $s .= sprintf "--- Contacts ---\n";

    foreach my $ct ( 'registrant', 'admin', 'tech' ) {
        my @r = $co->get($ct);
        my $v = "-";
        foreach my $r (@r) {
            $v = $r->srid if ( $r->srid );
            $s .= sprintf "$F", $ct, $v;
        }
    }

    ##
    # SecDNS
    #
    my $secdns = $dri->get_info('secdns');
    if (defined ($secdns) ) {
	    $s .= sprintf "--- Secure DNS ---\n";
	    my $count = scalar(@$secdns);
	    if ($count > 0) {
		$s .= sprintf "$F", 'SecDNS Key count', $count;

	    my $i = 0;
	    while ($i < $count) {
		my $n = $secdns->[$i];
		$s .= sprintf "$F", 'SecDNS keyTag', $n->{keyTag};
		$s .= sprintf "$F", '  digestType', $n->{digestType};
		$s .= sprintf "$F", '  alg', $n->{alg};
		$s .= sprintf "$F", '  digest', $n->{digest};
		$i++;
	    }
	    }

    }

    ####################
    # Domain status
    #
    $s .= sprintf "--- Status summary ---\n";

    my $st = $dri->get_info('status');

    # domain status methods
    my @dsm = (
        'is_active',
        'is_published',
        'is_pending',
        'is_linked',
        'can_update',
        'can_transfer',
        'can_delete',
        'can_renew',

        #'possible_no',    # hmmm.. what's this for?
        #'no'              # hmmm.. what's this for?

    );
    foreach my $ds (@dsm) {
        $v = "-";
        $v = $st->$ds if ( $st->$ds );
        $s .= sprintf "$F", $ds, $v;
    }

    ####
    # also dump all the detailed status values
    my @ls = $st->list_status();

    $s .= sprintf "--- Flag details ---\n";
    foreach my $l (@ls) {
        $s .= sprintf "$F", 'flag', $l;
    }
    return $s;
}

sub get_info_object_as_string {
    my ( $o, @om ) = @_;

    my $s = "";

    foreach my $m (@om) {
        my $v = "-";

        if ( $o->get_info($m) ) {
            $v = $o->get_info($m);
            if ( $v && ref($v) && ( ref($v) ne 'SCALAR' ) ) {

                # don't bother diving into it ... use a Dumper
                $v = sprintf Dumper $v;
                next;
            }
            $s .= sprintf "$F", $m, $v;
        } else {
            $s .= "-- method $m not possible \n";
        }
    }
    return $s;
}

sub init_reg_se {
    my ( $clid, $pw, $newpw, $socktype, $server, $port, $fh ) = @_;
    my $dri;

    if ($opt_f) {
       $dri = Net::DRI->new(
       {
           cache_ttl => 10,
           logging => ['files',
                       {output_directory => './',
                        output_filename=>$opt_f,
                        level=>'notice',
                        xml_indent=>1}]
       }
       );
    } else {
       $dri = Net::DRI->new(
       {
           cache_ttl => 10,
       }
       );
    }

    $dri->add_registry( 'SE', { clid => $clid } );

    my %pars = (
        defer               => 0,
        socktype            => $socktype,
        remote_host         => $server || 'epptestv3.iis.se',
        remote_port         => $port || 700,
        protocol_connection => 'Net::DRI::Protocol::EPP::Connection',
        protocol_version    => 1,
        client_login        => $clid,
        client_password     => $pw,
        ssl_debug           => 0,
        ssl_passwd_cb       => sub{return $cpwd},
        ssl_key_file        => $key,
        ssl_cert_file       => $cert,
        ssl_version         => 'TLSv1',
        ssl_verify          => 0x00,
    );

    $pars{client_newpassword} = $newpw if ($newpw);

    my $rc = $dri->target('SE')->add_current_profile(
        'profile1', 'epp',
        { %pars, },
    );

    ## Here we catch all errors during setup of transport, such as
    ## authentication errors
    die($rc) unless $rc->is_success();

    return ( $dri, $rc );
}

sub do_command {
    my ( $obj, $cmd, $dri, $rc, %p ) = @_;

    if ( $cmd eq 'hello' ) {
        print "*** hello ***\n";

        # no objects in this case

        $rc = $dri->process( 'session', 'noop', [] );
        die($rc) unless $rc->is_success();    ## Her
        print "Hello was a success\n";
        exit 0;
    }

    print "*** Executing EPP command: $obj . $cmd ***\n";

    if ( $obj eq 'host' ) {
        if ( $cmd eq 'check' ) {
            print ".check ", $p{name}, "\n";
            $rc = $dri->host_check( $p{name} );
            print_result( $dri, $rc );
            die($rc) unless $rc->is_success();

            # For a host check, only an exist check is available in DRI
            print "Host $p{name} ",
                $dri->get_info('exist') ? "exists" : "do not exist";
        }
        if ( $cmd eq 'info' ) {
            my %oi;

            # host info can specify a ownerid
            $oi{ownerid} = $p{ownerid} if ( $p{ownerid} );

            $rc = $dri->host_info( $p{name}, \%oi );
            print_result( $dri, $rc );
            die($rc) unless $rc->is_success();

            print host_object_as_string($dri);
        }
        if ( $cmd eq 'create' ) {

            # DRI 0.85 need to create the hosts objects directly ..
            my $nso = $dri->local_object('hosts');

            $nso->add( $p{name}, $p{v4}, $p{v6} );

            if ( $p{contact} ) {
                $rc = $dri->host_create( $nso, { contact => $p{contact} } );
            } else {
                $rc = $dri->host_create($nso);
            }
            print_result($dri);
            die($rc) unless $rc->is_success();
        }
        if ( $cmd eq 'update' ) {
            ###
            # We can change all params, name, ip-addresses and contact
            # Proper add/del keys must be supplied by the user to do this
            my $toc = $dri->local_object('changes');
            if ( $p{ipset} ) {

                # add and del keys shall describe what to do
                my ( $v4a, $v4d , $v6a, $v6d );
                $v4a = $p{ipset}{add}{v4} if ( $p{ipset}{add}{v4} );
                $v4d = $p{ipset}{del}{v4} if ( $p{ipset}{del}{v4} );
                $v6a = $p{ipset}{add}{v6} if ( $p{ipset}{add}{v6} );
                $v6d = $p{ipset}{del}{v6} if ( $p{ipset}{del}{v6} );
		# Add
		if ($v4a) {
		    if ($v6a) {
			$toc->add( 'ip',
			    $dri->local_object('hosts')->add( $p{name}, $v4a, $v6a ) );
		    } else {
			$toc->add( 'ip',
			    $dri->local_object('hosts')->add( $p{name}, $v4a, [] ) );
		    }
		} else {
		    if ($v6a) {
			$toc->add( 'ip',
			    $dri->local_object('hosts')->add( $p{name}, [], $v6a ) );
		    }
		}
		# Del
		if ($v4d) {
		    if ($v6d) {
			$toc->del( 'ip',
			    $dri->local_object('hosts')->add( $p{name}, $v4d, $v6d ) );
		    } else {
			$toc->del( 'ip',
			    $dri->local_object('hosts')->add( $p{name}, $v4d, [] ) );
		    }
		} else {
		    if ($v6d) {
			$toc->del( 'ip',
			    $dri->local_object('hosts')->add( $p{name}, [], $v6d ) );
		    }
		}
            }

            # Update name if nname is specified
            if ( $p{nname} && $p{nname} ne $p{name} ) {

                # a new name is specified, insert it as a chg
                $toc->set( 'name', $p{nname} );
            }

            #
            # Contact data
            if ( defined( $p{contact} ) ) {

                # add and del keys shall describe what to do
                foreach my $s ( 'add', 'del' ) {
                    my $n = $p{contact}{$s};
                    $toc->$s( 'contact', $n ) if ( defined($n) && $n );
                }
            }
            $rc = $dri->host_update( $p{name}, $toc );
            print_result($dri);
            die($rc) unless $rc->is_success();
        }
        if ( $cmd eq 'delete' ) {
            $rc = $dri->host_delete( $p{name} );
            print_result($dri);
            die($rc) unless $rc->is_success();
        }
    }

    if ( $obj eq 'contact' ) {

        if ( $cmd eq 'check' ) {
            my $co = $dri->local_object('contact')->new()->srid( $p{srid} );

            $rc = $dri->contact_check($co);
            print_result($dri);

            die($rc) unless $rc->is_success();

            print "Contact $p{srid} ",
                $dri->get_info('exist') ? " exists" : "do not exist";
        }

        if ( $cmd eq 'info' ) {
            my $co = $dri->local_object('contact')->new()->srid( $p{srid} );

            $rc = $dri->contact_info($co);

# print "Contact $p{srid} ", $dri->get_info('exist')?" exists":"do not exist";
            print_result($dri);

            die($rc) unless $rc->is_success();

            my $o = $dri->get_info('self');

            print contact_object_as_string( $dri, $o, @cm );
        }

        if ( $cmd eq 'create' ) {
            my $co = $dri->local_object('contact')->new();

            # auth not supported for .NO contact

            foreach my $m (@cm) {

                #next if $m eq 'sp'; # Not supported by .NO today,
                # but better to let server reject in case that changes
                my $v = $p{$m};

                #print STDERR "ref $m: ", ref($p{$m}), "\n";
                $co->$m( $p{$m} ) if ( $p{$m} );
            }
            $rc = $dri->contact_create($co);

            print_result($dri);

            die($rc) unless ( $rc->is_success() );

            #print contact_object_as_string($dri, $co, @cm);

            print get_info_object_as_string( $dri, @drim );
        }

        if ( $cmd eq 'update' ) {
            ###
            # We can change all params, name, ip-addresses and contact
            # Proper add/del keys must be supplied by the user to do this

            #########
            my $co  = $dri->local_object('contact')->srid( $p{srid} );
            my $toc = $dri->local_object('changes');
            my $co2 = $dri->local_object('contact');

            foreach my $m (@cm) {
                $co2->$m( $p{$m} ) if ( $p{$m} );
            }
            $toc->set( 'info', $co2 );

            if ( $p{type} ) {
                $toc->set( 'type', $p{type} );
            }
            if ( $p{mobilephone} ) {
                $toc->set( 'mobilephone', $p{mobilephone} );
            }
            if ( $p{xdisclose} ) {
                $toc->set( 'xdisclose', $p{xdisclose} );
            }
            if ( $p{identity} ) {
                $toc->set( 'identity', $p{identity} );
            }

            #
            # organization data
            #
            if ( $p{organization} ) {

                # add and del keys shall describe what to do
                foreach my $s ( 'add', 'del' ) {
                    my $n = $p{organization}{$s};
                    $toc->$s( 'organization', $n ) if ( defined($n) && $n );
                }
            }

            #
            # RoleContact data
            #
            if ( $p{rolecontact} ) {

                # add and del keys shall describe what to do
                foreach my $s ( 'add', 'del' ) {
                    my $n = $p{rolecontact}{$s};
                    $toc->$s( 'rolecontact', $n ) if ( defined($n) && $n );
                }
            }

            #
            # xemail data
            #
            if ( $p{xemail} ) {

                # add and del keys shall describe what to do
                foreach my $s ( 'add', 'del' ) {
                    my $n = $p{xemail}{$s};
                    $toc->$s( 'xemail', $n ) if ( defined($n) && $n );
                }
            }
            $rc = $dri->contact_update( $co, $toc );

            print_result($dri);
            die($rc) unless $rc->is_success();
        }

        if ( $cmd eq 'delete' ) {
            my $co = $dri->local_object('contact')->new()->srid( $p{srid} );

            $rc = $dri->contact_delete($co);
            print_result($dri);

            die($rc) unless $rc->is_success();

            # Do an info to verify the delete
            print "Verifying delete by an info ....: \n";
            do_command( $obj, 'info', $dri, $rc, %p );
        }
    }

    if ( $obj eq 'domain' ) {
        my ( $ace, $idn );

        # We accept input name as either an ace-name or an utf-8
        if ( $p{name} ) {
            $idn = lc( $p{name} );
            die "Cannot lower case domain name: $idn" unless ($idn);

            $ace = idn_to_ascii( $idn, 'utf-8', IDNA_USE_STD3_ASCII_RULES );
            die "Cannot convert domain to ace" unless ($ace);

            $idn = idn_to_unicode( $ace, 'utf-8', IDNA_USE_STD3_ASCII_RULES );
            die "Cannot convert domain to ace" unless ($ace);

            undef $idn if ( $ace eq $idn );
        } else {
            die "No domain name specified";
        }

        #print "input name: $p{name}\n";
        #print "ace       : $ace\n";
        #print "idn       : $idn\n";

        die "Illegal domain name" unless ($ace);

        if ( $cmd eq 'check' ) {

            $rc = $dri->domain_check($ace);

            print_rc_result($rc);
            print_result($dri);

            die($rc) unless $rc->is_success();

            print "Domain $p{name} ",
                $dri->get_info('exist') ? " exists" : "do not exist";
        }

        if ( $cmd eq 'info' ) {
            $rc = $dri->domain_info($ace);
            print_result($dri);
            die($rc) unless $rc->is_success();

            print domain_object_as_string($dri);
        }

        if ( $cmd eq 'create' ) {

     #
     # A create is supported as follows:
     #   A domain name in 'name'
     #   A contact set in coset=>{billing=>'THO123', admin=>'TH2345P', ...
     #   A name server set in nsset=>{billing=>'THO123', admin=>'TH2345P', ...
     #
            my $cs = $dri->local_object('contactset');

            my $du;
            if ( $p{duration} ) {
                $du = DateTime::Duration->new( $p{duration} );
                die "Illegal duration value" unless ($du);
            }
            $cs->set( $dri->local_object('contact')->srid( $p{registrant} ),
                'registrant' )
                if ( $p{registrant} );

            my $c;
            if ( $c = $p{coset} ) {

   # we have a contact set, DRI accepts multiple of each type, so we implement
## that and let server policy decide if multiple can be accepted

                my @acs;
                my @ca;
                foreach my $t ( 'admin', 'billing', 'tech' ) {
                    if ( $c->{$t} ) {
                        if ( ref( $c->{$t} ) eq 'ARRAY' ) {
                            @ca = @{ $c->{$t} };
                        } else {

                            # A single scalar srid
                            push @ca, $c->{$t};
                        }
                        foreach my $s (@ca) {
                            push @acs,
                                $dri->local_object('contact')->srid($s);
                        }
                        $cs->set( [@acs], $t );
                        undef @ca;
                        undef @acs;
                    }
                }
            }

  # see the DRI README doc.
  #  - domain_create() does a lot of checking and creating if the objects does
  #    not exist when used with pure_create=0,
  #  - domain_create() with pure_create=1 has a simpler behaviour
  #  We use domain_create() with pure_create=1, it's simplest
            my $nso = $dri->local_object('hosts');
            if ( $p{nsset} ) {
                if ( my @ns = @{ $p{nsset} } ) {
                    foreach my $n (@ns) {
                        $nso->add( $n, [], [] );
                    }
                }
            }
            # Secdns
            my @secdnso;
            if ( $p{secdns} ) {
                if ( my @secdns = @{ $p{secdns} } ) {
                  @secdnso = @secdns;
		}
            }
            $rc = $dri->domain_create(
                $ace,
                {   auth     => { pw => $p{pw} },
                    duration => $du,
                    contact  => $cs,
                    ns       => $nso,
                    secdns   => [ @secdnso ],
                    pure_create => 1,
                }
            );
            print_result($dri);
            die($rc) unless ( $rc->is_success() );
        }

        if ( $cmd eq 'update' ) {
            ###
            # We can change most params, but not domain name or duration
            # Proper add/del keys must be supplied by the user to do this

            my $cs  = $dri->local_object('contactset');
            my $toc = $dri->local_object('changes');

            $toc->set( 'registrant',
                $dri->local_object('contact')->srid( $p{registrant} ),
                'registrant' )
                if ( $p{registrant} );

   # Update is the only command where the status flags can be set/changed
   # The flag values to use by the DRI user is the following (from Status.pm):
   #   my %s=('delete'   => 'clientDeleteProhibited',
   #          'renew'    => 'clientRenewProhibited',
   #          'update'   => 'clientUpdateProhibited',
   #          'transfer' => 'clientTransferProhibited',
   #          'publish'  => 'clientHold',
   #       );

            if ( $p{pw} ) {
                $toc->set( 'auth', { pw => $p{pw} } );
            }

            if ( defined( $p{clientDelete} ) && ( ( $p{clientDelete} == 0 ) || ( $p{clientDelete} == 1 ) ) ) {
                $toc->set( 'client_delete', $p{clientDelete} );
            }

            if ( my $s = $p{status} ) {
                foreach my $op ( 'add', 'del' ) {
                    my $sl = $dri->local_object('status');

                    # add and del keys shall describe what to do

                    my $a;
                    $a = $p{status}{$op} if ( $p{status}{$op} );

                    # array or not
                    if ( ref($a) eq 'ARRAY' ) {
                        foreach my $m (@$a) {
                            $sl->no($m);
                        }
                    } else {
                        $sl->no($a);
                    }
                    $toc->$op( 'status', $sl ) or die "Invalid status value";
                }
            }

            if ( my $c = $p{coset} ) {

   # we have a contact set, DRI accepts multiple of each type, so we implement
   # that and let server policy decide if multiple can be accepted

                my @acs;
                my @ca;

                # add and del keys shall describe what to do
                foreach my $op ( 'add', 'del' ) {
                    $cs = $dri->local_object('contactset');
                    foreach my $r ( 'admin', 'billing', 'tech' ) {
                        if ( my $v = $c->{$op}->{$r} ) {

                            if ( ref($v) eq 'ARRAY' ) {
                                @ca = @{$v};
                            } else {

                                # A single scalar srid
                                push @ca, $v;
                            }
                            foreach my $va (@ca) {
                                push @acs,
                                    $dri->local_object('contact')->srid($va);
                            }
                        }
                        $cs->set( [@acs], $r );
                        undef @ca;
                        undef @acs;
                    }
                    $toc->$op( 'contact', $cs );
                    undef $cs;
                }
            }
            if ( $p{nsset} ) {

                foreach my $op ( 'add', 'del' ) {

                    # add and del keys shall describe what to do
                    my $a;
                    $a = $p{nsset}{$op} if ( $p{nsset}{$op} );

                    # array or not
                    if ( ref($a) eq 'ARRAY' ) {
                        foreach my $m (@$a) {
                            $toc->$op( 'ns',
                                $dri->local_object('hosts')->add($m) );
                        }
                    } else {
                        $toc->$op( 'ns',
                            $dri->local_object('hosts')->add($a) );
                    }
                }
            }
            if ( $p{secdns} ) {
                foreach my $op ( 'add', 'del' ) {

                    # add and del keys shall describe what to do
                    my $a;
                    $a = $p{secdns}{$op} if ( $p{secdns}{$op} );

                    # array or not
                    if ( ref($a) eq 'ARRAY' ) {
                        foreach my $m (@$a) {
                            $toc->$op( 'secdns', $m );
                        }
                    } else {
                        $toc->$op( 'secdns', $a );
                    }
                }
            }
            $rc = $dri->domain_update( $ace, $toc );
            print_result($dri);
            die($rc) unless $rc->is_success();
        }
        if ( $cmd eq 'delete' ) {
            die
                "Cannot delete domain, rejected by DRI:domain_status_allows_delete()"
                unless ( $dri->domain_status_allows_delete($ace) );

            my %a=(pure_delete => 1);
            $a{deletefromdns} = $p{deletefromdns} if $p{deletefromdns};
            $a{deletefromregistry} = $p{deletefromregistry}
                if $p{deletefromregistry};

            $rc = $dri->domain_delete( $ace, \%a );

            print_result($dri);
            die($rc) unless $rc->is_success();
        }

        if ( $cmd eq 'transfer' ) {

            # this is a transfer init operation.

            my %a;
            $a{auth} = { pw => $p{pw} } if ( $p{pw} );

            # notify parameters
            if ( $p{notify} ) {

                # Only one is accept
                $a{mobilephone} = $p{notify}{mobilephone}
                    if ( $p{notify}{mobilephone} );
                $a{email} = $p{notify}{email} if ( $p{notify}{email} );
            }
            $rc = $dri->domain_transfer_start( $ace, \%a );
            print_rc_result($rc);
            print_result($dri);
            die($rc) unless $rc->is_success();
        }
        if ( $cmd eq 'renew' ) {
            my $du = undef;
            if ( $p{duration} ) {
                $du = DateTime::Duration->new( $p{duration} );
                die "$0: Illegal duration value" unless ($du);
            }
            my $exp = undef;
            if ( $p{curexpiry} ) {
                my ( $y, $m, $d ) = split '-', $p{curexpiry};
                $exp = DateTime->new(
                    year  => $y,
                    month => $m,
                    day   => $d
                );
                die "$0: Illegal curexpiry date " unless ($exp);
            }
            $rc = $dri->domain_renew( $ace, $du, $exp );
            print_rc_result($rc);
            print_result($dri);
            die($rc) unless $rc->is_success();
        }

    }    # End of domain operations

# Standardized EPP elements
my @epp = (
	   'id',
	   'qdate',
           'msg',
	   'content',
	   'lang',
	   'object_type',
	   'object_id',
	   'action',
	   'result',
	   'trid',
	   'svtrid',
	   'date',
	   );

    my %m;

    # Message / poll operations
    if ( $obj eq 'message' ) {

        if ( $cmd eq 'waiting' ) {
            print "Poll: messages waiting: ", $dri->message_waiting(), "\n";
        }
        if ( $cmd eq 'count' ) {
            print "Poll: message count: ", $dri->message_count(), "\n";
        }
        if ( $cmd eq 'retrieve' ) {
            $rc = $dri->message_retrieve();

            print_rc_result($rc);
            print_result($dri);

            die($rc) unless $rc->is_success();

            if ( my $c = ($dri->message_count() > 0) ) {
		
                # messages returned
		for ( my $i = 1; $i <= $c; $i++ ) {
		    my $li = $dri->get_info('last_id');

		    my ($qda, $lng, $cnt, $oty, $oid,
                        $act, $res, $ctr, $str, $tr, $dat
			);
                    if ( defined($li) && $li) {
			foreach my $e (@epp) {
			    my $v;
			    $v = $dri->get_info( $e, 'message', $li );
			    
			    if (defined($v) && $v) {
				if ($e eq 'qdate') {
				    # make the DateTime object a scalar time string
				    $v = sprintf $v;
				}
				$m{$e} = $v;
			    }
			}
		    }
                }
            }
	    # Just dump the message elements
	    print "message: ", Dumper \%m;
        }
        if ( $cmd eq 'delete' ) {
            if ( my $id = $p{id} ) {
                $rc = $dri->message_delete($id);
                print_rc_result($rc);
                print_result($dri);
                die($rc) unless $rc->is_success();
            } else {
                print "Poll: No 'id' specified\n";
            }
        }
    }
    return;
}

sub dump_conditions {
    my $dri = shift;

  # get the conditions array from $rinfo structure which is built by Result.pm
  #
    my $cd = $dri->get_info('conditions');

    foreach my $c (@$cd) {
        foreach my $i ( 'code', 'severity', 'msg', 'details' ) {
            my $v;
            $v = '-' unless ( $v = $c->{$i} );
            printf "$F", $i, $v;
        }
    }
    return;
}

#__END__

=pod

=head1 NAME

epp_client_se.pl - A command line client program using Net::DRI towards the
.SE EPP registry.

=head1 DESCRIPTION

The client supports creation and maintainance of host, contact and domain
objects for .SE. It supports transfer operations, as well as poll operation
for the message queue.

It was developed for testing of the .SE extensions to Net::DRI, but can
probably be used by users who are comfortable with a simple command line
interfaces.

=head1 SYNOPSIS

=head2 Command line

B<perl epp_client_se.pl [Connect arguments] [Command arguments]>

=head3 Arguments

=over

=item Mandatory connect arguments

 -C: Client ID, your EPP registrar account name, typical regxxx,
     where xxx is a number
 -W: Account password, your EPP account password
 -S: Server name, the registry server
 -P: EPP server port
 -F: Path to pem certificate client certificate
 -w: Password for the pem file

As of version v3 of the .SE EPP server client certificate is mandatory.


=item Optional connect arguments

 -f: Log file. The Net::DRI raw XML exchange will be dumped to this file
 -L: Use SSL connection

=item Command arguments

The command argument specify the EPP operation to perform:

 -o: EPP object.
     One of contact, host, domain, message
 -c: EPP command.
     One of hello, create, update, info, delete, transfer, count,
     waiting, retrieve
 -p: EPP parameter argument string, in a format that can be eval'ed into
     a hash, se parameter string examples below.

=back

=head3 About each EPP command sequence

Each command will be performed as follows:

 - Socket connect, session initiation, a greeting is returned
 - an EPP login, which will succeed if the connect arguments are correct,
   otherwise fail,
   a greeting is returned if login is OK
 - an EPP command, according to the specified command arguments
 - an EPP logout
 - Session termination

=head3 A simple connect and greeting test

Basic connect to an EPP server should give you a greeting back if successful.
A simple connect to an EPP server and port:

Encrypted with SSL:

   openssl s_client -host <EPP server> -port <EPP port> -cert <Path to pem file> -key <Path to pem file>

=head3 About logging and filtering of the log output

Logging is useful for debugging purposes,

A client side log can be activated by -f option, like:

  '-f xx.log'

Tail on the log-file in a separate window is nice then. Even nicer is to
filter the tail through the supplied xmlfilter.pl utility, which will wrap the
raw XML to a pretty-printed dump.

The filters '-s' option will skip all the login/logout and greetings which
otherwise will dominate the outpot.

  'tail -f xx.log | ./xmlfilter.pl -s'

=head3 About authInfo

Auth-info (pw) can be set and updated only for domain objects, and is
needed only for a transfer.

=head1 EPP commands and arguments

=head2 Hello command

=over

=item Hello

-c hello -o host -p E<34>%p=()E<34>

A greeting shall be returned.

=back

=head2 Contact object commands

=head3 Contact create

A .SE contact can be one of two types, person, or organization.
For each contact created, the type must be specified via the mandatory
type extension.

=over

=item 1 Organization contact

-o contact -c create -p E<34>%p=(id=>'testse0810-0001', name=>'Anders ANdersson', org=>'Exempel AB', street=>['Box 42','Exempelfatan 42'], city=>'Stockholm', pc=>'12345', cc=>'SE', voice=>'+46.12345678', fax=>'+46.12345679', email=>'test@test.se', auth=>{pw=>''}, orgno=>'[SE]551234-5678', vatno=>'SE551234567801', disclose=>{voice=>0, email=>0})E<34>

=item 3 Person contact

-o contact -c create -p E<34>%p=(id=>'testse0811-0002', name=>'Anders Andersson', street=>['Exempelgatan 42'], city=>'Stockholm', pc=>'12345', cc=>'SE', voice=>'+46.12345678', fax=>'+46.12345679', email=>'test@test.se', auth=>{pw=>''}, orgno=>'[SE]640823-3234')"

=back

=head3 Contact update

In this example, a role contact update is shown.

=over

=item Contact update

-o contact -c update -p E<34>%p=(srid=>'testse0811-0002', street=>['Exempelgatan 24'], city=>'Stockholm', pc=>'12354', fax=>'+46.12345679', email=>'test@test.se')E<34>

=back

=head3 Contact info

The 'srid' returned on a create is  the same as the id when creating it.
Lets do an info on this handle.

=over

=item Info on an contact handle

-o contact -c info -p E<34>%p=(srid=>'testse0811-0002')E<34>

=back

=head3 Contact check

=over

=item Check on an contact handle

-o contact -c check -p E<34>%p=(srid=>'testse0811-0002')E<34>

=back

=head3 Contact delete

=over

=item Delete on an contact handle

-o contact -c delete -p E<34>%p=(srid=>'testse0811-0002')E<34>

=back

=head2 Host object commands

=head3 Host create

=over

=item 1 Create an external name server

An external name server is a non .SE name server.

External name servers must be registered without any IP-addresses.

-o host -c create -p E<34>%p=(name=>'ns1.example.com')E<34>

=item 2 A .SE name server can have up to 5 ipv4-addresses and up to 5 ipv6-addresses.

-o host -c create -p E<34>%p=(name=>'ns1.test.se', v4=>'123.234.123.12')E<34>

=item 3 Multiple ip-addresses, pass them as an array

-o host -c create -p E<34>%p=(name=>'ns2.test.se', v4=>['123.234.123.12','129.123.23.23'])E<34>

=item 4 A .SE name server with ipv6 address as well

-o host -c create -p E<34>%p=(name=>'ns3.test.se', v4=>['123.234.123.12','129.123.23.23'], v6=>['2001:700:1:0:215:f2ff:fe3e:fe65'])E<34>

=back

=head3 Host info

=over

=item 1 Info on a sponsored host object

-o host -c info -p E<34>%p=(name=>'ns1.test.se')E<34>

=item 2 info on a host object sponsored (owned) by another registrar

It is possible to query hosts sponsored by other registrars.

-o host -c info -p E<34>%p=(name=>'ns2.test2.se')E<34>

=back

=head3 Host check

=over

=item Check to see whether a host name is available or registered

-o host -c check -p E<34>%p=(name=>'ns1.test.se')E<34>

=back

=head3 Host delete

=over

=item Delete a host

-o host -c delete -p E<34>%p=(name=>'ns1.test.se')E<34>

=back

=head3 Host update

=over

=item 1 First create a host with no ip-addressest.

-o host -c create -p E<34>%p=(name=>'ns4.test.se')E<34>

=item 2 Do an info to verify

-o host -c info -p E<34>%p=(name=>'ns4.test.se')E<34>

=item 3 Now, change/update it

 - 1 new ipv4-addresses are added

-o host -c update -p E<34>%p=(name=>'ns4.test.se', ipset=>{add=>{v4=>['123.234.123.100']}})E<34>

=item 4 Do an info to verify

-o host -c info -p E<34>%p=(name=>'ns4.test.se')E<34>

=item 5 Now, change/update it again

 - 1 new ipv4-address are added
 - 1 old ipv4-address is removed

-o host -c update -p E<34>%p=(name=>'ns4.test.se', ipset=>{add=>{v4=>['123.234.123.101']}, del=>{v4=>['123.234.123.100']}})E<34>

=item 4 Do an info to verify

-o host -c info -p E<34>%p=(name=>'ns4.test.se')E<34>

=item 5 Now, change/update it again

 - 1 new ipv6-address are added

-o host -c update -p E<34>%p=(name=>'ns3.yask.se', ipset=>{add=>{v6=>['2001:698:a:e:208:2ff:fe15:b2e8']}})E<34>

=back

=head2 Domain object commands

=head3 Domain check

=over

=item 1 Check to see whether a domain name is available or registered

-o domain -c check -p E<34>%p=(name=>'test.se')E<34>

=back

=head3 Domain info

=over

=item 1 Do an info on an existing domain

-o domain -c info -p E<34>%p=(name=>'test.se')E<34>

=back

=head3 Domain create

=over

=item Notes

=over

=item * on the domain create methods in Net::DRI

A lot of domain create methods are offered by Net::DRI.

The client uses one specific create method, namely the domain_create() with pure_create=1

=over

=item * domain_create() with pure_create=1

This method assumes that the contacts handles and the nameservers listed are
ALREADY created in the registry, and this is closest to .SE's datamodel.
Hence, the client uses this method.

=item * domain_create() without pure_create or with pure_create=0

This is another method which is a very powerful Net::DRI method.

This method will do the same as domain_create() with pure_create=1, but will also accept and
handle full contacts and nameserver objects as parameters, meaning that it will
check and create various objects as an integral part of the command.

Support for this variant is not added to the client.

=back

=item * on the duration syntax

The duration parameter must specify one year to be accepted in create, due to
the period definition in lib/Net/DRI/DRD/SE.pm

Duration syntax: 'duration=>{years=>1}' or 'duration=>{months=>12}'

=back

=item 1 Create a normal domain without nameservers

Create a single domain with a a registrant, a contact set with one type each,
and and no name servers:

-o domain -c create -p E<34>%p=(name=>'test.se', pw=>'', registrant=>'testse0810-0001', coset=>{tech=>'testse0810-0002', admin=>'testse0810-0002'}, duration=>{years=>1})E<34>

=item 2 Create a normal domain with nameservers

Create a single domain with a a registrant, a contact set with one type each,
and and two name servers:

-o domain -c create -p E<34>%p=(name=>'test2.se', pw=>'', registrant=>'testse0810-0001', coset=>{tech=>'testse0810-0002', admin=>'testse0810-0002'}, duration=>{years=>1}, nsset=>['ns1.test.se', 'ns2.test.se'])E<34>

=item 3 Create an IDN domain

Create a single IDN-domain with a duration of 12 months, a registrant, a
contact set with one type each, and no name servers.

IDN domains are converted to the ACE-form (xn--...) by the client, and the
ACE-form is passed as the domain name to the registry.

-o domain -c create -p E<34>%p=(name=>'räksmörgås.se', pw=>'', registrant=>'testse0810-0001', coset=>{tech=>'testse0810-0002', admin=>'testse0810-0002'}, duration=>{years=>1})E<34>

=item 4 Create a domain with Secure DNS keys

Create a single domain with a a registrant, a contact set with one type each,
and and two name servers and one Secure DNS Key:

-o domain -c create -p E<34>%p=(name=>'test3.se', pw=>'', registrant=>'testse0810-0001', coset=>{tech=>'testse0810-0002', admin=>'testse0810-0002'}, duration=>{years=>1}, nsset=>['ns1.test.se', 'ns2.test.se'], secdns=>[{keyTag=>'12345',alg=>3,digestType=>2,digest=>'49FD46E6C4B45C55D4AC'}])E<34>

=back

=over

=back

=head3 Domain delete

Delete domain is not suported by .SE.

=head3 Domain update

The domain name cannot be changed, otherwise all parameters may be changed.

=over

=item 1 Update (change) some domain attributes

 - set authInfo to 'abc'
 - add and del on all the multiple objects, coset and nsset, which may be
   arrays or scalars
 - delete all secude DNS keys

-o domain -c update -p E<34>%p=(name=>'test.se', pw=>'abc', coset=>{add=>{tech=>['testse0810-0001'], admin=>['testse0810-0001']}, del=>{tech=>['testse0810-0002'], admin=>['testse0810-0002']}}, nsset=>{add=>['ns3.yask.se'], del=>'ns1.test.se'}, secdns=>{del=>[{keyTag=>'0'}]})E<34>

=item 2 Update of status flags

Update is the only command where the status flags can be set/changed.
.SE only handles clientHold. The name is not intuative so to put the clientHold flag on,
ie not to publish the domain - use the add command to set that the domain should NOT be
published and request the domain to be published again by deleteing the status flag.

The flag values to use by the DRI user is the following (from Status.pm):

  my %s=('delete'   => 'clientDeleteProhibited',
         'renew'    => 'clientRenewProhibited',
         'update'   => 'clientUpdateProhibited',
         'transfer' => 'clientTransferProhibited',
         'publish'  => 'clientHold');

Example update to set a domain to NOT be published:

-o domain -c update -p E<34>%p=(name=>'test.se', status=>{add=>['publish']})E<34>

Example update to set a domain to be published:

-o domain -c update -p E<34>%p=(name=>'test.se', status=>{del=>['publish']})E<34>

=back

=head3 DNS Secure

.SE suports the DNS secure extensions secDNS. The epp_client_se.pl can get/set/remove the
keys for DNSsec. One extensions that .SE has added is that you can delete all keys by just
sending a delete with keyTag 0. This will delete all keys.

=item 1 Add a DNSsec key

Add a DNSsec key to a domain.

-o domain -c update -p E<34>%p=(name=>'test.se', secdns=>{add=>[{keyTag=>'12346', alg=>3, digestType=>1, digest=>'49FD46E6C4B45C55D4DD'}]})E<34>

=item 2 Delete a DNSsec key

Delete a DNSsec key from a domain.

-o domain -c update -p E<34>%p=(name=>'yask04.se', secdns=>{del=>[{keyTag=>'12345'}]})E<34>

=over

=head3 clientRelease

.SE has one extensions for clientDelete. is you set this it will remove the domain
before its expiration date.

=over

=item 1 Set the clientDelete flag

- Update the domain and set the clientDelete flag to forece the domain to be removed

-o domain -c update -p E<34>%p=(name=>'test.se', clientDelete=>1)E<34>

=item 2 Unset the clientDelete flag

- Update the domain and remove the clientDelete flag to not have the domain be removed

-o domain -c update -p E<34>%p=(name=>'test.se', clientDelete=>0)E<34>

=back

=head3 Domain renew

=item 1 Renew with parameters.

Duration has to be 12 months or 1 year for .SE.
DRI requires curexpiry, which should match the expiry date of the domain being
renewed:

-o domain -c renew -p E<34>%p=(name=>'test.se', curexpiry=>'2008-12-11', duration=>{months=>12})E<34>

=head2 Domain transfer commands

Domain transfers are used if the registrant wants to change his registrar. He
must then ask the old registrar for the password and the old one has to set that.
The the new registrars can do the transfer.

=head3 Domain transfer request

When the registrant knows the authInfo, he passes it to the new registrar, who
can do a transfer containing the authInfo, and the transfer will
be performed.

- The transfer must be authorized by the token.

-o domain -c transfer -p E<34>%p=(name=>'test.se', pw=>'abc')E<34>

If the password is correct, the domain should be transferred.

=head2 Polling the message queue

=head3 Poll messages

=over

=item 1 message_waiting()

This method performs a poll request and returns true if one or more messages
are waiting in the queue.

-o message -c waiting -p E<34>%p=()E<34>

=item 2 message_count()

This method performs a poll request and returns the 'msgQ count' value from
the response, if any.

-o message -c count -p E<34>%p=()E<34>

=item 3 message_retrieve()

This method performs a poll request, and with get_info() you can grab all the
message details.

-o message -c retrieve -p E<34>%p=()E<34>

=item 4 message_delete()

This is the poll ack message, which will remove message (with id=12) from the
server message queue.

-o message -c delete -p E<34>%p=(id=>12)E<34>

=back

=head1 COPYRIGHT

Copyright (c) 2008,2011 .SE, E<lt>http://www.iis.se<gt>,
Jan Saell E<lt>jan@yask.seE<gt>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=head1 AUTHOR

Jan Saell, E<lt>jan@yask.seE<gt>

=cut
