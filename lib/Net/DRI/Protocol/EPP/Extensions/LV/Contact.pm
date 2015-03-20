## Domain Registry Interface, .LV Contact EPP extension commands [http://www.nic.lv/eppdoc/html/extensions/lvcontact.html]
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::LV::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use DateTime::Format::ISO8601;
use utf8;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LV::Contact - .LV EPP Contact extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

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
		update => [ \&update, undef ],
		info   => [ undef, \&info_parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub update {
	my ($epp, $c, $todo) = @_;
	my $mes = $epp->message();
	my $newc=$todo->set('info');
	
	my @e;
	
	return unless defined $c->vat() || $c->orgno();
	push @e,[ 'lvcontact:vatNr', $c->vat() ] if (defined $c->vat());
	push @e,[ 'lvcontact:regNr', $c->orgno() ] if (defined $c->orgno());
	
	my $eid=$mes->command_extension_register('lvcontact:update',sprintf('xmlns:lvcontact="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ext_contact')));
	$mes->command_extension($eid,\@e);
	
	return;
}

sub info_parse {
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
	my $mes=$po->message();
	return unless $mes->is_success();
	
	my $NS = $mes->ns('ext_contact');
	my $c = $rinfo->{contact}->{$oname}->{self};
	my $adata = $mes->get_extension('ext_contact','infData');
	
	return unless $adata;
		
	my $s=$rinfo->{contact}->{$oname}->{self};
	foreach my $el (Net::DRI::Util::xml_list_children($adata)) {
	 	my ($name,$c)=@$el;
	 		if ($name eq 'vatNr') {
	 			$s->vat($c->textContent());
	 		} elsif ($name eq 'regNr') {
	 			$s->orgno($c->textContent());
	 		}
	}
	
	return;
}

sub create {
	my ($epp,$c) = @_;
	my $mes = $epp->message;
	my @e;
	
	return unless defined $c->vat() || $c->orgno();
	
	push @e,[ 'lvcontact:vatNr', $c->vat() ] if (defined $c->vat());
	push @e,[ 'lvcontact:regNr', $c->orgno() ] if (defined $c->orgno());
	
	my $eid=$mes->command_extension_register('lvcontact:create',sprintf('xmlns:lvcontact="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ext_contact')));
	$mes->command_extension($eid,\@e);
	
	return;
}

####################################################################################################
1;