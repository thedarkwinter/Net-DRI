## Domain Registry Interface, FRED KeySET EPP commands
##
## Copyright (c) 2014-2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
################################################################################

package Net::DRI::Protocol::EPP::Extensions::FRED::KeySET;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FRED::KeySET - KeySET Extension for FRED

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2014-2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

################################################################################

sub register_commands {
  my ($class,$version)=@_;
  my %tmp=(
    check    => [ \&check, \&check_parse ],
    create   => [ \&create, \&create_parse ],
    delete   => [ \&delete, undef ],
    info     => [ \&info, \&info_parse ],
    transfer => [ \&transfer, undef ],
    update   => [ \&update, undef ],
  ); # KeySET commands
  return { 'keyset' => \%tmp,
  };
}

################################################################################

sub create {
  my ($epp,$keyset,$rd)=@_;
  my $mes=$epp->message();

  # validation
  validate_defined($keyset,'keyset id');
  validate_key($rd,'password');
  validate_key($rd,'tech');
  validate_key($rd,'dnskey');

  # build namespace
  build_namespace($mes,'create','keyset');

  # build xml
  my @d = build_keyset($keyset,$rd);

  # insert into command body
  $mes->command_body(\@d);

  return;
}

sub create_parse {
  my ($po, $otype, $oaction, $oname, $rinfo) = @_;
  my $mes = $po->message();
  return unless $mes->is_success();

  # get response
  my $infdata = $mes->get_response('keyset','creData');
  return unless $infdata;

  # declare object
  my $c = $infdata->getFirstChild();
  my $msg = {};

  # parse response
  while ($c) {
    my $name = $c->localname() || $c->nodeName();
    next unless $name;
    if ($name=~m/^(id|crDate)$/) {
      $msg->{$oname}->{$name}=$c->getFirstChild()->getData() if (defined $c);
    }
  $c = $c->getNextSibling();
  }

  # assign to return info
  $rinfo->{$otype}=$msg;

  return;
}

sub check {
  my ($epp,$keyset,$rd)=@_;
  my $mes=$epp->message();
  my @d;

  # validation
  validate_defined($keyset,'keyset id');

  # build namespace
  build_namespace($mes,'check','keyset');

  # build xml
  push @d, [ 'keyset:id', $keyset ] if (defined($keyset));

  # insert into command body
  $mes->command_body(\@d);

  return;
}

sub check_parse {
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  # get response
  my $infdata = $mes->get_response('keyset','chkData');
  return unless $infdata;

  # declare object
  my $msg = {};

  # parse response
  foreach my $cd ($infdata->getChildrenByTagNameNS($mes->ns('keyset'),'cd')) {
   my $keyset;
   foreach my $el (Net::DRI::Util::xml_list_children($cd)) {
    my ($name,$c)=@$el;
    if ($name eq 'id') {
     $keyset=$c->textContent();
     $msg->{$oname}->{action} = $oaction;
     $msg->{$oname}->{exist} = 1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
     $msg->{$oname}->{$name} = $c->getFirstChild()->getData() if (defined $c);
    }
   }
  }

  # assign to return info
  $rinfo->{$otype}=$msg;

  return;
}

sub info {
  my ($epp,$keyset,$rd)=@_;
  my $mes=$epp->message();
  my @d;

  # validation
  validate_defined($keyset,'keyset id');

  # build namespace
  build_namespace($mes,'info','keyset');

  # build xml
  push @d, [ 'keyset:id', $keyset ] if (defined($keyset));

  # insert into command body
  $mes->command_body(\@d);

  return;
}

sub info_parse {
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  # get response
  my $infdata = $mes->get_response('keyset','infData');
  return unless $infdata;

  # declare object
  my $c = $infdata->getFirstChild();
  my $msg = {};

  # parse response
  while ($c) {
    my $name = $c->localname() || $c->nodeName();
    next unless $name;
    if ($name=~m/^(id|roid|status|clID|crID|authInfo|tech)$/) {
      $msg->{$oname}->{$name}=$c->getFirstChild()->getData() if (defined $c);
    } elsif ($name eq 'dnskey') {
      foreach my $el (Net::DRI::Util::xml_list_children($c)) {
        my ($dname,$dc)=@$el;
        $msg->{$oname}->{$name}->{$dname}=$dc->getFirstChild()->getData()
          if (defined $dc);
      }
    }
  $c = $c->getNextSibling();
  }

  # assign to return info
  $rinfo->{$otype}=$msg;

  return;
}

