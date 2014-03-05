## Domain Registry Interface, VeriSign Balance object mapping EPP extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::Balance;

use strict;
use warnings;

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 return { 'balance' => { info   => [ \&balance_info_build, \&balance_info_parse ],
                       },
        };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'balance' => [ 'http://www.verisign.com/epp/balance-1.0','balance-1.0.xsd' ],
         });
 return;
}

####################################################################################################

sub balance_info_build
{
 my ($epp)=@_;
 my $mes=$epp->message();

 $mes->command(['info','balance:info', sprintf('xmlns:balance="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('balance'))]);
 return;
}

sub balance_info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_response('balance','infData');
 return unless defined $data;

 my %w=(action => 'balance_info');
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$c)=@$el;
  if ($name=~m/^(?:creditLimit|balance|availableCredit)$/)
  {
   $w{Net::DRI::Util::remcam($name)}=0+$c->textContent();
  } elsif ($name eq 'creditThreshold')
  {
   my ($ct)=Net::DRI::Util::xml_list_children($c);
   $w{'credit_threshold'}=0+$ct->[1]->textContent();
   $w{'credit_threshold_type'}=uc $ct->[0]; ## to be compatible with lowBalance poll
  }
 }

 $rinfo->{session}->{balance}=\%w;
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::Balance - VeriSign Balance object mapping EPP Extension for Net::DRI

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

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
