## Domain Registry Interface, .IT message extensions

package Net::DRI::Protocol::EPP::Extensions::IT::Message;

use strict;
use warnings;

sub register_commands
{
       my ($class, $version) = @_;
       return { 'message' => { 'result' => [ undef, \&parse_extvalue ] } };
}

####################################################################################################

sub parse_extvalue
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my @r=$mes->results_extra_info();
 return unless @r;

 foreach my $r (@r)
 {
  foreach my $rinfo (@$r)
  {
   if ($rinfo->{from} eq 'eppcom:value' && $rinfo->{type} eq 'rawxml' && $rinfo->{message}=~m!<extepp:wrongValue><extepp:element>(.+?)</extepp:element><extepp:namespace>(.+?)</extepp:namespace><extepp:value>(.+?)</extepp:value></extepp:wrongValue>!)
   {
    $rinfo->{message}="wrongValue $3 for $1";
    $rinfo->{from}='extepp';
    $rinfo->{type}='text';
   }

   if ($rinfo->{from} eq 'eppcom:extValue' && $rinfo->{type} eq 'rawxml' && $rinfo->{message}=~m!<extepp:reasonCode>(.+?)</extepp:reasonCode>!)
   {
    $rinfo->{message}="Reasoncode $1";
    $rinfo->{from}='extepp';
    $rinfo->{type}='text';
   }
  }
 }
 return;
}

1;
