## .FICORA message extension

package Net::DRI::Protocol::EPP::Extensions::FICORA::Message;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Data::Dumper;

sub register_commands
{
  my ($class, $version) = @_;
  return { 'message' => { 'retrieve' => [ undef, \&parse_poll ] } };
}

####################################################################################################

sub parse_poll
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;

  my $mes=$po->message();
  return unless $mes->is_success();

  my $msgid=$mes->msg_id();
  return unless $msgid;

  $oname=$msgid;
  $otype = $otype ? $otype : 'message';

  my $resdata = $mes->node_resdata();
  foreach my $el(Net::DRI::Util::xml_list_children($resdata)) {
    my ($name,$content)=@$el;
    next unless ($el && $content);
    my @resdata_children = Net::DRI::Util::xml_list_children($content);
    foreach my $el2(@resdata_children) {
      my ($name2,$content2)=@$el2;
      $rinfo->{$otype}->{$oname}->{$name2} = $content2->textContent();
    }
  }

  if ($rinfo->{$otype}->{$oname}->{'content'} && lc($rinfo->{$otype}->{$oname}->{'content'}) =~ m/^(contact)/ ) {
    $rinfo->{$otype}->{$oname}->{'object_type'} = 'contact';
  } else {
    $rinfo->{$otype}->{$oname}->{'object_type'} = 'domain'; # FIXME: do they have something similar for host object???
  }

  return;
}

1;
