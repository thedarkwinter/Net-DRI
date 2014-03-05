## Domain Registry Interface, VeriSign EPP WhoWas Extension
##
## Copyright (c) 2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::WhoWas;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 return { 'domain' => { 'whowas' => [ \&whowas_info, \&whowas_parse ] } };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'whowas' => [ 'http://www.verisign.com/epp/whowas-1.0','whowas-1.0.xsd' ] });
 return;
}

####################################################################################################

sub whowas_info
{
 my ($epp,$domain,$rd)=@_;

 Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined $domain && length $domain;
 my $isroid=0;
 if (index($domain,'.') > -1)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);
 } else
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid ROID value: '.$domain) unless Net::DRI::Util::is_roid($domain);
  $isroid=1;
 }
 my $mes=$epp->message();
 $mes->command(['info','whowas:info',sprintf('xmlns:whowas="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('whowas'))]);
 $mes->command_body([['whowas:type','domain'],[$isroid ? 'whowas:roid' : 'whowas:name',$domain]]);
 return;
}

sub whowas_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response('whowas','infData');
 return unless defined $infdata;

 my %r=(action => 'whowas', name => undef, type => undef, history => []);
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'type')
  {
   $r{type}=$c->textContent();
  } elsif ($name eq 'name')
  {
   $r{name}=$c->textContent();
  } elsif ($name eq 'history')
  {
   foreach my $subel (Net::DRI::Util::xml_list_children($c))
   {
    my ($subname,$subnode)=@$subel;
    next unless $subname eq 'rec';
    my %rec;
    foreach my $rec (Net::DRI::Util::xml_list_children($subnode))
    {
     my ($recname,$recnode)=@$rec;
     if ($recname=~m/^(?:name|newName|roid|op|clID|clName)$/)
     {
      $rec{$recname}=$recnode->textContent();
     } elsif ($recname eq 'date')
     {
      $rec{$recname}=$po->parse_iso8601($recnode->textContent());
     }
    }
    push @{$r{history}},\%rec;
   }
  }
 }

 my $name=$r{name};
 delete $r{name};
 $rinfo->{$otype}->{$name}=\%r;
 return;
}

#########################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::WhoWas - VeriSign EPP WhoWas Extension for Net::DRI

=head1 SYNOPSIS

        $dri=Net::DRI->new();
        $dri->add_registry('VNDS',{client_id=>'XXXXXX');

        ...

        $dri->domain_whowas('test.com');

This extension is automatically loaded when using the VNDS registry driver.

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

Copyright (c) 2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
