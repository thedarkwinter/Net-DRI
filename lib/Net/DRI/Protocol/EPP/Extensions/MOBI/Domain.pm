## Domain Registry Interface, .MOBI Domain EPP extension commands
##
## Copyright (c) 2006-2008,2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::MOBI::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Extensions::Afilias::MaintainerUrl;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::MOBI::Domain - .MOBI EPP Domain extension commands for Net::DRI

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

Copyright (c) 2006-2008,2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
          create => [ \&create, undef ],
          update => [ \&update, undef ],
          info   => [ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub add_maintainer_url
{
 my ($mes,$tag,$d)=@_;
 my $eid=$mes->command_extension_register($tag,sprintf('xmlns:mobi="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('mobi')));
 $mes->command_extension($eid,$d);
 return;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $d=Net::DRI::Protocol::EPP::Extensions::Afilias::MaintainerUrl::create('mobi',$rd);
 return unless defined $d;
 add_maintainer_url($mes,'mobi:create',$d);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $d=Net::DRI::Protocol::EPP::Extensions::Afilias::MaintainerUrl::update('mobi',$todo);
 return unless defined $d;
 add_maintainer_url($mes,'mobi:update',$d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('mobi','infData');
 return unless $infdata;

 my $c=Net::DRI::Protocol::EPP::Extensions::Afilias::MaintainerUrl::info_parse($mes->ns('mobi'),$infdata);
 $rinfo->{$otype}->{$oname}->{maintainer_url}=$c if defined $c;
 return;
}

####################################################################################################
1;
