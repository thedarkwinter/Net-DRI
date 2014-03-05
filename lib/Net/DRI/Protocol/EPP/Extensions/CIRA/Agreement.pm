## Domain Registry Interface, CIRA EPP Agreement commands
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

package Net::DRI::Protocol::EPP::Extensions::CIRA::Agreement;

use strict;
use warnings;

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 return { 'agreement' => { get => [ \&get, \&get_parse ] } };
}

sub get
{
 my ($epp,$language)=@_;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('cira:ciraInfo',sprintf('xmlns:cira="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('cira')));
 $mes->command_extension($eid,[['cira:action','get CIRA latest agreement'],['cira:language',defined $language ? $language : 'en']]);
 return;
}

sub get_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('cira','ciraInfo');
 return unless defined $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'language')
  {
   $rinfo->{agreement}->{cira}->{lang}=$c->textContent();
  } elsif ($name eq 'ciraAgreementVersion')
  {
   $rinfo->{agreement}->{cira}->{version}=$c->textContent();
  } elsif ($name eq 'ciraAgreement')
  {
   $rinfo->{agreement}->{cira}->{content}=$c->textContent();
  }
 }
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CIRA::Agreement - CIRA EPP Agreement commands for Net::DRI

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

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
