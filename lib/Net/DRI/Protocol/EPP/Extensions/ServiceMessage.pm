## Domain Registry Interface, Service Message Extension Mapping for EPP
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ServiceMessage;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 state $rops = { 'session' => { review_complete => [ undef, \&parse ] } };

 return $rops;
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'servicemessage' => [ 'http://tld-box.at/xmlns/resdata-1.1','resdata-1.1.xsd' ] });
 return;
}

sub implements { return 'https://tools.ietf.org/html/draft-mayrhofer-eppext-servicemessage-00'; }

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_response('servicemessage','message');
 return unless defined $data;

 my %r=(type => $data->getAttribute('type'));
 my $ns=$mes->ns('servicemessage');
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'desc')
  {
   $r{description}=$node->textContent();
  } elsif ($name eq 'reftrID')
  {
   $r{clTRID}=Net::DRI::Util::xml_traverse($node,$ns,qw/clTRID/);
   $r{svTRID}=Net::DRI::Util::xml_traverse($node,$ns,qw/svTRID/);
  } elsif ($name eq 'data')
  {
   my %entries;
   foreach my $subel (Net::DRI::Util::xml_list_children($node))
   {
    my ($subname,$subnode)=@$subel;
    if ($subname eq 'entry') ## specification says there are key/value tuples
    {
     my $key = $subnode->getAttribute('name');
     my $value = $subnode->textContent();
     if (exists $entries{$key})
     {
      $entries{$key}=[ $entries{$key} ] unless ref $entries{$key};
      push @{$entries{$key}},$value;
     } else
     {
      $entries{$key}=$value;
     }
    } elsif ($subname eq 'request')
    {
     $r{request}=$subnode->toString(0); ## TODO: do something better?
    } elsif ($subname eq 'response')
    {
     $r{response}=$subnode->toString(0); ## TODO: do something better?
    } else # An OPTIONAL "any other" element from "any other" namespace
    {
     $r{unspecified}=$subnode->toString(0);
    }
   }
   $r{entries}=\%entries;
  }
 }

 my $msgid=$mes->msg_id();
 $rinfo->{message}->{$msgid}->{servicemessage}=\%r;
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ServiceMessage - EPP Service Message Extension mapping (draft-mayrhofer-eppext-servicemessage-00) for Net::DRI

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

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
