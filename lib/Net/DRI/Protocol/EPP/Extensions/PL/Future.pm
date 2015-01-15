## Domain Registry Interface, .PL Future EPP extension commands
## Comlaude EPP extensions
##
## Copyright (c) 2007,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::EPP::Extensions::PL::Future;

use utf8;
use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use DateTime::Duration;
use DateTime::Format::ISO8601;


####################################################################################################

sub register_commands
{
  my ($class, $version) = @_;
  my %tmp =  (
               info		=> [ \&info, \&info_parse ],
               check	=> [ \&check, \&check_parse ],  
               create	=> [ \&create, \&create_parse ],
               update	=> [ \&update, undef ],
               transfer_request	=> [ \&transfer_request, \&transfer_parse ],
               transfer_query	=> [ \&transfer_query, \&transfer_parse ],
               transfer_cancel	=> [ \&transfer_cancel, \&transfer_parse ],
               renew	=> [ \&renew, \&renew_parse ],
			   			 delete	=> [ \&delete, undef ],                            
             );
             	
	$tmp{check_multi}=$tmp{check};
  return { 'future' => \%tmp };
}

#Setup added in Protocol/EPP/Extensions/PL.pm
#sub setup 
#{  
#  my ($self,$rp)=@_;
#  $rp->ns({#  
#    future => ['http://www.dns.pl/nask-epp-schema/future-2.0','future-2.0.xsd'],
#  });
#  return;
#}

sub info{
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my @d=future_build_command($mes,'info',$domain);
	push @d,future_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
	$mes->command_body(\@d);
	return;	
}

sub info_parse
{
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();  
  return unless $mes->is_success();

  my $infData=$mes->get_response('future','infData');
  return unless defined $infData;
  
  foreach my $el (Net::DRI::Util::xml_list_children($infData))
  {
    my ($name,$content)=@$el; 
    
    $rinfo->{future}->{$oname}->{$name}=$content->textContent() if $name =~ m/^(name|roid|registrant|clID|crID|upID)$/; # plain text
    $rinfo->{future}->{$oname}->{$name}=$po->parse_iso8601($content->textContent()) if $name =~ m/^(crDate|upDate|exDate|trDate)$/; # date fields
    
    if ($name eq 'authInfo')
    {
    	$rinfo->{future}->{$oname}->{auth}={pw => Net::DRI::Util::xml_child_content($content,$mes->ns('future'),'pw')};
    }
  }    
  return;
}

sub check
{
	my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
	my @f=future_build_command($mes,'check',$domain);
  $mes->command_body(\@f);
  return;
}

sub check_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  
  my $chkdata=$mes->get_response('future','chkData');
  return unless defined $chkdata;
  
  foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('future'),'cd'))
  {
    my $future;
  	foreach my $el (Net::DRI::Util::xml_list_children($cd))
  	{
  	  my ($n,$content)=@$el;
  	  if ($n eq 'name')
  	  {
  	  	$future=lc($content->textContent());
				$rinfo->{domain}->{$future}->{action}='check';
				$rinfo->{domain}->{$future}->{exist}=1-Net::DRI::Util::xml_parse_boolean($content->getAttribute('avail'));							
  	  } elsif ($n eq 'reason')
  	  { 
				$rinfo->{domain}->{$future}->{exist_reason}=$content->textContent();
  	  }
  	}
  }
  return;
}

sub create
{
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my @d=future_build_command($mes,'create',$domain);
	
	my $def=$epp->default_parameters();
	if ($def && (ref($def) eq 'HASH') && exists($def->{future_create}) && (ref($def->{future_create}) eq 'HASH'))
  {
  	$rd={} unless ($rd && (ref($rd) eq 'HASH') && keys(%$rd));
  	while(my ($k,$v)=each(%{$def->{future_create}}))
  	{
   		next if exists($rd->{$k});
   		$rd->{$k}=$v;
  	}
 	} 	
 	## Period
	push @d,build_period_future($rd->{duration}) if Net::DRI::Util::has_duration($rd);
	## Registrant
	push @d, ['future:registrant',$rd->{registrant}] if defined $rd->{registrant}; 	
 	## AuthInfo
 	Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
	push @d,future_build_authinfo($epp,$rd->{auth});
 	 	
 	$mes->command_body(\@d);
 	return;	
}

sub create_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();  
  return unless $mes->is_success();

  my $creData=$mes->get_response('future','creData');
  return unless defined $creData;

  foreach my $el (Net::DRI::Util::xml_list_children($creData))
  {
    my ($name,$content)=@$el;
    $rinfo->{future}->{$oname}->{name}=$content->textContent() if $name eq ('name');
    $rinfo->{future}->{$oname}->{crDate}=new DateTime::Format::ISO8601->new()->parse_datetime($content->textContent()) if $name eq ('crDate');
    $rinfo->{future}->{$oname}->{exDate}=new DateTime::Format::ISO8601->new()->parse_datetime($content->textContent()) if $name eq ('exDate');    
  }    
  return;
}

sub delete
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
	my @d=future_build_command($mes,'delete',$domain);
  $mes->command_body(\@d);
  return;
}

