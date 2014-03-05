## Domain Registry Interface, VeriSign EPP Client Object Attribute Extension
## From epp-client-object-attribute.pdf
##
## Copyright (c) 2011-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::ClientAttributes;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 return { 'domain' => { 'info'   => [ undef, \&info_parse ],
                        'create' => [ \&create, undef ],
                        'update' => [ \&update, undef ],
                      } };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'coa' => [ 'urn:ietf:params:xml:ns:coa-1.0','coa-1.0.xsd' ] });
 return;
}

sub capabilities_add { return ('domain_update','client_attributes',['add','del']); }

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('coa','infData');
 return unless defined $infdata;

 my %coa;
 my $ns=$mes->ns('coa');

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$node)=@$el;
  next unless $name eq 'attr';
  $coa{Net::DRI::Util::xml_child_content($node,$ns,'key')}=Net::DRI::Util::xml_child_content($node,$ns,'value');
 }

 $rinfo->{domain}->{$oname}->{'client_attributes'}=\%coa;
 return;
}

sub add_coa
{
 my ($name,$coa)=@_;

 my @d;
 while(my ($k,$v)=each(%$coa))
 {
  Net::DRI::Exception::usererr_invalid_parameters('Key parameter must be XML token of 50 characters or less, not: '.$k)     unless Net::DRI::Util::xml_is_token($k,1,50);
  if ($name eq 'rem')
  {
   push @d,['coa:key',$k];
   next;
  }
  Net::DRI::Exception::usererr_invalid_parameters('Value parameter must be XML token of 1000 characters or less, not: '.$v) unless Net::DRI::Util::xml_is_token($v,1,1000);
  push @d,['coa:attr',['coa:key',$k],['coa:value',$v]];
 }

 return @d;
}

sub create
{
 my ($epp,$domain,$rd)=@_;

 return unless Net::DRI::Util::has_key($rd,'client_attributes');

 my $rcoa=$rd->{client_attributes};
 Net::DRI::Exception::usererr_invalid_parameters('client_attributes must be a hash ref') unless ref $rcoa eq 'HASH';

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('coa:create',sprintf('xmlns:coa="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('coa')));
 $mes->command_extension($eid,add_coa('create',$rcoa));
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;

 my $rem=$todo->del('client_attributes');
 my $put=$todo->add('client_attributes');
 return unless defined $rem || defined $put;

 my @d;
 if (defined $rem)
 {
  $rem={ $rem => undef } if ! ref $rem;
  $rem={ map { $_ => undef } @$rem } if ref $rem eq 'ARRAY';
  Net::DRI::Exception::usererr_invalid_parameters('client_attributes to delete must be a hash ref') unless ref $rem eq 'HASH';
  push @d,['coa:rem',add_coa('rem',$rem)];
 }
 if (defined $put)
 {
  Net::DRI::Exception::usererr_invalid_parameters('client_attributes to add must be a hash ref') unless ref $put eq 'HASH';
  push @d,['coa:put',add_coa('put',$put)];
 }

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('coa:update',sprintf('xmlns:coa="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('coa')));
 $mes->command_extension($eid,@d);
 return;
}

#########################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::ClientAttributes - VeriSign EPP Client Object Attribute Extension for Net::DRI

=head1 SYNOPSIS

        $dri=Net::DRI->new();
        $dri->add_registry('VNDS',{client_id=>'XXXXXX');

        $rc=$dri->domain_info('whatever.com');
        $rh=$rc->get_data('client_attributes');

This extension is loaded by default during add_profile.

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

Copyright (c) 2011-2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
