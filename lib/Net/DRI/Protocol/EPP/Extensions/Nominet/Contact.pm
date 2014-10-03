## Domain Registry Interface, .UK EPP Contact commands
##
## Copyright (c) 2008-2010,2013-2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Protocol::EPP::Core::Contact;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::Contact - .UK EPP Contact commands for Net::DRI

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

Copyright (c) 2008-2010,2013-2014 Patrick Mevzek <netdri@dotandco.com>.
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
		info   => [ undef, \&info_parse ],
		create => [ \&create ],
		update => [ \&update ],
        fork    => [ \&fork, \&Net::DRI::Protocol::EPP::Core::Contact::create_parse ],
        lock => [ \&lock ],
	);

 return { 'contact' => \%tmp };
}

####################################################################################################
########### Query commands

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('contact-nom-ext','infData');
 return unless $infdata;

 my $s=$rinfo->{contact}->{$oname}->{self};
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  $s->type($c->textContent()) if $name eq 'type';
  $s->co_no($c->textContent()) if $name eq 'co-no';
  $s->opt_out($c->textContent()) if $name eq 'opt-out';
  $s->trad_name($c->textContent()) if $name eq 'trad-name';
 }
 return;
}

############ Transform commands ####################################################################

sub contact_nom_ext
{
 my $c=shift;
 my @n;
 push @n, ['contact-nom-ext:trad-name', $c->trad_name()] if defined $c->trad_name();
 push @n, ['contact-nom-ext:type', $c->type()] if defined $c->type();
 push @n, ['contact-nom-ext:co-no', $c->co_no()] if defined $c->co_no();
 push @n, ['contact-nom-ext:opt-out', $c->opt_out()] if defined $c->opt_out();
 return @n;
}

sub create
{
 my ($epp,$c)=@_;
 my @n = contact_nom_ext($c);
 return unless @n;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('contact-nom-ext:create',sprintf('xmlns:contact-nom-ext="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('contact-nom-ext')));
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 # I don't think name/org can be updated so this should be checked and return an exception. If they are the same then just remove from the changes
 my ($epp,$c,$todo)=@_;
 my $tochg = $todo->set('info');
 return unless $tochg;
 my @n = contact_nom_ext($tochg);
 return unless @n;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('contact-nom-ext:update',sprintf('xmlns:contact-nom-ext="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('contact-nom-ext')));
 $mes->command_extension($eid,\@n);
 return;
}

sub fork ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$c,$rd)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_insufficient_parameters('Contact srID is required') unless $c->srid();
 Net::DRI::Exception::usererr_insufficient_parameters('newContactID is required') unless $rd->{newContactId};
 $mes->command(['update','f:fork',sprintf('xmlns:f="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('std-fork'))]);
 my @doms = @{$rd->{domains}};
 my @d=(['f:contactID',$c->srid()],['f:newContactId',$rd->{newContactId}]);
 foreach (@doms) { push @d,['f:domainName',$_]; }
 $mes->command_body(\@d);
 return;
}

sub lock ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$c,$rd)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_insufficient_parameters('Contact srID is required') unless $c->srid();
 Net::DRI::Exception::usererr_insufficient_parameters('type must be set to investigation OR opt-out to lock a contact') unless $rd->{type} && $rd->{type} =~ m/^(investigation|opt-out)$/;
 $mes->command(['update','l:lock',sprintf('xmlns:l="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('std-locks')). ' object="contact" type="'.$rd->{type}.'"']);
 my @d=(['l:contactId',$c->srid()]);
 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;
