## Domain Registry Interface, nic.at domain transactions extension
## Contributed by Michael Braunoeder from NIC.AT <mib@nic.at>
##
## Copyright (c) 2006-2008,2013,2016,2018 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AT::Domain;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands {
       my ( $class, $version ) = @_;
       state $rops = { domain => { nocommand        => [ \&extonly,          \&extonly_parse_result ],
                                   delete           => [ \&delete,           undef ],
                                   transfer_request => [ \&transfer_request, \&extonly_parse_result ],
                                 },
                     };
       return $rops;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $ns = { 'at-ext-domain' => 'http://www.nic.at/xsd/at-ext-domain-1.0',
               'at-ext-epp'    => 'http://www.nic.at/xsd/at-ext-epp-1.0',
             };
 $po->ns($ns);
 return;
}

####################################################################################################

sub extonly {
       my ( $epp, $domain, $rd ) = @_;

       my $transaction;
       $transaction = $rd->{transactionname} if $rd->{transactionname};

       return unless ($transaction);

       my $mes = $epp->message();

      Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined($domain) && $domain;
      Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);
      ##$mes->command_body([['domain:name',$domain]]); ## Useless if pure extension

       my $eid = $mes->command_extension_register( 'at-ext-epp', 'command');

       my $cltrid=$mes->cltrid();

       if ( $transaction eq 'withdraw' ) {

               my %domns;
               $domns{'xmlns:domain'}       = $mes->ns('at-ext-domain');

			 	my %zdhash;
				$zdhash{'value'} = $rd->{zd} ? $rd->{zd} : 0;

	           $mes->command_extension(
               $eid,

                       [
                               ['withdraw',
                               [ 'domain:withdraw',  ['domain:name', $domain], \%domns ,
                               						  ['domain:zd', \%zdhash], \%domns  ]],
                               ['clTRID', $cltrid ]

                       ]
               );


       }
       elsif ( $transaction eq 'transfer_execute' ) {


               my $token;
               $token = $rd->{token} if $rd->{token};

       return unless ( defined($token) );

               my %domns;
               $domns{'xmlns:domain'}       = $mes->ns('domain');

               my %domns2;
               $domns2{'xmlns:at-ext-domain'} = $mes->ns('at-ext-domain');



               $mes->command_extension(
               $eid,
                       [
                               ['transfer',

                                       { 'op' => 'execute' },
                                       [ 'domain:transfer', \%domns, [ 'domain:name', $domain ]
                                       ]
                               ],
                               ['extension',
                                  ['at-ext-domain:transfer' , \%domns2, ['at-ext-domain:token',$token]
                                  ]
                               ],
                               ['clTRID', $cltrid]
                       ]
               );

       }
       return;
}

sub delete { ## no critic (Subroutines::ProhibitBuiltinHomonyms)

       my ( $epp, $domain, $rd ) = @_;
       my $mes = $epp->message();

       my $scheduledate;
       $scheduledate = $rd->{scheduledate} if $rd->{scheduledate};

       return unless ( defined($scheduledate) );

       my $eid = $mes->command_extension_register( 'at-ext-domain', 'delete');

       $mes->command_extension( $eid,
               [ 'at-ext-domain:scheduledate', $scheduledate ] );
       return;
}

sub transfer_request {
       my ( $epp, $domain, $rd ) = @_;
       my $mes = $epp->message();

       my $registrarinfo;
       $registrarinfo = $rd->{registrarinfo} if $rd->{registrarinfo};

       return unless ( defined($registrarinfo) );

       my $eid = $mes->command_extension_register( 'at-ext-domain', 'clientdata');

       my %entryname;
       $entryname{name} = 'Registrarinfo';
       $mes->command_extension( $eid,
               [ 'at-ext-domain:entry', \%entryname, $registrarinfo ] );
       return;
}

sub extonly_parse_result {
    my ($po,$otype,$oaction,$oname,$rinfo)=@_;
    my $mes=$po->message();
    return unless $mes->is_success();

    my $keydatedata=$mes->get_extension('at-ext-domain', 'keydate');
    return unless defined $keydatedata;

    my $keydate = $keydatedata->textContent();
    return unless defined $keydate;

    $rinfo->{domain}->{$oname}->{keydate}=$keydate;

    return;
}



####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AT::Domain - NIC.AT EPP Domain extension for Net::DRI

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

Copyright (c) 2006-2008,2013,2016,2018 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
