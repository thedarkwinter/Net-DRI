## Domain Registry Interface, SIDN EPP Domain extensions
##
## Copyright (c) 2009-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::SIDN::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           info             => [ undef, \&info_parse],
           create           => [ \&create, undef ],
           update           => [ \&update, undef ],
           delete_cancel    => [ \&delete_cancel, undef ],
           transfer_request => [ undef, \&transfer_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:sidn="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('sidn')));
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('sidn','ext');
 return unless defined $infdata;

 my $ns=$mes->ns('sidn');
 $infdata=Net::DRI::Util::xml_traverse($infdata,$ns,'infData','domain');
 return unless defined $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'optOut')
  {
   $rinfo->{domain}->{$oname}->{opt_out}=Net::DRI::Util::xml_parse_boolean($c->textContent());
  } elsif ($name eq 'limited')
  {
   $rinfo->{domain}->{$oname}->{limited}=Net::DRI::Util::xml_parse_boolean($c->textContent());
  } elsif ($name eq 'period')
  {
   $rinfo->{domain}->{$oname}->{period}=$c->textContent();
  } elsif ($name eq 'scheduledDeleteDate')
  {
   $rinfo->{domain}->{$oname}->{schedule_delete_date}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('contacts are mandatory in .NL for domain_create') unless Net::DRI::Util::has_contact($rd);
 Net::DRI::Exception::usererr_insufficient_parameters('one registrant is mandatory in .NL for domain_create') unless ($rd->{contact}->has_type('registrant'));
 Net::DRI::Exception::usererr_insufficient_parameters('one admin is mandatory in .NL for domain_create') unless ($rd->{contact}->has_type('admin'));
 Net::DRI::Exception::usererr_insufficient_parameters('at least one tech contact is mandatory in .NL for domain_create') unless ($rd->{contact}->has_type('tech'));

 return;
}

sub update
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless $rd->{operation} || $rd->{date};

 my ($operation,$date);
 $operation = $rd->set('operation') if defined $rd->set('operation');
 $date = $rd->set('date') if defined $rd->set('date');

 my @ext;
 Net::DRI::Exception::usererr_invalid_parameters('Only following operations supported: setDate, setDateToEndOfSubscriptionPeriod or cancel') unless $operation=~m/^(?:setDate|setDateToEndOfSubscriptionPeriod|cancel)$/;
 push @ext, ['scheduledDelete:operation', $operation] if $operation;
 if ($date && $operation eq 'setDate')
 {
  Net::DRI::Exception::usererr_invalid_parameters('date must be YYYY-MM-DD') unless $date=~m/^\d{4}-\d{2}-\d{2}$/;
  push @ext, ['scheduledDelete:date', $date] if $date && $operation eq 'setDate';
 }

 my $eid;
 $eid=$mes->command_extension_register('scheduledDelete:update',sprintf('xmlns:scheduledDelete="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('scheduled_delete')));
 $mes->command_extension($eid, \@ext);

 return;
}

sub delete_cancel
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined($domain) && $domain;
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);
 my $eid=build_command_extension($mes,$epp,'sidn:command');
 $mes->command_extension($eid,[['sidn:domainCancelDelete',['sidn:name',$domain]],['sidn:clTRID',$mes->cltrid()]]);
 return;
}

sub transfer_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $trndata=$mes->get_response('sidn','ext');
 return unless defined $trndata;

 my $ns=$mes->ns('sidn');
 my $pw=Net::DRI::Util::xml_traverse($trndata,$ns,'trnData','pw');
 return unless defined $pw;

 $rinfo->{domain}->{$oname}->{transfer_new_token}=$pw->textContent();
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SIDN::Domain - SIDN (.NL) EPP Domain extensions for Net::DRI

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

Copyright (c) 2009-2011,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
