## Domain Registry Interface, ES Contact EPP extension commands
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ES::Contact;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ES::Contact - ES EPP Contact extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT
Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
                       (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
          create            => [ \&create, undef ],
          info              => [ undef, \&info_parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub create
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();

 # these fields all cause xml.sax errorson the server  unless they are ommited
 my @command_body;
 foreach my $el (@{$mes->{'command_body'}}) {
  push @command_body,$el unless $el->[0] =~ m/(id|authInfo|disclose)$/;
 }

 push @command_body, ['contact:es_tipo_identificacion',$c->tipo_identificacion()];
 push @command_body, ['contact:es_identificacion',$c->identificacion()];
 push @command_body, ['contact:es_form_juridica',$c->form_juridica()] if defined($c->form_juridica());
 $mes->{'command_body'} = undef;
 $mes->command_body(@command_body);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response('contact','infData');
 return unless defined $infdata;

 my $s=$rinfo->{contact}->{$oname}->{self};
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  $s->tipo_identificacion($c->textContent()) if $name eq "es_tipo_identificacion";
  $s->identificacion($c->textContent()) if $name eq "es_identificacion";
  $s->form_juridica($c->textContent()) if $name eq "es_form_juridica";
 }
}

####################################################################################################
1;
