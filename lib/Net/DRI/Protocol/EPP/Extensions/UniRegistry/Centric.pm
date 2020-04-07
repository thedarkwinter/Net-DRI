## Domain Registry Interface, UniRegistry EPP Centric Extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::UniRegistry::Centric;

use strict;
use warnings;
use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Contact::UniRegistry;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::UniRegistry::Centric - Centric Extension for UniRegistry

=head1 DESCRIPTION

Adds the UniRegistry Registrant Centric Extension (http://ns.uniregistry.net/centric-1.0 ) to domain commands. This extensions is returned from the domain_info command, and used in domain_create and by adding contact type 'urc' to a contactset, and domain_update by setting the 'urc' with a contact object. The contact object should be created as a URC  L<Net::DRI::Data::Contact::UNIREG> contact,  and contains the below additional data. Note, the URC contact does not have a handle at the registry. You need to create / update using the acual contact data each time.

=item alt_email (valid email address)

=item mobile (valid phone number

=item challenge (array of hashes listing security questions and examples; min 3, max 5)

=head1 SYNOPSIS

 # domain info
 my $rc = $dri->domain_info('domain.tld');
 my $urc = $dri->get_info('contact')->get('urc');

 # setting urc contact data
 my $urc = $dri->local_object('urc_contact'); # urc_contact is object type!
 $urc->name('...')->org('..'); # starndard contact defailts
 $urc->alt_email('...');
 $urc->mobile('+1.6504231234');
 my @ch = ( {question => 'Question 1',answer=>'Answer 1'},{question => 'Question 2',answer=>'Answer 2'},{question => 'Question 3',answer=>'Answer 3'} );
 $urc->challenge(\@ch);

 # domain create
 my $cs=$dri->local_object('contactset');
 #$cs->set($c1,'registrant'); # whatever your other contacts are
 $cs->set($urc,'urc'); # set urc contact
 $rc = $dri->domain_create('domain.tld',{... contact => $cs} );

 # domain update
 $toc->set('urc',$urc); # Note, sending the contact not contactset
 $rc=$dri->domain_update('domain.tld',$toc);

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
(c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
           info=> [ undef, \&info_parse],
           create => [ \&create, undef ],
           update => [ \&update, undef ],
        );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->ns( { 'urc' => ['http://ns.uniregistry.net/centric-1.0','centric-1.0.xsd']} );
 $po->capabilities('domain_update','urc',['set']);
 $po->factories('urc_contact',sub { return Net::DRI::Data::Contact::UniRegistry->new(); });
}

####################################################################################################
## This is pretty mich a copy an past from the main contact biulder (build_cdata), however due to namespace that one fails.
sub build_centric
{
 my ($contact,$v)=@_;
 $contact->validate();

 Net::DRI::Exception::usererr_insufficient_parameters('URC contact alt_email') unless (defined $contact->alt_email());
 Net::DRI::Exception::usererr_insufficient_parameters('URC challenge questions/answers') unless (defined $contact->challenge());

 # FIXME, while technically possible, these fields are not needed and therefore should be ignored to keep the ordering and neatess
 delete $contact->{'auth'};
 delete $contact->{'disclose'};

 my @d = Net::DRI::Protocol::EPP::Core::Contact::build_cdata($contact,$v,'urc');
 push @d,['urc:emailAlt',$contact->alt_email()] if defined($contact->alt_email());
 push @d,Net::DRI::Protocol::EPP::Util::build_tel('urc:mobile',$contact->mobile()) if defined($contact->mobile());

 if ($contact->challenge())
 {
   my @ch;
   foreach my $c (@{$contact->challenge()})
   {
    my @qa = ['urc:question',$c->{question}];
    push @qa, ['urc:answer',$c->{answer}];
    push @ch, ['urc:challenge',@qa];
   }
   push @d,['urc:security',@ch] if @ch;
 }

 return @d;
}

####################################################################################################

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $urc;

 # urc is optional for .dealer, .inc and ICM TLDs (.adult, .porn, .sex, .xxx)
 if ($domain && $domain =~ m/\.(?:dealer|inc|adult|porn|sex|xxx)$/) {
  return unless ( Net::DRI::Util::has_key($rd,'contact')) && (Net::DRI::Util::check_isa($rd->{'contact'},'Net::DRI::Data::ContactSet')) && ($urc = $rd->{'contact'}->get('urc') );

 }

 Net::DRI::Exception::usererr_insufficient_parameters('URC contact required') unless ( (Net::DRI::Util::has_key($rd,'contact')) && (Net::DRI::Util::check_isa($rd->{'contact'},'Net::DRI::Data::ContactSet')) && ($urc = $rd->{'contact'}->get('urc')) );

 my @n = build_centric($urc,$epp->{contacti18n});
 return unless @n;
 my $eid=$mes->command_extension_register('urc','registrant');
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();
 my $urc;
 return unless $todo->set('urc') && ($urc = $todo->set('urc'));

 my @n = build_centric($urc,$epp->{contacti18n});
 return unless @n;
 my $eid=$mes->command_extension_register('urc','registrant');
 $mes->command_extension($eid,\@n);
 return;
}


