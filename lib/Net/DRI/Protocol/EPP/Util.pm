## Domain Registry Interface, EPP Protocol Utility functions
##
## Copyright (c) 2009,2010,2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Util;

use utf8;
use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub parse_node_status
{
 my ($node)=@_;
 my %tmp=( name => $node->getAttribute('s') );
 ($tmp{lang},$tmp{msg})=parse_node_msg($node);
 return \%tmp;
}

sub parse_node_msg
{
 my ($node)=@_; ## eppcom:msgType
 return (($node->getAttribute('lang') || 'en'),$node->textContent() || '');
}

## Try to enhance parsing of common cases
sub parse_node_value
{
 my ($n)=@_;
 my $t=$n->toString();
 $t=~s!^<value(?:\s+xmlns:epp=["'][^"']+["'])?>(.+?)</value>$!$1!;
 $t=~s/^\s+//;
 $t=~s/\s+$//;
 $t =~ s/>\s*</></g;
 $t=~s!^<text>(.+)</text>$!$1!;
 $t=~s!^<epp:undef\s*/>$!!;
 return $t;
}

sub parse_node_result
{
 my ($node,$ns,$from)=@_;
 $from='eppcom' unless defined $from;
 my ($lang,$msg)=parse_node_msg($node->getChildrenByTagNameNS($ns,'msg')->get_node(1));

 my @i;
 foreach my $el (Net::DRI::Util::xml_list_children($node)) ## <value> or <extValue> nodes, all optional
 {
  my ($name,$c)=@$el;
  if ($name eq 'extValue')
  {
   my @c=Net::DRI::Util::xml_list_children($c); ## we need to use that, instead of directly firstChild/lastChild because we want only element nodes, not whitespaces if there
   my $c1=$c[0]->[1];  ## <value> node
   my $c2=$c[-1]->[1]; ## <reason> node
   my ($ll,$lt)=parse_node_msg($c2);
   my $v=parse_node_value($c1);
   push @i,{ from => $from.':extValue', type => $v=~m/^</ ? 'rawxml' : 'text', message => $v, lang => $ll, reason => $lt };
  } elsif ($name eq 'value')
  {
   my $v=parse_node_value($c);
   push @i,{ from => $from.':value', type => $v=~m/^</ ? 'rawxml' : 'text', message => $v };
  }
 }

 return { code => $node->getAttribute('code'), message => $msg, lang => $lang, extra_info => \@i };
}

####################################################################################################

sub domain_build_command
{
 my ($msg,$command,$domain,$domainattr)=@_;
 my @dom=ref $domain ? @$domain : ($domain);
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless @dom;
 foreach my $d (@dom)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined $d && $d;
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$d) unless Net::DRI::Util::xml_is_token($d,1,255);
 }

 my $tcommand=ref $command ? $command->[0] : $command;
 $msg->command([$command,'domain:'.$tcommand,sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('domain'))]);

 my @d=map { ['domain:name',$_,$domainattr] } @dom;
 return @d;
}

sub domain_build_authinfo
{
 my ($epp,$rauth,$isupdate)=@_;
 return ['domain:authInfo',['domain:null']] if ((! defined $rauth->{pw} || $rauth->{pw} eq '') && $epp->{usenullauth} && (defined($isupdate) && $isupdate));
 return ['domain:authInfo',['domain:pw',$rauth->{pw},exists($rauth->{roid})? { 'roid' => $rauth->{roid} } : undef]];
}

sub build_tel
{
 my ($name,$tel)=@_;
 if ($tel=~m/^(\S+)x(\S+)$/)
 {
  return [$name,$1,{x=>$2}];
 } else
 {
  return [$name,$tel];
 }
}

sub parse_tel
{
 my $node=shift;
 my $ext=$node->getAttribute('x') || '';
 my $num=$node->textContent();
 $num.='x'.$ext if $ext;
 return $num;
}

sub build_period
{
 my ($dtd,$ns)=@_;
 $ns//='domain';
 my ($y,$m)=$dtd->in_units('years','months'); ## all values are integral, but may be negative
 ($y,$m)=(0,$m+12*$y) if ($y && $m);
 my ($v,$u);
 if ($y)
 {
  Net::DRI::Exception::usererr_invalid_parameters('years must be between 1 and 99') unless ($y >= 1 && $y <= 99);
  $v=$y;
  $u='y';
 } else
 {
  Net::DRI::Exception::usererr_invalid_parameters('months must be between 1 and 99') unless ($m >= 1 && $m <= 99);
  $v=$m;
  $u='m';
 }

 return [$ns.':period',$v,{'unit' => $u}];
}

sub build_ns
{
 my ($epp,$ns,$domain,$xmlns,$noip)=@_;
 # hostasns = <domain:ns>ns1.test.com</domain:ns>
 return map { ['domain:ns',$_] } $ns->get_names() if ($epp->{hostasns} == 1);  

 my @d;
 my $asattr=$epp->{hostasattr};

 if ($asattr)
 {
  foreach my $i (1..$ns->count())
  {
   my ($n,$r4,$r6)=$ns->get_details($i);
   my @h;
   push @h,['domain:hostName',$n];
   if ((($n=~m/\S+\.${domain}$/i) || (lc($n) eq lc($domain)) || ($asattr==2)) && (!defined($noip) || !$noip))
   {
    push @h,map { ['domain:hostAddr',$_,{ip=>'v4'}] } @$r4 if @$r4;
    push @h,map { ['domain:hostAddr',$_,{ip=>'v6'}] } @$r6 if @$r6;
   }
   push @d,['domain:hostAttr',@h];
  }
 } else
 {
  @d=map { ['domain:hostObj',$_] } $ns->get_names();
 }

 $xmlns='domain' unless defined($xmlns);
 return [$xmlns.':ns',@d];
}

sub parse_ns ## RFC 4931 §1.1
{
 my ($po,$node)=@_;
 my $ns=$po->create_local_object('hosts');

 foreach my $el (Net::DRI::Util::xml_list_children($node))
 {
  my ($name,$n)=@$el;
  if ($name eq 'hostObj')
  {
   $ns->add($n->textContent());
  } elsif ($name eq 'hostAttr')
  {
   my ($hostname,@ip4,@ip6);
   foreach my $sel (Net::DRI::Util::xml_list_children($n))
   {
    my ($name2,$nn)=@$sel;
    if ($name2 eq 'hostName')
    {
     $hostname=$nn->textContent();
    } elsif ($name2 eq 'hostAddr')
    {
     my $ip=$nn->getAttribute('ip') || 'v4';
     if ($ip eq 'v6')
     {
      push @ip6,$nn->textContent();
     } else
     {
      push @ip4,$nn->textContent();
     }
    }
   }
   $ns->add($hostname,\@ip4,\@ip6,1);
  }
 }
 return $ns;
}

