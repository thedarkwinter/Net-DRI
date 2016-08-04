## Domain Registry Interface, .PL Domain EPP extension commands
##
## Copyright (c) 2006,2008-2011,2013 Patrick Mevzek <netdri@dotandco.com> and Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. 
## Copyright (c) 2014-15 Michael Holloway <michael@thedarkwinter.com>
## All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::PL::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::Hosts;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PL::Domain - .PL EPP Domain extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHORS

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>
Tonnerre Lombard <tonnerre.lombard@sygroup.ch>
Marcus Fauré <netdri@faure.de>

=head1 COPYRIGHT

Copyright (c) 2006,2008-2011,2013 Patrick Mevzek <netdri@dotandco.com> and Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
Copyright (c) 2014-15 Michael Holloway <michael@thedarkwinter.com>
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
          create => [ \&create ],
          renew  => [ \&renew  ],
         );
 return { 'domain' => \%tmp };
}

####################################################################################################

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless exists($rd->{reason}) || exists($rd->{book});
 my @e;
 push @e,['extdom:reason',$rd->{reason}] if (exists($rd->{reason}) && $rd->{reason});
 push @e,['extdom:book']                 if (exists($rd->{book}) && $rd->{book});

 my $eid=$mes->command_extension_register('extdom:create',sprintf('xmlns:extdom="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('pl_domain')));
 $mes->command_extension($eid,\@e);
 return;
}

# domain:renew with extdom:reactivate equals domain:restore
## TODO: <extdom:renewToDate>
sub renew
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless exists $rd->{reactivate};
 my @e;

 # NASK expects an empty extdom:reactivate tag
 push @e,['extdom:reactivate',''];

 my $eid=$mes->command_extension_register('extdom:renew',sprintf('xmlns:extdom="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('pl_domain')));
 $mes->command_extension($eid,\@e);
 return;
}

####################################################################################################
1;
