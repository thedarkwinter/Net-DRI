#!/usr/bin/perl
##
## Copyright (c) 2008-2013 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
##                    Trond Haugen E<lt>info@norid.noE<gt>
##                    All rights reserved.
##
## This program illustrate the usage of Net::DRI towards the .NO registry.
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
## What is this: A Net::DRI based command line client for .NO
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
use Encode qw / decode is_utf8 /;
use Archive::Zip qw(:ERROR_CODES);

use Getopt::Std;

use Data::Dumper;
$Data::Dumper::Indent=1;

use encoding "utf-8";    # assume utf-8 encoded argument input

our $VERSION     = '0.95.no';
our $SVN_VERSION = do {
    my @r = ( q$Revision: 1.5 $ =~ /\d+/gxm );
    sprintf( "%d" . ".%02d" x $#r, @r );
};

# Format string for output of results
my $F = " %-15s: %s\n";

# status methods
my @sm = (
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

# All possible contact object methods
my @cm = (

    # standard DRI methods
    'loid', 'srid', 'id', 'roid', 'name',  'org',   'street',
    'city', 'sp',   'pc', 'cc',   'email', 'voice', 'fax',
    'auth', 'disclose',

    # .no extra methods
    'type', 'identity', 'mobilephone',
    'organization', 'rolecontact', 'xemail', 'xdisclose', 'facets'
);

# args
use vars qw($opt_c $opt_o $opt_h $opt_p $opt_f $opt_P $opt_S
    $opt_L $opt_C $opt_W $opt_w $opt_F);

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
    'withdraw'         => 1,
    'transfer'         => 1,
    'transfer_query'   => 1,
    'transfer_cancel'  => 1,
    'transfer_execute' => 1,    # extension command

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
);

# Scalar EPP elements

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
          'svtrid',

          'date',

           'nocontent',      # .NO specific content desc

          );


# The possible facet keys must be registered here, the value part must be TRUE
# in this hash for the facet to be activated
my %facets = (
       'skip-dns-checks'                => 1,
       'skip-manual-review'             => 1,
       'ignore-exceptions-as-registrar' => 1,
       'impersonate-registrar'          => 1
    );


##
# Mapping from the Applicant dataset file from the Norid EE-automaton
# to internal attribute values used for local checks.
my %ds_file_map = (
    'Domain name'        => 'domainname',
    'Domain name ACE'    => 'domainname_ace',
    'Applicant name'     => 'applicant_name',
    'Applicant id'       => 'applicant_identity',
    );

##
# Mapping from the Applicant dataset file from the Norid EE-automaton
# to attribute values in Net::DRI.
my %ds_dri_map = (
    'Version number'     => 'versionnumber',
    'Accept date'        => 'acceptdate',
    'Accept name'        => 'acceptname',
    );

# Hash to hold the EPP arguments
my %p;

&getopts("vLo:c:p:f:S:P:C:W:w:F:");

#server and port must be specified
my $socktype = 'tcp';
die "No server specified"    unless ($opt_S);
die "No port specified"      unless ($opt_P);
die "No client id specified" unless ($opt_C);
die "No password specified"  unless ($opt_W);

my $server = $opt_S;
my $port   = $opt_P;
$socktype = 'ssl' if ($opt_L);

my $clid = $opt_C;
my $pass = $opt_W;

my $dump_fmt  = 'string';

if ($opt_F) {
    unless ($opt_F eq 'hash' || $opt_F eq 'string') {
       pexit("Illegal format, must be 'hash' or 'string'");
    }
    $dump_fmt = $opt_F;
}

my $newpass;
$newpass = $opt_w if ($opt_w);

