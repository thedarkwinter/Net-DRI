## Domain Registry Interface, Misc. useful functions
##
## Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Util;

use utf8;
use strict;
use warnings;

use Time::HiRes ();
use Encode ();
use Module::Load;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Util - Various useful functions for Net::DRI operations

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

Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


####################################################################################################

## See http://www.iso.org/iso/country_codes/updates_on_iso_3166.htm for updates
## Done up to & including VI-13 (2012-08-02)
our %CCA2=map { $_ => 1 } qw/AF AX AL DZ AS AD AO AI AQ AG AR AM AW AU AT AZ BS BH BD BB BY BE BZ BJ BL BM BT BO BQ BA BW BV BR IO BN BG BF BI KH CM CA CV CW KY CF TD CL CN CX CC CO KM CG CD CK CR CI HR CU CY CZ DK DJ DM DO EC EG SV SX GQ ER EE ET FK FO FJ FI FR GF PF TF GA GM GE DE GH GI GR GL GD GP GU GT GG GN GW GY HT HM HN HK HU IS IN ID IR IQ IE IM IL IT JM JP JE JO KZ KE KI KP KR KW KG LA LV LB LS LR LY LI LT LU MO MK MG MW MY MV ML MT MH MQ MR MU YT MX FM MD ME MF MC MN MS MA MZ MM NA NR NP NL NC NZ NI NE NG NU NF MP NO OM PK PW PS PA PG PY PE PH PN PL PT PR QA RE RO RS RU RW SH KN LC PM VC WS SM ST SA SN CS SC SL SG SK SI SB SO ZA GS SS ES LK SD SR SJ SZ SE CH SY TW TJ TZ TH TL TG TK TO TT TN TR TM TC TV UG UA AE GB US UM UY UZ VU VA VE VN VG VI WF EH YE ZM ZW/;

sub all_valid
{
 my (@args)=@_;
 foreach (@args)
 {
  return 0 unless (defined($_) && (ref($_) || length($_)));
 }
 return 1;
}

sub hash_merge
{
 my ($rmaster,$rtoadd)=@_;
 while(my ($k,$v)=each(%$rtoadd))
 {
  $rmaster->{$k}={} unless exists($rmaster->{$k});
  while(my ($kk,$vv)=each(%$v))
  {
   $rmaster->{$k}->{$kk}=[] unless exists($rmaster->{$k}->{$kk});
   my @t=@$vv;
   push @{$rmaster->{$k}->{$kk}},\@t;
  }
 }
 return;
}

