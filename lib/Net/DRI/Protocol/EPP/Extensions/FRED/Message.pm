## Domain Registry Interface, FRED Poll EPP extension commands
##
## Copyright (c) 2014-2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
################################################################################

package Net::DRI::Protocol::EPP::Extensions::FRED::Message;

use strict;
use warnings;
use POSIX qw(strftime);

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FRED::Message - FRED Message extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 AUTHOR

David Makuni, E<lt>d.makuni@live.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 2014-2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
  my ($class, $version) = @_;
  return { 'message' => { 'retrieve' => [ undef, \&parse_poll ] } };
}

####################################################################################################

sub parse_poll {
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;

  my $mes=$po->message();
  return unless $mes->is_success();

  my $msgid=$mes->msg_id();
  my $msg_content = $mes->node_msg();
  return unless ((defined($msgid) && $msgid) && (defined($msg_content) && $msg_content));

  $oname = $msgid;
  $otype = $otype ? $otype : 'message';

  my @res_children = Net::DRI::Util::xml_list_children($msg_content);
  foreach my $el(@res_children) {
    my ($n,$c)=@$el;
    if ($n eq 'trnData') {
      my @trnData = Net::DRI::Util::xml_list_children($c);
      foreach my $el(@trnData) {
        my ($n,$c)=@$el;
        if ($n eq 'trDate') {
          $rinfo->{$otype}->{$oname}->{action} = 'transfer';
          $rinfo->{$otype}->{$oname}->{object_type} = 'domain';
          $rinfo->{$otype}->{$oname}->{object_id} = $rinfo->{$otype}->{$oname}->{name}
            if ($rinfo->{$otype}->{$oname}->{name});
        }
        if ($n eq 'clID') {
          $rinfo->{$otype}->{$oname}->{reID} = $c->textContent() ? $c->textContent() : '' if ($n);
        }
        $rinfo->{$otype}->{$oname}->{$n} = $c->textContent() ? $c->textContent() : '' if ($n);
      }
    }
  }

  return;

}

1;