unless ( $opt_c && $op{$opt_c} ) {
    pexit("Specify a valid command");
}
unless ( $opt_c eq 'hello' ) {
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

if ($p{facets}) {
    # verify that the facets are among the valid and registered ones
    foreach my $fkey (keys(%{$p{facets}})) {
       pexit("Invalid facet: '$fkey'") unless ($facets{$fkey});
    }
}

my $t1 = time();

my $logf = 'results-' . time() . '.log';
$logf = $opt_f if ($opt_f);
open( my $fh, '>>', $logf ) || die $!;

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
            = init_reg_no( $clid, $pw, $newpw, $socktype, $server, $port,
            $fh );
        do_command( $obj, $cmd, $dri, $rc, %p );
    };
    if ($@) {
        print "\n\nAn EXCEPTION happened !\n";
        if ( ref($@) ) {
            print "FAILURE: Error descriptions: ", ref($@), "\n";
            $@->print();
            print "\n";
            dump_error_conditions_as_fmt($dri);
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

sub init_reg_no {
    my ( $clid, $pw, $newpw, $socktype, $server, $port, $fh ) = @_;

    my $dri = Net::DRI->new(
       {
           cache_ttl => 10,
           logging => [
              # Use EPPClient's log module
              'EppClient::Model::NORID::DRILogging',
              # original
              #'files',
                       {output_directory => './',
                        output_filename=>$opt_f,
                        level=>'notice',
                        xml_indent=>0}]
       }
);

    $dri->add_registry( 'NO', { clid => $clid } );

    my %pars = (
        defer => 0,
        socktype            => $socktype,
        remote_host         => $server || 'epp.test.norid.no',
        remote_port         => $port || 700,
        protocol_connection => 'Net::DRI::Protocol::EPP::Connection',
        protocol_version    => 1,
        client_login        => $clid,
        client_password     => $pw,
    );

    $pars{client_newpassword} = $newpw if ($newpw);

    my $rc = $dri->target('NO')->add_current_profile(
        'profile1',
       'epp',
        { %pars, },
    );

    ## Here we catch all errors during setup of transport, such as
    ## authentication errors
    die($rc) unless $rc->is_success();

    return ( $dri, $rc );
}

sub do_command {
    my ( $obj, $cmd, $dri, $rc, %p ) = @_;

    use Data::Dumper;
    $Data::Dumper::Indent = 1;

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
            $rc = $dri->host_check( $p{name}, { facets => $p{facets}} );

           dump_as_fmt($rc, $dri);

            die($rc) unless $rc->is_success();

            # For a host check, only an exist check is available in DRI
            print "Host $p{name} ",
                $dri->get_info('exist') ? "exists" : "do not exist";
        }
        if ( $cmd eq 'info' ) {
            my %a;

            # host info can specify a sponsoringclientid
            $a{sponsoringclientid} = $p{sponsoringclientid} if ( $p{sponsoringclientid} );
            
           $a{facets} = $p{facets} if ( $p{facets} );

            $rc = $dri->host_info( $p{name}, \%a );

           dump_as_fmt ($rc, $dri, 'host');

            die($rc) unless $rc->is_success();

        }

        if ( $cmd eq 'create' ) {

            # DRI 0.85 need to create the hosts objects directly ..
            my $nso = $dri->local_object('hosts');

            $nso->add( $p{name}, $p{v4}, $p{v6} );
           $rc = $dri->host_create( $nso, { contact => $p{contact}, facets => $p{facets} } );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();

        }
        if ( $cmd eq 'update' ) {
            ###
            # We can change all params, name, ip-addresses and contact
            # Proper add/del keys must be supplied by the user to do this
            my $toc = $dri->local_object('changes');
            if ( $p{ipset} ) {

                # add and del keys shall describe what to do
                my ( $v4a, $v4d );
                $v4a = $p{ipset}{add}{v4} if ( $p{ipset}{add}{v4} );
                $v4d = $p{ipset}{del}{v4} if ( $p{ipset}{del}{v4} );
                $toc->add( 'ip',
                    $dri->local_object('hosts')->add( $p{name}, $v4a, [] ) )
                    if ($v4a);
                $toc->del( 'ip',
                    $dri->local_object('hosts')->add( $p{name}, $v4d, [] ) )
                    if ($v4d);
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

           # Facets
            if ( defined($p{facets}) ) {
                $toc->set( 'facets', $p{facets} );
            }

            $rc = $dri->host_update( $p{name}, $toc);

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();
        }
        if ( $cmd eq 'delete' ) {
            $rc = $dri->host_delete( $p{name}, { facets => $p{facets} } );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();
        }
    }

    if ( $obj eq 'contact' ) {

        if ( $cmd eq 'check' ) {
            my $co = $dri->local_object('contact')->new()->srid( $p{srid} );

            $rc = $dri->contact_check($co, { facets => $p{facets} } );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();

            print "Contact $p{srid} ",
                $dri->get_info('exist') ? " exists" : "do not exist";
        }

        if ( $cmd eq 'info' ) {
            my $co = $dri->local_object('contact')->new()->srid( $p{srid} );

            $rc = $dri->contact_info($co, { facets => $p{facets} } );

           my $o = $dri->get_info('self');

           dump_as_fmt ($rc, $dri, 'contact');
            die($rc) unless $rc->is_success();

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

           dump_as_fmt($rc, $dri, 'contact', 'create');

            die($rc) unless ( $rc->is_success() );

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
#                $co2->$m( $p{$m} ) if ( $p{$m} );
                $co2->$m( $p{$m} );
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

           # Facets
            if ( defined($p{facets}) ) {
                $toc->set( 'facets', $p{facets} );
            }

            $rc = $dri->contact_update( $co, $toc );

           dump_as_fmt ($rc, $dri);
            die($rc) unless $rc->is_success();
        }

        if ( $cmd eq 'delete' ) {
            my $co = $dri->local_object('contact')->new()->srid( $p{srid} );

            $rc = $dri->contact_delete($co, { facets => $p{facets} } );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();

            # Do an info to verify the delete
            print "Verifying delete by an info ....: \n";
            do_command( $obj, 'info', $dri, $rc, %p );
        }
    }

    if ( $obj eq 'domain' ) {
        my ( $ace, $idn, $dsace, $dsidn );

        # We accept input name as either an ace-name or an utf-8
        if ( $p{name} ) {
            $idn = lc( $p{name} );
            die "Cannot lower case domain name: $idn" unless ($idn);

            $ace = idn_to_ascii( $idn, 'utf-8', IDNA_USE_STD3_ASCII_RULES );
            die "Cannot convert domain to ace" unless ($ace);

            $idn = idn_to_unicode( $ace, 'utf-8', IDNA_USE_STD3_ASCII_RULES );
            die "Cannot convert domain to ace" unless ($idn);

        } else {
            die "No domain name specified";
        }

       if ( exists($p{applicantdatafile}) ) {

           # A zip-file containing the applicantdataset is supplied.
           # This function is designed to handle the zip-file from
           # the Norid EE-Automaton.
           # Unzip file and extract the applicantdataset from the file
           # if both file and dataset are given on argument, the file is used

           my ($ds, $fs) = unpack_dataset_file($p{applicantdatafile});

           delete $p{applicantdataset};

           $p{applicantdataset} = $ds;

           #print "ds: ", Dumper $ds;
           #print "fs: ", Dumper $fs;
           #print "p: ", Dumper \%p;

           ###
           # Verify that:
           # - the domains in the dataset file are in correct syntax
           # - the domain name in command is among the domain names in the dataset file

           if ( $fs && exists($fs->{domainname} ) ) {

               my $match;

               foreach my $domainname (@{$fs->{domainname}}) {
                   #print "dname: '$domainname'\n";

                   $dsidn = lc($domainname);
                   die "Cannot lower case domain name: $dsidn" unless ($dsidn);

                   $dsace = idn_to_ascii( $dsidn, 'utf-8', IDNA_USE_STD3_ASCII_RULES );
                   die "Cannot convert domain to ace" unless ($dsace);

                   $dsidn = idn_to_unicode( $dsace, 'utf-8', IDNA_USE_STD3_ASCII_RULES );
                   die "Cannot convert domain to ace" unless ($dsidn);

                   # The domain name to be created/updated must be found
                   if ($ace eq $dsace) {
                       ++$match;
                   }
               }
               unless ($match) {
                   die ("Domain name '$idn' is not found among the domain names in the applicantdataset in the file: " .
                        join ", ", @{$fs->{domainname}});
               }
           }
       }

       #print "p: ", Dumper \%p;

        #print "input name: $p{name}\n";
        #print "ace       : $ace\n";
        #print "idn       : $idn\n";

        die "Illegal domain name" unless ($ace);

        if ( $cmd eq 'check' ) {

            $rc = $dri->domain_check($ace, { facets => $p{facets} });

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();

            print "Domain $p{name} ",
                $dri->get_info('exist') ? " exists" : "do not exist";
        }

        if ( $cmd eq 'info' ) {
            $rc = $dri->domain_info($ace, { facets => $p{facets} });

           dump_as_fmt ($rc, $dri, 'domain');
            die($rc) unless $rc->is_success();

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
               # that and let server policy decide if multiple can be accepted

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
  #    not exist,
  #  - domain_create_only() has a simpler behaviour
  #  We use domain_create_only(), it's simplest
            my $nso = $dri->local_object('hosts');
            if ( $p{nsset} ) {
                if ( my @ns = @{ $p{nsset} } ) {
                    foreach my $n (@ns) {
                        $nso->add( $n, [], [] );
                    }
                }
            }
            $rc = $dri->domain_create(
                $ace,
                {   pure_create => 1, ## this was previously achieved by using domain_create_only that is now deprecated
                    auth     => { pw => $p{pw} },
                    duration => $du,
                    contact  => $cs,
                    ns       => $nso,
                   facets   => $p{facets},
                   applicantdataset => $p{applicantdataset}
                }
            );

           dump_as_fmt ($rc, $dri);

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

            if ( defined($p{pw}) ) {

                $toc->set( 'auth', { pw => $p{pw} } );
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
               foreach my $op ('add', 'del') {
                    # add and del keys shall describe what to do
                   my $a = $p{nsset}{$op} if ($p{nsset}{$op});
                   my $nso = $dri->local_object('hosts');
                        foreach my $m (@$a) {
                       $nso->add($m);
                        }
                   $toc->$op('ns', $nso);
                    }
                }

           # applicantDataset
            if ( defined($p{applicantdataset}) ) {

               #print STDERR "ds p: ", Dumper \%p;

                $toc->set( 'applicantdataset', $p{applicantdataset} );
            }

           # Facets
            if ( defined($p{facets}) ) {
                $toc->set( 'facets', $p{facets} );
            }

            $rc = $dri->domain_update( $ace, $toc );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();
        }
        if ( $cmd eq 'delete' ) {
            die
                "Cannot delete domain, rejected by DRI:domain_status_allows_delete()"
                unless ( $dri->domain_status_allows_delete($ace) );

           # pure_delete should suppress a domain_info() from being first performed
           # to check if the domain exists
            my %a=(pure_delete => 1);

            $a{deletefromdns} = $p{deletefromdns} if $p{deletefromdns};
            $a{deletefromregistry} = $p{deletefromregistry} if $p{deletefromregistry};
           $a{facets} = $p{facets} if $p{facets};

            $rc = $dri->domain_delete( $ace, \%a );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();
        }

        if ( $cmd eq 'transfer_query' ) {
            my %a;
            $a{auth} = { pw => $p{pw} } if ( $p{pw} );
           $a{facets} = $p{facets} if ( $p{facets} );

            $rc = $dri->domain_transfer_query( $ace, \%a );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();
        }

        if ( $cmd eq 'transfer_cancel' ) {
            my %a;
            $a{auth} = { pw => $p{pw} } if ( $p{pw} );
           $a{facets} = $p{facets} if ( $p{facets} );

            $rc = $dri->domain_transfer_stop( $ace, \%a );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();
        }

        if ( $cmd eq 'transfer' ) {

            # this is a transfer init operation.

            my %a;
            $a{auth} = { pw => $p{pw} } if ( $p{pw} );
           $a{facets} = $p{facets} if ( $p{facets} );

            # notify parameters
            if ( $p{notify} ) {

                # Only one is accept
                $a{mobilephone} = $p{notify}{mobilephone}
                    if ( $p{notify}{mobilephone} );
                $a{email} = $p{notify}{email} if ( $p{notify}{email} );
            }
            $rc = $dri->domain_transfer_start( $ace, \%a );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();
        }
        if ( $cmd eq 'transfer_execute' ) {
            my %a;
            $a{auth}   = { pw => $p{pw} } if ( $p{pw} );
            $a{token}  = $p{token} if ( $p{token} );
           $a{facets} = $p{facets} if ( $p{facets} );

            # require either a token or a pw
            unless ( exists( $p{token} ) && $p{token} || exists( $p{pw} ) ) {

                die "Missing mandatory 'token' or 'pw' parameter in $cmd";
            }
            my $du;
            if ( $p{duration} ) {
                $du = DateTime::Duration->new( $p{duration} );
                die "Illegal duration value" unless ($du);
                $a{duration} = $du;
           }
            $rc = $dri->domain_transfer_execute( $ace, \%a );

           dump_as_fmt ($rc, $dri);

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
            $rc = $dri->domain_renew( $ace, { duration => $du, current_expiration => $exp, facets => $p{facets} } );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();
        }

        if ( $cmd eq 'withdraw' ) {

            $rc = $dri->domain_withdraw($ace, { facets => $p{facets} } );

           dump_as_fmt ($rc, $dri);

            die($rc) unless $rc->is_success();
        }
    }    # End of domain operations


    # Message / poll operations
    if ( $obj eq 'message' ) {

        if ( $cmd eq 'waiting' ) {
            print "Poll: messages waiting: ", $dri->message_waiting({ facets => $p{facets} }), "\n";
        }
        if ( $cmd eq 'count' ) {
            print "Poll: message count: ", $dri->message_count({ facets => $p{facets} }), "\n";
        }
        if ( $cmd eq 'retrieve' ) {
            $rc = $dri->message_retrieve({ facets => $p{facets} });

           #print STDERR "rc: ", Dumper $rc;

            if ( $dri->message_count() > 0 ) {
                # messages exist, the first one is read, fetch the elements of it
               my $li = $dri->get_info('last_id');

               dump_as_fmt ($rc, $dri, 'message');

               #my $r =  message_object_as_fmt($dri, 'hash');
               #print "Message:\n", Dumper $r;

            } else {
               dump_as_fmt ($rc);

		    }
           die($rc) unless $rc->is_success();

        }
        if ( $cmd eq 'delete' ) {
            if ( my $id = $p{id} ) {
                $rc = $dri->message_delete($id, { facets => $p{facets} });

               dump_as_fmt ($rc, $dri);

                die($rc) unless $rc->is_success();
            } else {
                print "Poll: No 'id' specified\n";
            }
        }
    }
    return;
}

sub dump_error_conditions_as_fmt {
    my $dri = shift;

  # get the conditions array from $rinfo structure which is built by Result.pm
  #
    if (my $cd = $dri->get_info('conditions')) {

       if ($dump_fmt eq 'hash') {
           print "Conditions:\n", Dumper $cd;
       } else {
    foreach my $c (@$cd) {
        foreach my $i ( 'code', 'severity', 'msg', 'details' ) {
            my $v;
            $v = '-' unless ( $v = $c->{$i} );
            printf "$F", $i, $v;
        }
    }
       }
    }
    return;
}


sub dump_as_fmt {
    my ($rc, $dri, $ob, $op) = @_;

    my $fmt = $dump_fmt;

    my ($rcres, $drires, $obres);

    if ($rc) {
       $rcres = rc_result_as_fmt( $rc, $fmt );
       $rcres = Dumper $rcres if ($fmt eq 'hash');
       print "RC_RESULT:\n$rcres\n";
    }
    if ($dri) {
       $drires = dri_result_as_fmt( $dri, $fmt );
       $drires = Dumper $drires if ($fmt eq 'hash');
       print "DRI_RESULT:\n$drires\n",
    }
    if ($ob) {
       if ($ob eq 'contact') {
           $obres = contact_object_as_fmt( $dri, $fmt, $op);
       } elsif ($ob eq 'host') {
           $obres = host_object_as_fmt( $dri, $fmt);
       } elsif ($ob eq 'domain') {
           $obres = domain_object_as_fmt( $dri, $fmt);
       } elsif ($ob eq 'message') {
           $obres = message_object_as_fmt( $dri, $fmt);
       }
       $obres = Dumper $obres if ($fmt eq 'hash');
       print uc($ob), ":\n$obres\n";
    }
}



=begin head2 rc_result_as_fmt

Helper function to map rc result information from DRI into a hash
or a string as the user prefers.

TODO: This should be fixed in the DRI:
Due to a problem in Net::DRI the msg contains part of the
login response extension, and I cannot get the normal
conditions_parse in my Result.pm inside Net::DRI to
work for login responses.
The as_string returns wrongly formatted message, which includes
something like this:

 "Command syntax error</msg></result><extension><conditions xmlns=\"http://www.norid.no/xsd/no-ext-result-1.0\" xsi:schemaLocation=\"http://www.norid.no/xsd/no-ext-result-1.0 no-ext-result-1.0.xsd\"><condition code=\"EC000015\" severity=\"error\"><msg>EPP parse error (2001/2001) ERROR"

So, the methods <msg> hack extracts the two msg parts of the result.

Keys returned can be:

   Summary
   Class
   EPP_RFC_code
   EPP_native_code
   Info
   Message

   rc_is_pending
   rc_info

   clTRID
   svTRID

    * is_success()
    * code()
    * native_code()
    * message()
    * lang()
    * info()
    * as_string(EXTRA)
    * print()
    * print_full()
    * trid() 

=end head2 rc_result_as_fmt

=cut
sub rc_result_as_fmt {
    my $rc  = shift;
    my $fmt = shift;

    return unless (ref($rc) eq "Net::DRI::Protocol::ResultStatus");

    #print STDERR "\ngd raw cmd:\n\n "  , Dumper $rc->get_data('session', 'exchange', 'raw_command'), "\n\n";
    #print STDERR "\ngd raw rep:\n\n "  , Dumper $rc->get_data('session', 'exchange', 'raw_reply'), "\n\n";
    #print STDERR "DRI.pm: rc_result_as_fmt PRINT: ", $rc->as_string(1), "\n";
    # print STDERR "DRI.pm: rc_result_as_fmt - rc in is:", Dumper $rc, "\n";

    my $s;
    unless ($fmt || $fmt eq 'hash') {
       $fmt = 'string';
       $s = "";
    }

    my ($cl, $cd, $ncd, $inf, $msg);
    $cl = $cd = $ncd = $inf = $msg = '-';

    $cl  = ref($rc) if (ref($rc));
    $cd  = $rc->code() if ($rc->code());
    $ncd = $rc->native_code() if ($rc->can('native_code') && $rc->native_code());
    $inf = $rc->info() if ($rc->can('info') && $rc->info());
    $msg = $rc->as_string() if ($rc->can('as_string') && $rc->as_string());

    if ($msg =~ m|(^.+)</msg>.+<msg>(.+$)|mx) {
       if ($1 && $2) {
           $msg  = $1 . ' - ' . $2;
       }
    }
    if ($fmt eq 'hash') {
       $s->{Class}           = $cl;
       $s->{EPP_RFC_code}    = $cd;
       $s->{EPP_native_code} = $ncd;
       $s->{Info}            = $inf;
       $s->{Message}         = $msg;
    } else {
       $s .=  
           "Class       : $cl\n" . 
           "EPP_RFC_code: $cd\n" .
           "EPP_native_code : $ncd\n" .
           "Info        : $inf\n" .
           "Message     : $msg\n";
    }
       
    # rc is ok
    # Print rc-specific info, not found in $dri->result_*()
         
    if ($rc->can('is_pending')) {
       my $v = "";
       $v = $rc->is_pending() if $rc->is_pending();
       
       if ($fmt eq 'hash') {
           $s->{rc_is_pending} = $v;
       } else {
           $s .= "rc_is_pending : $v\n";
       }
    }
    if ($rc->can('info')) {
       my $v = "";
       $v = $rc->info() if $rc->info();
       if ($fmt eq 'hash') {
           $s->{rc_info} = $v;
       } else {
           $s .= "rc_info : $v\n";
       }
    }
    if ($rc->can('trid') && $rc->trid()) {
       my @v;
       @v = $rc->trid();
       
       # trid seems to be returned as an array with two values
       if ($fmt eq 'hash') {
           $s->{clTRID} = $v[0];
           $s->{svTRID} = $v[1];
       } else {
           $s .= sprintf "$F", 'clTRID',  $v[0];
           $s .= sprintf "$F", 'svTRID',  $v[1];
       }
    }

    # print STDERR "rc_result_as_fmt returns s: ", Dumper $s;

    return $s;
}


=begin dri_exception_as_fmt

Helper function to map dri exception information from DRI into a hash
or a string as the user prefers.

Keys returned can be:

   dx_area
   dx_code
   dx_msg
   dx_as_string

   dx_as_array   (hash fmt only: the string as array elements, one line per entry)

=end dri_exception_as_fmt

=cut

sub dri_exception_as_fmt {
    my $rx  = shift;
    my $fmt = shift;

    return unless ($rx);

    # If the $rx is a string, return it
    return $rx unless (ref($rx) eq "Net::DRI::Exception");

    #print STDERR "dri_exception_as_fmt got rx: ", Dumper $rx;

    my $s;
    unless ($fmt || $fmt eq 'hash') {
       $fmt = 'string';
       $s = "";
    }
    # Print exception specific info
    foreach my $m ('area', 'code', 'msg', 'as_string') {
       if ($rx->can($m)) {
           my $v;
           $v = $rx->$m() if $rx->$m;
           next unless $v;

           if ($fmt eq 'hash') {
               $s->{"dx_$m"} = $v;

               if ($m eq 'as_string') {
                   # also represent the string as an array in hash mode
                   push @{$s->{dx_as_array}}, split '\n', $v;
               }
           } else {
               $s .= "dx_$m : $v\n";
           }
       }
    }
    #print STDERR "dri_exception_as_fmt returns s: ", Dumper $s;
    return $s;
}


=begin dri_result_as_fmt

Helper function to map dri result information from DRI into a hash
or a string as the user prefers.

Keys returned can be:

    result_code
    native_code
    message
    lang

    is_pending

    info

    print
    print_full

    action
    exist
    exist_reason

    trStatus
    reID
    reDate
    acID
    acDate
    exDate

    # msgQ data in message:
    msgq.
      count
      id

    # NO specific extension codes, array, each with:
    code
    severity
    msg
    details

=end dri_result_as_fmt

=cut

sub dri_result_as_fmt {
    my ($dri, $fmt) = @_;

    return unless (ref($dri) eq "Net::DRI");

    # print STDERR "DRI_result_as_fmt dri: ", ref($dri), "\n";
    # print STDERR "DRI_result_as_fmt dri is: ", Dumper $dri, "\n";
    my $s;
    unless ($fmt || $fmt eq 'hash') {
       $fmt = 'string';
       $s = "";
    }
    my ($rcode, $ncode, $message, $lang);
    $rcode = $ncode = $message = $lang = '-';

    if ($dri->can('result_code') && $dri->result_code()) {
       $rcode = $dri->result_code();
    }

    if ($dri->can('result_native_code') && $dri->result_native_code()) {
       $ncode = $dri->result_native_code();
    }

    if ($dri->can('result_message') && $dri->result_message()) {
       $message = $dri->result_message();
    }

    if ($dri->can('result_lang') &&  $dri->result_lang()) {
       $lang = $dri->result_lang();
    }

    if ($fmt eq 'hash') {
       $s->{result_code} =  $rcode;
       $s->{native_code} =  $ncode;
       $s->{message}     =  $message;
       $s->{lang}        =  $lang;
    } else {
       $s = "\n";
       $s .= " result_code    : $rcode\n";
       $s .= " native_code    : $ncode\n";
       $s .= " result_message : $message\n";
       $s .= " language       : $lang\n";
    }
    #print STDERR "set_dri_result_as_fmt\n";

    if ($dri->can('result_is_pending')) {
       my $v = $dri->result_is_pending();
       if ($fmt eq 'hash') {
           $s->{is_pending} = $v;
       } else {
           $s .= "is_pending  : $v\n";
       }
    }
    if ($dri->can('result_info')) {
       my $v = $dri->result_info();
       if ($fmt eq 'hash') {
           $s->{info} = $v;
       } else {
           $s .= "info : $v\n";
       }
    }
    if ($dri->can('result_print')) {
       my $v = $dri->result_print();
       if ($fmt eq 'hash') {
           $s->{print} = $v;
       } else {
           $s .= "print: $v\n";
       }
    }
    if ($dri->can('result_print_full')) {
       my $v = $dri->result_print_full();
       if ($fmt eq 'hash') {
           $s->{print_full} = $v;
       } else {
           $s .= "print_full: $v\n";
       }
    }

#    print STDERR "dri: ", Dumper $dri;

    foreach my $w ('action', 'exist', 'exist_reason', 'trStatus', 'reID','reDate',
                  'acID', 'acDate', 'exDate') {

       if (my $v = $dri->get_info($w)) {
           if ($fmt eq 'hash') {
               $s->{$w} = "$v";
           } else {
               $s .= sprintf "$F", $w,  "$v";
           }
       }
    }

    ####
    # Find any piggybacked msgQ count and id
    foreach my $m ('count', 'id') {
       if (my $v = $dri->get_info($m,'message','info')) {
           if ($fmt eq 'hash') {
               $s->{msgq}->{$m} = $v;
           } else {
               $s .= sprintf "$F", "msgq_" .$m, $v;
           }
       }
    }

    #
    # Get the .NO conditions array from $rinfo structure which is built by Result.pm
    my $cd = $dri->get_info('conditions');

   # print STDERR "dri_result_as_fmt NO_XXXTENSIONS: , cd: ", Dumper $cd;

    foreach my $c (@$cd) {
       foreach my $i ('code', 'severity', 'msg', 'details') {
           my $v;
           $v = '-' unless ($v = $c->{$i});

           if ($fmt eq 'hash') {

# print STDERR "dri_result_as_fmt: $i = $v\n";

               push @{$s->{conditions}->{condition}->{$i}}, $v;
               #push @{$s->{$i}}, $v;

           } else {
               $s .= sprintf "$F", "conds-".$i,  $v;
           }
       }
    }

#   print STDERR "\n\n *** dri_result_as_fmt returns s: ", Dumper $s, "\n***\n\n";
    return $s;
}      

=begin contact_object_as_fmt

Helper function to map contact object information from DRI into a hash
or a string as the user prefers.

Keys returned can be:

    loid
    srid
    id
    roid
    name
    org
    street
    city
    sp
    pc
    cc
    email
    voice
    fax
    auth
    disclose->
       voice
       fax
       email
    xdisclose->
       mobilePhone
    identity->type
    identity->value
    mobilephone, 
    organization
    rolecontact
    xemail

    roid
    crDate
    upDate
    clID
    crID
    upID

=end contact_object_as_fmt

=cut

sub contact_object_as_fmt {
    my ($dri, $fmt, $op) = @_;

    my $s;
    unless ($fmt || $fmt eq 'hash') {
       $fmt = 'string';
       $s = "";
    }

    # The handle id of a contact create need to be picked manually
    if ($op && $op eq 'create') {
       if ( my $v = $dri->get_info('id') ) {
           if ( ref($v) && ( ref($v) ne 'SCALAR' ) ) {
               # don't bother diving into it ... use a Dumper
               $v = sprintf Dumper $v;
           }
           if ($fmt eq 'hash') {
               $s->{id} = $v; 
           } else {
               $s .= sprintf "$F", 'id', $v;
           }
       }
       return $s;
    } else {

       ####
       # Now the contact object information for update/info
       my $o = $dri->get_info('self');

       foreach my $m (@cm) {

           if ($o->can($m)) {
               my $v = $o->$m;
               
               if ($m eq 'identity') {
                   my $t = $v->{type} if ($v && $v->{type});
                   my $v = $v->{value}  if ($v && $v->{value});
                   if ($fmt eq 'hash') {
                       $s->{identity}->{type}  = $t if ($t);
                       $s->{identity}->{value} = $v if ($v);
                   } else {
                       $s .= sprintf "$F", 'identity type'   , $t if ($t);
                       $s .= sprintf "$F", ', identity value', $v if ($v);
                   }
               } elsif ($m eq 'disclose') {
                   # discloses:
                   # The server has a default policy with full disclose
                   # It only signals 0 when one is set to off
                   # We have to initialize all discloseure to 1,
                   # and change to 0 on the ones the server tells us
                   
                   # Special disclose mapping
                   foreach my $d ('voice', 'fax', 'email') {
                       # set default disclose value
                       if ($fmt eq 'hash') {
                           $s->{$m}->{$d} = '1';
                       } else {
                           $s .= sprintf "$F", $d."disclose", "1";
                       }
                       
                       next unless (defined($v) && $v);
#print STDERR "DRI disclose, v returned and is now:", Dumper $v;
                       if ($v->{$d} eq "0") {
                           if ($fmt eq 'hash') {
                               $s->{$m}->{$d} = '0';
                           } else {
                               $s .= sprintf "$F", $d."disclose", "0";
                           }
                       }
                   }
               } elsif ($m eq 'xdisclose') {
                   # set default disclose value
                   if ($fmt eq 'hash') {
                       $s->{$m}->{mobilePhone} = '1';
                   } else {
                       $s .= sprintf "$F", $m. 'mobilePhone', "1";
                   }
                   next unless (defined($v) && $v);
                   if ($v->{mobilePhone} eq "0") {
                       if ($fmt eq 'hash') {
                           $s->{$m}->{mobilePhone} = '0';
                       } else {
                           $s .= sprintf "$F", $m. 'mobilePhone', "0";
                       }
                   }
               } else {
                   next unless (defined($v) && $v);
                   if ($fmt eq 'hash') {
                       $s->{$m} = $v;
                   } else {
                       $s .= sprintf "$F", $m, $v;
                   }
               }
           }
       }
       foreach my $i ('roid', 'crDate', 'upDate', 'clID', 'crID', 'upID') {
           my $v = $dri->get_info($i);
           $v = '-' unless $v;

           if ($fmt eq 'hash') {
               $s->{$i} = "$v";
           } else {
               $s .= sprintf "$F", $i,  "$v";
           }
       }

       ###################
       # Contact status
       #
       $s = statuses_as_fmt ($dri, $s, $fmt);
    }


#print STDERR "DRI contact as fmt, s: ", Dumper $s;

    return $s;
}


=begin host_object_as_fmt

Helper function to map host information from DRI into a hash
or a string as the user prefers.

Keys returned can be:

    loid
    count
    name
    v4
    v6
    status

    contact

    roid
    exDate
    crDate
    upDate
    trDate
    clID
    crID
    upID

=end host_object_as_fmt

=cut

sub host_object_as_fmt {
    my ($dri, $fmt) = @_;

    my $s;
    unless ($fmt || $fmt eq 'hash') {
       $fmt = 'string';
       $s = "";
    }

    my $hi = $dri->get_info('self');

    foreach my $m ('loid', 'count') {
       #my $v = '-';
       my $v;
       $v = $hi->$m if ($hi->$m);

       if ($fmt eq 'hash') {
           $s->{$m} = $v;
       } else {
           $s .= sprintf "$F", $m, $v;
       }
    }
    
    my @nms = $hi->get_names();
    if (scalar(@nms) != 1) {
       Net::DRI::Exception->die(1,'Client::DRI.pm',9000, 'Error: we expect only one host name');
    }
    if ($fmt eq 'hash') {
       $s->{name} = join ", ", @nms;
    } else {
       $s .= sprintf "$F", 'name', @nms;
    }
    foreach my $n (@nms) {
       my @d =  $hi->get_details($n);

       # ip-addresses are optional
       my @v = @{$d[1]} if (@{$d[1]});
       if ($fmt eq 'hash') {
           push @{$s->{v4}}, @v if (@v);
       } else {
           $s .= sprintf "$F", 'v4 addresses',  join (", ", @v);
       }
       @v = ();
       @v = @{$d[2]} if (@{$d[2]});
       if ($fmt eq 'hash') {
           push @{$s->{v6}}, @v if (@v);
       } else {
           $s .= sprintf "$F", 'v6 addresses',  join (", ", @v);
       }
    }

    # contact is currently a single value
    # but Net::DRI returns an array because the schemas
    # support multiple, as a possible future change
    my $ct = "-";
    if ($ct = $dri->get_info('contact')) {
       if (defined($ct->[0])) {
           if ($fmt eq 'hash') {
               $s->{contact} = $ct->[0];
           } else {
               $s .= sprintf "$F", 'contact',  $ct->[0];
           }
       }
    }
    foreach my $i ('roid','exDate', 'crDate', 'upDate', 'trDate', 'clID', 'crID', 'upID') {
       if (my $v = $dri->get_info($i)) {
           if ($fmt eq 'hash') {
               $s->{$i} = "$v";
           } else {
               $s .= sprintf "$F", $i,  "$v";
           }
       }
    }

    ####################
    # Host status
    #
    $s = statuses_as_fmt($dri, $s, $fmt);


#    print STDERR "host s: ", Dumper $s;

    return $s;
}


#You may use get_info with the following keys to get more information:
# - ns : a Net::DRI::Data::Hosts object representing the nameservers of the domain
# - status : a Net::DRI::Data::StatusList object representing the current status list of the domain queried
# - exDate, crDate, upDate, trDate : DateTime objects representing the expiration, creation, last update, and
#                          transfer date for the domain queried
# - clID, crID, upID : (strings) local registry ID of the current sponsoring registrar, the registrar having created,
#                       and the registrar (or registry) having last modified the domain queried


=begin domain_object_as_fmt

Helper function to map domain information from DRI into a hash
or a string as the user prefers.

Keys returned can be:

    name
    ace

    pw 
    pwsetbuthidden

    nscount
    nsset[]

    registrant
    coset.
      admin[]
      tech[]

    status
    statuslist

    roid

    exDate
    crDate
    upDate
    trDate

    clID
    crID
    upID

  - applicantDataset values:
    versionNumber
    acceptName
    acceptDate
    updateClientID
    updateDate

=end domain_object_as_fmt

=cut

sub domain_object_as_fmt {
    my ($dri, $fmt) = @_;

    my $s;
    unless ($fmt || $fmt eq 'hash') {
       $fmt = 'string';
       $s = "";
    }

    foreach my $m ('name', 'roid','exDate', 'crDate', 'upDate', 'trDate', 'clID', 'crID', 'upID') {
       my $v = $dri->get_info($m);
       if ($v) {
           #print STDERR "m: $m, v: $v\n";

           if ($m eq 'name') {
               # Also print the UTF-8 of an ACE
               my $idn = idn_to_unicode($v, 'UTF-8', IDNA_USE_STD3_ASCII_RULES);
               unless (is_utf8($idn)) {
                   $idn = Encode::decode('UTF-8', $idn, 1);
               }
               if ($fmt eq 'hash') {
                   $s->{name} = $idn;
                   $s->{ace}  = $v;
               } else {
                   $s .= sprintf "$F", 'Name',  $idn;
                   $s .= sprintf "$F", 'ACE-name',  $v;
               }
               next;
           }
           if ($fmt eq 'hash') {
               $s->{$m} = "$v";
           } else {
               $s .= sprintf "$F", $m,  "$v";
           }
       }
    }

    ####
    # authInfo
    #
    my $au;
    $au = $dri->get_info('auth') if ($dri->get_info('auth'));

    #print STDERR "au: ", Dumper $au;

    if ($au && defined($au->{pw})) {
       if ($fmt eq 'hash') {
           $s->{pw} = $au->{pw};
           if ($au->{pw} eq '') {
               # Special server rule. The domain has an authInfo, but it is secret 
               # for non-sponsors
               $s->{pwsetbuthidden} = 1;
           }
       } else {
           $s .= sprintf "$F", 'authInfo pw', $au->{pw};
       }
    }


    ##
    # name servers
    #
    unless ($fmt eq 'hash') {
       $s .= sprintf "--- Name servers ---\n";
    }

    if (my $ns = $dri->get_info('ns')) {
       my $v = '-';
       if (($v = $ns->count()) > 0) {
           if ($fmt eq 'hash') {
               $s->{ns_count} = $v;
           } else {
               $s .= sprintf "$F", 'ns count', $v;
           }
       }
       foreach my $n (sort $ns->get_names()) {
           if ($fmt eq 'hash') {
               push @{$s->{nsset}}, $n;
           } else {
               $s .= sprintf "$F", 'ns name',  $n;
           }
       }
    }

    ####################
    # Contacts
    # 
    # contact is an array ref.
    my $co = $dri->get_info('contact');
    
    unless ($fmt eq 'hash') {
       $s .= sprintf "--- Contacts ---\n";
    }

    foreach my $ct ('registrant', 'admin', 'tech') {
       my @r = $co->get($ct);
       my $v = "-";
       foreach my $r (@r) {
           $v = $r->srid if ($r->srid);
           if ($fmt eq 'hash') {
               if ($ct eq 'registrant') {
                   $s->{registrant} = $v;
               } else {
                   push @{$s->{coset}->{$ct}}, $v;
               }
           } else {
               $s .= sprintf "$F", $ct, $v;
           }
       }
    }

    ####################
    # Domain status
    #
    $s = statuses_as_fmt($dri, $s, $fmt);


    #####################
    # Applicant dataset
    #

    unless ($fmt eq 'hash') {
       $s .= sprintf "--- Applicant Dataset ---\n";
    }

    my $aset = $dri->get_info('applicantDataset');
    for my $m ('versionNumber', 'acceptName', 'acceptDate', 'updateClientID', 'updateDate') {
       my $v = $aset->{$m};
       if ($v) {
           #print STDERR "m: $m, v: ", Dumper $v;
           if ($fmt eq 'hash') {
               $s->{$m} = "$v";
           } else {
               $s .= sprintf "$F", $m,  "$v";
           }
       }
    }

    return $s;
}


=begin statuses_as_fmt

Routine to set status values from dri into the hash,
should work for host, contact and domain objects

=end statuses_as_fmt

=cut

sub statuses_as_fmt {
    my ($dri, $s, $fmt) = @_;

#    my $s = $sref;

    my $st = $dri->get_info('status');

    unless ($fmt eq 'hash') {
       $s .= sprintf "--- Status summary ---\n";
    }

    foreach my $hs (@sm) {
       my $v = undef;

       if ($st->$hs) {
           $v = $st->$hs;
           if ($fmt eq 'hash') {
               $s->{status}->{$hs} = $v;
           } else {
               $s .= sprintf "$F", $hs, $v;
           }
       }
    }

    ####
    # also dump all the detailed status values
    my @ls = $st->list_status();

    unless ($fmt eq 'hash') {
       $s .= sprintf "--- Status list ---\n";
    }
    foreach my $l (@ls) {
       if ($fmt eq 'hash') {
           $s->{statuslist}->{$l} = 1;
       } else {
           $s .= sprintf "$F", 'statuslist', $l;
       }
    }

   ####
    # also dump all the status details
    my $sd = $st->status_details;

    unless ($fmt eq 'hash') {
       $s .= sprintf "--- Status details ---\n";
    }
    foreach my $l (keys %$sd) {
       if ($fmt eq 'hash') {
           $s->{statusdetails}->{$l} = $sd->{$l};

#print STDERR "statusdetails: $l = ",  Dumper $sd->{$l}, "\n";

       } else {
           $s .= sprintf "$F", 'statusdetails', $l . ": " . $sd->{$l};
       }
    }

    return $s;

}

=begin message_object_as_fmt

Helper function to map retrieved message information from DRI into a hash
or a string as the user prefers.

Keys returned can be:

    id
    qdate
    msg
    content
    lang
    object_type
    object_id
    action
    result
    trid
    svtrid
    date

    ##
    # .NO specific

    # the specific content desc
    nocontent     

    # the conditions array, each element contains msg/code/..
    conditions[]
          msg
          code
          severity
          details

    # Inner TRIDs from late-responses etc.
    trid.
       cltrid
       svtrid

    # in case of domain late response, get the transfer status data
    # each element contains msg/code/..
    trStatus
    reID
    reDate
    acID
    acDate
    exDate

=end message_object_as_fmt

=cut

sub message_object_as_fmt {
    my ($dri, $fmt) = @_;

    my $s;
    unless ($fmt || $fmt eq 'hash') {
       $fmt = 'string';
       $s = "";
    }

    my $c = $dri->get_info('count','message','info');

     if (defined($c) && $c > 0) {
       # messages exist, read data from the last_id one
       my $li = $dri->get_info('last_id');

       if ( defined($li) && $li) {

           foreach my $e (@epp) {
               my $v;
               $v = $dri->get_info( $e, 'message', $li );
               
               #print STDERR "DRI dri info message $e, ref: ", ref($e), "Dumper: ", Dumper $v;
               
               if (defined($v) && $v) {

                   # stringify dates
                   $v = "$v" if ($e eq 'qdate' || $e eq 'date');

                   if ($fmt eq 'hash') {
                       $s->{$e} = $v;
                   } else {
                       $s .= sprintf "$F", $e, $v;
                   }
               }
           }

           # from @epp, 'content' an 'nocontent' are often equal, use it once if so
           if ($fmt eq 'hash') {
               if ($s->{content} && $s->{nocontent} && $s->{content} eq $s->{nocontent}) {
                   delete $s->{nocontent};
               }
           }

           # .NO conditions
           if (my $cd = $dri->get_info( 'conditions', 'message', $li )) {
               foreach my $c (@$cd) {
                   foreach my $i ('code', 'severity', 'msg', 'details') {
                       my $v;
                       $v = '-' unless ($v = $c->{$i});
                       
                       if ($fmt eq 'hash') {
                          push @{$s->{conditions}->{condition}->{$i}}, $v;
                       } else {
                           $s .= sprintf "$F", "conds-".$i,  $v;
                       }
                   }
               }
           }
       }
       
       # domain transfer late response result
       # really deep digging into the Net::DRI structures
       if ((my $d = $dri->get_info( 'domain', 'message', $li ))) {

           if (my @dn = keys(%$d)) {
               my $nmp=0;

               # Set resptype = 'contact'
               if ($fmt eq 'hash') {
                   $s->{late}->{respType} = 'domain';
               } else {
                   $s .= sprintf "$F", 'respType',  'domain';
               }

               foreach my $w ('action', 'exist', 'trStatus', 'reID','reDate',
                              'acID', 'acDate', 'exDate') {

                   # Cannot get get_info to dig as deep as I need, so use
                   # the $d hash data from above get_info.

                   if (my $v = $d->{$dn[0]}->{$w}) {

                       if ($fmt eq 'hash') {
                           $s->{late}->{$w} = "$v";
                           $s->{late}->{name} = $dn[0] unless $nmp;
                       } else {
                           $s .= sprintf "$F", $w,  "$v";
                           $s .= sprintf "$F", "name",  $dn[0] unless $nmp;
                       }
                       #print STDERR "message_object domain found $w: $v\n";
                   }
                   ++$nmp;
               }
           }
       }

       # contact create late response result
       # really deep digging into the Net::DRI structures
       if ((my $d = $dri->get_info( 'contact', 'message', $li ))) {
           
           #print STDERR "message_object contact message found: ", ref $d, "\n";;
           #print STDERR "message_object contact message found: ", Dumper $d;
           
           if ( defined($d->{session}->{id}) ) {
               my $id = $d->{session}->{id};
               if (my $ip = $d->{$id}) {
                   # Set resptype = 'contact'
                   if ($fmt eq 'hash') {
                       $s->{late}->{respType} = 'contact';
                   } else {
                       $s .= sprintf "$F", 'respType',  'contact';
                   }
                   # Extract the interesting stuff
                   foreach my $w ('id', 'action', 'exist', 'crDate') {
                       if (my $v = $d->{$id}->{$w}) {
                           if ($fmt eq 'hash') {
                               $s->{late}->{$w} = "$v";
                           } else {
                               $s .= sprintf "$F", $w,  "$v";
                           }
                           #print STDERR "message_object contact found $w: $v\n";
                       }
                   }
               }
           }
       }

       # any inner TRIDs
       if ((my $trid = $dri->get_info( 'trid', 'message', $li ))) {
           
           if ($fmt eq 'hash') {
               $s->{clTRID} = $trid->{cltrid} if (defined($trid->{cltrid}));
               $s->{svTRID} = $trid->{svtrid} if (defined($trid->{svtrid}));
           } else {
               $s .= sprintf "$F", "clTRID", $trid->{cltrid} if (defined($trid->{cltrid}));
               $s .= sprintf "$F", "svTRID", $trid->{svtrid} if (defined($trid->{svtrid}));
           }
       }
    }

    foreach my $i ('roid', 'crDate', 'upDate', 'clID', 'crID', 'upID') {
       if (my $v = $dri->get_info($i)) {
           if ($fmt eq 'hash') {
               $s->{$i} = "$v";
           } else {
               $s .= sprintf "$F", $i,  "$v";
           }
       }
    }


#    print STDERR "message_object Dumper: ", Dumper $s;

    return $s;
}

=begin unpack_dataset_file

The applicant data set file shall reside as a txt file inside the
zip file along with the pdf of the applicant declaration.

 - Unpack the zip
    - Two files should be contained, one .pdf and one .txt
    - If this is not the caser, abort.

 - Open the .txt file
   - parse it, if wrong syntax, abort
   - extract the applicant data set entries

 - Return the applicant dataset

=end unpack_dataset_file

=cut

sub unpack_dataset_file {
    my $zf = shift;
    
    my $txtfile;
    my ($ds, $fs);

    unless ( -f $zf ) {
       die ("No file $zf");
    }

    my $zip = Archive::Zip->new();
    my $status = $zip->read( $zf );
    die "Read of $zf failed\n" if $status != AZ_OK;
    
    for my $ft ('pdf', 'txt') {
       my @filemembers = $zip->membersMatching( ".*\.$ft" );
       unless (@filemembers) {
           die "No '*.$ft' file found inside $zf";
       }
       if (@filemembers > 1) {
           die "More than one '*.$ft' file found inside $zf";
       }
       $txtfile = $filemembers[0];
    }

    my $txtfname = $txtfile->fileName;
    $status = $zip->extractMemberWithoutPaths($txtfile);
    die "Extracting $txtfile from $zf failed\n" if $status != AZ_OK;

    # Open txtfile and parse it
    open(IF, "<$txtfname") or die ("Cannot open $txtfname");

    while (<IF>) {
       chomp;
       my $l = $_;

       next unless ($l);
       next if ($l =~ /\#/);

       #print "l in: $l\n";

       # Split on first colon (Limit=2):
       my ($h, $v) = split ':', $l, 2;

       # collapse all white spaces
       $h =~ s/\s+/ /g;
       $h =~ s/^\s+//g;
       $h =~ s/\s+$//g;
       $v =~ s/\s+/ /g;
       $v =~ s/^\s+//g;
       $v =~ s/\s+$//g;

       die "Invalid file key: '$h'" unless ($ds_dri_map{$h} || $ds_file_map{$h});

       #print "h: $h, v: $v\n";

       if ($ds_dri_map{$h}) {
           # Map the field names from the file tags to the Net::DRI tags
           $ds->{$ds_dri_map{$h}} = $v;

       } elsif ($ds_file_map{$h}) {

           if ($h =~ m/Domain name/) {
               push @{$fs->{$ds_file_map{$h}}}, $v;
           } elsif ($ds_file_map{$h}) {
               $fs->{$ds_file_map{$h}} = $v;
           }
       }
    }
    close(IF);

    #unlink($txtfname);

    return $ds, $fs;
}


__END__


=pod

=head1 NAME

epp_client_no.pl - A command line client program using Net::DRI towards the
.NO EPP registry.

=head1 DESCRIPTION

The client supports creation and maintainance of host, contact and domain
objects for .NO. It supports various transfer operations, as well as poll
operation for the message queue.

It was developed for testing of the .NO extensions to Net::DRI, but can
probably be used by users who are comfortable with a simple command line
interfaces.

=head1 SYNOPSIS

=head2 Command line

B<perl epp_client_no.pl [Connect arguments] [Command arguments]>

=head3 Arguments

=over

=item Mandatory connect arguments

 -C: Client ID, your EPP registrar account name, typical regxxx,
     where xxx is a number
 -W: Account password, your EPP account password
 -S: Server name, the registry server
 -P: EPP server port

=item Optional connect arguments

 -f: Log file. The Net::DRI raw XML exchange will be dumped to this file
 -L: Use SSL connection
 -w: New account password, will be set in first EPP login
 -F: Format on output, 'string' (default) or 'hash'

=item Command arguments

The command argument specify the EPP operation to perform:

 -o: EPP object.
     One of contact, host, domain, message
 -c: EPP command.
     One of hello, create, update, info, delete, transfer, transfer_cancel,
     transfer_execute, count, waiting, retrieve
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

Raw port (no SSL):

   telnet <EPP server> <EPP port>

Encrypted with SSL:

   openssl s_client -host <EPP server> -port <EPP port>

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
needed only for a transfer-execute.

=head1 EPP commands and arguments

=head2 Hello command

=over 

=item Hello

-c hello

A greeting shall be returned, with the menu!

=back

=head2 Contact object commands

=head3 Contact create

A .NO contact can be one of three types, person, organization or role.
For each contact created, the type must be specified via the mandatory
type extension.

=over

=item 1 Organization contact

-o contact -c create -p E<34>%p=(name=>'EXAMPLE FIRM AS', street=>['Example building','Example st. 23', '5 etg'], city=>'Trondheim', pc=>'NO-7005', cc=>'NO', voice=>'+47.12345678', fax=>'+47.12345678x01', email=>'xml@example.no', type=>'organization', identity=>{type=>'organizationNumber', value=>'987654321'})E<34>

=item 2 Person contact 1 affiliated with a company

-o contact -c create -p E<34>%p=(name=>'Peter Example Olsen', street=>['First example building','Example st. 1'], city=>'Trondheim', pc=>'NO-7005', cc=>'NO', voice=>'+47.22345671',  mobilephone=>'+47.123456781', email=>'peter.xml@example.no', type=>'person', organization=>'EFA12O')E<34>

=item 3 Person contact 2 not affiliated with a company

-o contact -c create -p E<34>%p=(name=>'John Example Johnsen', street=>['Second example building','Example st. 2'], city=>'Trondheim', pc=>'NO-7005', cc=>'NO', voice=>'+47.22345672',  mobilephone=>'+47.123456782', email=>'john.xml@example.no', type=>'person')E<34>

=item 4 Role contact with two contact end a secondary extra email address

-o contact -c create -p E<34>%p=(name=>'Example hostmaster', street=>['Example building','Example st. 23', '5 floor'], city=>'Trondheim', pc=>'NO-7005', cc=>'NO', voice=>'+47.12345678', fax=>'+47.12345678x01',  mobilephone=>'+47.123456789', email=>'hostmaster@example.no', type=>'role', rolecontact=>['PEO1P', 'JEO2P'],  xemail=>'xml@example.no')E<34>

=back

=head3 Contact update

In this example, a role contact update is shown.

=over

=item Role contact update

Update a role and add an org. affiliation and a new person affiliation, also
remove one of the existing person affiliations.
Also change some of the address information and the mobile phone number. Keep
the rest of the info.

-o contact -c update -p E<34>%p=(srid=>'TOH12R', nname=>'New name on Hostmaster', street=>['Changed example building','Changed Example st. 23', '5 floor'],  city=>'Trondheim', pc=>'NO-7005', cc=>'NO', mobilephone=>'+47.123433389', organization=>{add=>['TOH1O']}, rolecontact=>{add=>['TOH1P'], del=>['TOH1P']})E<34>

=back

=head3 Contact info

If a 'srid' returned on a create is 'TOH169O', it means that the org. handle
has the value 'TOH169O-NORID'. Lets do an info on this handle.

=over 

=item Info on an organization contact handle

-o contact -c info -p E<34>%p=(srid=>'TOH169O')E<34>

=back

=head3 Contact check

=over

=item Check on an organization contact handle

-o contact -c check -p E<34>%p=(srid=>'TOH169O')E<34>

You may get an usupported command on this!

=back

=head3 Contact delete

=over

=item Delete on an organization contact handle

-o contact -c delete -p E<34>%p=(srid=>'TOH169O')E<34>

=back

=head2 Host object commands

=head3 Host create

=over

=item 1 Create an external name server

An external name server is a non .NO name server.

External name servers must be registered without any IP-addresses.

-o host -c create -p E<34>%p=(name=>'ns1.example.com')E<34>

=item 2 A .NO name server will require an ipv4-address

-o host -c create -p E<34>%p=(name=>'ns1.test.no', v4=>'123.234.123.12')E<34>

=item 3 A .NO name server also with an optional contact

-o host -c create -p E<34>%p=(name=>'ns2.test.no', v4=>'123.234.123.12', contact=>'JEO50P')E<34>

=item 4 Multiple ip-addresses, pass them as an array

-o host -c create -p E<34>%p=(name=>'ns3.test.no', v4=>['123.234.123.12','129.123.23.23'])E<34>

=item 5 A .NO name server with ipv6 address as well

 Will probably be rejected by server policy:

-o host -c create -p E<34>%p=(name=>'ns4.test.no', v4=>['123.234.123.12','129.123.23.23'], v6=>['2001:700:1:0:215:f2ff:fe3e:fe65'])E<34>

=back

=head3 Host info

=over

=item 1 Info on a sponsored host object

-o host -c info -p E<34>%p=(name=>'ns1.suniswanted.no')E<34>

=item 2 info on a host object sponsored (owned) by another registrar

It is possible to query hosts sponsored by other registrars, but you need to
specify his registrar id by the 'sponsoringClientID'.

-o host -c info -p E<34>%p=(name=>'ns1.suniswanted.no', sponsoringclientid=>'reg9998')E<34>

=back

=head3 Host check

=over

=item Check to see whether a host name is available or registered

-o host -c check -p E<34>%p=(name=>'ns1.test.no')E<34>

=back

=head3 Host delete

=over

=item Delete a host

-o host -c delete -p E<34>%p=(name=>'ns1.test.no')E<34>

=back

=head3 Host update

=over

=item 1 First create a host with two ip-addresses and a contact

-o host -c create -p E<34>%p=(name=>'ns7.test.no', v4=>['123.234.123.100','129.123.23.23'], contact=>'TAH8P')E<34>

=item 2 Do an info to verify

-o host -c info -p E<34>%p=(name=>'ns7.test.no')E<34>

=item 3 Now, change/update it

 - The name is changed to a new name specified in key nname
 - 3 new ip-addresses are added, one of the existing is removed, thus 4
   ip-addresses shall be the final result
 - The contact is deleted and changed to another one.

-o host -c update -p E<34>%p=(name=>'ns7.test.no', nname=>'ns8.test.no', ipset=>{add=>{v4=>['1.2.3.1','1.2.3.2','1.2.3.3']}, del=>{v4=>'123.234.123.100'}}, contact=>{del=>'TAH8P', add=>'EFA2P'})E<34>

=back

=head2 Domain object commands

=head3 Domain check

=over

=item * Check to see whether a domain name is available or registered

-o domain -c check -p E<34>%p=(name=>'test.no')E<34>

=back

=head3 Domain info

=over

=item * Do an info on an existing domain

-o domain -c info -p E<34>%p=(name=>'test.no')E<34>

=back

=head3 Domain create

=over

=item Notes

=over

=item * on the domain create methods in Net::DRI

A lot of domain create methods are offered by Net::DRI.

The client uses one specific create method, namely the domain_create_only().

=over

=item * domain_create_only()

This method assumes that the contacts handles and the nameservers listed are
ALREADY created in the registry, and this is closest to Norid's datamodel.
Hence, the client uses this method.

=item * domain_create()

This is another method which is a very powerful Net::DRI method.

This method will do the same as domain_create_only(), but will also accept and
handle full contacts and nameserver objects as parameters, meaning that it will
check and create various objects as an integral part of the command.

Support for this variant is not added to the client.

=back

=item * on the duration syntax

The duration parameter must specify one year to be accepted in create, due to
the period definition in lib/Net/DRI/DRD/NO.pm

Duration syntax: 'duration=>{years=>1}' or 'duration=>{months=>12}'

=back


=item * Create a normal domain

Create a single domain with a a registrant, a contact set with one type each,
two existing name servers, which is the minimum for .no.

B<Using the 1.0 version of the domain schema:>

-o domain -c create -p E<34>"%p=(name=>'test.no', pw=>'', registrant=>'THO12O', coset=>{tech=>'THO23P', admin=>'TH2345P'}, nsset=>['ns1.sol.no', 'ns2.sol.no'])"E<34>

B<Using the 1.1 version of the domain schema:>

The 1.1 version requires the applicantdataset which represents parts of the applicant statement.

a) with applicantdataset specifed directly as arguments, only the three attributes required in EPP are passed:

-o domain -c create -p E<34>%p=(name=>'test.no', pw=>'1234xxx8', registrant=>'BJOH4O', coset=>{tech=>'TH10139P', admin=>'TH10139P'}, nsset=>['ns1.sol.no', 'ns2.sol.no'], applicantdataset=>{ acceptname => 'Peter Absalon', acceptdate => '2011-10-11T08:19:31.00Z', versionnumber => '3.0'})E<34>

b) with applicantdataset specifed in the 'applicantdatafile' zip-file from the Norid EE-Automaton. The .txt file inside need to contain all attributes from the EE-Automaton:

-o domain -c create -p E<34>%p=(name=>'test.no', pw=>'1234xxx8', registrant=>'BJOH4O', coset=>{tech=>'TH10139P', admin=>'TH10139P'}, nsset=>['ns1.sol.no', 'ns2.sol.no'], applicantdatafile=>'/tmp/appl.zip')E<34>

Example of content of the file 'applicant_declaration.txt' found inside the '/tmp/appl.zip':

 Domain name       : sE<248>l.no
 Domain name ACE   : xn--sl-lka.no
 Domain name       : test.no
 Domain name       : olsen.no
 Applicant name    : UNINETT NORID AS
 Applicant identity: 985821585
 Accept name       : Hilde M. Thunem
 Accept date       : 2011-10-11T08:19:31.00Z
 Version number    : 3.0

=item Create an IDN domain

Create a single IDN-domain with a duration of 12 months, a registrant, a
contact set with one type each, and two existing name servers, which is the
minimum for .NO.

IDN domains are converted to the ACE-form (xn--...) by the client, and the
ACE-form is passed as the domain name to the registry.

-o domain -c create -p E<34>%p=(name=>'test-E<198>E<216>E<197>.no', pw=>'', duration=>{months=>12}, registrant=>'THO12O', coset=>{tech=>'THO23P', admin=>'TH2345P'}, nsset=>['ns1.sol.no', 'ns2.sol.no']})E<34>