####################################################################################################

## This is pretty mich a copy an past from the main contact parser, however due to namespace that one fails. I have done this this before with .IT; perhaps time to change the main contact parser ??
sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_extension($mes->ns('urc'),'registrant');
 return unless defined $infdata;

 my %cd=map { $_ => [] } qw/name org city sp pc cc/;
 $cd{street}=[[],[]];
 my $contact = $po->create_local_object('urc_contact');
 my @s;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'id')
  {
   $oname=$c->textContent();
   $rinfo->{contact}->{$oname}->{action}='info';
   $rinfo->{contact}->{$oname}->{exist}=1;
   $rinfo->{contact}->{$oname}->{id}=$oname;
   $contact->srid($oname);
  } elsif ($name eq 'roid')
  {
   $contact->roid($c->textContent());
   $rinfo->{contact}->{$oname}->{roid}=$contact->roid();
  } elsif ($name eq 'status')
  {
   push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c);
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate|trDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'email')
  {
   $contact->email($c->textContent());
  } elsif ($name eq 'emailAlt')
  {
   $contact->alt_email($c->textContent());
  } elsif ($name =~ m/^(voice|fax|mobile)$/)
  {
   $contact->$name(Net::DRI::Protocol::EPP::Util::parse_tel($c));
  } elsif ($name eq 'postalInfo')
  {
   Net::DRI::Protocol::EPP::Util::parse_postalinfo($po,$c,\%cd);
  } elsif ($name eq 'authInfo') ## we only try to parse the authInfo version defined in the RFC, other cases are to be handled by extensions
  {
   $contact->auth({pw => Net::DRI::Util::xml_child_content($c,$mes->ns('contact'),'pw')});
  } elsif ($name eq 'disclose')
  {
   $contact->disclose(parse_disclose($c));
  } elsif ($name eq 'security')
  {
    $contact->challenge(());
    foreach my $el2 (Net::DRI::Util::xml_list_children($c))
    {
     my ($n2,$c2)=@$el2;
     if ($n2 eq 'challenge')
     {
        my $ch = {};
        foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
        {
         my ($n3,$c3)=@$el3;
         $ch->{$n3} = $c3->textContent() if $n3 =~ m/^(question|answer)$/;
        }
       push @{$contact->{'challenge'}},$ch;
       }
     }
  }
 }
 # FIXME SECURTY CHALLENGE

 $contact->name(@{$cd{name}});
 $contact->org(@{$cd{org}});
 $contact->street(@{$cd{street}});
 $contact->city(@{$cd{city}});
 $contact->sp(@{$cd{sp}});
 $contact->pc(@{$cd{pc}});
 $contact->cc(@{$cd{cc}});

 $rinfo->{domain}->{$oname}->{contact}->set($contact,'urc');
 return;
}

####################################################################################################


1;
