## Domain Registry Interface, AFNIC Email Domain commands
##
## Copyright (c) 2006,2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::AFNIC::Email::Domain;

use strict;
use warnings;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::AFNIC::Email::Domain - AFNIC Email Domain commands for Net::DRI

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

Copyright (c) 2006,2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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
          create => [ \&create, undef ], ## TODO : parsing of return messages
          delete => [ \&delete, undef ],
          update => [ \&update, undef ],
          transfer_request => [ \&transfer_request, undef],
          trade => [ \&trade, undef],
         );

 return { 'domain' => \%tmp };
}

## AFNIC says international format is : +code_pays 10 20 30 40 50
## yeah right !
sub format_tel
{
 my $in=shift;
 $in=~s/x.*$//;
 my @t=split(/\./,$in,2);
 return $t[0].' '.reverse(join(' ',grep { defined($_) && $_ ne '' } split(/(\d{2})/,reverse($t[1]))));
}

sub add_starting_block
{
 my ($action,$domain,$mes,$rd)=@_;
 my $ca=$mes->client_auth();

 $mes->line('1a',$action);
 $mes->line('1b',$ca->{id}); ## code fournisseur
 $mes->line('1c',$ca->{pw}); ## mot de passe
 $mes->line('1e',$mes->trid()); ## reference client (=trid) ## allow more/other ?
 $mes->line('1f','2.5.0');
 $mes->line('1g',$rd->{auth_code}) if ($action=~m/^[CD]$/ && Net::DRI::Util::has_key($rd,'auth_code') && $rd->{auth_code}); ## authorization code for reserved domain names

 $mes->line('2a',$domain);
 return;
}

sub create
{
 my ($a,$domain,$rd)=@_;
 my $mes=$a->message();

 add_starting_block('C',$domain,$mes,$rd);
 Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
 $mes->line('2z',$rd->{auth}->{pw});

 Net::DRI::Exception::usererr_insufficient_parameters('contacts are mandatory') unless Net::DRI::Util::has_contact($rd);
 my $cs=$rd->{contact};
 my $co=$cs->get('registrant');
 Net::DRI::Exception::usererr_insufficient_parameters('registrant contact is mandatory') unless Net::DRI::Util::isa_contact($co,'Net::DRI::Data::Contact::AFNIC');
 $co->validate();
 $co->validate_registrant();

 if ($co->legal_form()) ## PM
 {
  $mes->line('3w','PM');
  add_company_info($mes,$co);
 } else ## PP
 {
  $mes->line('3w','PP');
  Net::DRI::Exception::usererr_insufficient_parameters('name or key needed for PP') unless ($co->name() || $co->key());
  if ($co->key())
  {
   $mes->line('3q',$co->key());
  } else
  {
   $mes->line('3a',sprintf('%s, %s',$co->firstname(),$co->name()));
   my $b=$co->birth();
   Net::DRI::Exception::usererr_insufficient_parameters('birth data (date+city) mandatory, if no registrant key provided') unless ($b && (ref($b) eq 'HASH') && exists($b->{date}) && exists($b->{place}));
   $mes->line('3r',(ref($b->{date}))? $b->{date}->strftime('%d/%m/%Y') : $b->{date});
   $mes->line('3s',$b->{place});
  }
 }

 add_owner_info($mes,$co);
 add_maintainer_disclose($mes,$co,$rd->{maintainer}) unless $mes->line('3x');
 add_admin_contact($mes,$cs); ## optional
 add_tech_contacts($mes,$cs); ## mandatory

 add_all_ns($domain,$mes,$rd->{ns}) if Net::DRI::Util::has_ns($rd);
 add_installation($mes,$rd);
 return;
}

sub add_company_info
{
 my ($mes,$co)=@_;
 $mes->line('3a',$co->name());
 Net::DRI::Exception::usererr_insufficient_parameters('one legal form must be provided') unless ($co->legal_form() || $co->legal_form_other());
 $mes->line('3h',$co->legal_form())       if $co->legal_form();
 $mes->line('3i',$co->legal_form_other()) if $co->legal_form_other();
 Net::DRI::Exception::usererr_insufficient_parameters('legal id must be provided if no trademark') if (($co->legal_form() eq 'S') && !$co->trademark() && !$co->legal_id());
 $mes->line('3j',$co->legal_id())         if $co->legal_id();
 my $jo=$co->jo();
 Net::DRI::Exception::usererr_insufficient_parameters('jo data is needed for non profit organization without legal id or trademark') if (($co->legal_form() eq 'A') && !$co->legal_id() && !$co->trademark() && (!$jo || (ref($jo) ne 'HASH') || !exists($jo->{date_publication}) || !exists($jo->{page})));
 if ($jo && (ref($jo) eq 'HASH'))
 {
  $mes->line('3k',$jo->{date_declaration}) if (exists($jo->{date_declaration}) && $jo->{date_declaration});
  $mes->line('3l',$jo->{date_publication}) if (exists($jo->{date_publication}) && $jo->{date_publication});
  $mes->line('3m',$jo->{number})           if (exists($jo->{number})           && $jo->{number});
  $mes->line('3n',$jo->{page})             if (exists($jo->{page})             && $jo->{page});
 }
 $mes->line('3p',$co->trademark()) if $co->trademark();
 return;
}