This should be accepted if the handles and name servers exist and the domain
don't.

=back

=over 

=item Some domain create variants supported by Net::DRI but rejected by .NO registry policy.

A lot of variants will pass the DRI, but should be rejected by the registry
because of local policy.

=over

=item * Create a single domain with a pw and a contact set, no name servers

-o domain -c create -p E<34>%p=(name=>'test.no', pw=>'xxx123yZ', registrant=>'THO12O', coset=>{tech=>'THO23P', admin=>'TH2345P'})E<34>

=item * Create a single domain with a duration of 12 months, no contact set, but only a nameserver

-o domain -c create -p E<34>%p=(name=>'test2.no', pw=>'', registrant=>'THO12O', nsset=>['ns1.sol.no', 'ns2.sol.no'])E<34>

=item * Create a single domain with a duration of 12 months, no registrant, no contact set, but only a nameserver

-o domain -c create -p E<34>%p=(name=>'test2.no', pw=>'', nsset=>['ns1.sol.no'])E<34>

=item * Create a single domain with a a domain name only:

-o domain -c create -p E<34>%p=(name=>'test2.no', pw=>'')E<34>

=back 

=back

=head3 Domain delete

Delete domain, optionally specify the two optional Norid dates for removal
from DNS and registry:

-o domain -c delete -p E<34>%p=(name=>'test.no', deletefromregistry=>'2008-02-27', deletefromdns=>'2008-01-15')E<34>

