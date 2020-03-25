## Domain Registry Interface, .PL Contact EPP extension commands
##
## Copyright (c) 2006,2008,2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::EPP::Extensions::PL::Contact;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PL::Contact - .PL EPP Contact extension commands for Net::DRI

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

Copyright (c) 2006,2008,2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
          info   => [ \&info, \&info_parse ],
          update => [ \&update, undef ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub add_individual_element
{
 my ($epp,$contact,$op)=@_;
 my $mes=$epp->message();

 ## validate() has already been called
 my $ind=$contact->individual();

 return unless (defined($ind));
 my @e;
 push @e,['extcon:individual',$ind]           if defined($ind);

 $epp->message()->command_extension('extcon', [$op, @e]);
 return;
}

sub create
{
 my ($epp,$contact)=@_;
 return add_individual_element($epp,$contact,'create');
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $newc=$todo->set('info');
 return unless $newc;
 return add_individual_element($epp,$newc,'update');
}

sub info
{
 my ($epp,$contact,$ep)=@_;
 my $mes=$epp->message();

 return unless (Net::DRI::Util::has_auth($ep) && exists $ep->{auth}->{pw});
 if (Net::DRI::Util::has_key($ep->{auth},'roid'))
 {
  $mes->command_extension('extcon', ['info', ['extcon:authInfo',['extcon:pw',{roid=>$ep->{auth}->{roid}},$ep->{auth}->{pw}]]]);
 } else {
  $mes->command_extension('extcon', ['info', ['extcon:authInfo',['extcon:pw',$ep->{auth}->{pw}]]]);
 }
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('extcon','infData');
 return unless defined $infdata;

 my $contact=$rinfo->{contact}->{$oname}->{self};

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'individual')
  {
   $contact->individual(Net::DRI::Util::xml_parse_boolean($c->textContent()));
  }
 }
 return;
}

####################################################################################################
1;
