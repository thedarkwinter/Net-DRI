## Domain Registry Interface, ES Domain EPP extension commands 
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

package Net::DRI::Protocol::EPP::Extensions::ES::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ES::Domain - ES EPP Domain extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

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
              info                => [ undef, \&info_parse ],
             create            => [ \&create, undef ],
             update          => [ \&update, undef ],
             renew            => [ \&renew, undef ],
             transfer_request  => [ \&transfer_request, \&transfer_request_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response('domain','infData');
 return unless defined $infdata;
 
  foreach my $el (Net::DRI::Util::xml_list_children($infdata))
  {
   my ($name,$c)=@$el;
   next unless $name =~ m/^(es_ipMaestra|es_marca|es_inscripcion|es_accion_comercial|es_codaux)$/;
   $name =~ s/es_//;
   $name = Net::DRI::Util::to_under($name) if $name =~ m/^(ipMaestra|autoRenew)$/; # these two fields are mixed case in xml
   $rinfo->{domain}->{$oname}->{$name}=$c->textContent();
  }
  
  # get auto_renew outside <infData> element
  my $autorenew=$mes->get_response('domain','autoRenew');
  return unless defined $autorenew;
  $rinfo->{domain}->{$oname}->{'auto_renew'} = $autorenew->textContent();
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 #$mes->command(['create','domain:create',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('domain')).' '.sprintf('xmlns:es_creds="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('es_creds'))]);
 #my $auth = pop $mes->{'command_body'}; # remove domain auth as its not allowed in create
 domain_extension($mes,$rd);
}

# copied the entire sub from EPP::Core::Domain, and added .es stuff in the middle
sub update
{
 my ($epp,$domain,$todo,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 my $nsadd=$todo->add('ns');
 my $nsdel=$todo->del('ns');
 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 my $cadd=$todo->add('contact');
 my $cdel=$todo->del('contact');

 my (@add,@del);
 push @add,Net::DRI::Protocol::EPP::Util::build_ns($epp,$nsadd,$domain)         if Net::DRI::Util::isa_hosts($nsadd);
 push @add,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cadd)       if Net::DRI::Util::isa_contactset($cadd);
 push @add,$sadd->build_xml('domain:status','core')                             if Net::DRI::Util::isa_statuslist($sadd);
 push @del,Net::DRI::Protocol::EPP::Util::build_ns($epp,$nsdel,$domain,undef,1) if Net::DRI::Util::isa_hosts($nsdel);
 push @del,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cdel)       if Net::DRI::Util::isa_contactset($cdel);
 push @del,$sdel->build_xml('domain:status','core') if Net::DRI::Util::isa_statuslist($sdel);
 my $f;
 foreach my $es ('ip_maestra','marca','inscripcion','accion_comercial','codaux','auto_renew')
 {
  if (my $esf=$todo->add($es))
  {
   $f = ($es =~ m/^(ip_maestra|auto_renew)$/) ? Net::DRI::Util::to_mixed($es) : $es;  # these two fields are mixed case in xml
   $esf = (($esf =~ m/^(0|false|no)$/)?'false':'true') if $es eq 'auto_renew';
   push @add,['domain:es_'.$f, $esf] unless $es =~ m/^(codaux|auto_renew)$/;
   push @add,['domain:'.$f, $esf] if $es  =~ m/^(codaux|auto_renew)$/;
  }
  if (my $esf=$todo->del($es))
  {
   $f = ($es =~ m/^(ip_maestra|auto_renew)$/) ? Net::DRI::Util::to_mixed($es) : $es;  # these two fields are mixed case in xml
   $esf = (($esf =~ m/^(0|false|no)$/)?'false':'true') if $es eq 'auto_renew';
   push @del,['domain:es_'.$f, $esf] unless $es =~ m/^(codaux|auto_renew)$/;
   push @del,['domain:'.$f, $esf] if $es  =~ m/^(codaux|auto_renew)$/;
  }
 }

 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'update',$domain);
 push @d,['domain:add',@add] if @add;
 push @d,['domain:rem',@del] if @del;

 my $chg=$todo->set('registrant');
 my @chg;
 push @chg,['domain:registrant',$chg->srid()] if Net::DRI::Util::isa_contact($chg);
 $chg=$todo->set('auth');
 push @chg,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$chg,1) if ($chg && (ref $chg eq 'HASH') && exists $chg->{pw});
 push @d,['domain:chg',@chg] if @chg;
 push @d,['domain:autoRenew', $rd->{'auto_renew'}] if $rd->{'auto_renew'} && $rd->{'auto_renew'}=~m/^(?:true|false)$/;
 $mes->command_body(\@d);
}