=head3 Domain update

The domain name cannot be changed, otherwise all parameters may be changed.

=over

=item 1 Update (change) some domain attributes

 - registrant is changed
 - set authInfo to 'abc'
 - add and del on all the multiple objects, coset and nsset, which may be
   arrays or scalars

B<Using the 1.0 version of the domain schema:>

-o domain -c update -p E<34>%p=(name=>'test.no', pw=>'abc', duration=>{months=>12}, registrant=>'TOH191O', coset=>{add=>{tech=>['TOH1P'], admin=>['TOH2P']}, del=>{tech=>['TOH1P'], admin=>['TOH2P', 'TOH3P']}}, nsset=>{add=>['ns1.sol.no', 'ns2.sol.no'], del=>'ns4.sol.no'})E<34>


B<Using the 1.1 version of the domain schema:>

The parameter 'applicantdataset' must be supplied, either as arguments or as file, as for domain create.

-o domain -c update -p E<34>%p=(name=>'test.no', pw=>'abc', duration=>{months=>12}, registrant=>'TOH191O', coset=>{add=>{tech=>['TOH1P'], admin=>['TOH2P']}, del=>{tech=>['TOH1P'], admin=>['TOH2P', 'TOH3P']}}, nsset=>{add=>['ns1.sol.no', 'ns2.sol.no'], del=>'ns4.sol.no'}, applicantdatafile=>'/tmp/appl.zip')E<34>