sub update {
  my ($epp,$keyset,$todo,$rd)=@_;
  my $mes=$epp->message();
  my (@add,@del,@chg,@d);

  # check 'changes' object
  Net::DRI::Exception::usererr_invalid_parameters
    ($todo.' must be a non empty Net::DRI::Data::Changes object')
      unless Net::DRI::Util::isa_changes($todo);

  # check 'changes' object types
  if ((grep { ! /^(?:contact|dnskey|tech|auth)$/ } $todo->types())) {
    Net::DRI::Exception->die(0, 'protocol/EPP', 11, 'Only contact/dnskey/tech '.
    '"add/del" and auth "set" available for KeySET');
  }

  # get changes Data
  my $dnskeyadd=$todo->add('dnskey');
  my $dnskeydel=$todo->del('dnskey');
  my $ctadd=$todo->add('contact');
  my $ctdel=$todo->del('contact');
  my $authcge=$todo->set('auth');

  # validation
  validate_defined($keyset,'keyset id');

  # build namespace
  build_namespace($mes,'update','keyset');

  # build keyset id
  push @d, [ 'keyset:id', $keyset ] if (defined($keyset));

  # build dnskey(s)
  foreach my $e (ref $dnskeyadd eq 'ARRAY' ? @$dnskeyadd : ($dnskeyadd)) {
    push @add, [ 'keyset:dnskey', build_keyset_dnskey($e) ]  if ($e); }
  foreach my $e (ref $dnskeydel eq 'ARRAY' ? @$dnskeydel : ($dnskeydel)) {
    push @del, [ 'keyset:dnskey', build_keyset_dnskey($e) ]  if ($e); }

  # build contact(s)
  push @del,build_contacts($epp,$ctdel) if Net::DRI::Util::isa_contactset($ctdel);
  push @add,build_contacts($epp,$ctadd) if Net::DRI::Util::isa_contactset($ctadd);

  # build auth
  push @chg,build_authinfo($epp,$authcge,1)
    if ($authcge && (ref $authcge eq 'HASH') && exists $authcge->{pw});

  # build xml
  push @d,['keyset:add',@add] if @add;
  push @d,['keyset:rem',@del] if @del;
  push @d,['keyset:chg',@chg] if @chg;

  $mes->command_body(\@d);

  return;
}

sub transfer {
  my ($epp,$keyset,$rd)=@_;
  my $mes=$epp->message();
  my @d;

  # validation
  validate_defined($keyset,'keyset id');
  validate_key($rd,'auth');

  # build namespace
  build_namespace($mes,'transfer','keyset');

  # build xml
  push @d, [ 'keyset:id', $keyset ] if (defined($keyset));
  push @d, [ 'keyset:authInfo', $rd->{auth}->{pw} ]
    if Net::DRI::Util::has_key($rd,'auth');

  # insert into command body
  $mes->command_body(\@d);

  return;
}

sub delete {
  my ($epp,$keyset,$rd)=@_;
  my $mes=$epp->message();
  my @d;

  # validation
  validate_defined($keyset,'keyset id');

  # build namespace
  build_namespace($mes,'delete','keyset');

  # build xml
  push @d, [ 'keyset:id', $keyset ] if (defined($keyset));

  # insert into command body
  $mes->command_body(\@d);

  return;
}

################################################################################

sub build_authinfo {
  my ($epp,$rauth)=@_;
  return ['keyset:authInfo',$rauth->{pw}];
}