## was Core::Domain::build_contact_noregistrant
sub build_core_contacts
{
 my ($epp,$cs,$ns)=@_;
 my @d;
 # All nonstandard contacts go into the extension section
 my %r=map { $_ => 1 } $epp->core_contact_types();
 foreach my $t (sort(grep { exists($r{$_}) } $cs->types()))
 {
  my @o=$cs->get($t);
  push @d,map { [ ($ns // 'domain').':contact',$_->srid(),{'type'=>$t}] } @o;
 }
 return @d;
}

sub parse_postalinfo
{
 my ($epp,$pi,$rcd)=@_;
 my $type=$pi->getAttribute('type'); ## int or loc, mandatory in EPP !
 $type=$epp->{defaulti18ntype} if (!defined($type) && defined($epp->{defaulti18ntype}));
 state $index={'loc' => 0, 'int' => 1};
 my $ti=$index->{$type};

 foreach my $el (Net::DRI::Util::xml_list_children($pi))
 {
  my ($name,$node)=@$el;
  if ($name=~m/^(name|org)$/)
  {
   $rcd->{$name}->[$ti]=$node->textContent();
  } elsif ($name eq 'addr')
  {
   my @street;
   foreach my $sel (Net::DRI::Util::xml_list_children($node))
   {
    my ($subname,$subnode)=@$sel;
    if ($subname eq 'street')
    {
     push @street,$subnode->textContent();
    } elsif ($subname=~m/^(city|sp|pc|cc)$/)
    {
     $rcd->{$subname}->[$ti]=$subnode->textContent();
    }
   }
   $rcd->{street}->[$ti]=\@street;
  }
 }
 return;
}

sub parse_disclose
{
 my ($disclose)=@_;
 my $flag=Net::DRI::Util::xml_parse_boolean($disclose->getAttribute('flag'));
 my %r;
 foreach my $el (Net::DRI::Util::xml_list_children($disclose))
 {
  my ($name,$node)=@$el;
  if ($name=~m/^(name|org|addr)$/)
  {
   $r{$1.'_'.$node->getAttribute('type')}=$flag;
  } else
  {
   $r{$name}=$flag;
  }
 }
 return \%r;
}

sub build_disclose
{
 my ($d,$ns,@items)=@_;
 $ns//='contact';
 return () unless $d && ref $d eq 'HASH';
 my %v=map { $_ => 1 } values %$d;
 return () unless keys(%v)==1; ## 1 or 0 as values, not both at same time
 my @d;

 state $l1 = [ qw/name org addr/ ];
 foreach my $item (@$l1)
 {
  if (exists $d->{$item})
  {
   push @d,[$ns.':'.$item,{type=>'int'}],[$ns.':name',{type=>'loc'}];
  } else
  {
   push @d,[$ns.':'.$item,{type=>'int'}] if exists $d->{$item.'_int'};
   push @d,[$ns.':'.$item,{type=>'loc'}] if exists $d->{$item.'_loc'};
  }
 }
 state $l2 = [ qw/voice fax email/ ];
 foreach my $item (@$l2, @items)
 {
  push @d,[$ns.':'.$item] if exists $d->{$item};
 }
 return [$ns.':disclose',@d,{flag=>(keys(%v))[0]}];
}

sub _do_locint
{
 my ($rl,$ri,$contact,$ns,$what)=@_;
 my @tmp=$contact->$what();
 return unless @tmp;
 if ($what eq 'street')
 {
  if (defined($tmp[0])) { foreach (@{$tmp[0]}) { push @$rl,[$ns.':street',$_]; } };
  if (defined($tmp[1])) { foreach (@{$tmp[1]}) { push @$ri,[$ns.':street',$_]; } };
 } else
 {
  if (defined($tmp[0])) { push @$rl,[$ns.':'.$what,$tmp[0]]; }
  if (defined($tmp[1])) { push @$ri,[$ns.':'.$what,$tmp[1]]; }
 }
 return;
}

sub build_postalinfo
{
 my ($contact,$v,$ns)=@_;
 $ns//='contact';
 my $hasloc=$contact->has_loc();
 my $hasint=$contact->has_int();
 if ($hasint && !$hasloc && (($v & 5) == $v))
 {
  $contact->int2loc();
  $hasloc=1;
 } elsif ($hasloc && !$hasint && (($v & 6) == $v))
 {
  $contact->loc2int();
  $hasint=1;
 }

 my (@postl,@posti,@addrl,@addri);
 _do_locint(\@postl,\@posti,$contact,$ns,'name');
 _do_locint(\@postl,\@posti,$contact,$ns,'org');
 _do_locint(\@addrl,\@addri,$contact,$ns,'street');
 _do_locint(\@addrl,\@addri,$contact,$ns,'city');
 _do_locint(\@addrl,\@addri,$contact,$ns,'sp');
 _do_locint(\@addrl,\@addri,$contact,$ns,'pc');
 _do_locint(\@addrl,\@addri,$contact,$ns,'cc');
 push @postl,[$ns.':addr',@addrl] if @addrl;
 push @posti,[$ns.':addr',@addri] if @addri;

 my @d;
 push @d,[$ns.':postalInfo',@postl,{type=>'loc'}] if (($v & 5) && $hasloc); ## loc+int OR loc
 push @d,[$ns.':postalInfo',@posti,{type=>'int'}] if (($v & 6) && $hasint); ## loc+int OR int

 return @d;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Util - EPP Protocol Utility functions for Net::DRI

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

Copyright (c) 2009,2010,2015 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
