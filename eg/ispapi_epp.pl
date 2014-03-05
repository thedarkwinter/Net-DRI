#!/usr/bin/perl

##
## Copyright (c) 2010 HEXONET GmbH, E<lt>http://www.hexonet.netE<gt>,
##                    Jens Wagner E<lt>info@hexonet.netE<gt>
##                    All rights reserved.
##
## This program illustrate the usage of Net::DRI towards the ISPAPI (aka HEXONET) EPP server.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
##
#######

use strict;
use warnings;

#use FindBin;
#use lib $FindBin::Bin."/lib";
use Net::DRI;

my $r = eval {
	my $dri = Net::DRI->new( { cache_ttl => 10 } );
#	my $dri = Net::DRI->new( { cache_ttl => 10, logging => ['stderr', { level => 'notice' } ] } );

# load DRD for ISPAPI
	$dri->add_registry('ISPAPI');

# create new connection to the EPP server, port 1700 (OT&E)
	$dri->target('ISPAPI')->add_current_profile('profile1', 'epp', {
		remote_port => 1700,
		client_login => 'test.user',
		client_password => 'test.passw0rd'
	} );

# using an extension hash for IDN registration, set transferlock, create DNS zone
	my $kv = {
		'X-IDN-LANGUAGE' => 'de',
		'TRANSFERLOCK' => 1,
		'INTERNALDNS' => 1
	};
	my $create_rc = $dri->domain_create('xn--mller-kva.com',{pure_create => 1, auth => { pw => '2fooBAR' }, keyvalue => $kv});
	print STDERR $create_rc->as_string(1);

	print STDERR "\n";
	print STDERR "\n";

# query a domain name, in addition get the RENEWALMODE
	my $info_rc = $dri->domain_info('000audio.com', {keyvalue => { COMMAND => 'StatusDomain'} });
	print STDERR $info_rc->get_data('keyvalue')->{RENEWALMODE};

	print STDERR "\n";
	print STDERR "\n";

# free-form API call, used to query the account status
	my $api = $dri->remote_object('api');
	my $rc = $api->call( { COMMAND => "StatusAccount" } );
	$kv = $rc->get_data('keyvalue');
	foreach my $key ( sort keys %$kv ) {
		print STDERR "$key=".$kv->{$key}."\n";
	}

	print STDERR "\n";
	print STDERR "\n";

# query the list of domains (limited to 10), DRI style
	my $list_rc = $dri->account_list_domains( { FIRST => 0, LIMIT => 10, DOMAIN => '*.com' } );
	my $list = $list_rc->get_data('list');
	foreach my $domain ( @$list ) {
		print STDERR "$domain\n";
	}

	print STDERR "\n";

};