sub add_installation
{
 my ($mes,$rd)=@_;

 ## Default = A = waiting for client, otherwise I = direct installation
 my $inst=(Net::DRI::Util::has_key($rd,'installation_type') && $rd->{installation_type}=~m/^[IA]$/)? $rd->{installation_type} : 'A';
 $mes->line('8a',$inst);
 ## S = standard = fax need to be sent, Default = E = Express = no fax
 my $form=(Net::DRI::Util::has_key($rd,'form_type') && $rd->{form_type}=~m/^[SE]$/)? $rd->{form_type} : 'E';
 $mes->line('9a',$form);
 return;
}

sub add_owner_info
{
 my ($mes,$co)=@_;

 if ($co->srid())
 {
  $mes->line('3x',$co->srid().'-FRNIC');
 } else
 {
  my $s=$co->street();
  Net::DRI::Exception::usererr_insufficient_parameters('1 line of address at least needed if no nichandle') unless ($s && (ref($s) eq 'ARRAY') && @$s && $s->[0]);
  $mes->line('3b',$s->[0]);
  $mes->line('3c',$s->[1]) if $s->[1];
  $mes->line('3d',$s->[2]) if $s->[2];
  Net::DRI::Exception::usererr_insufficient_parameters('city, pc & cc mandatory if no nichandle') unless ($co->city() && $co->pc() && $co->cc());
  $mes->line('3e',$co->city());
  $mes->line('3f',$co->pc());
  $mes->line('3g',uc($co->cc()));
  Net::DRI::Exception::usererr_insufficient_parameters('voice & email mandatory if no nichandle') unless ($co->voice() && $co->email());
  $mes->line('3t',format_tel($co->voice()));
  $mes->line('3u',format_tel($co->fax())) if $co->fax();
  $mes->line('3v',$co->email());
 }
 return;
}

sub add_maintainer_disclose
{
 my ($mes,$co,$maintainer)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('maintainer mandatory if no nichandle') unless (defined($maintainer) && $maintainer=~m/^[A-Z0-9][-A-Z0-9]+[A-Z0-9]$/i);
 $mes->line('3y',$maintainer);
 Net::DRI::Exception::usererr_insufficient_parameters('disclose option is mandatory if no nichandle') unless ($co->disclose());
 $mes->line('3z',$co->disclose());
 return;
}

sub add_admin_contact
{
 my ($mes,$cs)=@_;
 my $co=$cs->get('admin');
 $mes->line('4a',$co->srid().'-FRNIC') if (Net::DRI::Util::isa_contact($co) && $co->srid());
 return;
}

sub add_tech_contacts
{
 my ($mes,$cs)=@_;
 my @co=map { $_->srid() } grep { Net::DRI::Util::isa_contact($_) && defined $_->srid() } $cs->get('tech');
 Net::DRI::Exception::usererr_insufficient_parameters('at least one technical contact is mandatory') unless @co;
 $mes->line('5a',$co[0].'-FRNIC');
 $mes->line('5c',$co[1].'-FRNIC') if $co[1];
 $mes->line('5e',$co[2].'-FRNIC') if $co[2];
 return;
}

sub add_all_ns
{
 my ($domain,$mes,$ns)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('at least 2 nameservers are mandatory') unless (Net::DRI::Util::isa_hosts($ns,'Net::DRI::Data::Hosts') && $ns->count()>=2);

 add_one_ns($mes,$ns,1,$domain,'6a','6b');
 add_one_ns($mes,$ns,2,$domain,'7a','7b');
 my $nsc=$ns->count();
 add_one_ns($mes,$ns,3,$domain,'7c','7d') if ($nsc >= 3);
 add_one_ns($mes,$ns,4,$domain,'7e','7f') if ($nsc >= 4);
 add_one_ns($mes,$ns,5,$domain,'7g','7h') if ($nsc >= 5);
 add_one_ns($mes,$ns,6,$domain,'7i','7j') if ($nsc >= 6);
 add_one_ns($mes,$ns,7,$domain,'7k','7l') if ($nsc >= 7);
 add_one_ns($mes,$ns,8,$domain,'7m','7n') if ($nsc >= 8);
 return;
}

