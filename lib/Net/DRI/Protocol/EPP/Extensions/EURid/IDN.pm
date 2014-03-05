## Domain Registry Interface, EURid IDN EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::EURid::IDN;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
          create => [ undef, \&_parse ],
          info   => [ undef, \&_parse ],
          check  => [ undef, \&check_parse ],
          renew  => [ undef, \&_parse ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'idn' => [ 'http://www.eurid.eu/xml/epp/idn-1.0','idn-1.0.xsd' ] });
 return;
}

####################################################################################################

sub get_names
{
 my ($mes,$node)=@_;
 my $ns=$mes->ns('idn');
 my @r;
 foreach my $e (Net::DRI::Util::xml_traverse($node,$ns,'name'))
 {
  push @r,[Net::DRI::Util::xml_child_content($e,$ns,'ace'),Net::DRI::Util::xml_child_content($e,$ns,'unicode')];
 }

 return @r;
}

sub _parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('idn','mapping');
 return unless defined $data;

 ($rinfo->{domain}->{$oname}->{ace},$rinfo->{domain}->{$oname}->{unicode})=@{(get_names($mes,$data))[0]};
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_extension('idn','mapping');
 return unless defined $chkdata;

 foreach my $ra (get_names($mes,$chkdata))
 {
  my ($a,$u)=@$ra;
  my $dom=exists $rinfo->{domain}->{$a} ? $a : $u;
  $rinfo->{domain}->{$dom}->{ace}=$a;
  $rinfo->{domain}->{$dom}->{unicode}=$u;
 }
 return;
}

####################################################################################################
1;


__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::IDN - EURid IDN EPP Extension for Net::DRI

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

Copyright (c) 2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

