## Domain Registry Interface, Afilias IPR extension (for .ME and .ASIA)
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

package Net::DRI::Protocol::EPP::Extensions::Afilias::IPR;

use strict;
use warnings;

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           create => [ \&create, undef ],
           update => [ \&update, undef ],
	   info =>   [ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

## Namespace should be set in calling superclass, as it differs in .ASIA & .ME

####################################################################################################

sub build_ipr
{
 my ($ipr)=@_;

 my @iprdata;
 foreach my $k (qw/name ccLocality number/)
 {
  my $kk=($k eq 'ccLocality') ? 'cc' : $k;
  next unless exists $ipr->{$kk} && length $ipr->{$kk};
  push @iprdata,['ipr:'.$k,$ipr->{$kk}];
 }
 foreach my $k (qw/appDate regDate/)
 {
  next unless exists $ipr->{$k};
  Net::DRI::Util::check_isa($ipr->{$k},'DateTime');
  push @iprdata,['ipr:'.$k,$ipr->{$k}->set_time_zone('UTC')->ymd()];
 }
 foreach my $k (qw/class entitlement form type preVerified/)
 {
  next unless exists $ipr->{$k} && length $ipr->{$k};
  push @iprdata,['ipr:'.$k,$ipr->{$k}];
 }

 return @iprdata;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 return unless Net::DRI::Util::has_key($rd,'ipr');
 my @n=build_ipr($rd->{ipr});

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('ipr','create');
 $mes->command_extension($eid,\@n);
 return;
}

# ipr-1.1 adds ability to change or remove (but not add?)
sub update
{
 my ($epp,$domain,$todo)=@_;
 my $todel=$todo->del('ipr');
 my $tochg=$todo->set('ipr');
 my @def=grep { defined } ($todel,$tochg);
 return unless @def; ## no updates asked

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('ipr','update');

 my @n;
 push @n,['ipr:rem',build_ipr($todel)] if defined $todel;
 push @n,['ipr:chg',build_ipr($tochg)] if defined $tochg;
 $mes->command_extension($eid,\@n);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('ipr','infData');
 return unless defined $infdata;

 my %ipr;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  if ($n=~m/^(?:name|number|class|entitlement|form|preVerified|type)$/)
  {
   $ipr{$n}=$c->textContent();
  } elsif ($n eq 'ccLocality')
  {
   $ipr{cc}=$c->textContent();
  } elsif ($n=~m/^(?:appDate|regDate)$/)
  {
   $ipr{$n}=$po->parse_iso8601($c->textContent());
  }
 }

 $rinfo->{$otype}->{$oname}->{ipr}=\%ipr;
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Afilias::IPR - Afilias IPR EPP Extension for Net::DRI

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
