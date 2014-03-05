## Domain Registry Interface, Mark & Signed Mark for EPP (draft-lozano-tmch-smd-02)
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

package Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

use XML::LibXML ();

####################################################################################################

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'mark'       => [ 'urn:ietf:params:xml:ns:mark-1.0','mark-1.0.xsd' ],
           'signedMark' => [ 'urn:ietf:params:xml:ns:signedMark-1.0','signedMark-1.0'] });
 return;
}

my %xml2perl = ( trademark       => 'trademark',
                 treatyOrStatute => 'treaty_statute',
                 court           => 'court',
                 markName        => 'mark_name',
                 goodsAndServices=> 'goods_services',
                 apId            => 'application_id',
                 apDate          => 'application_date',
                 regNum          => 'registration_number',
                 regDate         => 'registration_date',
                 exDate          => 'expiration_date',
                 refNum          => 'reference_number',
                 proDate         => 'protection_date',
                 execDate        => 'execution_date',
                 courtName       => 'court_name',
               );

####################################################################################################

sub build_marks
{
 my ($po,$rd)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('A ref array must be passed for marks, or a standalone ref hash for only one mark') unless defined $rd && (ref $rd eq 'ARRAY' || ref $rd eq 'HASH');
 my @r;
 foreach my $m (ref $rd eq 'ARRAY' ? @$rd : $rd)
 {
  push @r,['mark:mark',{ 'xmlns:mark' => $po->ns()->{'mark'}->[0]},build_mark($m)];
 }
 return @r;
}

sub build_mark
{
 my ($rd)=@_;
 my @r;

 Net::DRI::Exception::usererr_invalid_parameters() unless defined $rd && ref $rd eq 'HASH';
 my $type=$rd->{type};
 $type='' unless defined $type;

 if ($type eq 'trademark' || exists $rd->{jurisdiction})
 {
  return _build_trademark($rd);
 } elsif ($type eq 'treaty_statute' || exists $rd->{protection})
 {
  return _build_treaty($rd);
 } elsif ($type eq 'court' || exists $rd->{court_name})
 {
  return _build_court($rd);
 } else 
 {
  Net::DRI::Exception::usererr_invalid_parameters(qq{Unrecognized type "$type" of mark, and no "jurisdiction", "protection" or "court_name" element});
 }
 return;
}

sub _build_addr
{
 my ($contact)=@_;
 my (@r,$v);

 $v=scalar $contact->street();
 Net::DRI::Exception::usererr_insufficient_parameters('Contact address must have from 1 to 3 street elements') unless defined $v && ref $v eq 'ARRAY' && @$v >=1 && @$v <= 3;
 push @r,map { ['mark:street',$_] } @$v;

 $v=scalar $contact->city();
 Net::DRI::Exception::usererr_insufficient_parameters('Contact address must have a city') unless defined $v;
 Net::DRI::Exception::usererr_invalid_parameters('Contact address city must be an XML token string') unless Net::DRI::Util::xml_is_token($v);
 push @r,['mark:city',$v];

 $v=scalar $contact->sp();
 if (defined $v && length $v)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Contact address sp must be an XML token string') unless Net::DRI::Util::xml_is_token($v);
  push @r,['mark:sp',$v];
 }

 $v=scalar $contact->pc();
 if (defined $v && length $v)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Contact address pc must be an XML token string with 16 characters or less') unless Net::DRI::Util::xml_is_token($v,0,16);
  push @r,['mark:pc',$v];
 }

 $v=scalar $contact->cc();
 Net::DRI::Exception::usererr_insufficient_parameters('Contact address must have a cc') unless defined $v;
 Net::DRI::Exception::usererr_invalid_parameters('Contact address cc must be an XML token string of 2 characters') unless Net::DRI::Util::xml_is_token($v,2,2);
 push @r,['mark:cc',$v];

 return @r;
}

