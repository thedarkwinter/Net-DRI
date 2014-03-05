## Domain Registry Interface, VeriSign Zone Management EPP extension
##
## Copyright (c) 2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::ZoneManagement;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 return { 'domain' => { create => [ \&domain_create_generate, undef ],
                        info   => [ undef, \&domain_info_parse ],
                        update => [ \&domain_update_generate, undef ] },
        };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'zoneMgt' => [ 'http://www.verisign.com/epp/zoneMgt-1.0','zoneMgt-1.0.xsd' ],
         });
 return;
}

####################################################################################################

sub _generate_rrecs
{
 my ($rr)=@_;
 my @d=ref $rr eq 'ARRAY' ? @$rr : ($rr);

 Net::DRI::Exception::usererr_invalid_parameters('RRs must be array of ref hashes') if grep { ref $_ ne 'HASH' } @d;
 my @r;
 foreach my $r (@d)
 {
  my @rr;
  Net::DRI::Exception::usererr_insufficient_parameters('In RR, "type" key must exist') unless Net::DRI::Util::has_key($r,'type');
  Net::DRI::Exception::usererr_invalid_parameters('In RR, for key "type", value must be an XML token') unless Net::DRI::Util::xml_is_token($r->{type});
  push @rr,['zoneMgt:type',$r->{type}];
  if (Net::DRI::Util::has_key($r,'class'))
  {
   Net::DRI::Exception::usererr_invalid_parameters('In RR, for key "class", value must be an XML token, if provided') unless Net::DRI::Util::xml_is_token($r->{class});
   push @rr,['zoneMgt:class',$r->{class}];
  } else
  {
   push @rr,['zoneMgt:class','IN'];
  }
  if (Net::DRI::Util::has_key($r,'ttl'))
  {
   Net::DRI::Exception::usererr_invalid_parameters('In RR, for key "tll", value must be an XML integeter, if provided') unless Net::DRI::Util::verify_int($r->{ttl});
   push @rr,['zoneMgt:ttl',$r->{ttl}];
  }
  Net::DRI::Exception::usererr_insufficient_parameters('In RR, "rdata" key must exist') unless Net::DRI::Util::has_key($r,'rdata');
  Net::DRI::Exception::usererr_invalid_parameters('In RR, for key "rdata", value must be an XML token') unless Net::DRI::Util::xml_is_token($r->{rdata});
  push @rr,['zoneMgt:rdata',$r->{rdata}];
  push @r,['zoneMgt:rrec',@rr];
 }
 return @r;
}

sub domain_create_generate
{
 my ($epp,$domain,$rp)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rp,'zone');

 my $eid=$mes->command_extension_register('zoneMgt','create');
 $mes->command_extension($eid,[_generate_rrecs($rp->{zone})]);
 return;
}

sub domain_info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_response('zoneMgt','infData');
 return unless defined $data;

 my @r;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$c)=@$el;
  my %r;
  if ($name eq 'rrec')
  {
   foreach my $subel (Net::DRI::Util::xml_list_children($c))
   {
    my ($subname,$subc)=@$subel;
    if ($subname=~m/^(type|class|ttl|rdata)$/)
    {
     $r{$1}=$subc->textContent();
    }
   }
   push @r,\%r;
  }
 }

 $rinfo->{domain}->{$oname}->{zone}=\@r;
 return;
}

sub domain_update_generate
{
 my ($epp,$domain,$todo,$rp)=@_;

 if (grep { ! /^(?:add|del)$/ } $todo->types('zone'))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only zone add/del available for domain');
 }

 my $zadd=$todo->add('zone');
 my $zdel=$todo->del('zone');
 return unless $zadd || $zdel;

 my @n;
 push @n,['zoneMgt:add',_generate_rrecs($zadd)] if $zadd;
 push @n,['zoneMgt:rem',_generate_rrecs($zdel)] if $zdel;

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('zoneMgt','update');
 $mes->command_extension($eid,\@n);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::ZoneManagement - VeriSign Zone Management EPP for Net::DRI

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

Copyright (c) 2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
