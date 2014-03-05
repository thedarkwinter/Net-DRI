## Domain Registry Interface, Afilias Trademark extension (for .INFO .MOBI .IN)
##
## Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Afilias::Trademark;

use strict;
use warnings;

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           create =>	[ \&create, undef ],
## update
	   info =>	[ undef, \&info_parse ]
         );

 return { 'domain' => \%tmp };
}

## Namespace should be set in calling superclass, as it differs in each TLD !
##
## INFO requires: name, country, number, date
## MOBI requires: name, country, number, regDate, appDate
##   IN requires: name, country, number, date, ownerCountry

####################################################################################################

sub create
{
 my ($epp,$domain,$rd)=@_;

 return unless Net::DRI::Util::has_key($rd,'trademark');
 my $rt=$rd->{trademark};

 my @t;
 foreach my $k (qw/name country number/)
 {
  next unless exists $rt->{$k} && length $rt->{$k};
  push @t,['trademark:'.$k,$rt->{$k}];
 }
 foreach my $k (qw/date regDate appDate/)
 {
  next unless exists $rt->{$k};
  Net::DRI::Util::check_isa($rt->{$k},'DateTime');
  push @t,['trademark:'.$k,$rt->{$k}->set_time_zone('UTC')->ymd()];
 }
 foreach my $k (qw/ownerCountry/)
 {
  next unless exists $rt->{$k} && length $rt->{$k};
  push @t,['trademark:'.$k,$rt->{$k}];
 }

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('trademark:create',sprintf('xmlns:trademark="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('trademark')));
 $mes->command_extension($eid,\@t);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('trademark','infData');
 return unless defined $infdata;

 my %t;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  if ($n=~m/^(?:name|country|number|ownerCountry)$/)
  {
   $t{$n}=$c->textContent();
  } elsif ($n=~m/^(?:date|appDate|regDate)$/)
  {
   $t{$n}=$po->parse_iso8601($c->textContent());
  }
 }

 $rinfo->{$otype}->{$oname}->{trademark}=\%t;
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Afilias::Trademark - Afilias Trademark EPP Extension for Net::DRI

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

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
