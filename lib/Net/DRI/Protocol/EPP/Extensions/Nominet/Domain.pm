## Domain Registry Interface, .UK EPP Domain commands
##
## Copyright (c) 2008-2010,2013-2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Protocol::EPP::Core::Domain;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::Domain - .UK EPP Domain commands  for Net::DRI

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

Copyright (c) 2008-2010,2013-2014 Patrick Mevzek <netdri@dotandco.com>.
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
		info   => [ undef, \&info_parse ],
		create => [ \&create ],
		update => [\&update],
        unrenew => [\&unrenew, \&Net::DRI::Protocol::EPP::Core::Domain::renew_parse ],
        list => [\&list, \&list_parse ],
        lock => [\&lock],
        transfer_start => [\&release],
        transfer_accept => [\&handshake_accept, \&handshake_parse],
        transfer_refuse => [\&handshake_reject],
         );
 return { 'domain' => \%tmp };
}

####################################################################################################
########### Query commands


sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('domain-nom-ext','infData');
 return unless $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  next unless $name =~ m/^(reg-status|first-bill|recur-bill|auto-bill|next-bill|auto-period|next-period|notes|reseller|renew-not-required)$/;
  $rinfo->{domain}->{$oname}->{$name} = $c->textContent();
 }
 return;
}

sub list_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response('std-list','listData');
 return unless $infdata;
 $rinfo->{domain_list}->{0}->{total} = $infdata->getAttribute('noDomains');
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
  {
  my ($name,$c)=@$el;
  push @{$rinfo->{domain_list}->{0}->{domains}}, $c->textContent() if $name eq 'domainName';
 }
 return;
}

sub handshake_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 return unless my $infdata=$mes->get_response('std-handshake','hanData');
 my $ns = $mes->ns('std-handshake');
 return unless my $dl = $infdata->getChildrenByTagNameNS($ns,'domainListData')->shift();
 $rinfo->{domain_list}->{0}->{total} = $dl->getAttribute('noDomains');
 foreach my $el (Net::DRI::Util::xml_list_children($dl))
 {
  my ($name,$c)=@$el;
  push @{$rinfo->{domain_list}->{0}->{domains}}, $c->textContent() if $name eq 'domainName';
 }
 return;
}

############ Transform commands ####################################################################

sub domain_nom_ext
{
 my $rd=shift;
 my @n;
 #TODO Validate these fields? 
 my @errs;
 foreach (qw/first-bill recur-bill/) { push @errs, "$_ [$rd->{$_}]" if ($rd->{$_} && $rd->{$_} !~ m/^(bc|th)$/); }
 foreach (qw/auto-bill next-bill/) { push @errs, "$_ [$rd->{$_}]" if ($rd->{$_} && !($rd->{$_} =~ /^[+]?\d+$/ && $rd->{$_}<183)); }
 foreach (qw/auto-period next-period/) { push @errs, "$_ [$rd->{$_}]" if ($rd->{$_} && !($rd->{$_} =~ /^[+]?\d+$/ && $rd->{$_}<10)); }
 foreach (qw/renew-not-required/)
 {
  next unless $rd->{$_};
  $rd->{$_} = 'Y' if $rd->{$_} =~ m/^(1|Y|YES|TRUE)$/i;
  $rd->{$_} = 'N' if $rd->{$_} =~ m/^(0|N|NO|FALSE)$/i;
  push @errs, "$_ [$rd->{$_}]" if $rd->{$_} !~ m/^(Y|N)$/;
}
 Net::DRI::Exception::usererr_invalid_parameters('Invalid domain information: '.join('/',@errs)) if @errs;

 foreach (qw/first-bill recur-bill auto-bill next-bill notes reseller auto-period next-period renew-not-required/) {
  my $f = $_;
  push @n, ['domain-nom-ext:'.$f, $rd->{$_}] if defined $rd->{$_};
 }
 return @n;
}

