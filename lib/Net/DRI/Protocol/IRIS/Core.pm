## Domain Registry Interface, IRIS Core functions
##
## Copyright (c) 2008-2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::IRIS::Core;

use utf8;
use strict;
use warnings;

use Carp;
use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::IRIS::Core - IRIS Core (RFC3981) functions for Net::DRI

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

Copyright (c) 2008-2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

our %ERRORS=(insufficientResources => 2400,
             invalidName => 2005,
             invalidSearch => 2306,
             queryNotSupported => 2101,
             limitExceeded => 2201,
             nameNotFound => 2303,
             permissionDenied => 2200,
             bagUnrecognized => 2005,
             bagUnacceptable => 2005,
             bagRefused => 2306,
            );

sub parse_msglang
{
 my ($c,$name)=@_;
 my (@i,$msg,$lang);
 foreach my $sn ($c->getChildrenByTagNameNS($c->namespaceURI(),$name))
 {
  if (! defined $msg) { ($lang,$msg)=($sn->getAttribute('language'),$sn->textContent()); }
  push @i,sprintf('[%s] %s',$sn->getAttribute('language'),$sn->textContent());
 }
 return (\@i,$msg,$lang);
}

sub parse_error
{
 my ($node)=@_; ## $node should be a topmost <resultSet> to be able to catch all errors type

 foreach my $el (Net::DRI::Util::xml_list_children($node))
 {
  my ($name,$c)=@$el;
  next if ($name eq 'answer' || $name eq 'additional');
  carp('Got unknown error <'.$name.'>, please report') unless exists($ERRORS{$name});
  my ($ri,$msg,$lang)=parse_msglang($c,'explanation');
  ## We have only one error element at most, so break here if we found one
  return Net::DRI::Protocol::ResultStatus->new('iris',$name,exists $ERRORS{$name} ? $ERRORS{$name} : 'COMMAND_FAILED',0,$msg,$lang,$ri);
 }
 return Net::DRI::Protocol::ResultStatus->new_success();
}

## RFC4991 §6 §7
sub parse_authentication
{
 my ($node)=@_; ## $node should be a topmost <resultSet> to be able to catch all errors type
 my ($ri,$msg,$lang);

 foreach my $el (Net::DRI::Util::xml_list_children($node))
 {
  my ($name,$c)=@$el;
  next unless ($name eq 'authenticationSuccess' || $name eq 'authenticationFailure');
  ($ri,$msg,$lang)=parse_msglang($c,'description');
  last;
 }

 return ($msg,$lang,$ri);
}

####################################################################################################
1;
