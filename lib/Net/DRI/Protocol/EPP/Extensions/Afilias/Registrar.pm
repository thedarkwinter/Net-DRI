## Domain Registry Interface, AFILIAS Registrar.pm
## Comlaude EPP extensions
##
## Copyright (c) 2007,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013-2014 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::Afilias::Registrar;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use DateTime::Format::ISO8601;
use DateTime::Duration;
use Data::Dumper;


####################################################################################################

sub register_commands
{
       my ($class, $version) = @_;
       my %tmp =  (
                    info => [ \&info, \&info_parse ],
                  );
       return { 'registrar' => \%tmp };
}

sub setup
{
  my ($self,$rp)=@_;
  $rp->ns({ registrar => ['urn:ietf:params:xml:ns:registrar-1.0','registrar-1.0.xsd'] });
  return;
}

####################################################################################################

sub info{
  my ($epp,$clID)=@_;
  my $mes=$epp->message();
  $mes->command(['info','registrar:info',sprintf('xmlns:registrar="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('registrar'))]);
  my @d;
  push @d, ['registrar:id',$clID];
  $mes->command_body(\@d);
  return;
}

sub info_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  my $infData=$mes->get_response('registrar','infData');
  return unless defined $infData;

  my $cs = $po->create_local_object('contactset');
  my (@s,@p); # portfolios in max unbound

  foreach my $el (Net::DRI::Util::xml_list_children($infData))
  {
    my ($name,$content)=@$el;
    $rinfo->{registrar}->{$oname}->{$name}=$content->textContent() if $name =~ m/^(id|roid|user|ctID|crID|email|guid|category|url|upID|balance|threshold)$/; # plain text
    $rinfo->{registrar}->{$oname}->{$name}=$po->parse_iso8601($content->textContent()) if $name =~ m/Date$/; # date fieds
    $cs->set($po->create_local_object('contact')->srid($content->textContent()),$content->getAttribute('type')) if $name eq 'contact' && $content->hasAttribute('type'); # contacts
    push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($content) if $name eq 'status';

    if ($name eq 'portfolio') # get portfolio balance
    {
      my $p = {};
      $p->{name} = $content->getAttribute('name') if $content->hasAttribute('name');
      foreach my $el2 (Net::DRI::Util::xml_list_children($content))
      {
        my ($name2,$content2)=@$el2;
        $p->{$name2} = $content2->textContent() if $name2 =~ /^(threshold|balance)$/;
      }
      push @p,$p;
    } 
  }
  $rinfo->{registrar}->{$oname}->{contact}=$cs;
  $rinfo->{registrar}->{$oname}->{status}=$po->create_local_object('status')->add(@s);
  @{$rinfo->{registrar}->{$oname}->{portfolio}}=@p if @p;

  # since this is inconsistent, lets put the first balance into the main result if there is not one already
  if (!defined($rinfo->{registrar}->{$oname}->{balance}) && $#p==0) {
    $rinfo->{registrar}->{$oname}->{balance} = $p[0]->{balance};
    $rinfo->{registrar}->{$oname}->{threshold} = $p[0]->{threshold};
  }

  return;
}

1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Afilias::Registrar - Afilias Registrar EPP Extension for Net::DRI

=head1 DESCRIPTION

Adds the registrar extension to Afilias registries.

  $rc = $dri->registrar_info('ClientX'); # or $rc = $dri->registrar_info(); - blank will use current clID from add_registry
  print $dri->get_info('crDate');
  print $dri->get_info('balance');
  @ps = $dri->get_info('portfolio');
  print @ps->[0]->{balance};

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2013-2014 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut