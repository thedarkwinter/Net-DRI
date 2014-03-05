## Domain Registry Interface, VeriSign EPP Suggestion Extension
##
## Copyright (c) 2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::Suggestion;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 return { 'domain' => { 'suggestion'  => [ \&suggestion, \&parse ],
                      } };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'suggestion' => [ 'http://www.verisign-grs.com/epp/suggestion-1.1','suggestion-1.1.xsd' ] });
 return;
}

####################################################################################################

sub suggestion
{
 my ($epp,$domain,$rd)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('suggestion domain/key must be a string of up to 32 characters') unless Net::DRI::Util::xml_is_string($domain,1,32);
 my @d;
 push @d,['suggestion:key',$domain];

 if (Net::DRI::Util::has_key($rd,'language'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('language value must be of XML language type') unless Net::DRI::Util::xml_is_language($rd->{language});
  push @d,['suggestion:language',$rd->{language}];
 }

 my @f;
 if (Net::DRI::Util::has_key($rd,'filter_id'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('filter_id must be an integer') unless $rd->{filter_id}=~m/^\d+$/;
  push @d,['suggestion:filterid',$rd->{filter_id}];
 } else
 {
  my %f;
  foreach my $k (qw/contentfilter customfilter usehyphens usenumbers/)
  {
   $f{$k}=$rd->{$k} if Net::DRI::Util::has_key($rd,$k) && Net::DRI::Util::xml_is_boolean($rd->{$k});
  }
  if (Net::DRI::Util::has_key($rd,'view'))
  {
   Net::DRI::Exception::usererr_invalid_parameters('view must be either table or grid') unless $rd->{view}=~m/^(?:table|grid)$/;
   $f{view}=$rd->{view};
  }
  if (Net::DRI::Util::has_key($rd,'forsale'))
  {
   Net::DRI::Exception::usererr_invalid_parameters('forsale must be either off, low, medium or high') unless $rd->{forsale}=~m/^(?:off|low|medium|high)$/;
   $f{forsale}=$rd->{forsale};
  }
  if (Net::DRI::Util::has_key($rd,'maxlength'))
  {
   Net::DRI::Exception::usererr_invalid_parameters('maxlength must be a number between 1 and 63') unless Net::DRI::Util::verify_int($rd->{maxlength},1,63);
   $f{maxlength}=$rd->{maxlength};
  }
  if (Net::DRI::Util::has_key($rd,'maxresults'))
  {
   Net::DRI::Exception::usererr_invalid_parameters('maxresults must be a number between 1 and 100') unless Net::DRI::Util::verify_int($rd->{maxresults},1,100);
   $f{maxresults}=$rd->{maxresults};
  }

  if (Net::DRI::Util::has_key($rd,'action') && ref $rd->{action} eq 'HASH')
  {
   foreach my $action (sort { $a cmp $b } keys %{$rd->{action}})
   {
    my $weight=$rd->{action}->{$action};
    Net::DRI::Exception::usererr_invalid_parameters(sprintf('weight for action "%s" myst be either off, low, medium or high',$action)) unless defined $weight && $weight=~/^(?:off|low|medium|high)$/;
    push @f,['suggestion:action',{name => $action, weight => $weight }];
   }
  }
  if (Net::DRI::Util::has_key($rd,'tld'))
  {
   foreach my $tld (ref $rd->{tld} eq 'ARRAY' ? @{$rd->{tld}} : ($rd->{tld}))
   {
    Net::DRI::Exception::usererr_invalid_parameters(sprintf('TLD must be 2 to 6 characters among a-zA-Z and not: ',defined $tld ? $tld : '<undef>')) unless defined $tld && $tld=~m/^[a-zA-Z]{2,6}$/;
    push @f,['suggestion:tld',$tld];
   }
  }

  @f=(['suggestion:filter',\%f,@f]) if %f || @f;
 }

 push @d,@f if @f;

 my $mes=$epp->message();
 $mes->command(['info','suggestion:info',sprintf('xmlns:suggestion="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('suggestion'))]);
 $mes->command_body(\@d);
 return;
}

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response('suggestion','infData');
 return unless defined $infdata;

 my $key;
 my $ns=$mes->ns('suggestion');
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  if ($n eq 'key')
  {
   $key=$c->textContent();
   $rinfo->{domain}->{$key}->{action}='suggest';
   $rinfo->{domain}->{$key}->{suggestions}={};
  } elsif ($n eq 'language')
  {
   $rinfo->{domain}->{$key}->{suggestions}->{language}='ENG';
  } elsif ($n eq 'token')
  {
   $rinfo->{domain}->{$key}->{suggestions}->{tokens}->{$c->getAttribute('name')}=[ map { $_->textContent() } (Net::DRI::Util::xml_traverse($c,$ns,'related')) ];
  } elsif ($n eq 'answer')
  {
   my $ans=Net::DRI::Util::xml_traverse($c,$ns,'table');
   if (defined $ans)
   {
    $rinfo->{domain}->{$key}->{suggestions}->{result_type}='table';
    $rinfo->{domain}->{$key}->{suggestions}->{answer}=parse_table($ans,$ns);
   }
   $ans=Net::DRI::Util::xml_traverse($c,$ns,'grid');
   if (defined $ans)
   {
    $rinfo->{domain}->{$key}->{suggestions}->{result_type}='grid';
    $rinfo->{domain}->{$key}->{suggestions}->{answer}=parse_grid($ans,$ns);
   }
  }
 }
 return;
}

sub parse_table
{
 my ($node,$ns)=@_;
 my %r;

 foreach my $row (Net::DRI::Util::xml_traverse($node,$ns,'row'))
 {
  my %d;
  my $name=$row->getAttribute('name');
  $d{score}=0+$row->getAttribute('score');
  $d{status}=$row->getAttribute('status');
  foreach my $key (qw/source morelikethis ppcvalue/)
  {
   my $v=$row->getAttribute($key);
   next unless defined $v;
   $d{$key}=$v;
  }
  $r{$name}=\%d;
 }
 return \%r;
}


sub parse_grid
{
 my ($node,$ns)=@_;
 my %r;

 foreach my $row (Net::DRI::Util::xml_traverse($node,$ns,'record'))
 {
  my %d;
  my $name=$row->getAttribute('name');
  foreach my $key (qw/source morelikethis ppcvalue/)
  {
   my $v=$row->getAttribute($key);
   next unless defined $v;
   $d{$key}=$v;
  }
  my %rr;
  foreach my $cell (Net::DRI::Util::xml_traverse($row,$ns,'cell'))
  {
   my $tld=$cell->getAttribute('tld');
   $rr{$tld}={ score => 0+$cell->getAttribute('score'), status => $cell->getAttribute('status'), %d };
  }
  $r{$name}=\%rr;
 }
 return \%r;
}
#########################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::Suggestion - VeriSign EPP Suggestion Extension for Net::DRI

=head1 SYNOPSIS

        $dri=Net::DRI->new();
        $dri->add_registry('VNDS',{client_id=>'XXXXXX');

	$dri->domain_suggest('whatever.com',{...});

This extension is loaded by default during add_profile.

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

Copyright (c) 2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
