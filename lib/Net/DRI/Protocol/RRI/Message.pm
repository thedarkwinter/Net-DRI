## Domain Registry Interface, RRI Message
##
## Copyright (c) 2007-2009,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::RRI::Message;

use strict;
use warnings;

use XML::LibXML ();

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;
use Net::DRI::Util;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version command command_body cltrid svtrid result
	errcode errmsg node_resdata result_extra_info));

=pod

=head1 NAME

Net::DRI::Protocol::RRI::Message - RRI Message for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007-2009,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my $class = shift;
 my $trid = shift;

 my $self = {
           result => 'uninitialized',
          };

 bless($self,$class);

 $self->cltrid($trid) if (defined($trid) && $trid);
 return $self;
}

sub ns
{
 my ($self,$what)=@_;
 return $self->{ns} unless defined($what);

 if (ref($what) eq 'HASH')
 {
  $self->{ns}=$what;
  return $what;
 }
 return unless exists($self->{ns}->{$what});
 return $self->{ns}->{$what}->[0];
}

sub is_success { return (shift->result() =~ m/^success/)? 1 : 0; }

sub result_status
{
 my $self=shift;
 my $rs = Net::DRI::Protocol::ResultStatus->new('rri',
	($self->is_success() ? 1000 : $self->errcode()), undef,
	$self->is_success(), $self->errmsg(), 'en',
	$self->result_extra_info());
 $rs->_set_trid([ $self->cltrid(), $self->svtrid() ]);
 return $rs;
}

sub as_string
{
 my ($self)=@_;
 my $rns=$self->ns();
 my $topns=$rns->{_main};
 my $ens=sprintf('xmlns="%s"', $topns->[0]);
 my $cmdi = $self->command();
 my @d;
 push @d,'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
 my ($type, $cmd, $ns, $attr);
 ($type, $cmd, $ns, $attr) = @{$cmdi} if (ref($cmdi) eq 'ARRAY');

 $attr = '' unless (defined($attr));
 $attr = ' ' . join(' ', map { $_ . '="' . $attr->{$_} . '"' }
	sort { $a cmp $b } keys (%{$attr})) if (ref($attr) eq 'HASH');

 if (defined($ns))
 {
  if (ref($ns) eq 'HASH')
  {
   $ens .= ' ' . join(' ', map { 'xmlns:' . $_ . '="' . $ns->{$_} . '"' }
	sort { $a cmp $b } keys(%{$ns}));
   $cmd = $type . ':' . $cmd;
  }
  else
  {
   $ens .= ' xmlns:' . $type . '="' . $ns . '"';
   $cmd = $type . ':' . $cmd;
  }
 }
 else
 {
  $cmd = $type;
  $type = undef;
 }

 push @d,'<registry-request '.$ens.'>';

 my $body=$self->command_body();
 if (defined($body) && $body)
 {
  push @d,'<'.$cmd.$attr.'>';
  push @d,Net::DRI::Util::xml_write($body);
  push @d,'</'.$cmd.'>';
 } else
 {
  push @d,'<'.$cmd.$attr.'/>';
 }
 
 ## OPTIONAL clTRID
 my $cltrid=$self->cltrid();
 push @d,'<ctid>'.$cltrid.'</ctid>'
	if (defined($cltrid) && $cltrid &&
		Net::DRI::Util::xml_is_token($cltrid,3,64));
 push @d,'</registry-request>';

 return join('',@d);
}

sub topns { return shift->ns->{_main}->[0]; }

sub get_content
{
 my ($self,$nodename,$ns,$ext)=@_;
 return unless (defined($nodename) && $nodename);

 my @tmp;
 my $n1=$self->node_resdata();

 $ns||=$self->topns();

 @tmp=$n1->getElementsByTagNameNS($ns,$nodename) if (defined($n1));

 return unless @tmp;
 return wantarray()? @tmp : $tmp[0];
}

sub parse
{
 my ($self,$dc,$rinfo)=@_;
 my $NS=$self->topns();
 my $trNS = $self->ns('tr');
 my $parser=XML::LibXML->new();
 my $xstr = $dc->as_string();
 $xstr =~ s/^\s*//;
 my $doc=$parser->parse_string($xstr);
 my $root=$doc->getDocumentElement();
 Net::DRI::Exception->die(0, 'protocol/RRI', 1,
	'Unsuccessfull parse, root element is not registry-response')
		unless ($root->getName() eq 'registry-response');

 my @trtags = $root->getElementsByTagNameNS($trNS, 'transaction');
 Net::DRI::Exception->die(0, 'protocol/RRI', 1,
	'Unsuccessfull parse, no transaction block') unless (@trtags);
 my $res = $trtags[0];

 ## result block(s)
 my @results = $res->getElementsByTagNameNS($trNS,'result'); ## success indicator
 foreach (@results)
 {
  $self->result($_->firstChild()->getData());
 }

 if ($res->getElementsByTagNameNS($trNS,'message')) ## OPTIONAL
 {
  my @msgs = $res->getElementsByTagNameNS($trNS,'message');
  my $msg = $msgs[0];
  my @extra = ();

  if (defined($msg))
  {
   my @texts = $msg->getElementsByTagNameNS($trNS, 'text');
   my $msgtype = $msg->getAttribute('level');
   my $text = $texts[0];

   if ($msgtype eq 'error')
   {
    $self->errcode($msg->getAttribute('code'));
    $self->errmsg($text->getFirstChild()->getData()) if (defined($text));
   }
   else
   {
    push @extra, { from => 'rri', type => 'text', code => $msg->getAttribute('code'), message => (defined $text ? $text->textContent() : '') };
   }
  }
  $self->result_extra_info(\@extra);
 }

 if ($res->getElementsByTagNameNS($trNS,'data')) ## OPTIONAL
 {
  $self->node_resdata(($res->getElementsByTagNameNS($trNS,'data'))[0]);
 }

 ## trID
 if ($res->getElementsByTagNameNS($trNS, 'stid'))
 {
  my @svtrid = $res->getElementsByTagNameNS($trNS, 'stid');
  $self->svtrid($svtrid[0]->firstChild()->getData());
 }
 if ($res->getElementsByTagNameNS($trNS, 'ctid'))
 {
  my @cltrid = $res->getElementsByTagNameNS($trNS, 'ctid');
  $self->cltrid($cltrid[0]->firstChild()->getData());
 }

 return;
}

####################################################################################################
1;

