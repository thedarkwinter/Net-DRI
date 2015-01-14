## Domain Registry Interface, .MX domain extensions from 'EPP Manual 2.0 MX.PDF'
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::MX::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

use DateTime::Format::ISO8601;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::MX::Domain - .MX EPP Domain extension commands for Net::DRI

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

Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>.
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
          restore => [ \&restore, undef ],
         );

 return { 'domain' => \%tmp };
}

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:nicmx-domrst="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ext_domrst')));
}

####################################################################################################

sub build_command
{
 my ($domain)=@_;
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless (defined($domain) && $domain && !ref($domain));
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Domain name not in .MX: '.$domain) unless $domain=~m/\.MX$/i;
 return ['nicmx-domrst:name',$domain];
}

sub restore_build_command
{
  my ($msg,$command,$restore)=@_;
  my @res=ref $restore ? @$restore : ($restore);
  Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless @res;
  foreach my $r (@res)
  {
    Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined $r && $r;
    Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$r) unless Net::DRI::Util::xml_is_token($r,1,255);
  }
  my $tcommand='restore';
  $msg->command([$command,'nicmx-domrst:'.$tcommand,sprintf('xmlns:nicmx-domrst="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('ext_domrst'))]);
  return ['nicmx-domrst:name',$restore];
}

# created like it's in the manual - command looks strange!!! They say it's a domain_renew without the curExpDate and duration elements
sub restore
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
  my @d=restore_build_command($mes,'renew',$domain);
  $mes->command_body(\@d);
  return;
}

####################################################################################################
1;