sub _build_contact
{
 my ($type,$contact)=@_;

 Net::DRI::Exception::usererr_invalid_parameters('Element must be contact object, not: '.$contact) unless Net::DRI::Util::isa_contact($contact);

 my (@r,$v);

 $v=scalar $contact->name();
 if (defined $v && length $v)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Name of contact must be an XML token string, not: '.$v) unless Net::DRI::Util::xml_is_token($v);
  push @r,['mark:name',$v];
 } else
 {
  Net::DRI::Exception::usererr_insufficient_parameters('Name is mandatory for a contact') if ($type eq 'contact');
 }

 $v=scalar $contact->org();
 if (defined $v && length $v)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Org of contact must be an XML token string, not: '.$v) unless Net::DRI::Util::xml_is_token($v);
  push @r,['mark:org',$v];
 }

 push @r,['mark:addr',_build_addr($contact)];

 $v=$contact->voice();
 if (defined $v && length $v)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Voice of contact must be an XML token string verifying pattern "(\+[0-9]{1,3}\.[0-9]{1,14})?"') unless Net::DRI::Util::xml_is_token($v,0,17) && $v=~m/^\+[0-9]{1,3}\.[0-9]{1,14}$/;
  push @r,Net::DRI::Protocol::EPP::Util::build_tel('mark:voice',$v);
 } else
 {
  Net::DRI::Exception::usererr_insufficient_parameters('Voice is mandatory for a contact') if ($type eq 'contact');
 }

 $v=$contact->fax();
 if (defined $v && length $v)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Fax of contact must be an XML token string verifying pattern "(\+[0-9]{1,3}\.[0-9]{1,14})?"') unless Net::DRI::Util::xml_is_token($v,0,17) && $v=~m/^\+[0-9]{1,3}\.[0-9]{1,14}$/;
  push @r,Net::DRI::Protocol::EPP::Util::build_tel('mark:fax',$v);
 }

 $v=$contact->email();
 if (defined $v && length $v)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Email of contact must be an XML token string with at least 1 character, not: '.$v) unless Net::DRI::Util::xml_is_token($v,1);
  push @r,['mark:email',$v];
 } else
 {
  Net::DRI::Exception::usererr_insufficient_parameters('Email is mandatory for a contact') if ($type eq 'contact');
 }

 return @r;
}

sub _add_token
{
 my ($rd,$key,$optional)=@_;
 my $pkey=exists $xml2perl{$key} ? $xml2perl{$key} : $key;
 if (Net::DRI::Util::has_key($rd,$pkey))
 {
  Net::DRI::Exception::usererr_invalid_parameters(qq{Value for "$pkey" key must be an XML token string}) unless Net::DRI::Util::xml_is_token($rd->{$pkey});
  return ['mark:'.$key,$rd->{$pkey}];
 } else
 {
  Net::DRI::Exception::usererr_insufficient_parameters(qq{"$pkey" key must exist}) unless (defined $optional && $optional);
  return;
 }
}

sub _add_datetime
{
 my ($rd,$key,$optional)=@_;
 my $pkey=exists $xml2perl{$key} ? $xml2perl{$key} : $key;
 if (Net::DRI::Util::has_key($rd,$pkey))
 {
  Net::DRI::Exception::usererr_invalid_parameters(qq{Value for "$pkey" key must be a DateTime object}) unless Net::DRI::Util::is_class($rd->{$pkey},'DateTime');
  return ['mark:'.$key,Net::DRI::Util::dto2zstring($rd->{$pkey})];
 } else
 {
  Net::DRI::Exception::usererr_insufficient_parameters(qq{"$pkey" key must exist}) unless (defined $optional && $optional);
  return;
 }
}

sub _build_common1
{
 my ($rd)=@_;
 my @r;

 push @r,_add_token($rd,'id');
 Net::DRI::Exception::usererr_invalid_parameters('Value for "id" key must match pattern "\d+-\d+"') unless $rd->{id}=~m/^\d+-\d+$/;

 push @r,_add_token($rd,'markName');

 Net::DRI::Exception::usererr_insufficient_parameters('"contact" key must exist') unless Net::DRI::Util::has_key($rd,'contact');
 Net::DRI::Exception::usererr_invalid_parameters('Value for "contact" key must be a ContactSet object') unless Net::DRI::Util::isa_contactset($rd->{contact});
 Net::DRI::Exception::usererr_insufficient_parameters('Value for "contact" key must have at least one contact of type holder_owner, holder_assignee or holder_licensee') unless grep { /^(?:holder_owner|holder_assignee|holder_licensee)$/ } $rd->{contact}->types();
 foreach my $type (qw/owner assignee licensee/)
 {
  my @o=$rd->{contact}->get('holder_'.$type);
  next unless @o;
  foreach my $c (@o)
  {
   push @r,['mark:holder',{ entitlement => $type },_build_contact('holder',$c)];
  }
 }
 foreach my $type (qw/owner agent thirdparty/)
 {
  my @o=$rd->{contact}->get('contact_'.$type);
  next unless @o;
  foreach my $c (@o)
  {
   push @r,['mark:contact',{ type => $type },_build_contact('contact',$c)];
  }
 }

 return @r;
}

