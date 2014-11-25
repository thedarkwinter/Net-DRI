## Domain Registry Interface, .PL policies
##
## Copyright (c) 2006,2008-2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013-2014 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::PL;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
use DateTime::Duration;

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_accept domain_transfer_refuse contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse/);

=pod

=head1 NAME

Net::DRI::DRD::PL - .PL policies for Net::DRI

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

Copyright (c) 2006,2008-2012 Patrick Mevzek <netdri@dotandco.com>.
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
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=1;	## LOC only
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'NASK'; }
## See http://www.dns.pl/english/dns-funk.html
sub tlds     { return ('pl',map { $_.'.pl'} qw/aid agro atm auto biz com edu gmina gsm info mail miasta media mil net nieruchomosci nom org pc powiat priv realestate rel sex shop sklep sos szkola targi tm tourism travel turystyka waw/ ); }
sub object_types { return ('domain','contact','ns','future'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::HTTP',{protocol_connection=>'Net::DRI::Protocol::EPP::Extensions::HTTP'},'Net::DRI::Protocol::EPP::Extensions::PL',{}) if $type eq 'epp'; ## EPP is over HTTPS here
 return;
}

####################################################################################################

sub message_retrieve
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','plretrieve',[$id]);
 return $rc;
}

sub report_create
{
 my ($self,$ndr,$id,$rp)=@_;
 my $rc=$ndr->process('report','create',[$id,$rp]);
 return $rc;
}

sub future_info
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('future','info',[$id,$rd]);
}

sub future_check # based domain_check from /lib/Net/DRI/DRD.pm
{
	my ($self,$ndr,@p)=@_;
	my (@names,$rd);
	foreach my $p (@p)
	{
		if (defined $p && ref $p eq 'HASH')
		{
			Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in future_check') if defined $rd;
			$rd=Net::DRI::Util::create_params('future_check',$p);
		}
		$self->enforce_domain_name_constraints($ndr,$p,'check');
    push @names,$p;
	}
	Net::DRI::Exception::usererr_insufficient_parameters('future_check needs at least one domain name to check') unless @names;
	$rd={} unless defined $rd;

	my (@rs,@todo);
	my (%seendom,%seenrc);
	foreach my $domain (@names)
	{
	  next if exists $seendom{$domain};
	  $seendom{$domain}=1;
	  my $rs=$ndr->try_restore_from_cache('future',$domain,'check');
	  if (! defined $rs)
	  {
	   push @todo,$domain;
	  } else
    {
      push @rs,$rs unless exists $seenrc{''.$rs}; ## Some ResultStatus may relate to multiple domain names (this is why we are doing this anyway !), so make sure not to use the same ResultStatus multiple times
      $seenrc{''.$rs}=1;
    }
  }
	return Net::DRI::Util::link_rs(@rs) unless @todo;

	 if (@todo > 1 && $ndr->protocol()->has_action('future','check_multi'))
	 {
	  my $l=$self->info('check_limit');
	  if (! defined $l)
	  {
	   $ndr->log_output('notice','core','No check_limit specified in driver, assuming 10 for domain_check action. Please report if you know the correct value');
	   $l=10;
	  }
	  while (@todo)
	  {
	   my @lt=splice(@todo,0,$l);
	   push @rs,$ndr->process('future','check_multi',[\@lt,$rd]);
	  }
	 } else ## either one domain only, or more than one but no check_multi available at protocol level
	 {
	  push @rs,map { $ndr->process('future','check',[$_,$rd]); } @todo;
	}
	return Net::DRI::Util::link_rs(@rs);
}

sub future_create
{
	my ($self,$reg,$id,$rd)=@_;
	return $reg->process('future','create',[$id,$rd]);
}

sub future_renew
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('future','renew',[$id,$rd]);
}

sub future_delete
{
 my ($self,$reg,$rd)=@_;
 return $reg->process('future','delete',[$rd]);
}

sub future_update
{
 my ($self,$reg,$rd,$todo)=@_;
 return $reg->process('future','update',[$rd,$todo]);
}

sub future_transfer_request
{
 my ($self,$reg,$rd,$rp)=@_;
 return $reg->process('future','transfer_request',[$rd,$rp]);
}

sub future_transfer_query
{
 my ($self,$reg,$rd,$rp)=@_;
 return $reg->process('future','transfer_query',[$rd,$rp]);
}

sub future_transfer_cancel
{
 my ($self,$reg,$rd,$rp)=@_;
 return $reg->process('future','transfer_cancel',[$rd,$rp]);
}


####################################################################################################
1;