sub deepcopy ## no critic (Subroutines::RequireFinalReturn)
{
 my $in=shift;
 return $in unless defined $in;
 my $ref=ref $in;
 return $in unless $ref;
 my $cname;
 ($cname,$ref)=($1,$2) if ("$in"=~m/^(\S+)=([A-Z]+)\(0x/);

 if ($ref eq 'SCALAR')
 {
  my $tmp=$$in;
  return \$tmp;
 } elsif ($ref eq 'HASH')
 {
  my $r={ map { $_ => (defined $in->{$_} && ref $in->{$_}) ? deepcopy($in->{$_}) : $in->{$_} } keys(%$in) };
  bless($r,$cname) if defined $cname;
  return $r;
 } elsif ($ref eq 'ARRAY')
 {
  return [ map { (defined $_ && ref $_)? deepcopy($_) : $_ } @$in ];
 } else
 {
  Net::DRI::Exception::usererr_invalid_parameters('Do not know how to deepcopy '.$in);
 }
}

sub link_rs
{
 my (@rs)=@_;
 my %seen;
 foreach my $i (1..$#rs)
 {
  $rs[$i-1]->_set_last($rs[$i]) unless exists $seen{$rs[$i]};
  $seen{$rs[$i]}=1;
 }
 return $rs[0];
}

####################################################################################################

sub isint
{
 my $in=shift;
 return ($in=~m/^\d+$/)? 1 : 0;
}

## eppcom:roidType
sub is_roid
{
 my $in=shift;
 return xml_is_token($in,3,89) && $in=~m/^\w{1,80}-[0-9A-Za-z]{1,8}$/;
}

sub check_equal
{
 my ($input,$ra,$default)=@_;
 return $default unless defined($input);
 foreach my $a (ref($ra)? @$ra : ($ra))
 {
  return $a if ($a=~m/^${input}$/);
 }
 return $default if $default;
 return;
}

sub check_isa
{
 my ($what,$isa)=@_;
 Net::DRI::Exception::usererr_invalid_parameters((${what} || 'parameter').' must be a '.$isa.' object') unless $what && is_class($what,$isa);
 return 1;
}

sub is_class
{
 my ($obj,$class)=@_;
 return eval { $obj->isa($class); } ? 1 : 0;
}

sub isa_contactset
{
 my $cs=shift;
 return (defined $cs && is_class($cs,'Net::DRI::Data::ContactSet') && !$cs->is_empty())? 1 : 0;
}

sub isa_contact
{
 my ($c,$class)=@_;
 $class='Net::DRI::Data::Contact' unless defined $class;
 return (defined $c && is_class($c,$class))? 1 : 0; ## no way to check if it is empty or not ? Contact->validate() is too strong as it may die, Contact->roid() maybe not ok always
}

sub isa_hosts
{
 my ($h,$emptyok)=@_;
 $emptyok=0 unless defined $emptyok;
 return (defined $h && is_class($h,'Net::DRI::Data::Hosts') && ($emptyok || !$h->is_empty()) )? 1 : 0;
}

sub isa_nsgroup
{
 my $h=shift;
 return (defined $h && is_class($h,'Net::DRI::Data::Hosts'))? 1 : 0;
}

sub isa_changes
{
 my $c=shift;
 return (defined $c && is_class($c,'Net::DRI::Data::Changes') && !$c->is_empty())? 1 : 0;
}

sub isa_statuslist
{
 my $s=shift;
 return (defined $s && is_class($s,'Net::DRI::Data::StatusList') && !$s->is_empty())? 1 : 0;
}

sub has_key
{
 my ($rh,$key)=@_;
 return 0 unless (defined $key && $key);
 return 0 unless (defined $rh && (ref $rh eq 'HASH') && exists $rh->{$key} && defined $rh->{$key});
 return 1;
}

sub has_contact
{
 my $rh=shift;
 return has_key($rh,'contact') && isa_contactset($rh->{contact});
}

sub has_ns
{
 my $rh=shift;
 return has_key($rh,'ns') && isa_hosts($rh->{ns});
}

sub has_duration
{
 my $rh=shift;
 return has_key($rh,'duration') && check_isa($rh->{'duration'},'DateTime::Duration'); ## check_isa throws an Exception if not
}

sub has_auth
{
 my $rh=shift;
 return (has_key($rh,'auth') && ref $rh->{'auth'} eq 'HASH')? 1 : 0;
}

sub has_status
{
 my $rh=shift;
 return (has_key($rh,'status') && isa_statuslist($rh->{status}))? 1 : 0;
}

####################################################################################################

sub microtime
{
 my ($t,$v)=Time::HiRes::gettimeofday();
 return $t.sprintf('%06d',$v);
}

sub fulltime
{
 my ($t,$v)=Time::HiRes::gettimeofday();
 my @t=localtime($t);
 return sprintf('%d-%02d-%02d %02d:%02d:%02d.%06d',1900+$t[5],1+$t[4],$t[3],$t[2],$t[1],$t[0],$v);
}

## From EPP, trID=token from 3 to 64 characters
sub create_trid_1
{
 my ($name)=@_;
 my $mt=microtime(); ## length=16
 return uc($name).'-'.$$.'-'.$mt;
}

sub create_params
{
 my ($op,$rd)=@_;
 return {} unless defined $rd;
 Net::DRI::Exception::usererr_invalid_parameters('last parameter of '.$op.', if defined, must be a ref hash holding extra parameters as needed') unless ref $rd eq 'HASH';
 return { %$rd };
}

####################################################################################################

sub is_hostname ## RFC952/1123
{
 my ($name,$unicode)=@_;
 return 0 unless defined $name;
 $unicode=0 unless defined $unicode;

 my @d=split(/\./,$name,-1);
 foreach my $d (@d)
 {
  return 0 unless (defined $d && $d ne '');
  return 0 unless (length $d <= 63);
  return 0 if (($d=~m/^-/) || ($d=~m/-$/));
  return 0 if (!$unicode && $d=~m/[^A-Za-z0-9\-]/);
 }
 return 1;
}

sub is_ipv4
{
 my ($ip,$checkpublic)=@_;

 return 0 unless defined $ip;
 my (@ip)=($ip=~m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
 return 0 unless (@ip==4);
 foreach my $s (@ip)
 {
  return 0 unless (($s >= 0) && ($s <= 255));
 }

 return 1 unless (defined $checkpublic && $checkpublic);

 ## Check if this IP is public (see RFC3330)
 return 0 if ($ip[0] == 0); ## 0.x.x.x [ RFC 1700 ]
 return 0 if ($ip[0] == 10); ## 10.x.x.x [ RFC 1918 ]
 return 0 if ($ip[0] == 127); ## 127.x.x.x [ RFC 1700 ]
 return 0 if (($ip[0] == 169) && ($ip[1]==254)); ## 169.254.0.0/16 link local
 return 0 if (($ip[0] == 172 ) && ($ip[1]>=16) && ($ip[1]<=31)); ## 172.16.x.x to 172.31.x.x [ RFC 1918 ]
 return 0 if (($ip[0] == 192 ) && ($ip[1]==0) && ($ip[2]==2)); ## 192.0.2.0/24 TEST-NET
 return 0 if (($ip[0] == 192 ) && ($ip[1]==168)); ## 192.168.x.x [ RFC 1918 ]
 return 0 if (($ip[0] >= 224) && ($ip[0] < 240 )); ## 224.0.0.0/4 Class D [ RFC 3171]
 return 0 if ($ip[0] >= 240); ## 240.0.0.0/4 Class E [ RFC 1700 ]
 return 1;
}

## Inspired by Net::IP which unfortunately requires Perl 5.8
sub is_ipv6
{
 my ($ip,$checkpublic)=@_;
 return 0 unless defined $ip;

 my (@ip)=split(/:/,$ip);
 return 0 unless ((@ip > 0) && (@ip <= 8));
 return 0 if (($ip=~m/^:[^:]/) || ($ip=~m/[^:]:$/));
 return 0 if ($ip =~ s/:(?=:)//g > 1);

 ## We do not allow IPv4 in IPv6
 return 0 if grep { ! /^[a-f\d]{0,4}$/i } @ip;

 return 1 unless (defined($checkpublic) && $checkpublic);

 ## Check if this IP is public
 my ($ip1,$ip2)=split(/::/,$ip);
 $ip1=join('',map { sprintf('%04s',$_) } split(/:/,$ip1 || ''));
 $ip2=join('',map { sprintf('%04s',$_) } split(/:/,$ip2 || ''));
 my $wip=$ip1.('0' x (32-length($ip1)-length($ip2))).$ip2; ## 32 chars
 my $bip=unpack('B128',pack('H32',$wip)); ## 128-bit array

 ## RFC 3513 §2.4
 return 0 if ($bip=~m/^0{127}/); ## unspecified + loopback
 return 0 if ($bip=~m/^1{7}/); ## multicast + link-local unicast + site-local unicast
 ## everything else is global unicast,
 ## but see §4 and http://www.iana.org/assignments/ipv6-address-space
 return 0 if ($bip=~m/^000/); ## unassigned + reserved (first 6 lines)
 return 1 if ($bip=~m/^001/); ## global unicast (2000::/3)
 return 0; ## everything else is unassigned
}

####################################################################################################

sub compare_durations
{
 my ($dtd1,$dtd2)=@_;

 ## from DateTime::Duration module, internally are stored: months, days, minutes, seconds and nanoseconds
 ## those are the keys of the hash ref given by the deltas method
 my %d1=$dtd1->deltas();
 my %d2=$dtd2->deltas();

 ## Not perfect, but should be enough for us
 return (($d1{months}  <=> $d2{months})  ||
         ($d1{days}    <=> $d2{days})    ||
         ($d1{minutes} <=> $d2{minutes}) ||
         ($d1{seconds} <=> $d2{seconds}) 
        );
}

####################################################################################################

sub xml_is_normalizedstring
{
 my ($what,$min,$max)=@_;
 my $r=xml_is_string($what,$min,$max);
 return 0 if $r==0;
 return 0 if $what=~m/[\r\n\t]/;
 return 1;
}

sub xml_is_string
{
 my ($what,$min,$max)=@_;
 return 0 unless defined $what;
 return 0 unless $what=~m/^[\x{0009}\x{000A}\x{000D}\x{0020}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]*$/; ## XML Char definition (all Unicode excluding the surrogate blocks, FFFE, and FFFF)
 my $l=length $what;
 return 0 if (defined $min && $l < $min);
 return 0 if (defined $max && $l > $max);
 return 1;
}

sub xml_is_token
{
 my ($what,$min,$max)=@_;

 return 0 unless defined $what;
 return 0 if $what=~m/[\r\n\t]/;
 return 0 if $what=~m/^\s/;
 return 0 if $what=~m/\s$/;
 return 0 if $what=~m/\s\s/;

 my $l=length $what;
 return 0 if (defined $min && $l < $min);
 return 0 if (defined $max && $l > $max);
 return 1;
}

sub xml_is_ncname ## xml:id is of this type
{
 my ($what)=@_;
 return 0 unless defined($what) && $what;
 return ($what=~m/^\p{ID_Start}\p{ID_Continue}*$/)
}

sub verify_ushort { my $in=shift; return (defined($in) && ($in=~m/^\d+$/) && ($in < 65536))? 1 : 0; }
sub verify_ubyte  { my $in=shift; return (defined($in) && ($in=~m/^\d+$/) && ($in < 256))? 1 : 0; }
sub verify_hex    { my $in=shift; return (defined($in) && ($in=~m/^[0-9A-F]+$/i))? 1 : 0; }
sub verify_int
{
 my ($in,$min,$max)=@_;
 return 0 unless defined($in) && ($in=~m/^-?\d+$/);
 return 0 if ($in < (defined $min ? $min : -2147483648));
 return 0 if ($in > (defined $max ? $max : 2147483647));
 return 1;
}

sub verify_base64
{
 my ($in,$min,$max)=@_;
 my $b04='[AQgw]';
 my $b16='[AEIMQUYcgkosw048]';
 my $b64='[A-Za-z0-9+/]';
 return 0 unless ($in=~m/^(?:(?:$b64 ?$b64 ?$b64 ?$b64 ?)*(?:(?:$b64 ?$b64 ?$b64 ?$b64)|(?:$b64 ?$b64 ?$b16 ?=)|(?:$b64 ?$b04 ?= ?=)))?$/);
 return 0 if (defined $min && (length $in < $min));
 return 0 if (defined $max && (length $in > $max));
 return 1;
}

## Same in XML and in RFC3066
sub xml_is_language
{
 my $in=shift;
 return 0 unless defined $in;
 return 1 if ($in=~m/^[a-zA-Z]{1,8}(?:-[a-zA-Z0-9]{1,8})*$/);
 return 0;
}

sub xml_is_boolean
{
 my $in=shift;
 return 0 unless defined $in;
 return 1 if ($in=~m/^(?:1|0|true|false)$/);
 return 0;
}

sub xml_parse_boolean
{
 my $in=shift;
 return {'true'=>1,1=>1,0=>0,'false'=>0}->{$in};
}

sub xml_escape
{
 my ($in)=@_;
 $in=~s/&/&amp;/g;
 $in=~s/</&lt;/g;
 $in=~s/>/&gt;/g;
 return $in;
}

sub xml_write
{
 my $rd=shift;
 my @t;
 foreach my $d ((ref($rd->[0]))? @$rd : ($rd)) ## $d is a node=ref array
 {
  my @c; ## list of children nodes
  my %attr;
  foreach my $e (grep { defined } @$d)
  {
   if (ref($e) eq 'HASH')
   {
    while(my ($k,$v)=each(%$e)) { $attr{$k}=$v; }
   } else
   {
    push @c,$e;
   }
  }
  my $tag=shift(@c);
  my $attr=keys(%attr)? ' '.join(' ',map { $_.'="'.$attr{$_}.'"' } sort(keys(%attr))) : '';
  if (!@c || (@c==1 && !ref($c[0]) && ($c[0] eq '')))
  {
   push @t,'<'.$tag.$attr.'/>';
  } else
  {
   push @t,'<'.$tag.$attr.'>';
   push @t,(@c==1 && !ref($c[0]))? xml_escape($c[0]) : xml_write(\@c);
   push @t,'</'.$tag.'>';
  }
 }
 return @t;
}

sub xml_indent
{
 my $xml=shift;
 chomp $xml;
 my $r='';

 $xml=~s!(<)!\n$1!g;
 $xml=~s!<(\S+)>(.+)\n</\1>!<$1>$2</$1>!g;
 $xml=~s!<(\S+)((?:\s+\S+=['"][^'"]+['"])+)>(.+)\n</\1>!<$1$2>$3</$1>!g;

 my $s=0;
 foreach my $m (split(/\n/,$xml))
 {
  next if $m=~m/^\s*$/;
  $s-- if ($m=~m!^</\S+>$!);

  $r.=' ' x $s;
  $r.=$m."\n";

  $s++ if ($m=~m!^<[^>?]+[^/](?:\s+\S+=['"][^'"]+['"])*>$!);
  $s-- if ($m=~m!^</\S+>$!);
 }

 ## As xml_indent is used during logging, we do a final quick check (spaces should not be relevant anyway)
 ## This test should probably be dumped as some point in the future when we are confident enough. But we got hit in the past by some subtleties, so...
 my $in=$xml;
 $in=~s/\s+//g;
 my $out=$r;
 $out=~s/\s+//g;
 if ($in ne $out) { Net::DRI::Exception::err_assert('xml_indent failed to do its job, please report !'); }

 return $r;
}

sub xml_list_children
{
 my $node=shift;
 ## '*' catch all element nodes being direct children of given node
 return map { [ $_->localname() || $_->nodeName(),$_ ] } grep { $_->nodeType() == 1 } $node->getChildrenByTagName('*');
}

sub xml_traverse
{
 my ($node,$ns,@nodes)=@_;
 my $p=sprintf('*[namespace-uri()="%s" and local-name()="%s"]',$ns,shift(@nodes));
 $p.='/'.join('/',map { '*[local-name()="'.$_.'"]' } @nodes) if @nodes;
 my $r=$node->findnodes($p);
 return unless $r->size();
 return ($r->size()==1)? $r->get_node(1) : $r->get_nodelist();
}

sub xml_child_content
{
 my ($node,$ns,$what)=@_;
 my $list=$node->getChildrenByTagNameNS($ns,$what);
 return undef unless $list->size()==1; ## no critic (Subroutines::ProhibitExplicitReturnUndef)
 my $n=$list->get_node(1);
 return defined $n ? $n->textContent() : undef;
}

####################################################################################################

sub remcam
{
 my $in=shift;
 $in=~s/ID/_id/g;
 $in=~s/([A-Z])/_$1/g;
 return lc($in);
}

sub encode       { my ($cs,$data)=@_; return Encode::encode($cs,ref $data? $data->as_string() : $data,1); } ## Will croak on malformed data (a case that should not happen)
sub encode_utf8  { return encode('UTF-8',$_[0]); } ## no critic (Subroutines::RequireArgUnpacking)
sub encode_ascii { return encode('ascii',$_[0]); } ## no critic (Subroutines::RequireArgUnpacking)
sub decode       { my ($cs,$data)=@_; return Encode::decode($cs,$data,1); } ## Will croak on malformed data (a case that should not happen)
sub decode_utf8  { return decode('UTF-8',$_[0]); } ## no critic (Subroutines::RequireArgUnpacking)
sub decode_ascii { return decode('ascii',$_[0]); } ## no critic (Subroutines::RequireArgUnpacking)
sub decode_latin1{ return decode('iso-8859-1',$_[0]); } ## no critic (Subroutines::RequireArgUnpacking)

sub normalize_name
{
 my ($type,$key)=@_;
 $type=lc($type);
 ## contact IDs may be case sensitive...
 ## Will need to be redone differently with IDNs
 $key=lc $key if ($type eq 'domain' || $type eq 'nsgroup');
 $key=lc $key if ($type eq 'host' && $key=~m/\./); ## last test part is done only to handle the pure mess created by Nominet .UK "EPP" implementation...
 return ($type,$key);
}

## DateTime object to Zulu time stringified
sub dto2zstring
{
 my ($dt)=@_;
 my $date=$dt->clone()->set_time_zone('UTC');
 return $date->ymd('-').'T'.$date->hms(':').($date->microsecond() ? '.'.sprintf('%06s',$date->microsecond()) : '').'Z';
}

####################################################################################################

## RFC2782
## (Net::DNS rrsort for SRV records does not seem to implement the same algorithm as the one specificied in the RFC,
##  as it just does a comparison on priority then weight)
sub dns_srv_order
{
 my (@args)=@_;
 my (@r,%r);
 foreach my $ans (@args)
 {
  push @{$r{$ans->priority()}},$ans;
 }
 foreach my $pri (sort { $a <=> $b } keys(%r))
 {
  my @o=@{$r{$pri}};
  if (@o > 1)
  {
   my $ts=0;
   foreach (@o) { $ts+=$_->weight(); }
   my $s=0;
   @o=map { $s+=$_->weight(); [ $s, $_ ] } (grep { $_->weight() == 0 } @o, grep { $_->weight() > 0 } @o);
   my $cs=0;
   while(@o > 1)
   {
    my $r=int(rand($ts-$cs+1));
    foreach my $i (0..$#o)
    {
     next unless $o[$i]->[0] >= $r;
     $cs+=$o[$i]->[0];
     foreach my $j (($i+1)..$#o) { $o[$j]->[0]-=$o[$i]->[0]; }
     push @r,$o[$i]->[1];
     splice(@o,$i,1);
     last;
    }
   }
  }
  push @r,$o[0]->[1];
 }
 return map { [$_->target(),$_->port()] } @r;
}

####################################################################################################

sub load_module
{
 my ($class,$etype)=@_;
 eval { Module::Load::load($class); };
 Net::DRI::Exception::err_failed_load_module($etype,$class,$@) if $@;
 return;
}

####################################################################################################
1;