sub create {
 my ($epp,$domain,$rd)=@_;
 undef $rd->{'renew-not-required'}; # only for updates
 my @n = domain_nom_ext($rd);
 return unless @n;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('domain-nom-ext:create',sprintf('xmlns:domain-nom-ext="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('domain-nom-ext')));
 $mes->command_extension($eid,\@n);
 return;
}

sub update {
 my ($epp,$domain,$todo)=@_;
 my $rd;
 foreach (qw/first-bill recur-bill auto-bill next-bill notes reseller auto-period next-period renew-not-required/) {
  $rd->{$_} = $todo->set($_) if defined $todo->set($_);
  }
 return unless $rd;
 my @n = domain_nom_ext($rd);
 return unless @n;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('domain-nom-ext:update',sprintf('xmlns:domain-nom-ext="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('domain-nom-ext')));
 $mes->command_extension($eid,\@n);
 return;
}

sub list
{
 my ($epp,$rd)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_insufficient_parameters('month or expiry is required') unless $rd->{regMonth} || $rd->{exMonth};
 foreach (qw/regMonth exMonth/)
 {
  $rd->{$_} = $rd->{$_}->format_cldr('yyyy-MM') if UNIVERSAL::isa($rd->{$_},'DateTime');
  Net::DRI::Exception::usererr_invalid_parameters($_) if $rd->{$_} and $rd->{$_} !~ m/^[0-9]{4}-[0-9]{2}$/;
 }

  $mes->command(['info','l:list',sprintf('xmlns:l="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('std-list'))]);
 my @d;
 push @d, ['l:month',$rd->{'regMonth'}] if $rd->{regMonth};
 push @d, ['l:expiry',$rd->{'exMonth'}] if $rd->{exMonth};
 $mes->command_body(\@d);
 return;
}

## Warning: this can also be used for multiple domain names at once,
## see http://www.nominet.org.uk/registrars/systems/nominetepp/Unrenew/
## However, if we accept that, we will probably have to tweak Core::Domain::renew_parse
## to handle multiple renData nodes in the response.
sub unrenew
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_insufficient_parameters('Domain name required') unless $domain;
 Net::DRI::Exception::usererr_invalid_parameters('domain') unless Net::DRI::Util::is_hostname($domain);
 $mes->command(['update','u:unrenew',sprintf('xmlns:u="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('std-unrenew'))]);
 my @d=(['u:domainName',$domain]);
 $mes->command_body(\@d);
 return;
}

# called by domain_transfer_start, can release a domain or an account here
sub release
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_insufficient_parameters('Domain name required, specify alldomains.co.uk if you are releasing an account') unless $domain;
 Net::DRI::Exception::usererr_insufficient_parameters('registar_tag is required') unless $rd->{registrar_tag};
 Net::DRI::Exception::usererr_insufficient_parameters('To release an account you must specify alldomains.co.uk as the domain name') if defined $rd->{account_id} && $domain ne 'alldomains.co.uk'; # failsafe
 $mes->command(['update','r:release',sprintf('xmlns:r="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('std-release'))]);
 my @d=((defined $rd->{account_id} ? ['r:registrant',$rd->{account_id}] : ['r:domainName',$domain]),['r:registrarTag',$rd->{registrar_tag}]);
 $mes->command_body(\@d);
 return;
}

# called by domain_transfer_accept
sub handshake_accept
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_insufficient_parameters('case_id is required') unless $rd->{case_id};
 $mes->command(['update','h:accept',sprintf('xmlns:h="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('std-handshake'))]);
 my @d=(['h:caseId',$rd->{case_id}]);
 push @d, ['h:registrant',$rd->{'registrant'}] if $rd->{'registrant'};
 $mes->command_body(\@d);
 return;
}

# called by domain_transfer_refuse
sub handshake_reject
 {
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_insufficient_parameters('case_id is required') unless $rd->{case_id};
 $mes->command(['update','h:reject',sprintf('xmlns:h="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('std-handshake'))]);
 my @d=(['h:caseId',$rd->{case_id}]);
 $mes->command_body(\@d);
 return;
}

sub lock ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_insufficient_parameters('Domain name required') unless $domain;
 Net::DRI::Exception::usererr_insufficient_parameters('type must be set to investigation to lock a domain') unless $rd->{type} && $rd->{type} eq 'investigation';
 $mes->command(['update','l:lock',sprintf('xmlns:l="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('std-locks')). ' object="domain" type="investigation"']);
 my @d=(['l:domainName',$domain]);
 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;
