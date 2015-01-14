## .MX message extensions

package Net::DRI::Protocol::EPP::Extensions::MX::Message;

use strict;
use warnings;
use Data::Dumper;

sub register_commands
{
  my ($class, $version) = @_;
  return { 'message' => { 'retrieve' => [ undef, \&parse ] } };
}

####################################################################################################

sub parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  my $msgid=$mes->msg_id();

  foreach my $res($mes->get_extension($mes->ns('ext_msg'),'nicmx'))
  {
    next unless $res;
    foreach my $el(Net::DRI::Util::xml_list_children($res))
    {
      my ($n,$c)=@$el;
      if ($n eq 'msgTypeID')
      {
        Net::DRI::Exception::usererr_invalid_parameters('msgTypeID can only take values from 4 to 11') unless ($c->textContent() >= 4 && $c->textContent() <= 11);
        $rinfo->{message}->{$msgid}->{msg_type_id}=$c->textContent();
      }
      $rinfo->{message}->{$msgid}->{object}=$c->textContent() if $n eq 'object';
      $rinfo->{message}->{$msgid}->{msDate}=$po->parse_iso8601($c->textContent) if ($n =~ m/msDate$/);
      $rinfo->{message}->{$msgid}->{exDate}=$po->parse_iso8601($c->textContent) if ($n =~ m/exDate$/ && $rinfo->{message}->{$msgid}->{msg_type_id} eq 6); # only used in the notice of renewal (Type 6)
    }
  }

  return;
}

1;