=item 2 Update of status flags

Update is the only command where the status flags can be set/changed

The flag values to use by the DRI user is the following (from Status.pm):

  my %s=('delete'   => 'clientDeleteProhibited',
         'renew'    => 'clientRenewProhibited',
         'update'   => 'clientUpdateProhibited',
         'transfer' => 'clientTransferProhibited',
         'publish'  => 'clientHold');

Example update when a couple of flags are set, and two already set are removed:

-o domain -c update -p E<34>%p=(name=>'test.no', status=>{add=>['delete','publish'], del=>['update', 'transfer']})E<34>


=item 2 Update of applicantdataset only

A registrar may have collected an updated applicant statement. This is how to send it it, just ba a simple domain update, with new applicantdataset,
this implies useing the 1.1 version of the domain schema:

-o domain -c update -p E<34>%p=(name=>'test.no', applicantdatafile=>'/tmp/appl.zip')E<34>

=back

=head3 Domain renew

Rule from DRD.pm: we must have : curexp+duration < now + maxdelta
maxdelta = the permitted period which is 1 year (set in NO.pm).

So basicly curexpiry must have a value between today (=now) and up to one year
ahead in time. Values outside that generates a DRI-error.

=over

=item 1 Renew with minimum parameters

DRI requires curexpiry, which should match the expiry date of the domain being
renewed:

