## Domain Registry Interface, VeriSign EPP Suggestion Extension
##
## Copyright (c) 2010,2012,2013,2016,2018 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
 $po->ns({ 'suggestion' => 'http://www.verisign-grs.com/epp/suggestion-1.1' });
 return;
}

####################################################################################################

sub suggestion
{
 my ($epp,$domain,$rd)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('suggestion domain/key must be a string') unless Net::DRI::Util::xml_is_string($domain);
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
  foreach my $k (qw/contentfilter customfilter usehyphens usenumbers useidns/)
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
    Net::DRI::Exception::usererr_invalid_parameters(sprintf('TLD must be 1 to 255 characters and not: ',defined $tld ? $tld : '<undef>')) unless Net::DRI::Util::xml_is_token($tld,1,255);
    push @f,['suggestion:tld',$tld];
   }
  }
  if (Net::DRI::Util::has_key($rd,'geo') && ref $rd->{geo} eq 'HASH')
  {
   if (exists $rd->{geo}->{lat} && exists $rd->{geo}->{lon})
   {
    my $lat = $rd->{geo}->{lat};
    Net::DRI::Exception::usererr_invalid_parameters('geo latitude must be a decimal with at most 6 decimal digits, between -90 and +90') unless Net::DRI::Util::xml_is_decimal($lat, 6, undef, -90, 90);
    my $lon = $rd->{geo}->{lon};
    Net::DRI::Exception::usererr_invalid_parameters('geo longitude must be a decimal with at most 6 decimal digits, between -180 and +180') unless Net::DRI::Util::xml_is_decimal($lat, 6, undef, -180, 180);
    push @f,['suggestion:geo',['suggestion:coordinates', { lat => $lat, lon => $lon } ]];
   } elsif (exists $rd->{geo}->{addr})
   {
    my $addr = $rd->{geo}->{addr};
    Net::DRI::Exception::usererr_invalid_parameters('geo addr must be an XML token with 3 to 45 characters') unless Net::DRI::Util::xml_is_token($addr, 3, 45);
    my $ip = exist $rd->{geo}->{ip} ? $rd->{geo}->{ip} : 'v4';
    Net::DRI::Exception::usererr_invalid_parameters('geo ip must be v4 or v6 string') unless $ip=~m/^v[46]$/;
    push @f,['suggestion:geo',['suggestion:addr',{ ip => $ip }, $addr]];
   } else
   {
    Net::DRI::Exception::usererr_insufficient_parameters('geo data should have either lat+lon keys or addr/addr+ip keys');
   }
  }

  @f=(['suggestion:filter',\%f,@f]) if %f || @f;
 }

 push @d,@f if @f;
 if (Net::DRI::Util::has_key($rd, 'sub_id'))
 {
  my $subid=$rd->{sub_id};
  Net::DRI::Exception::usererr_invalid_parameters('if provided sub_id value must be an XML token') unless Net::DRI::Util::xml_is_token($subid);
  push @d,['suggestion:subID', $subid];
 }

 my $mes=$epp->message();
 $mes->command(['info','suggestion:info', $mes->nsattrs('suggestion')]);
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
  foreach my $key (qw/source morelikethis ppcvalue uName/)
  {
   my $v=$row->getAttribute($key);
   next unless defined $v;
   $d{lc $key}=$v;
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
   $rr{$tld}->{utld}=$cell->getAttribute('uTld') if $cell->hasAttribute('uTld');
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
        $dri->add_registry('VeriSign::NameStore',{client_id=>'XXXXXX');
        $dri->add_profile(...);
	$dri->domain_suggest('whatever.tv',{...});

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

Copyright (c) 2010,2012,2013,2016,2018 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
