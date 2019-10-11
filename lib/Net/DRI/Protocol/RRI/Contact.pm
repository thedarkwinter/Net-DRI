## Domain Registry Interface, RRI Contact commands (DENIC-29)
##
## Copyright (c) 2007,2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
##           (c) 2012,2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2019 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::RRI::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

use DateTime::Format::ISO8601 ();

=pod

=head1 NAME

Net::DRI::Protocol::RRI::Contact - RRI Contact commands (DENIC-29-EN_3.0) for Net::DRI

=head1 DESCRIPTION

This was updated to represent changes listed under DENIC version 3.0.

The fields Phone, Fax, Sip, Remarks and Disclose are no longer available

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
          (c) 2012,2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
          (c) 2019 Paulo Jorge <paullojorgge@gmail.com>.
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
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           create => [ \&create, \&create_parse ],
	   update => [ \&update ],
         );

 ##$tmp{check_multi}=$tmp{check};
 return { 'contact' => \%tmp };
}

sub build_command
{
 my ($msg, $command, $contact) = @_;
 my @contact = (ref($contact) eq 'ARRAY')? @$contact : ($contact);
 my @c = map { Net::DRI::Util::isa_contact($_)? $_->srid() : $_ }
	@contact;

 Net::DRI::Exception->die(1,'protocol/RRI',2,'Contact id needed') unless @c;
 foreach my $n (@c)
 {
  Net::DRI::Exception->die(1,'protocol/RRI',2,'Contact id needed') unless defined($n) && $n;
  Net::DRI::Exception->die(1,'protocol/RRI',10,'Invalid contact id: '.$n) unless Net::DRI::Util::xml_is_token($n,3,32);
 }

 my $tcommand = (ref($command))? $command->[0] : $command;
 my @ns = @{$msg->ns->{contact}};
 $msg->command(['contact',$tcommand,$ns[0]]);

 my @d = map { ['contact:handle',$_] } @c;

 return @d;
}

####################################################################################################
########### Query commands

sub check
{
 my ($rri,$c)=@_;
 my $mes=$rri->message();
 my @d=build_command($mes,'check',$c);
 $mes->command_body(\@d);
 $mes->cltrid(undef);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes = $po->message();
 return unless $mes->is_success();

 my $chkdata = $mes->get_content('checkData',$mes->ns('contact'));
 return unless ($chkdata);
 my @c = $chkdata->getElementsByTagNameNS($mes->ns('contact'),'handle');
 my @s = $chkdata->getElementsByTagNameNS($mes->ns('contact'),'status');
 return unless (@c && @s);
 my $contact = $c[0]->getFirstChild()->getData();
 $rinfo->{contact}->{$contact}->{action} = 'check';
 $rinfo->{contact}->{$contact}->{exist} = ($s[0]->getFirstChild()->getData() eq 'free')? 0 : 1;
 return;
}

sub info
{
 my ($rri,$c)=@_;
 my $mes=$rri->message();
 my @d=build_command($mes,'info',$c);
 $mes->command_body(\@d);
 $mes->cltrid(undef);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_content('infoData',$mes->ns('contact'));
 return unless $infdata;

 my %cd=map { $_ => [] } qw/name org street city sp pc cc/;
 my $contact=$po->create_local_object('contact');
 my @s;
 my $c=$infdata->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1);
  my $name=$c->localname() || $c->nodeName();
  next unless $name;
  if ($name eq 'handle')
  {
   my $clID;
   $oname = $c->getFirstChild()->getData();
   if ($oname =~ /^(\w+)-(\d+)-/)
   { $clID = $1 . '-' . $2 . '-RRI'; }
   $rinfo->{contact}->{$oname}->{action} = 'info';
   $rinfo->{contact}->{$oname}->{exist} = 1;
   $rinfo->{contact}->{$oname}->{clID} =
   $rinfo->{contact}->{$oname}->{crID} = $clID;
   $contact->srid($oname);
  } elsif ($name eq 'roid')
  {
   my $el = $c->getFirstChild();
   $contact->roid($el->getData()) if (defined($el));
   $rinfo->{contact}->{$oname}->{roid} = $contact->roid();
  } elsif ($name eq 'changed')
  {
   my $el = $c->getFirstChild();
   $rinfo->{contact}->{$oname}->{upDate} =
   $rinfo->{contact}->{$oname}->{crDate} =
	DateTime::Format::ISO8601->new()->
	parse_datetime($c->getFirstChild()->getData()) if (defined($el));
  } elsif ($name eq 'type')
  {
   my $el = $c->getFirstChild();
   $contact->type($el->getData()) if (defined($el));
  } elsif ($name eq 'email')
  {
   my $el = $c->getFirstChild();
   $contact->email($el->getData()) if (defined($el));
  } elsif ($name eq 'name')
  {
   my $el = $c->getFirstChild();
   $contact->name($el->getData()) if (defined($el));
  } elsif ($name eq 'organisation')
  {
   my $el = $c->getFirstChild();
   $contact->org($el->getData()) if (defined($el));
  } elsif ($name eq 'postal')
  {
   parse_postalinfo($c,\%cd);
  } elsif ($name eq 'uri-template')
  {
    my $el = $c->getFirstChild();
    $contact->uri_template($el->getData()) if (defined($el));
  } elsif ($name eq 'disputeReference')
  {
    my $el = $c->getFirstChild();
    $contact->dispute_reference($el->getData()) if (defined($el));
  }
 } continue { $c=$c->getNextSibling(); }

 $contact->street(@{$cd{street}});
 $contact->city(@{$cd{city}});
 $contact->pc(@{$cd{pc}});
 $contact->cc(@{$cd{cc}});

 $rinfo->{contact}->{$oname}->{self}=$contact;
 return;
}