sub build_contacts {
  my ($epp,$cs,$ns)=@_;
  my @d;
  my %r=map { $_ => 1 } $epp->core_contact_types();
  foreach my $t (sort(grep { exists($r{$_}) } $cs->types())) {
    Net::DRI::Exception::usererr_invalid_parameters
      ("Only 'tech' contact allowed") if ($t ne 'tech');
    my @o=$cs->get($t);
    push @d,map { [ ($ns // 'keyset').":".$t,$_->srid()] } @o;
  }
  return @d;
}

sub build_namespace {
  my ($mes,$tcommand,$nsattr)=@_;
  $mes->command([$tcommand,'keyset:' . $tcommand,
  sprintf('xmlns:keyset="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs($nsattr))]);
  return;
}

sub build_keyset {
  my ($keyset,$rd)=@_;
  my (@o,@p);

  # validation information
  validate_keyset($keyset,$rd);

  # generate keyset id
  push @o, [ 'keyset:id', $keyset ] if (defined($keyset));

  # generate tech element
  my $tech = $rd->{tech} if Net::DRI::Util::has_key($rd,'tech');
  push @o, [ 'keyset:tech', $tech ] if (defined($tech));

  # generate authinfo element
  my $auth_info = $rd->{password} if Net::DRI::Util::has_key($rd,'password');
  push @o, [ 'keyset:authInfo', $auth_info ] if (defined($auth_info));

  # generate dnskey element(s)
  foreach my $e (ref $rd->{dnskey} eq 'ARRAY' ? @{$rd->{dnskey}} : ($rd->{dnskey}))
    { push @o, [ 'keyset:dnskey', build_keyset_dnskey($e) ]  if ($e); }

  return @o;
}

sub build_keyset_dnskey {
  my ($rdata)=shift;
  my @p;

  # 'flags' element
  if (Net::DRI::Util::has_key($rdata,'flags'))
  { push @p, [ 'keyset:flags', $rdata->{flags} ] if (defined $rdata->{flags}); }

  # 'protocol' element
  if (Net::DRI::Util::has_key($rdata,'protocol'))
  { push @p, [ 'keyset:protocol', $rdata->{protocol} ] if (defined $rdata->{protocol}); }

  # 'alg' element
  if (Net::DRI::Util::has_key($rdata,'alg'))
  { push @p, [ 'keyset:alg', $rdata->{alg} ] if (defined $rdata->{alg}); }

  # 'pubkey' element
  if (Net::DRI::Util::has_key($rdata,'pubkey'))
  { push @p, [ 'keyset:pubKey', $rdata->{pubkey} ] if (defined $rdata->{pubkey}); }

  return @p;
}

###############################################################################

sub validate_keyset {
  my ($keyset,$rd)=@_;

  # validation technical contact
  if (Net::DRI::Util::has_key($rd,'tech')) {
    Net::DRI::Exception::usererr_invalid_parameters
      ("Technical contact SRID cannot be empty if defined in keyset")
        if ($rd->{tech} eq '');
  }

  # validation password
  if (Net::DRI::Util::has_key($rd,'password')) {
    Net::DRI::Exception::usererr_invalid_parameters
      ("Password cannot be empty if defined in keyset")
        if ($rd->{password} eq '');
  }

  # validation dnskey
  if (Net::DRI::Util::has_key($rd,'dnskey')) {
    my (@dnskey_error);
    foreach my $e (@{$rd->{dnskey}}) {
      # check keys exist
      push @dnskey_error, 'flags' if (!(Net::DRI::Util::has_key($e,'flags')));
      push @dnskey_error, 'protocol' if (!(Net::DRI::Util::has_key($e,'protocol')));
      push @dnskey_error, 'alg' if (!(Net::DRI::Util::has_key($e,'alg')));
      push @dnskey_error, 'pubkey' if (!(Net::DRI::Util::has_key($e,'pubkey')));
      # throw error
      Net::DRI::Exception::usererr_invalid_parameters(
        'Missing dnskey information: '.join(' / ',@dnskey_error))
          if (@dnskey_error);
    }
  }

  return;
}

sub validate_key {
  my ($cdata,$name)=@_;
  Net::DRI::Exception::usererr_insufficient_parameters
    ("The [$name] element is currently missing. Please check your parameters")
      if (!(Net::DRI::Util::has_key($cdata,$name)));
  return;
}

sub validate_defined {
  my ($value,$name)=@_;
  Net::DRI::Exception::usererr_insufficient_parameters
    ("The [$name] element is currently undefined. Please check your parameters")
      if (!($value));
  return;
}

###############################################################################
1;
