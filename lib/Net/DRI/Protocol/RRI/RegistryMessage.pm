## Domain Registry Interface, RRI Registry messages commands (DENIC-11)
##
## Copyright (c) 2008,2012 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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
#########################################################################################

package Net::DRI::Protocol::RRI::RegistryMessage;

use strict;
use warnings;

use DateTime::Format::ISO8601 ();

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::RRI::RegistryMessage - RRI Registry messages commands (DENIC-11) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/project/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
           retrieve => [ \&pollreq, \&parse_poll ],
           delete   => [ \&pollack ],
         );

 return { 'message' => \%tmp };
}

sub pollack
{
 my ($rri, $msgid) = @_;
 my $mes = $rri->message();
 $mes->command(['msg', 'delete', $mes->ns->{msg}->[0], {msgid => $msgid}]);
 return;
}

sub pollreq
{
 my ($rri,$msgid)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('In RRI, you can not specify the message id you want to retrieve') if defined($msgid);
 my $mes = $rri->message();
 $mes->command(['msg', 'queue-read', $mes->ns->{msg}->[0]]);
 $mes->cltrid(undef);
 return;
}

## We take into account all parse functions, to be able to parse any result
sub parse_poll
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes = $po->message();
 return unless $mes->is_success();
 my $msgdata = $mes->get_content('message', $mes->ns('msg'));
 return unless ($msgdata);

 my $msgid = $msgdata->getAttribute('msgid');
 return unless (defined($msgid) && $msgid);
 $rinfo->{message}->{session}->{last_id}=$msgid; ## needed here and not lower below, in case of pure text registry message
 
 my $rd = {};
 $rd->{id} = $msgid;

 $rd->{lang} = 'en';
 $rd->{qdate} = DateTime::Format::ISO8601->new()->parse_datetime($msgdata->getAttribute('msgtime'));
 $rd->{objtype} = 'domain';

 my $el = $msgdata;#->getFirstChild();
 my $action = undef;
 my @actions = ( 'authInfo2Notify', 'authInfo2Delete', 'authInfoExpire', 'chprovAuthInfo', 'expire', 'expireWarning', 'domainDelete' );
 foreach (@actions) {
  next unless ($el->getElementsByTagNameNS($mes->ns('msg'), $_));
  $action = $rd->{action} = $_;
 }

 # domain and clID
  my @doms = $el->getElementsByTagNameNS($mes->ns('msg'), 'domain');
  my @news = $el->getElementsByTagNameNS($mes->ns('msg'), 'new');
  my @olds = $el->getElementsByTagNameNS($mes->ns('msg'), 'old');
  my $dom = $doms[0];
 my $new;
 $new = $news[0]->getFirstChild()->getData() if (@news);
 $rd->{clID} = $new if (length($new));
 my $old;
 $old = $olds[0]->getFirstChild()->getData() if (@olds);
 $rd->{oldID} = $old if (length($old)); # should this be acID ? its already left the account
 my $dn;
  if ($dom)
  {
   my @hndls = $dom->getElementsByTagNameNS($mes->ns('msg'), 'handle');
   my @exps = $dom->getElementsByTagNameNS($mes->ns('msg'), 'expire');
   my $hndl = $hndls[0];

   $dn = $rd->{object_id} = $hndl->getFirstChild()->getData() if (@hndls);
   $rd->{exDate} = DateTime::Format::ISO8601->new()->parse_datetime($exps[0]->getFirstChild()->getData()) if (@exps);

   my @authexps = $el->getElementsByTagNameNS($mes->ns('msg'), 'authinfoexpire');
   $rd->{authInfoExpire} = DateTime::Format::ISO8601->new()->parse_datetime($authexps[0]->getFirstChild()->getData()) if (@authexps);
  }

 $rd->{content} = $dn . ' change of provider to ' . $new if ($action eq 'chprovAuthInfo');
 $rd->{content} = $dn . ' will expire on ' .  $rd->{exDate}->ymd . ' at ' . $rd->{exDate}->hms if ($action eq 'expireWarning');
 $rd->{content} = $dn . ' expired on ' .  $rd->{exDate}->ymd . ' at ' . $rd->{exDate}->hms if ($action eq 'expire');
 $rd->{content} = $dn . ' deleted by DENIC legal department on ' .  $rd->{exDate}->ymd . ' at ' . $rd->{exDate}->hms if ($action eq 'domainDelete');
 $rd->{content} = $dn . ' authinfo expired on '.  $rd->{authInfoExpire}->ymd if ($action eq 'authInfoExpire');
 $rd->{content} = $dn . ' authinfo2 created' if ($action eq 'authInfo2Notify');
 $rd->{content} = $dn . ' authinfo2 deleted' if ($action eq 'authInfo2Delete');
 $rd->{content} = $dn . ' ' . $action unless (defined $rd->{content});
 
 $rinfo->{message}->{$msgid} = $rd;
 return;
}

####################################################################################################
1;
