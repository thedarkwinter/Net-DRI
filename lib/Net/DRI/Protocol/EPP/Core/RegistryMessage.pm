## Domain Registry Interface, EPP Registry messages commands (RFC5730)
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Core::RegistryMessage;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::RegistryMessage - EPP Registry messages commands (RFC5730) for Net::DRI

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

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($epp,$msgid)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_invalid_parameters('In EPP, you must specify the message id (XML token) you want to delete') unless Net::DRI::Util::xml_is_token($msgid);
 $mes->command([['poll',{op=>'ack',msgID=>$msgid}]]);
 return;
}

sub pollreq
{
 my ($epp,$msgid)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('In EPP, you can not specify the message id you want to retrieve') if defined($msgid);
 my $mes=$epp->message();
 $mes->command([['poll',{op=>'req'}]]);
 return;
}

## We take into account all parse functions, to be able to parse any result
sub parse_poll
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 return if exists $rinfo->{_processing_parse_poll}; ## calling myself here would be a very bad idea !
 my $mes=$po->message();
 return unless $mes->is_success();

 my $msgid=$mes->msg_id();
 return unless (defined($msgid) && $msgid);
 $rinfo->{message}->{session}->{last_id}=$msgid; ## needed here and not lower below, in case of pure text registry message

 ## Was there really a registry message with some content ?
 return unless ($mes->result_code() == 1301 && (defined($mes->node_resdata()) || defined($mes->node_extension()) || defined($mes->node_msg())));

 my $rd=$rinfo->{message}->{$msgid}; ## already partially filled by Message::parse()
 my ($totype,$toaction,$toname); ## $toaction will remain undef, but could be $haction if only one
 my %info;
 my $h=$po->commands();

 while (my ($htype,$hv)=each(%$h))
 {
  ## Because of new Perl hash keys randomization, we must make sure review_complete action is done first
  ## as it will setup $toname & such
  my @k=keys(%$hv);
  foreach my $haction ((grep { $_ eq 'review_complete' } @k),(sort { $a cmp $b } grep { $_ ne 'review_complete' } @k))
  {
   next if $htype eq 'message' && $haction eq 'result';
   foreach my $t (@{$hv->{$haction}})
   {
    my $pf=$t->[1];
    next unless (defined($pf) && (ref($pf) eq 'CODE'));
    $info{_processing_parse_poll}=1;
    $pf->($po,$totype,$toaction,$toname,\%info);
    delete $info{_processing_parse_poll};
    my @tmp=grep { $_ ne '_internal' } keys %info;
    next unless @tmp;
    next if defined($toname); ## this must be there and not optimised as a last call further below as there can be multiple information to parse for a given $toname
    Net::DRI::Exception::err_assert('EPP::parse_poll can not handle multiple types !') unless @tmp==1;
    $totype=$tmp[0];
    @tmp=keys %{$info{$totype}};
    Net::DRI::Exception::err_assert('EPP::parse_poll can not handle multiple names !') unless @tmp==1; ## this may happen for check_multi !
    $toname=$tmp[0];
    $info{$totype}->{$toname}->{name}=$toname;
   }
  }
 }

 ## If message not completely in the <msg> node, we have to parse something !
 Net::DRI::Exception::err_assert('EPP::parse_poll was not able to parse anything, please report !') if ((defined($mes->node_resdata()) || defined($mes->node_extension())) && ! defined $toname);

 ## Copy local %info into $rd (which is in fact global info as set above) someway (we're working with references)
 ## Here, $rd=$rinfo->{message}->{$msgid}
 $rd->{object_type}=$totype;
 $rd->{object_id}=$toname; ## this has to be taken broadly, it is in fact a name for domains and hosts
 while(my ($k,$v)=each(%{$info{$totype}->{$toname}}))
 {
  $rd->{$k}=$v;
 }
 ## Also update data about the queried object, for easier access
 while(my ($k,$v)=each(%$rd))
 {
  $rinfo->{$totype}->{$toname}->{$k}=$v;
 }
 return;
}

####################################################################################################
1;