-o domain -c renew -p E<34>%p=(name=>'ÆRE-pw-abc.no', curexpiry=>'2007-12-11')E<34>

=item 2 Renew with max. parameters. We specify duration as well to two months

-o domain -c renew -p E<34>%p=(name=>'ÆRE-pw-abc.no', curexpiry=>'2007-12-11', duration=>{months=>2})E<34>

=back

=head3 Domain withdraw

This is a .NO specific extension command.

Withdraw will transfer the domain to REG0, thus a registrar can push the
responsibility for a domain into the bucket.
 
-o domain -c withdraw -p E<34>%p=(name=>'test.no')E<34>

If the sponsor for a domain is REG0, any registrar can do a transfer on it to
take over the responsibility.

=head2 Domain transfer commands

Domain transfers are used if the registrant wants to change his registrar. He
must then ask a new registrar to transfer his domains from the current
registrar to the new one.

=head3 authInfo is known, can use it in a direct 'transfer execute'

If the registrant knows the authInfo, he passes it to the new registrar, who
can do a transfer 'op=execute' containing the authInfo, and the transfer will
be performed.

 - The execute must be authorized by the token.
 - An optional duration can specify a renew period for the domain (1-12 months).

-o domain -c transfer_execute -p E<34>%p=(name=>'test.no', pw=>'abc', duration=>{months=>'6'})E<34>

