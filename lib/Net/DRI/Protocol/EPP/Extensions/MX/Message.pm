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

  my @ns = ('nicmx', 'niclat'); # to parse into message defined by the Registry
  # TODO: confirm the next 3 variable. Check if MX didn't change because of NGTLD!
  my $min_type_id = 4;
  my $max_type_id = 11;
  my $ex_date_renew = 6;

  foreach (@ns) {
    $max_type_id = 22 if $_ eq 'niclat'; # more codes for .LAT TLD
    $ex_date_renew = 5 if $_ eq 'niclat'; # date renew code different from .MX. Why? :(
    my $profile_namespace = $_.'-msg'; # with recent Net-DRI namespace tweaks we need to get/build this properly :)
    foreach my $res($mes->get_extension($profile_namespace, $_))
    {
      next unless $res;
      my @res_children = Net::DRI::Util::xml_list_children($res);
      foreach my $el(@res_children) {
        my ($n,$c)=@$el;
        $oname = $c->textContent() if ($n eq 'object'); # get oname
      }
      foreach my $el(@res_children)
      {
        my ($n,$c)=@$el;
        $otype = $otype ? $otype : 'domain'; # set to domain if undef (which it appears to be)
        if ($n eq 'msgTypeID')
        {
          Net::DRI::Exception::usererr_invalid_parameters('msgTypeID can only take values from ' . $min_type_id . ' to ' . $max_type_id) unless ($c->textContent() >= $min_type_id && $c->textContent() <= $max_type_id);
          $rinfo->{$otype}->{$oname}->{msg_type_id}=$c->textContent();
        }
        $rinfo->{$otype}->{$oname}->{$n}=$c->textContent();
        $rinfo->{$otype}->{$oname}->{msDate}=$po->parse_iso8601($c->textContent) if ($n =~ m/msDate$/);
        $rinfo->{$otype}->{$oname}->{exDate}=$po->parse_iso8601($c->textContent) if ($n =~ m/exDate$/ && $rinfo->{$otype}->{$oname}->{msg_type_id} eq $ex_date_renew); # only used in the notice of renewal (Type 6 for MX and Type 5 for LAT)
      }
    }
  }

  return;
}

1;
