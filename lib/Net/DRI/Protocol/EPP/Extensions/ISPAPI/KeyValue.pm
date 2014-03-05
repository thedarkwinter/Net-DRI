## Domain Registry Interface, ISPAPI (aka HEXONET) Key-Value EPP extensions
##
## Copyright (c) 2010,2013 HEXONET GmbH, http://www.hexonet.net,
##                    Jens Wagner <info@hexonet.net>
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

package Net::DRI::Protocol::EPP::Extensions::ISPAPI::KeyValue;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ISPAPI::KeyValue - EPP extension for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>support@hexonet.netE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Alexander Biehl, E<lt>abiehl@hexonet.netE<gt>
Jens Wagner, E<lt>jwagner@hexonet.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2010,2013 HEXONET GmbH, E<lt>http://www.hexonet.netE<gt>,
Alexander Biehl <abiehl@hexonet.net>,
Jens Wagner <jwagner@hexonet.net>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
          check => [ \&create_keyvalue, \&parse_keyvalue ],
          info => [ \&create_keyvalue, \&parse_keyvalue ],
          create => [ \&create_keyvalue, \&parse_keyvalue ],
          update => [ \&create_keyvalue, \&parse_keyvalue ],
          transfer_request => [ \&create_keyvalue, \&parse_keyvalue ],
         );
 my %api=(
          call => [ \&create_keyvalue_extension, \&parse_keyvalue ],
         );

 my %account=(
              list_domains => [\&list_domains, \&list_domains_parse ],
             );

 return { 'domain' => \%tmp, 'contact' => \%tmp, 'ns' => \%tmp, 'account' => \%account, 'api' => \%api };
}

our @NS = ('http://schema.ispapi.net/epp/xml/keyvalue-1.0', 'http://schema.ispapi.net/epp/xml/keyvalue-1.0 keyvalue-1.0.xsd');


####################################################################################################

############ Transform commands

sub create_keyvalue_extension
{
 my ($epp,$hash)=@_;

 my $mes=$epp->message();

 my $eid=$mes->command_extension_register('keyvalue:extension','xmlns:keyvalue="'.$NS[0].'" xsi:schemaLocation="'.$NS[1].'"', 'keyvalue');

 my @kv = ();

 foreach my $key ( keys %{$hash} ) {
  my $value = $hash->{$key};
  if ( defined $value ) {
   push @kv, ['keyvalue:kv', { key => $key, value => $value }];
  }
  else {
   push @kv, ['keyvalue:kv', { key => $key }];
  }
 }
 return unless @kv;
 $mes->command_extension($eid,\@kv);
 return;
}


sub create_keyvalue
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'keyvalue');

 return create_keyvalue_extension($epp, $rd->{keyvalue});
}


sub parse_keyvalue
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes = $po->message();
 my $extension = $mes->get_extension($NS[0],'extension');
 return unless (defined($extension));

 my $keyvalue = {};

 foreach my $kv ( $extension->getChildrenByTagNameNS($NS[0], 'kv') ) {
  $keyvalue->{$kv->getAttribute('key')} = $kv->getAttribute('value');
 }
 $rinfo->{$otype}{$oname}{keyvalue} = $keyvalue;
 return;
}


sub list_domains
{
 my ($epp, $hash)=@_;
 $hash = {} if !defined $hash;
 $hash->{COMMAND} = 'QueryDomainList' if !exists $hash->{COMMAND};
 $hash->{USERDEPTH} = 'SELF' if !exists $hash->{USERDEPTH};
 $hash->{ORDERBY} = 'DOMAIN' if !exists $hash->{DOMAIN};
 $hash->{LIMIT} = '10000' if !exists $hash->{LIMIT};

 return create_keyvalue_extension( $epp, $hash );
}


sub list_domains_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;

 parse_keyvalue($po,'account','list','domains',$rinfo);

 if ( exists $rinfo->{account}{domains}{keyvalue} ) {
  my @domains = ();
  my $hash = $rinfo->{account}{domains}{keyvalue};

  if ( exists $hash->{DOMAIN} ) {
   push @domains, $hash->{DOMAIN};
   my $i;
   for ( $i = 1; exists $hash->{"DOMAIN$i"}; $i++ ) {
    push @domains, $hash->{"DOMAIN$i"};
   }
  }

  delete $rinfo->{account}{domains}{keyvalue};

  $rinfo->{account}->{domains}->{action} = 'list';
  $rinfo->{account}->{domains}->{list} = \@domains;
 }
 return;
}

####################################################################################################
1;