If the password is correct, the domain should be transferred.

=head3 authInfo not known, must request one-time token

If the registrant does not know the authInfo, the new registrar must initiate a
transfer by sending a transfer request without authInfo. This will trig the
registry to generate a one-time password (a token) and send it to the
registrant, which in turn must pass the token to his new registrar. The new
registrar can then send a transfer execute containing the token, and then the
transfer will be performed.

=over

=item 1 Domain transfer request

Initate a transfer request to ask for a token. The DRI-method used is
domain_transfer_start(). The token will be sent to the primary email address
registered on the registrant unless a special alternative address is selected.

-o domain -c transfer -p E<34>%p=(name=>'test.no')E<34>

Optionally, use the notify address to specify that the token shall be sent to
another email address. It must match one of the registered email addresses:

-o domain -c transfer -p E<34>%p=(name=>'test.no', notify=>{email=>'xml@example.no'})E<34>

Optionally, specify that the token shall be sent by SMS to a mobilePhone number
as notify address. It must match the registered mobilePhone number.

-o domain -c transfer -p E<34>%p=(name=>'test.no', notify=>{mobilephone=>'+47123456789'})E<34>

=item 2 Domain transfer query

After a transfer request is received, the token is sent to the registrant.
Until a transfer execute is received the domain will remain in a pending state.

The status of pending transfers can be queried.

-o domain -c transfer_query -p E<34>%p=(name=>'test.no')E<34>

=item 3 Cancel a pending transfer

A pending transfer can be cancelled. The token will be deleted and the pending
state information will be restored to the normal state.

-o domain -c transfer_cancel -p E<34>%p=(name=>'test.no')

=item 4 Execute a pending transfer

 - Execute must be authorized by the token. 
 - An optional duration can specify a renew period for the domain (1-12 months).

-o domain -c transfer_execute -p E<34>%p=(name=>'test.no', token=>'MySecretToken', duration=>{months=>'9'})E<34>

If the token is correct, the domain should be transferred.

=back


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

=head2 Facets

Facets are some special control attributes that can be used to
trig special behaviour by the registry when a transaction is received.

By use of facets, a registrar can suppress certain checks and perform
actions on behalf of another registrar. The right do do such an
operation could be defined as a super registrar function.

The facets are only available for a registrar account when the account
has been granted these special control rights by server configuration.

Warning:
If facets are attempted set by a non-authorized registrar account, they
will be rejected. The registry may detect such abuse and apply prevailing
actions towards non-authorized registrars, so don't play with this
mechanism unless you know you have the rights to use a facet on your account.

=head3 Facet keys, values and functionality

Facets are key/value pairs and their names and syntax are decided by the registry.


=head3 Facets usage in commands

Facets may be set for any EPP command.

To add facets into the parameter string, use the following facet syntax
in the parameter string:

   facets => { '<facet1>' => '<value1>', '<facet2>' => '<value2>', <facet3> => <value3>', ... }


=head1 COPYRIGHT

Copyright (c) 2008-2013 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
Trond Haugen E<lt>info@norid.noE<gt>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=head1 AUTHOR

Trond Haugen, E<lt>info@norid.noE<gt>

=cut

