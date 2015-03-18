## Domain Registry Interface, .LV Domain EPP extension commands [http://www.nic.lv/eppdoc/html/extensions/lvdomain.html]
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

package Net::DRI::Protocol::EPP::Extensions::LV::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use DateTime::Format::ISO8601;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Data::Hosts;
use utf8;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LV::Domain - .LV EPP Domain extension commands for Net::DRI

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
          update => [ \&update, undef ],
          info   => [ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub update { 
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 
 return unless defined $rd->set('auto_renew');
 my @e;
 my $user_message = $rd->set('auto_renew_message');
  
 if ( $rd->set('auto_renew') eq 'false' || $rd->set('auto_renew') eq '0' || $rd->set('auto_renew') eq 'no') {
 	 if (defined $user_message) {
 	 	push @e,['lvdomain:rem',['lvdomain:status',{ s => 'clientAutoRenewProhibited', lang => $user_message->{'lang'} }, $user_message->{'message'} ]];
 	 } else {
 	 	push @e,['lvdomain:rem',['lvdomain:status',{ s => 'clientAutoRenewProhibited'}]];
 	 }	
 } else {
 	 if (defined $user_message) {
 	 	push @e,['lvdomain:add',['lvdomain:status',{ s => 'clientAutoRenewProhibited', lang => $user_message->{'lang'} }, $user_message->{'message'} ]];
 	 } else {
 	 	push @e,['lvdomain:add',['lvdomain:status',{ s => 'clientAutoRenewProhibited'}]];
 	 }
 }

 my $eid=$mes->command_extension_register('lvdomain:update',sprintf('xmlns:lvdomain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ext_domain')));
 $mes->command_extension($eid,\@e);

 return;
}

sub info_parse {
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $NS = $mes->ns('ext_domain');
 my $c = $rinfo->{domain}->{$oname}->{self};
 my $adata = $mes->get_extension('ext_domain','infData');
 
 unless(defined($adata)) {
 	$rinfo->{domain}->{$oname}->{auto_renew}='1';
 	return;
 } else {
 	$rinfo->{domain}->{$oname}->{auto_renew}='0';
 }

 my $msg = {};
 
 foreach my $el (Net::DRI::Util::xml_list_children($adata)) {
 	my ($name,$c)=@$el;
 		if ($name eq 'status') {
 			$msg->{message} = $c->textContent();
 			$msg->{lang} = $c->getAttribute('lang') if $c->hasAttribute('lang');
 		}
 }
 $rinfo->{domain}->{$oname}->{auto_renew_message} = $msg;
 return;
}

####################################################################################################
1;