sub _build_common2
{
 my ($rd)=@_;
 my @r;

 if (Net::DRI::Util::has_key($rd,'label'))
 {
  foreach my $label (ref $rd->{label} eq 'ARRAY' ? @{$rd->{label}} : ($rd->{label}))
  {
   Net::DRI::Exception::usererr_invalid_parameters(qq{Label "$label" must be an XML token string from 1 to 63 characters}) unless Net::DRI::Util::xml_is_token($label,1,63);
   Net::DRI::Exception::usererr_invalid_parameters(qq{Label "$label" must pass regex "[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?"}) unless $label=~m/^[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$/;
   push @r,['mark:label',$label];
  }
 }

 push @r,_add_token($rd,'goodsAndServices'); 

 return @r;
}

sub _build_common3
{
 my ($rd)=@_;
 my @r;

 push @r,_add_token($rd,'refNum');
 push @r,_add_datetime($rd,'proDate');

 return @r;
}

sub _build_trademark
{
 my ($rd)=@_;
 my @r;

 push @r,_build_common1($rd); ## id/markName/holder/contact
 
 push @r,_add_token($rd,'jurisdiction');
 Net::DRI::Exception::usererr_invalid_parameters(qq{Value for "jurisdiction" key must be an XML token string of 2 characters}) unless Net::DRI::Util::xml_is_token($rd->{jurisdiction},2,2);

 if (Net::DRI::Util::has_key($rd,'class'))
 {
  foreach my $class (ref $rd->{class} eq 'ARRAY' ? @{$rd->{class}} : ($rd->{class}))
  {
   Net::DRI::Exception::usererr_invalid_parameters('Class must be an integer, not: '.$class) unless $class=~m/^\d+$/;
   push @r,['mark:class',$class];
  }
 }

 push @r,_build_common2($rd); ## label/goodsAndServices

 push @r,_add_token($rd,'apId',1);
 push @r,_add_datetime($rd,'apDate',1);
 push @r,_add_token($rd,'regNum');
 push @r,_add_datetime($rd,'regDate');
 push @r,_add_datetime($rd,'exDate',1);

 return ['mark:trademark',@r];
}

sub _build_treaty
{
 my ($rd)=@_;
 my @r;

 push @r,_build_common1($rd); ## id/markName/holder/contact

 Net::DRI::Exception::usererr_insufficient_parameters('Key "protection" must exist') unless Net::DRI::Util::has_key($rd,'protection');
 foreach my $rprot (ref $rd->{protection} eq 'ARRAY' ? @{$rd->{protection}} : ($rd->{protection}))
 {
  my @pro;
  Net::DRI::Exception::usererr_invalid_parameters('Each protection item must be a ref hash, not: '.$rprot) unless ref $rprot eq 'HASH';

  push @r,_add_token($rprot,'cc');
  Net::DRI::Exception::usererr_invalid_parameters(qq{Value for "cc" key must be an XML token string of 2 characters}) unless Net::DRI::Util::xml_is_token($rprot->{cc},2,2);

  push @r,_add_token($rprot,'region',1);

  if (Net::DRI::Util::has_key($rprot,'ruling'))
  {
   foreach my $ruling (ref $rprot->{ruling} eq 'ARRAY' ? @{$rprot->{ruling}} : ($rprot->{ruling}))
   {
    push @r,_add_token({ ruling => $ruling },'ruling');
    Net::DRI::Exception::usererr_invalid_parameters(qq{Each "ruling" item must be an XML token string of 2 characters}) unless Net::DRI::Util::xml_is_token($ruling,2,2);
   }
  }

  push @r,['mark:protection',@pro];
 }

 push @r,_build_common2($rd); ## label/goodsAndServices
 push @r,_build_common3($rd); ## refNum/proDate

 push @r,_add_token($rd,'title');
 push @r,_add_datetime($rd,'execDate');

 return ['mark:treatyOrStatute',@r];
}

sub _build_court
{
 my ($rd)=@_;
 my @r;

 push @r,_build_common1($rd); ## id/markName/holder/contact
 push @r,_build_common2($rd); ## label/goodsAndServices
 push @r,_build_common3($rd); ## refNum/proDate

 push @r,_add_token($rd,'cc');
 Net::DRI::Exception::usererr_invalid_parameters(qq{Value for "cc" key must be an XML token string of 2 characters}) unless Net::DRI::Util::xml_is_token($rd->{cc},2,2);

 if (Net::DRI::Util::has_key($rd,'region'))
 {
  foreach my $region (ref $rd->{region} eq 'ARRAY' ? @{$rd->{region}} : ($rd->{region}))
  {
   push @r,_add_token({ region => $region },'region');
  }
 }

 push @r,_add_token($rd,'courtName');

 return ['mark:court',@r];
}

####################################################################################################

sub parse_tel
{
 my ($node)=@_;
 my $r=$node->textContent();
 $r.='x'.$node->getAttribute('x') if $node->hasAttribute('x');
 return $r;
}

sub parse_contact
{
 my ($po,$start)=@_;
 my $contact=$po->create_local_object('contact');

 foreach my $el (Net::DRI::Util::xml_list_children($start))
 {
  my ($name,$node)=@$el;
  if ($name=~m/^(?:name|org|email)$/)
  {
   $contact->$name($node->textContent());
  } elsif ($name=~m/^(?:voice|fax)$/)
  {
   $contact->$name(parse_tel($node));
  } elsif ($name eq 'addr')
  {
   my @street;
   foreach my $subel (Net::DRI::Util::xml_list_children($node))
   {
    my ($addrname,$addrnode)=@$subel;
    if ($addrname eq 'street')
    {
     push @street,$addrnode->textContent();
    } elsif ($addrname=~m/^(?:city|sp|pc|cc)$/)
    {
     $contact->$addrname($addrnode->textContent());
    }
   }
   $contact->street(\@street);
  } elsif ($name=~m/^(?:voice|fax)$/)
  {
   $contact->$name(Net::DRI::Protocol::EPP::Util::parse_tel($node));
  }
 }

 return $contact;
}

sub parse_mark
{
 my ($po,$start)=@_;
 my @marks; 

 foreach my $el (Net::DRI::Util::xml_list_children($start))
 {
  my ($name,$node)=@$el;
  if ($name=~m/^(?:trademark|treatyOrStatute|court)$/)
  {
   my %m=(type => $xml2perl{$name});
   my (@class,@label,@protection,@region);
   my $cs=$po->create_local_object('contactset');
   foreach my $subel (Net::DRI::Util::xml_list_children($node))
   {
    my ($mname,$mnode)=@$subel;
    if ($mname=~m/^(id|markName|jurisdiction|goodsAndServices|apId|regNum|refNum|title|cc|courtName)$/)
    {
     $m{exists $xml2perl{$mname} ? $xml2perl{$mname} : $mname}=$mnode->textContent();
    } elsif ($mname eq 'holder')
    {
     my $type='holder_'.$mnode->getAttribute('entitlement'); ## owner, assignee, licensee
     $cs->add(parse_contact($po,$mnode),$type);
    } elsif ($mname eq 'contact')
    {
     my $type='contact_'.$mnode->getAttribute('type'); ## owner, agent, thirdparty
     $cs->add(parse_contact($po,$mnode),$type);
    } elsif ($mname eq 'class')
    {
     push @class,$mnode->textContent();
    } elsif ($mname eq 'label')
    {
     push @label,$mnode->textContent();
    } elsif ($mname=~m/^(?:apDate|regDate|exDate|proDate|execDate)$/)
    {
     $m{$xml2perl{$mname}}=$po->parse_iso8601($mnode->textContent());
    } elsif ($mname eq 'protection')
    {
     my %p;
     foreach my $pel (Net::DRI::Util::xml_list_children($mnode))
     {
      my ($pname,$pnode)=@$pel;
      if ($pname=~m/^(cc|region)$/)
      {
       $p{$pname}=$pnode->textContent();
      } elsif ($pname eq 'ruling')
      {
       push @{$p{ruling}},$pnode->textContent();
      }
     }
     push @protection,\%p;
    } elsif ($mname eq 'region')
    {
     push @region,$mnode->textContent();
    }
   }
   $m{contact}=$cs;
   $m{class}=\@class if @class;
   $m{label}=\@label if @label;
   $m{protection}=\@protection if @protection;
   $m{region}=\@region if @region;
   if (exists $m{goods_services})
   {
    $m{goods_services}=~s/\n +/ /g;
    $m{goods_services}=~s/ +$//s;
   }
   push @marks,\%m;
  }
 }

 return \@marks;
}

sub lined_content
{
 my ($node,$signs,@keys)=@_;
 my $r=Net::DRI::Util::xml_traverse($node,$signs,@keys)->textContent();
 $r=~s/\s+//g;
 return $r;
}

sub parse_signed_mark
{
 my ($po,$start)=@_;
 my %smark;

 foreach my $el (Net::DRI::Util::xml_list_children($start))
 {
  my ($name,$node)=@$el;
  if ($name eq 'id')
  {
   $smark{id}=$node->textContent();
  } elsif ($name eq 'issuerInfo')
  {
   my %issuer=(id => $node->getAttribute('issuerID'));
   foreach my $iel (Net::DRI::Util::xml_list_children($node))
   {
    my ($iname,$inode)=@$iel;
    if ($iname=~m/^(?:org|email|url)$/)
    {
     $issuer{$iname}=$inode->textContent();
    } elsif ($iname eq 'voice')
    {
     $issuer{$iname}=parse_tel($inode);
    }
   }
   $smark{issuer}=\%issuer;
  } elsif ($name eq 'notBefore')
  {
   $smark{'creation_date'}=$po->parse_iso8601($node->textContent());
  } elsif ($name eq 'notAfter')
  {
   $smark{'expiration_date'}=$po->parse_iso8601($node->textContent());
  } elsif ($name eq 'mark')
  {
   $smark{mark}=parse_mark($po,$node);
  } elsif ($name eq 'Signature')
  {
   my $signs='http://www.w3.org/2000/09/xmldsig#';
   my %s=(id => $start->getAttribute('id'));
   $s{'value'}=lined_content($node,$signs,qw/SignatureValue/);
   ## TODO: handle other algorithms
   $s{'key'}={ algorithm => 'rsa', 
               modulus => lined_content($node,$signs,qw/KeyInfo KeyValue RSAKeyValue Modulus/),
               exponent => lined_content($node,$signs,qw/KeyInfo KeyValue RSAKeyValue Exponent/),
               x509_certificate => lined_content($node,$signs,qw/KeyInfo X509Data X509Certificate/),
             };

   require Net::SAML2::XML::Sig;
   $s{'validated'}=Net::SAML2::XML::Sig->new()->verify($start->toString()); ## TODO : is this working ok ?

   $smark{'signature'}=\%s;
  }
 }
 return \%smark;
}

sub parse_encoded_signed_mark
{
 my ($po,$start)=@_;
 my $content;

 if (ref $start)
 {
  my $encoding=$start->hasAttribute('encoding') ? $start->getAttribute('encoding') : 'base64';
  Net::DRI::Exception::err_invalid_parameter('For encoded signed mark, only base64 encoding is supported') unless $encoding eq 'base64';
  $content=$start->textContent();
 } else
 {
  my @a=grep { /-----BEGIN ENCODED SMD-----/ .. /-----END ENCODED SMD-----/ } split(/\n/,$start);
  $content=join("\n",@a[1..($#a-1)]);
 }

 require MIME::Base64;
 my $xml=MIME::Base64::decode_base64($content);

 my $parser=XML::LibXML->new();
 my $doc=$parser->parse_string($xml);
 my $root=$doc->getDocumentElement();
 Net::DRI::Exception::err_invalid_parameter('Decoding should give a signedMark root element') unless $root->localname() eq 'signedMark';

 return parse_signed_mark($po,$root);
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark - ICANN TMCH Mark/Signed Mark EPP Extension (draft-lozano-tmch-smd-02) for Net::DRI

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

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
