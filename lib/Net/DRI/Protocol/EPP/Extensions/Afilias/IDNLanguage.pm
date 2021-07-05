## Domain Registry Interface, EPP IDN Language (EPP-IDN-Lang-Mapping.pdf)
##
## Copyright (c) 2007,2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Afilias::IDNLanguage;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Afilias::IDNLanguage - Afilias EPP IDN Language commands (EPP-IDN-Lang-Mapping.pdf) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> and
E<lt>http://oss.bdsprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
           create => [ \&create, undef ],
           check =>  [ \&check, undef ],
           check_multi =>  [ \&check, undef ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
  my ($class,$po,$version)=@_;
  $po->ns({'idn' =>['urn:afilias:params:xml:ns:idn-1.0','idn-1.0.xsd']});
}

####################################################################################################

sub add_language
{
 my ($tag,$epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $script;
 if (Net::DRI::Util::has_key($rd,'idn') && UNIVERSAL::isa($rd->{idn},'Net::DRI::Data::IDN') && defined $rd->{idn}->iso639_1()) { # use IDN object if possible
  $script = $rd->{idn}->iso639_1() . (defined $rd->{idn}->extlang() ? '-'.$rd->{idn}->extlang():''); # Warning, I *think* .asia uses different codes here?
 } 
 elsif (Net::DRI::Util::has_key($rd,'language')) # Fall back to old/standard
 {
  Net::DRI::Exception::usererr_invalid_parameters('IDN language tag must be of type XML schema language') unless Net::DRI::Util::xml_is_language($rd->{language});
  $script = $rd->{language};
 }
 return unless $script;
 my $eid=$mes->command_extension_register('idn',$tag);
 $mes->command_extension($eid,['idn:script', $script]);
 return;
}

sub create { return add_language('create',@_); }

sub check { return add_language('check',@_); }

####################################################################################################
1;