sub parse_tel
{
 my $node=shift;
 my $ext=$node->getAttribute('x') || '';
 my $num=get_data($node);
 $num.='x'.$ext if $ext;
 return $num;
}

sub get_data
{
 my $n=shift;
 return ($n->getFirstChild())? $n->getFirstChild()->getData() : '';
}

sub parse_postalinfo
{
 my ($c,$rcd)=@_;
 my @street;
 my $n = $c->getFirstChild();

 while ($n)
 {
  next unless ($n->nodeType() == 1);
  my $name=$n->localname() || $n->nodeName();
  next unless $name;
  if ($name eq 'city')
  {
   $rcd->{city}->[0] = get_data($n);
  } elsif ($name eq 'postalCode')
  {
   $rcd->{pc}->[0] = get_data($n);
  } elsif ($name eq 'countryCode')
  {
   $rcd->{cc}->[0] = get_data($n);
  } elsif ($name eq 'address')
  {
    push @street, get_data($n);
  }
 } continue { $n=$n->getNextSibling(); }

 $rcd->{street}->[0]=\@street;
 return;
}

############ Transform commands

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

sub build_cdata
{
 my $contact=shift;
 my @d;

 my (@post,@addr);
 _do_locint(\@post,$contact,'type','type');
 _do_locint(\@post,$contact,'name','name');
 _do_locint(\@post,$contact,'organisation','org');
 _do_locint(\@addr,$contact,'address','street');
 _do_locint(\@addr,$contact,'postalCode','pc');
 _do_locint(\@addr,$contact,'city','city');
 _do_locint(\@addr,$contact,'countryCode','cc');
 _do_locint(\@post,$contact,'uri-template','uri_template');
 push @post,['contact:postal',@addr] if @addr;

 push (@d,@post) if @post;

 push @d,['contact:email',$contact->email()] if defined($contact->email());

 return @d;
}

sub _do_locint
{
 my ($r, $contact, $tagname, $what) = @_;
 my @tmp = $contact->$what();
 my $loaded = 0;
 return unless (@tmp);
 if ($what eq 'street')
 {
  if (defined($tmp[0]))
  {
    foreach (@{$tmp[0]})
    {
      push @$r,['contact:'.$tagname,$_];
      $loaded = 1;
    }
  }
  if (defined($tmp[1]) && !$loaded)
  {
    foreach (@{$tmp[1]})
    {
      push @$r,['contact:'.$tagname,$_];
    }
  }
 } else
 {
  if (defined($tmp[0]))
  {
    push @$r,['contact:'.$tagname,$tmp[0]];
    $loaded = 1;
  }
  if (defined($tmp[1]) && !$loaded)
  {
    push @$r,['contact:'.$tagname,$tmp[1]];
  }
 }
 return;
}

sub create
{
 my ($rri,$contact)=@_;
 my $mes=$rri->message();
 my @d=build_command($mes,'create',$contact);

 Net::DRI::Exception->die(1,'protocol/RRI',10,'Invalid contact '.$contact) unless (Net::DRI::Util::isa_contact($contact));
 $contact->validate(); ## will trigger an Exception if needed
 push @d,build_cdata($contact);
 $mes->command_body(\@d);
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_content('creData',$mes->ns('contact'));
 return unless $credata;

 my $c=$credata->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  if ($name eq 'id')
  {
   my $new=$c->getFirstChild()->getData();
   $rinfo->{contact}->{$oname}->{id}=$new if (defined($oname) && ($oname ne $new)); ## registry may give another id than the one we requested or not take ours into account at all !
   $oname=$new;
   $rinfo->{contact}->{$oname}->{id}=$oname;
   $rinfo->{contact}->{$oname}->{action}='create';
   $rinfo->{contact}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(crDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
  }
 } continue { $c=$c->getNextSibling(); }
 return;
}

sub update
{
 my ($rri,$contact,$todo)=@_;
 my $mes=$rri->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);
 if ((grep { ! /^(?:add|del)$/ } $todo->types('status')) ||
     (grep { ! /^(?:set)$/ } $todo->types('info'))
    )
 {
  Net::DRI::Exception->die(0,'protocol/RRI',11,'Only status add/del or info set available for contact');
 }

 my @d=build_command($mes,'update',$contact);

 my $newc=$todo->set('info');
 if ($newc)
 {
  Net::DRI::Exception->die(1,'protocol/RRI',10,'Invalid contact '.$newc) unless Net::DRI::Util::isa_contact($newc);
  $newc->type($contact->type());
  $newc->validate(1); ## will trigger an Exception if needed
  push @d,build_cdata($newc);
 }
 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;
