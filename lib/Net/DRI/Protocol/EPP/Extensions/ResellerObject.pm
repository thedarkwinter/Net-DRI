## Domain Registry Interface, Reseller Extension Mapping for EPP
##
## Copyright (c) 2015,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ResellerObject;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 state $rops = { 'reseller' => { check  => [ \&check_build,  \&check_parse ],
                                 info   => [ \&info_build,   \&info_parse ],
                                 create => [ \&create_build, \&create_parse ],
                                 delete => [ \&delete_build, undef ],
                                 update => [ \&update_build, undef ],
                               }
               };

 return $rops;
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'reseller' => [ 'urn:ietf:params:xml:ns:reseller-1.0','reseller-1.0.xsd' ] });
 return;
}

sub capabilities_add
{
 state $c = [ [ 'reseller_update', 'contact', [qw/add del set/] ],
              [ 'reseller_update', 'status', ['set'] ],
              [ 'reseller_update', 'parent_id', ['set'] ],
              [ 'reseller_update', 'url', ['set'] ],
            ];
 return $c;
}

sub implements { return 'https://tools.ietf.org/html/draft-zhou-eppext-reseller-mapping-03'; }

####################################################################################################

sub _add_id
{
 my ($mes,$command,$reseller)=@_;
 my @r;

 Net::DRI::Exception::usererr_insufficient_parameters('Missing reseller id') unless defined $reseller && (!ref $reseller || ref $reseller eq 'ARRAY');
 Net::DRI::Exception::usererr_invalid_parameters('Only one reseller id allowed for command '.$command) if $command ne 'check' && ref $reseller;
 foreach my $id (ref $reseller ? @$reseller : ($reseller))
 {
  Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for reseller id: '.$id) unless Net::DRI::Util::xml_is_token($id,3,16);
  push @r,['reseller:id',$id];
 }

 $mes->command([$command,'reseller:'.$command,sprintf('xmlns:reseller="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('reseller'))]);

 return @r;
}

sub check_build
{
 my ($epp,$reseller,$rd)=@_;
 my $mes=$epp->message();

 my @d=_add_id($mes,'check',$reseller);
 $mes->command_body(\@d);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_response('reseller','chkData');
 return unless defined $chkdata;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('reseller'),'cd'))
 {
  my $id;
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'id')
   {
    $id=$c->textContent();
    $rinfo->{reseller}->{$id}->{action}='check';
    $rinfo->{reseller}->{$id}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   } elsif ($n eq 'reason')
   {
    $rinfo->{reseller}->{$id}->{exist_reason}=$c->hasAttribute('lang') ? { lang => $c->getAttribute('lang'), reason => $c->textContent() } : $c->textContent();
   }
  }
 }
 return;
}

sub info_build
{
 my ($epp,$reseller,$rd)=@_;
 my $mes=$epp->message();

 my @d=_add_id($mes,'info',$reseller);
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_response('reseller','infData');
 return unless defined $data;

 my %r=(action => 'info', exist => 1);
 my $cs=$po->create_local_object('contactset');
 my %ccache;
 my %cd=map { $_ => [] } qw/name org city sp pc cc/;
 $cd{street}=[[],[]];
 my $contact=$po->create_local_object('contact');

 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name=~m/^(?:id|roid|state|parentId|url)$/)
  {
   my $key=Net::DRI::Util::remcam($name);
   $key='status' if $key eq 'state';
   $r{$key}=$node->textContent();
  } elsif ($name=~m/^(email)$/) ## TODO: url should be there too
  {
   $contact->$name($node->textContent());
  } elsif ($name eq 'postalInfo')
  {
   Net::DRI::Protocol::EPP::Util::parse_postalinfo($po,$node,\%cd);
  } elsif ($name eq 'voice' || $name eq 'fax')
  {
   $contact->$name(Net::DRI::Protocol::EPP::Util::parse_tel($node));
  } elsif ($name eq 'contact')
  {
   my $id=$node->textContent();
   $ccache{$id}=$po->create_local_object('contact')->srid($id) unless exists $ccache{$id};
   $cs->add($ccache{$id},$node->getAttribute('type'));
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $r{$1}=$node->textContent();
  } elsif ($name=~m/^(crDate|upDate)$/)
  {
   $r{$1}=$po->parse_iso8601($node->textContent());
  } elsif ($name eq 'disclose')
  {
   $contact->disclose(Net::DRI::Protocol::EPP::Util::parse_disclose($node));
  }
 }

 $contact->name(@{$cd{name}});
 $contact->org(@{$cd{org}});
 $contact->street(@{$cd{street}});
 $contact->city(@{$cd{city}});
 $contact->sp(@{$cd{sp}});
 $contact->pc(@{$cd{pc}});
 $contact->cc(@{$cd{cc}});
 $cs->set($contact,'main');
 $r{contact}=$cs;
 $rinfo->{$otype}->{$r{id}}=\%r;

 return;
}

sub create_build
{
 my ($epp,$reseller,$rd)=@_;
 my $mes=$epp->message();

 my @d=_add_id($mes,'create',$reseller);

 Net::DRI::Exception::usererr_insufficient_parameters('Missing mandatory reseller state') unless Net::DRI::Util::has_key($rd,'status');
 Net::DRI::Exception::usererr_invalid_parameters('Invalid reseller state: '.$rd->{status}) unless $rd->{status}=~m/^(?:ok|readonly|terminated)$/;
 push @d,['reseller:state',$rd->{status}];

 if (Net::DRI::Util::has_key($rd,'parent_id'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for reseller parent_id: '.$rd->{parent_id}) unless Net::DRI::Util::xml_is_token($rd->{parent_id},3,16);
  push @d,['reseller:parentId',$rd->{parent_id}];
 }

 my $cs=$rd->{contact};
 Net::DRI::Exception::usererr_invalid_parameters('Missing mandatory contact structure') unless Net::DRI::Util::has_contact($rd);
 Net::DRI::Exception::usererr_invalid_parameters('Missing mandatory contact "main"') unless $cs->has_type('main');
 my $co=$cs->get('main');
 ## Fake data to pass validate
 $co->auth('FAKE');
 $co->srid('FAKE');
 $co->validate();
 push @d,Net::DRI::Protocol::EPP::Util::build_postalinfo($co,$epp->{contacti18n},'reseller');
 push @d,Net::DRI::Protocol::EPP::Util::build_tel('reseller:voice',$co->voice()) if defined $co->voice();
 push @d,Net::DRI::Protocol::EPP::Util::build_tel('reseller:fax',$co->fax()) if defined $co->fax();
 push @d,['reseller:email',$co->email()];

 Net::DRI::Exception::usererr_insufficient_parameters('Missing mandatory reseller url') unless Net::DRI::Util::has_key($rd,'url');
 Net::DRI::Exception::usererr_invalid_parameters('Invalid reseller url: '.$rd->{url})   unless Net::DRI::Util::xml_is_token($rd->{url},1,undef) && $rd->{url}=~m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|; ## regexp taken from URI Perl module
 push @d,['reseller:url',$rd->{url}];

 if (Net::DRI::Util::has_contact($rd))
 {
  push @d,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$rd->{contact},'reseller');
 }

 my $d=$co->disclose();
 if (defined $d)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Invalid reseller disclose item: '.$d) unless ref $d eq 'HASH';
  my @dd=Net::DRI::Protocol::EPP::Util::build_disclose($d,'reseller',qw/url contact/);
  Net::DRI::Exception::usererr_invalid_parameters('Invalid reseller disclose item: '.$d) unless @dd;
  push @d,@dd;
 }

 $mes->command_body(\@d);
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_response('reseller','creData');
 return unless defined $credata;

 my %r=(action => 'create', exist => 1);
 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
  my ($name,$node)=@$el;
  if ($name eq 'id')
  {
   $r{id}=$node->textContent();
  } elsif ($name eq 'crDate')
  {
   $r{crDate}=$po->parse_iso8601($node->textContent());
  }
 }

 $rinfo->{reseller}->{$r{id}}=\%r;
 return;
}

sub delete_build
{
 my ($epp,$reseller,$rd)=@_;
 my $mes=$epp->message();

 my @d=_add_id($mes,'delete',$reseller);
 $mes->command_body(\@d);
 return;
}

sub update_build
{
 my ($epp,$reseller,$todo,$rp)=@_;

 my (@add,@del,@set);
 my $cs;

 $cs=$todo->add('contact');
 if (Net::DRI::Util::isa_contactset($cs))
 {
  push @add,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cs,'reseller');
 }

 $cs=$todo->del('contact');
 if (Net::DRI::Util::isa_contactset($cs))
 {
  push @del,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cs,'reseller');
 }

 my $e;

 $e=$todo->set('status');
 push @set,['reseller:state',$e] if defined $e;

 $e=$todo->set('parent_id');
 push @set,['reseller:parentId',$e] if defined $e;

 my $co;
 $cs=$todo->set('contact');
 if (Net::DRI::Util::isa_contactset($cs))
 {
  $co=$cs->get('main');
  if (defined $co && Net::DRI::Util::isa_contact($co))
  {
   ## Fake data to pass validate
   $co->auth('FAKE');
   $co->srid('FAKE');
   $co->validate(1);
   push @set,Net::DRI::Protocol::EPP::Util::build_postalinfo($co,$epp->{contacti18n},'reseller');
   push @set,Net::DRI::Protocol::EPP::Util::build_tel('reseller:voice',$co->voice()) if defined $co->voice();
   push @set,Net::DRI::Protocol::EPP::Util::build_tel('reseller:fax',$co->fax()) if defined $co->fax();
   push @set,['reseller:email',$co->email()] if defined $co->email();
  } else
  {
   $co=undef;
  }
 }

 $e=$todo->set('url');
 push @set,['reseller:url',$e] if defined $e;

 my $d;
 if (defined $co && defined($d=$co->disclose()))
 {
  Net::DRI::Exception::usererr_invalid_parameters('Invalid reseller disclose item: '.$d) unless ref $d eq 'HASH';
  my @dd=Net::DRI::Protocol::EPP::Util::build_disclose($d,'reseller',qw/url contact/);
  Net::DRI::Exception::usererr_invalid_parameters('Invalid reseller disclose item: '.$d) unless @dd;
  push @set,@dd;
 }

 return unless @add || @del || @set;

 my $mes=$epp->message();
 my @d=_add_id($mes,'update',$reseller);
 push @d,['reseller:add',@add] if @add;
 push @d,['reseller:rem',@del] if @del;
 push @d,['reseller:chg',@set] if @set;

 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ResellerObject - EPP Reseller Object Extension mapping (draft-zhou-eppext-reseller-mapping-03) for Net::DRI

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

Copyright (c) 2015,2016 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