sub renew
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 # core + mandatory Registry exDate format
 my $curexp=Net::DRI::Util::has_key($rd,'current_expiration')? $rd->{current_expiration} : undef;
 Net::DRI::Exception::usererr_insufficient_parameters('current expiration date') unless defined($curexp);
 $curexp=$curexp->clone()->set_time_zone('UTC')->strftime('%Y-%m-%d') if (ref($curexp) && Net::DRI::Util::check_isa($curexp,'DateTime'));
 Net::DRI::Exception::usererr_invalid_parameters('current expiration date must be YYYY-MM-DD') unless $curexp=~m/^\d{4}-\d{2}-\d{2}$/;
 $curexp = $curexp . 'T00:00:00.01'; # now we append this since it's mandotory for this command
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'renew',$domain);
 push @d,['domain:renewOp','accept'];
 push @d,['domain:curExpDate',$curexp];
 push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);
 $mes->command_body(\@d);

 domain_extension($mes,$rd);

 return;
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 domain_extension($mes,$rd);
}

# Since .ES returns 1000 here when its actually action pending (awaiting admin-c to approve email), i will change result code to 1001 to be uniform with standard EPP
sub transfer_request_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 if ($mes->result_code() == 1000) 
 {
    my $results = shift $mes->{results};
    $results->{code}=1001;
    $mes->{results} = [$results];
 }
}

sub domain_extension
{
 my ($mes,$rd)=@_;
 # TODO check this validation validate this data
 Net::DRI::Exception->die(0,'protocol/EPP',3,'Invalid IP Address for ip_maestra') if (defined $rd->{'ip_maestra'} && !Net::DRI::Util::is_ipv4(defined $rd->{'ip_maestra'}));
 Net::DRI::Exception->die(0,'protocol/EPP',3,'Marca And Inscripcion must either both be defined or neither') if ( ($rd->{'marca'} || $rd->{'inscripcion'}) && !($rd->{'marca'} && $rd->{'inscripcion'}) );
 Net::DRI::Exception->die(0,'protocol/EPP',3,'accion_comercial must be a number between 1 and 9999 if its defined') if (defined $rd->{'accion_comercial'} && !Net::DRI::Util::isint($rd->{'accion_comercial'})) ;

 if (defined($rd->{'auto_renew'}))
 {
   undef $rd->{'auto_renew'} if (defined $rd->{'auto_renew'} && $rd->{'auto_renew'} =~ m/^(0|false|no)$/);
   push $mes->{'command_body'},['domain:autoRenew',($rd->{'auto_renew'}?'true':'false')];
 }
 
 push $mes->{'command_body'},['domain:es_ipMaestra',$rd->{'ip_maestra'}] if defined $rd->{'ip_maestra'};
 push $mes->{'command_body'},['domain:es_marca',$rd->{'marca'}] if defined $rd->{'marca'};
 push $mes->{'command_body'},['domain:es_inscripcion',$rd->{'inscripcion'}] if defined $rd->{'inscripcion'};
 push $mes->{'command_body'},['domain:es_accion_comercial',$rd->{'accion_comercial'}] if defined $rd->{'accion_comercial'};
 push $mes->{'command_body'},['domain:codaux',$rd->{'codaux'}] if defined $rd->{'codaux'};
}

####################################################################################################
1;