sub renew
{
  my ($epp,$domain,$rd)=@_;
	
  my $curexp=Net::DRI::Util::has_key($rd,'current_expiration')? $rd->{current_expiration} : undef;
  Net::DRI::Exception::usererr_insufficient_parameters('current expiration date') unless defined($curexp);
  $curexp=$curexp->clone()->set_time_zone('UTC')->strftime('%Y-%m-%d') if (ref($curexp) && Net::DRI::Util::check_isa($curexp,'DateTime'));
  Net::DRI::Exception::usererr_invalid_parameters('current expiration date must be YYYY-MM-DD') unless $curexp=~m/^\d{4}-\d{2}-\d{2}$/;
  # Should force to get the future exDate (future_info->get_info(exDate)) and only accept Duration period as param fulfilling the curExpDate automatically?
	
  my $mes=$epp->message();
	my @d=future_build_command($mes,'renew',$domain);
  push @d,['future:curExpDate',$curexp];
	push @d,build_period_future($rd->{duration}) if Net::DRI::Util::has_duration($rd);
	
  $mes->command_body(\@d);
  return;
}

sub renew_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
	
  my $rendata=$mes->get_response('future','renData');
  return unless defined $rendata;
  	
  foreach my $el (Net::DRI::Util::xml_list_children($rendata))
  {	
    my ($name,$content)=@$el;    
    if ($name=~m/^(name)$/)
  	{
  	  $rinfo->{future}->{$oname}->{$1}=$content->textContent();
  	}
  	elsif ($name=~m/^(exDate)$/)
  	{
  	  $rinfo->{future}->{$oname}->{$1}=$po->parse_iso8601($content->textContent());
  	}
  }
  return;
}

# based on EPP::Core::Domain	
sub update
{
  my ($epp,$domain,$todo)=@_;
  my $mes=$epp->message();
	
  Net::DRI::Exception::usererr_insufficient_parameters($todo.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);
	my @d=future_build_command($mes,'update',$domain);
	
  # chg elem
  my $chg=$todo->set('registrant');
  my @chg;
  push @chg,['future:registrant',$chg->srid()] if Net::DRI::Util::isa_contact($chg);
  $chg=$todo->set('auth');
	push @chg,future_build_authinfo($epp,$chg,1) if ($chg && (ref $chg eq 'HASH') && exists $chg->{pw});
  push @d,['future:chg',@chg] if @chg;
	
  $mes->command_body(\@d);	
  return;
}

sub transfer_request
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
	my @d=future_build_command($mes,['transfer',{'op'=>'request'}],$domain);
  push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);
	push @d,future_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
  $mes->command_body(\@d);
  return;
}

sub transfer_query 
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
	my @d=future_build_command($mes,['transfer',{'op'=>'query'}],$domain);
	push @d,future_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
  $mes->command_body(\@d);
  return;
}

sub transfer_cancel
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
	my @d=future_build_command($mes,['transfer',{'op'=>'cancel'}],$domain);
	push @d,future_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
  $mes->command_body(\@d);
  return;
}

sub transfer_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  
  my $trndata=$mes->get_response('future','trnData');
  return unless defined $trndata;
  
  $oname = 'future' unless defined $oname;
  foreach my $el (Net::DRI::Util::xml_list_children($trndata))
  {
    my ($name,$content)=@$el;
    if ($name=~m/^(name|trStatus|reID|acID)$/)
    {
      $rinfo->{future}->{$oname}->{$1}=$content->textContent();
    }
    elsif ($name=~m/^(reDate|acDate|exDate)$/)
    {
      $rinfo->{future}->{$oname}->{$1}=$po->parse_iso8601($content->textContent());
    }
  }
  return;
}

# check if authInfo inserted for the .PL future extension
sub future_build_authinfo
{
 my ($epp,$rauth,$isupdate)=@_;
 return ['future:authInfo',['future:null']] if ((! defined $rauth->{pw} || $rauth->{pw} eq '') && $epp->{usenullauth} && (defined($isupdate) && $isupdate));
 return ['future:authInfo',['future:pw',$rauth->{pw},exists($rauth->{roid})? { 'roid' => $rauth->{roid} } : undef]];
} 

sub future_build_command
{
  my ($msg,$command,$future,$futureattr)=@_;
  my @fut=ref $future ? @$future : ($future);
  
  Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless @fut;
  foreach my $f (@fut)
  {
  	Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined $f && $f;
  	Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$f) unless Net::DRI::Util::xml_is_token($f,1,255);
  } 
  
  my $tcommand=ref $command ? $command->[0] : $command;
  $msg->command([$command,'future:'.$tcommand,sprintf('xmlns:future="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('future'))]);
  
  my @f=map { ['future:name',$_,$futureattr] } @fut;
  return @f;
}

sub build_period_future
{
 my $dtd=shift; ## DateTime::Duration
 my ($y,$m)=$dtd->in_units('years','months'); ## all values are integral, but may be negative
 ($y,$m)=(0,$m+12*$y) if ($y && $m);
 my ($v,$u);
 if ($y)
 {
  Net::DRI::Exception::usererr_invalid_parameters('years must be between 1 and 99') unless ($y >= 1 && $y <= 99);
  $v=$y;
  $u='y';
 } else
 {
  Net::DRI::Exception::usererr_invalid_parameters('months must be between 1 and 99') unless ($m >= 1 && $m <= 99);
  $v=$m;
  $u='m';
 }
 return ['future:period',$v,{'unit' => $u}];
}

1;