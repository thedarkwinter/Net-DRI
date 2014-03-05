## Domain Registry Interface, Afilias Association extension (for .XXX)
##
## Copyright (c) 2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Afilias::Association;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           create =>	[ \&create, undef ],
           update =>	[ \&update, undef ],
           info =>	[ undef, \&info_parse ]
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({association => ['urn:afilias:params:xml:ns:association-1.0','association-1.0.xsd']});
 return;
}

sub capabilities_add { return ('domain_update','association',['add','del','set']); }

####################################################################################################

sub build_association
{
  my $as = shift;
  my @pw = defined $as->{'pw'} ? ['association:authInfo',[ 'association:pw',$as->{'pw'}] ] : ();
   return (
     ['association:contact',{'type' =>'membership'},
      ['association:id',$as->{'id'}],
      @pw
    ]
  );
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 return unless Net::DRI::Util::has_key($rd,'association');
 my $as=$rd->{association};
 Net::DRI::Exception::usererr_invalid_parameters('Invalid Association Membership Contact ID and PW') unless Net::DRI::Util::xml_is_token($as->{'id'},1,63) && Net::DRI::Util::xml_is_token($as->{'pw'},6,16); 
 my @t = build_association($as);
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('association','create');
 $mes->command_extension($eid,\@t);

 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();
 my $toadd=$todo->add('association');
 my $todel=$todo->del('association');
 my $tochg=$todo->set('association');
 my @def=grep { defined } ($toadd,$todel);
 return unless @def; ## no updates asked

 my $eid=$mes->command_extension_register('association','update');

 my @n;
 if (defined $toadd)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Invalid Association Membership Contact ID and PW') unless Net::DRI::Util::xml_is_token($toadd->{'id'},1,63) && Net::DRI::Util::xml_is_token($toadd->{'pw'},6,16); 
  push @n,['association:add',build_association($toadd)]
 }
 if (defined $todel)
 {
  undef $todel->{'pw'};
  Net::DRI::Exception::usererr_invalid_parameters('Invalid Association Membership Contact ID') unless Net::DRI::Util::xml_is_token($toadd->{'id'},1,63);
  push @n,['association:rem',build_association($todel)] if (defined $todel);
 }
 if (defined $tochg)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Invalid Association Membership Contact ID and PW') unless Net::DRI::Util::xml_is_token($tochg->{'id'},1,63) && Net::DRI::Util::xml_is_token($tochg->{'pw'},6,16); 
  push @n,['association:rem',build_association($tochg)] if (defined $tochg);
 }

 $mes->command_extension($eid,\@n);

 return;
}


sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('association','infData');
 return unless defined $infdata;

 my %t;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  next unless $n eq 'contact';
  $t{'type'} = $c->getAttribute('type');
  foreach  my $el2 (Net::DRI::Util::xml_list_children($c))
  {
   my ($n2,$c2)=@$el2;
   $t{$n2}=$c->textContent() if ($n2=~m/^(?:id)$/)
   }
  }

 $rinfo->{$otype}->{$oname}->{association}=\%t;

 return;
}

####################################################################################################
1;