sub add_one_ns
{
 my ($mes,$ns,$pos,$domain,$l1,$l2)=@_;
 my @g=$ns->get_details($pos);
 return unless @g;
 $mes->line($l1,$g[0]); ## name
 return unless ($g[0]=~m/\S+\.${domain}/i || (lc($g[0]) eq lc($domain)));
 $mes->line($l2,join(' ',@{$g[1]},@{$g[2]})); ## nameserver in domain, we add IPs
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($a,$domain,$rd)=@_;
 my $mes=$a->message();

 add_starting_block('S',$domain,$mes,$rd);
 add_installation($mes,$rd);
 return;
}

sub update ## no critic (Subroutines::RequireFinalReturn)
{
 my ($a,$domain,$todo,$rd)=@_;
 my $mes=$a->message();

 Net::DRI::Util::check_isa($todo,'Net::DRI::Data::Changes');

 if ((grep { ! /^(?:ns|contact)/ } $todo->types()) || 
     (grep { ! /^(?:set)$/ } $todo->types('ns')) ||
     (grep { ! /^(?:set)$/ } $todo->types('contact'))
    )
 {
  Net::DRI::Exception->die(0,'protocol/AFNIC/Email',11,'Only ns/contact set available for domain');
 }

 my $ns=$todo->set('ns');
 my $cs=$todo->set('contact');

 my $wc=Net::DRI::Util::isa_contactset($cs);
 Net::DRI::Exception::usererr_invalid_parameters('can not change both admin & tech contacts at the same time') if ($wc && $cs->has_type('tech') && ($cs->has_type('admin') || $cs->has_type('registrant')));

 ## Technical change (DNS / Tech contacts)
 if ($wc && $cs->has_type('tech'))
 {
  add_starting_block('T',$domain,$mes); ## no $rd here !
  add_tech_contacts($mes,$cs); ##  tech contacts mandatory even for only nameserver changes !
  add_all_ns($domain,$mes,$ns) if (defined $ns && Net::DRI::Util::isa_hosts($ns,'Net::DRI::Data::Hosts'));
  add_installation($mes,$rd);
  return;
 }

 ## Admin change (Admin contact)
 if ($wc && ($cs->has_type('admin') || $cs->has_type('registrant')))
 {
  add_starting_block('A',$domain,$mes);
  my $co=$cs->get('registrant');
  if (Net::DRI::Util::isa_contact($co) && $co->legal_form()) ## only for PM
  {
   $co->validate();
   $mes->line('3a',$co->name());
   add_owner_info($mes,$co);
  } else
  {
   my $ca=$cs->get('admin');
   Net::DRI::Exception::usererr_insufficient_parameters('contact admin is mandatory for PP admin change') unless (Net::DRI::Util::isa_contact($ca) && $ca->srid());
  }
  add_admin_contact($mes,$cs);
  add_installation($mes,$rd);
  return;
 } 

 Net::DRI::Exception::err_assert('We do not know how to handle this kind of update, please report.');
}

sub trade
{
 my ($a,$domain,$rd)=@_;
 my $mes=$a->message();

 create($a,$domain,$rd);
 my $type=(Net::DRI::Util::has_key($rd,'trade_type') && $rd->{trade_type}=~m/^[VF]$/)? $rd->{trade_type} : 'V';

 $mes->line('1a','P');
 $mes->line('1h',$type);

 if ($type eq 'F')
 {
  Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
  $mes->line('2z',$rd->{auth}->{pw});
 }
 return;
}

sub transfer_request
{
 my ($a,$domain,$rd)=@_;
 my $mes=$a->message();

 add_starting_block('D',$domain,$mes,$rd);
 Net::DRI::Exception::usererr_invalid_parameters() unless (defined($rd) && (ref($rd) eq 'HASH') && keys(%$rd));
 Net::DRI::Exception::usererr_insufficient_parameters('contacts are mandatory') unless Net::DRI::Util::has_contact($rd);
 my $cs=$rd->{contact};
 my $co=$cs->get('registrant');
 Net::DRI::Exception::usererr_insufficient_parameters('registrant contact is mandatory') unless Net::DRI::Util::isa_contact($co,'Net::DRI::Data::Contact::AFNIC');
 $co->validate();
 $co->validate_registrant();

 Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
 $mes->line('2z',$rd->{auth}->{pw});

 if ($co->legal_form()) ## PM
 {
  add_company_info($mes,$co);
 } else ## PP
 {
  Net::DRI::Exception::usererr_insufficient_parameters('key mandatory for PP') unless ($co->key());
  $mes->line('3q',$co->key());
 }

 add_tech_contacts($mes,$cs); ##  tech contacts mandatory
 add_all_ns($domain,$mes,$rd->{ns}) if Net::DRI::Util::has_ns($rd);
 add_installation($mes,$rd);
 return;
}

####################################################################################################
1;
