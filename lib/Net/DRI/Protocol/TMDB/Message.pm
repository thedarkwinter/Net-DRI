## Domain Registry Interface, TMCH Message
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::TMDB::Message;

use utf8;
use strict;
use warnings;

use DateTime::Format::ISO8601 ();
use DateTime ();
use XML::LibXML ();

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Util;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version command command_body msg_content cnis_data smdrl_data));


####################################################################################################
sub new
{
 my ($class)=@_;
 my $self={ results => [], ns => {} };
 return bless($self,$class);
}

sub _get_result
{
 my ($self,$what,$pos)=@_;
 my $rh=$self->{results}->[defined $pos ? $pos : 0];
 return unless (defined $rh && ref $rh eq 'HASH' && keys(%$rh)==4);
 return $rh->{$what};
}

sub results            { return @{shift->{results}}; }
sub results_code       { return map { $_->{code} } shift->results(); }
sub results_message    { return map { $_->{message} } shift->results(); }
sub results_lang       { return map { $_->{lang} } shift->results(); }
sub results_extra_info { return map { $_->{extra_info} } shift->results(); }

sub result_is         { my ($self,$code)=@_; return Net::DRI::Protocol::ResultStatus::is($self->_get_result('code'),$code); }
sub result_code       { my ($self,@args)=@_; return $self->_get_result('code',@args); }
sub result_message    { my ($self,@args)=@_; return $self->_get_result('message',@args); }
sub result_lang       { my ($self,@args)=@_; return $self->_get_result('lang',@args); }
sub result_extra_info { my ($self,@args)=@_; return $self->_get_result('extra_info',@args); }

sub ns
{
 my ($self,$what)=@_;
 return $self->{ns} unless defined $what;

 if (ref $what eq 'HASH')
 {
  $self->{ns}=$what;
  return $what;
 }
 return unless exists $self->{ns}->{$what};
 return $self->{ns}->{$what}->[0];
}

sub is_success { return _is_success(shift->result_code()); }
sub _is_success { return (shift=~m/^1/)? 1 : 0; } ## 1XXX is for success, 2XXX for failures

sub result_status
{
 my ($self)=@_;
 my @rs;

 foreach my $result (@{$self->{results}})
 {
  my $rs=Net::DRI::Protocol::ResultStatus->new('tmdb',$result->{code},undef,_is_success($result->{code}),$result->{message},$result->{lang},$result->{extra_info});
  #$rs->_set_trid([ $self->cltrid(),$self->svtrid() ]);
  push @rs,$rs;
 }
 return Net::DRI::Util::link_rs(@rs);
}

sub as_string { return $_[0]->{command_body}; }

sub parse
{
 my ($self,$dc,$rinfo,$otype,$oaction)=@_;
 push @{$self->{results}},{ code => 1000, message => 'Command completed successfully', lang => 'en', extra_info => []}; # Unless there is a HTTP error, this is a success
 $self->{message_body} = $dc->{data};
 return;
}

####################################################################################################
1;