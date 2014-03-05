## Domain Registry Interface, Registry object
##
## Copyright (c) 2005-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Registry;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast Net::DRI::BaseClass);
__PACKAGE__->mk_ro_accessors(qw(name driver profile trid_factory logging)); ## READ-ONLY !!

use Time::HiRes ();

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Data::RegistryObject;

our $AUTOLOAD;

=pod

=head1 NAME

Net::DRI::Registry - Specific Registry Driver Instance inside Net::DRI

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

Copyright (c) 2005-2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($class,$name,$drd,$cache,$trid,$logging)=@_;

 my $self={name   => $name,
           driver => $drd,
           cache  => $cache,
           profiles => {}, ## { profile name => { protocol  => X
                           ##                     transport => X
                           ##                     status    => Net::DRI::Protocol::ResultStatus
                           ##                     %extra
                           ##                   }
                           ## }
           profile => undef, ## current profile
           auto_target => {},
           last_data => {},
	   last_process => {},
           trid_factory => $trid,
           logging => $logging,
          };

 bless($self,$class);
 return $self;
}

sub available_profile
{
 my $self=shift;
 return (defined($self->{profile}))? 1 : 0;
}

sub available_profiles
{
 my ($self,$full)=@_;
 $full||=0;
 my @r=sort { $a cmp $b } ($full ? map { $_->{fullname} } values(%{$self->{profiles}}) : keys(%{$self->{profiles}}));
 return @r;
}

sub exist_profile
{
 my ($self,$name)=@_;
 return (defined($name) && exists($self->{profiles}->{$name}));
}

sub err_no_current_profile           { Net::DRI::Exception->die(0,'DRI',3,'No current profile available'); } ## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)
sub err_profile_name_does_not_exist  { Net::DRI::Exception->die(0,'DRI',4,'Profile name '.$_[0].' does not exist'); } ## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)

sub remote_object
{
 my ($self,@args)=@_;
 return Net::DRI::Data::RegistryObject->new($self,@args);
}

sub _current
{
 my ($self,$what,$tostore)=@_;
 err_no_current_profile()                          unless (defined($self->{profile}));
 err_profile_name_does_not_exist($self->{profile}) unless (exists($self->{profiles}->{$self->{profile}}));
 Net::DRI::Exception::err_assert('key should be transport, protocol or status, and not: '.$what) unless defined $what && exists $self->{profiles}->{$self->{profile}}->{$what};

 if (($what eq 'status') && $tostore)
 {
  $self->{profiles}->{$self->{profile}}->{$what}=$tostore;
 }

 return $self->{profiles}->{$self->{profile}}->{$what};
}

sub transport { return shift->_current('transport'); }
sub protocol  { return shift->_current('protocol');  }
sub status    { return shift->_current('status',@_); } ## no critic (Subroutines::RequireArgUnpacking)
sub protocol_transport { my $self=shift; return ($self->protocol(),$self->transport()); }

sub local_object
{
 my ($self,$f,@args)=@_;
 return unless $self && $f;
 return $self->_current('protocol')->create_local_object($f,@args);
}

sub _result
{
 my ($self,$f)=@_;
 my $p=$self->profile();
 err_no_current_profile() unless (defined($p));
 Net::DRI::Exception->die(0,'DRI',6,'No last status code available for current registry and profile') unless (exists($self->{profiles}->{$p}->{status}));
 my $rc=$self->{profiles}->{$p}->{status}; ## a Net::DRI::Protocol::ResultStatus object !
 Net::DRI::Exception->die(1,'DRI',5,'Status key is not a Net::DRI::Protocol::ResultStatus object') unless Net::DRI::Util::is_class($rc,'Net::DRI::Protocol::ResultStatus');
 return $rc if ($f eq 'self');
 Net::DRI::Exception::method_not_implemented($f,'Net::DRI::Protocol::ResultStatus') unless ($f && $rc->can($f));
 return $rc->$f();
}

sub result_is_success  { return shift->_result('is_success');  }
sub is_success         { return shift->_result('is_success');  } ## Alias
sub result_code        { return shift->_result('code');        }
sub result_native_code { return shift->_result('native_code'); }
sub result_message     { return shift->_result('message');     }
sub result_lang        { return shift->_result('lang');        }
sub result_status      { return shift->_result('self');        }
sub result_extra_info  { return shift->_result('info');        }

sub cache_expire { return shift->{cache}->delete_expired(); }
sub cache_clear  { return shift->{cache}->delete(); }

sub set_info
{
 my ($self,$type,$key,$data,$ttl)=@_;
 my $p=$self->profile();
 err_no_current_profile() unless defined($p);
 my $regname=$self->name();

 my $c=$self->{cache}->set($regname.'.'.$p,$type,$key,$data,$ttl);
 $self->{last_data}=$c; ## the hash exists, since we called clear_info somewhere before 
 $self->{last_data}->{result_from_cache}=0;

 return $c;
}

## Returns a $rc object or undef if nothing found in cache for the specific object ($type/$key) and action ($action)
sub try_restore_from_cache
{
 my ($self,$type,$key,$action)=@_;
 if (! Net::DRI::Util::all_valid($type,$key,$action)) { Net::DRI::Exception::err_assert('try_restore_from_cache improperly called'); }

 my $a=$self->get_info('action',$type,$key);
 ## not in cache or in cache but for some other action
 if (! defined $a || ($a ne $action)) { $self->log_output('debug','core',sprintf('Cache MISS (empty cache or other action) for type=%s key=%s',$type,$key)); return; }

 ## retrieve from cache, copy, and do some cleanup
 $self->{last_data}=$self->get_info_all($type,$key);
 ## since we passed the above test on get_info('action'), we know here we received something defined by get_info_all,
 ## but we test explicitly again (get_info_all returns an empty ref hash on problem, not undef), to avoid race conditions and such
 if (! keys(%{$self->{last_data}})) { $self->log_output('debug','core',sprintf('Cache MISS (no last_data content) for type=%s key=%s',$type,$key)); return; }

 ## Clone the result_status object as it may be linked from others part, and we may tweak its link chain (for example in domain_check)
 $self->{last_data}->{result_status}=$self->{last_data}->{result_status}->clone();

 ## get_info_all makes a copy, but only at first level ! so this high level change is ok (no pollution), but be warned for below !
 $self->{last_data}->{result_from_cache}=1;

 ## Important note here:
 ## we were previously kind of copying the session/exchange branch as obtained from $self->{last_data}->{result_status}->{local,global}_get_data_collection()
 ## before doing change
 ## however this is in fact unnecessary and complicated
 ## complicated because in fact of the ambiguity above in local or global get_data_collection
 ## unneccessary because wer are just setting result_from_cache to 1 here in session/exchange,
 ## and 1) as soon as this flag is flipped, it will never revert back to 0
 ##     2) in process_back() below we made a copy of session/exchange before putting it in ResultStatus, so changing it here, does not change previous result status given back to client
 $self->{last_data}->{result_status}->local_get_data_collection()->{session}->{exchange}->{result_from_cache}=1;
 $self->{cache}->set_result_from_cache($type,$key);
 $self->{cache}->set_result_from_cache('session','exchange');
 $self->{cache}->set_result_from_cache('message','info');

 $self->log_output('debug','core',sprintf('Cache HIT for type=%s key=%s',$type,$key));
 return $self->{last_data}->{result_status};
}

sub clear_info { shift->{last_data}={}; } ## no critic (Subroutines::RequireFinalReturn)

sub get_info
{
 my ($self,$what,$type,$key)=@_;
 return unless defined $what && $what;

 if (Net::DRI::Util::all_valid($type,$key)) ## search the cache, by default same registry & profile !
 {
  my $p=$self->profile();
  err_no_current_profile() unless defined($p);
  my $regname=$self->name();
  return $self->{cache}->get($type,$key,$what,$regname.'.'.$p);
 } else
 {
  return unless exists $self->{last_data}->{$what};
  return $self->{last_data}->{$what};
 }
}

sub get_info_all
{
 my ($self,$type,$key)=@_;
 my $rh;

 if (Net::DRI::Util::all_valid($type,$key))
 {
  my $p=$self->profile();
  err_no_current_profile() unless defined($p);
  my $regname=$self->name();
  $rh=$self->{cache}->get($type,$key,undef,$regname.'.'.$p);
 } else
 {
  $rh=$self->{last_data};
 }

 return {} unless (defined($rh) && ref($rh) && keys(%$rh));

 my %h=%{ $rh }; ## create a copy, as we will delete content... ## BUGFIX !!
 foreach my $k (grep { /^_/ } keys(%h)) { delete($h{$k}); }
 return \%h;
}

sub get_info_keys
{
 my ($self,$type,$key)=@_;
 my $rh=$self->get_info_all($type,$key);
 my @r=sort { $a cmp $b } keys %$rh;
 return @r;
}

####################################################################################################
## Change profile
sub target
{
 my ($self,$profile)=@_;
 err_profile_name_does_not_exist($profile) unless ($profile && exists($self->{profiles}->{$profile}));
 $self->{profile}=$profile;
 return;
}

sub profile_auto_switch
{
 my ($self,$otype,$oaction)=@_;
 my $p=$self->get_auto_target($otype,$oaction);
 return unless defined($p);
 $self->target($p);
 return;
}

sub set_auto_target
{
 my ($self,$profile,$otype,$oaction)=@_; ## $otype/$oaction may be undef
 err_profile_name_does_not_exist($profile) unless ($profile && exists($self->{profiles}->{$profile}));

 my $rh=$self->{auto_target};
 $otype||='_default';
 $oaction||='_default';
 $rh->{$otype}={} unless (exists($rh->{$otype}));
 $rh->{$otype}->{$oaction}=$profile;
 return;
}

sub get_auto_target
{
 my ($self,$otype,$oaction)=@_;
 my $at=$self->{auto_target};
 $otype='_default' unless (exists($at->{$otype}));
 return unless (exists($at->{$otype}));
 my $ac=$at->{$otype};
 return unless (defined($ac) && ref($ac));
 $oaction='_default' unless (exists($ac->{$oaction}));
 return unless (exists($ac->{$oaction}));
 return $ac->{$oaction};
}

sub add_current_profile
{
 my ($self,@p)=@_;
 my $rc=$self->add_profile(@p);
 $self->target($p[0]) if $rc->is_success();
 return $rc;
}

## Transport and Protocol parameters are merged (semantically but not chronologically, parameters coming later erase previous ones) in this order;
## - TransportConnectionClass->transport_default() [only for transport parameters]
## - Protocol->transport_default() [only for transport parameters]
## - DRD->transport_protocol_default()
## - user specified parameters to add_profile (they always have precedence over defaults stored in the 3 previous cases)

## API: profile name, profile type, transport params {}, protocol params {}
sub add_profile
{
 my ($self,$name,$type,$trans_p,$prot_p)=@_;

 if (! Net::DRI::Util::all_valid($name,$type))   { Net::DRI::Exception::usererr_insufficient_parameters('add_profile needs at least 2 parameters: new profile name and type'); }
 if ($self->exist_profile($name))                { Net::DRI::Exception::usererr_invalid_parameters('New profile name "'.$name.'" already in use'); }
 if (defined $trans_p && ref $trans_p ne 'HASH') { Net::DRI::Exception::usererr_invalid_parameters('If provided, 3rd parameter of add_profile (transport data) must be a ref hash'); }
 if (defined $prot_p  && ref $prot_p ne 'HASH')  { Net::DRI::Exception::usererr_invalid_parameters('If provided, 4th parameter of add_profile (protocol data) must be a ref hash'); }

 my $drd=$self->driver();
 my ($tc,$tp,$pc,$pp)=$drd->transport_protocol_default($type); ## Transport Class, Transport Params, Protocol Class, Protocol Params
 my $test=0;
 if (exists $INC{'Test/More.pm'} && defined $trans_p && exists $trans_p->{f_send})
 {
  $test=1;
  $self->log_output('emergency','core','For profile "'.$name.'", using INTERNAL TESTING configuration! This should not happen in production, but only during "make test"!');
  $tc='Net::DRI::Transport::Dummy';
  $tp={};
 }

 if (!Net::DRI::Util::all_valid($tc,$tp,$pc,$pp) || ref $tp ne 'HASH' || ref $pp ne 'HASH') { Net::DRI::Exception::usererr_invalid_parameters(sprintf('Registry "%s" does not provide profile type "%s")',$self->name(),$type)); }

 $tp={ %$tp, %$trans_p } if defined $trans_p;
 $pp={ %$pp, %$prot_p  } if defined $prot_p;

 $drd->transport_protocol_init($type,$tc,$tp,$pc,$pp,$test) if $drd->can('transport_protocol_init');

 Net::DRI::Util::load_module($tc,'DRI');
 Net::DRI::Util::load_module($pc,'DRI');
 $self->log_output('debug','core',sprintf('For profile "%s" attempting to initialize transport "%s" and protocol "%s"',$name,$tc,$pc));

 ## Protocol must come first, as it may be needed during transport setup; it should not die
 my $po=$pc->new({registry=>$self,profile=>$name,transport_class=>$tc},$pp);
 $tp={ $po->transport_default(), %$tp } if ($po->can('transport_default'));

 my ($to,$rc);
 my $ok=eval
 {
  ($to,$rc)=$tc->new({registry=>$self,profile=>$name,protocol=>$po},$tp); ## this may die !
  1;
 };
 if (! $ok) ## some kind of error happened
 {
  my $err=$@;
  return $err if ref $err eq 'Net::DRI::Protocol::ResultStatus';
  $err=Net::DRI::Exception->new(1,'internal',0,'Error not handled: '.$err) unless ref $err;
  die $err;
 }
 return $rc if defined $rc && ! $rc->is_success();

 my $fullname=sprintf('%s (%s/%s + %s/%s)',$name,$po->name(),$po->version(),$to->name(),$to->version());
 $self->{profiles}->{$name}={ fullname => $fullname, transport => $to, protocol => $po, status => undef };
 $self->log_output('notice','core','Successfully added profile "'.$fullname.'"');
 my $lrc=Net::DRI::Protocol::ResultStatus->new_success('Profile "'.$name.'" added successfully','en');
 return $lrc unless defined $rc;
 $rc->_set_last($lrc);
 return $rc;
}

sub del_profile
{
 my ($self,$name)=@_;
 if (defined($name))
 {
  err_profile_name_does_not_exist($name) unless $self->exist_profile($name);
 } else
 {
  err_no_current_profile() unless defined $self->{profile};
  $name=$self->{profile};
 }

 my $p=$self->{profiles}->{$name};
 $p->{protocol}->end()  if ref $p->{protocol} && $p->{protocol}->can('end');
 $p->{transport}->end({registry => $self, profile => $name}) if ref $p->{transport} && $p->{transport}->can('end');
 delete($self->{profiles}->{$name});
 $self->{profile}=undef if $self->{profile} eq $name; ## current profile is not defined anymore
 return Net::DRI::Protocol::ResultStatus->new_success('Profile "'.$name.'" deleted successfully','en');
}

sub end
{
 my $self=shift;
 foreach my $name (keys %{$self->{profiles}})
 {
  my $p=$self->{profiles}->{$name};
  $p->{transport}->end({protocol => $p->{protocol}}) if ref $p->{transport} && $p->{transport}->can('end');
  $p->{protocol}->end()                              if ref $p->{protocol}  && $p->{protocol}->can('end');
  delete $self->{profiles}->{$name}
 }

 $self->{driver}->end() if $self->{driver}->can('end');
 return;
}

sub can
{
 my ($self,$what)=@_;
 return $self->SUPER::can($what) || $self->driver->can($what);
}

####################################################################################################
####################################################################################################

sub has_action
{
 my ($self,$otype,$oaction)=@_;
 my ($po,$to)=$self->protocol_transport();
 return $po->has_action($otype,$oaction);
}

sub process
{
 my ($self,$otype,$oaction,$pa,$ta)=@_;
 $pa=[] unless defined $pa; ## store them ?
 $ta=[] unless defined $ta;
 $self->{last_process}=[$otype,$oaction,$pa,$ta]; ## should be handled more generally by LocalStorage/Exchange

 ## Automated switch, if enabled
 $self->profile_auto_switch($otype,$oaction);

 ## Current protocol/transport objects for current profile
 my ($po,$to)=$self->protocol_transport();
 my $trid=$self->generate_trid();
 my $ctx={trid => $trid, otype => $otype, oaction => $oaction, phase => 'active', protocol => $po };
 my $tosend;

 my $ok=eval { $tosend=$po->action($otype,$oaction,$trid,@$pa); 1; }; ## TODO : this may need to be pushed in loop below if we need to change message to send when failure
 if (! $ok)
 {
  my $err=$@;
  return $self->format_error($err);
 }

 $self->{ops}->{$trid}=[0,$tosend,undef]; ## 0 = todo, not sent ## This will be done in/with LocalStorage
 my $timeout=$to->timeout();
 my $prevalarm=alarm(0); ## removes current alarm
 my $pause=$to->pause();
 my $start=Time::HiRes::time();
 $self->{ops}->{$trid}->[2]=$start;

 my $count=0;
 my $r;
 while (++$count <= $to->retry())
 {
  $self->log_output('debug','core',sprintf('New process loop iteration for TRID=%s with count=%d pause=%f timeout=%f',$trid,$count,$pause,$timeout));
  Time::HiRes::sleep($pause) if (defined($pause) && $pause && ($count > 1));
  $self->log_output('warning','core',sprintf('Starting try #%d for TRID=%s',$count,$trid)) if $count>1;
  $r=eval
  {
   local $SIG{ALRM}=sub { die 'timeout' };
   alarm($timeout) if ($timeout);
   $self->log_output('debug','core',sprintf('Attempting to send data for TRID=%s',$trid));
   $to->send($ctx,$tosend,$count,$ta); ## either success or exception, no result code ## TODO : and if open_connection was called inside send ???
   $self->log_output('debug','core','Successfully sent data to registry for TRID='.$trid);
   $self->{ops}->{$trid}->[0]=1; ## now it is sent
   return $self->process_back($trid,$po,$to,$otype,$oaction,$count) if $to->is_sync();
   my $rc=Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL_PENDING');
   $rc->_set_trid([ $trid ]);
   $self->status($rc);
   return $rc;
  };
  alarm(0) if $timeout; ## removes our alarm
  if (! defined $r || ! $r) ## some die happened inside the eval (some sources say eval return undef on problem, others say empty string)
  {
   my $err=$@;
   return $self->format_error($err) if (ref $err eq 'Net::DRI::Protocol::ResultStatus'); ## should probably be a return here see below TODOXXX
   my $is_timeout=(!ref $err && ($err=~m/timeout/))? 1 : 0;
   $err=$is_timeout? Net::DRI::Exception->new(1,'transport',1,'timeout') : Net::DRI::Exception->new(1,'internal',0,'Error not handled: '.$err) unless ref $err;
   $self->log_output('debug','core',$is_timeout? 'Got timeout for TRID='.$trid : 'Got error for TRID='.$trid.' : '.$err->as_string());
   next if $to->try_again($ctx,$po,$err,$count,$is_timeout,$self->{ops}->{$trid}->[0],\$pause,\$timeout); ## will determine if 1) we break now the loop/we propagate the error (fatal error) 2) we retry
   die $err;
  }
  last if defined $r;
 } ## end of while
 if ($prevalarm) ## re-enable previous alarm
 {
  $prevalarm-=Time::HiRes::time()-$start; ## try to take into account the time spent here
  alarm($prevalarm) if $prevalarm > 0;
 }
 Net::DRI::Exception->die(0,'transport',1,sprintf('Unable to communicate with registry after %d tries for a total delay of %.03f seconds',$to->retry(),Time::HiRes::time()-$start)) unless defined $r;
 return $r;
}

sub format_error
{
 my ($self,$err)=@_;
 if (ref($err) eq 'Net::DRI::Protocol::ResultStatus')
 {
  $self->status($err); ## should that be done above also ? TODOXXX
  return $err;
 }
 $err=Net::DRI::Exception->new(1,'internal',0,'Error not handled: '.$err) unless ref($err);
 die($err);
}

## also called directly , when we found something to do for asynchronous case, through TRID (TODO)
## We are already in an eval here, and a while loop for retries
sub process_back
{
 my ($self,$trid,$po,$to,$otype,$oaction,$count)=@_;
 my $ctx={trid => $trid, otype => $otype, oaction => $oaction, protocol => $po }; ## How will we fill that in case of async operation (direct call here) ?
 my ($rc,$ri,$oname);

 $self->log_output('debug','core','Attempting to receive data from registry for TRID='.$trid);
 my $res=$to->receive($ctx,$count); ## a Net::DRI::Data::Raw or die inside
 my $stop=Time::HiRes::time();
 Net::DRI::Exception->die(0,'transport',5,'Unable to receive message from registry') unless defined $res;
 $self->log_output('debug','core','Successfully received data from registry for TRID='.$trid);
 $self->{ops}->{$trid}->[0]=2; ## now it is received
 $self->clear_info(); ## make sure we will overwrite current latest info
 $oname=_extract_oname($otype,$oaction,$self->{last_process}->[2]); ## lc() would be good here but this breaks a lot of things !
 ($rc,$ri)=$po->reaction($otype,$oaction,$res,$self->{ops}->{$trid}->[1],$oname,$trid); ## $tosend needed to propagate EPP version, for example

 if ($rc->is_closing() || (exists $ri->{_internal} && exists $ri->{_internal}->{must_reconnect} && $ri->{_internal}->{must_reconnect}))
 {
  $self->log_output('notice','core','Registry closed connection, we will automatically reconnect during next exchange');
  $to->current_state(0);
 }
 delete($ri->{_internal});

 ## Set latest status from what we got
 $self->status($rc);

 $ri->{session}->{exchange}->{transport}=$to->name().'/'.$to->version();
 $ri->{session}->{exchange}->{registry}=$self->name();
 $ri->{session}->{exchange}->{profile}=$self->profile();

 ## set_info stores also data in last_data, so we make sure to call last for current object
 foreach my $type (keys(%$ri))
 {
  foreach my $key (keys(%{$ri->{$type}}))
  {
   next if ($oname && ($type eq $otype) && ($key eq $oname));
   $self->set_info($type,$key,$ri->{$type}->{$key});
  }
 }

 ## Now set the last info, the one regarding directly the object
 if ($oname && $otype)
 {
  my $rli={ result_status => $rc };
  $rli=$ri->{$otype}->{$oname} if (exists($ri->{$otype}) && exists($ri->{$otype}->{$oname})); ## result_status already done in Protocol
  $self->set_info($otype,$oname,$rli);
 }

 ## Not before !
 ## Remove all ResultStatus object, to avoid all circular references
 foreach my $v1 (values(%$ri))
 {
  foreach my $v2 (values(%{$v1}))
  {
   delete($v2->{result_status}) if exists($v2->{result_status});
  }
 }

 ## the fact that here we copy the session/exchange branch before putting it inside the $rc object is very important
 ## see comments above in try_restore_from_cache() for details
 $ri->{session}->{exchange}={ %{$ri->{session}->{exchange}}, duration_seconds => $stop-$self->{ops}->{$trid}->[2], raw_command => $self->{ops}->{$trid}->[1]->as_string(), raw_reply => $res->as_string(), object_type => $otype, object_action => $oaction };
 $ri->{session}->{exchange}->{object_name}=$oname if $oname;
 $rc->_set_data($ri);
 delete($self->{ops}->{$trid});
 return $rc;
}

sub _extract_oname
{
 my ($otype,$oaction,$pa)=@_;

 return 'domains' if ($otype eq 'account' && $oaction eq 'list_domains');
 my $o=$pa->[0];
 return 'session' unless defined($o);
 $o=$o->[1] if (ref($o) eq 'ARRAY'); ## should be enough for _multi but still a little strange
 return (Net::DRI::Util::normalize_name($otype,$o))[1] unless ref($o); ## ?? ## TODO ## this fails t/626nominet line 306
 return (Net::DRI::Util::normalize_name('nsgroup',$otype eq 'nsgroup'? $o->name() : $o->get_details(1)))[1] if Net::DRI::Util::isa_hosts($o);
 return $o->srid() if Net::DRI::Util::isa_contact($o);
 return 'session';
}

####################################################################################################

sub protocol_capable
{
 my ($ndr,$op,$subop,$action)=@_;
 return 0 unless ($op && $subop); ## $action may be undefined
 my $po=$ndr->protocol();
 my $cap=$po->capabilities(); ## hashref

 return 0 unless ($cap && (ref($cap) eq 'HASH') && exists($cap->{$op}) 
                       && (ref($cap->{$op}) eq 'HASH') && exists($cap->{$op}->{$subop})
                       && (ref($cap->{$op}->{$subop}) eq 'ARRAY'));

 return 1 unless (defined($action) && $action);

 foreach my $a (@{$cap->{$op}->{$subop}})
 {
  return 1 if ($a eq $action);
 }
 return 0;
}

sub log_output
{
 my ($self,$level,$where,$msg)=@_;
 my $r=$self->name();
 $r.='.'.$self->{profile} if (defined $self->{profile});
 $msg='('.$r.') '.$msg;
 return $self->SUPER::log_output($level,$where,$msg);
}

####################################################################################################

sub AUTOLOAD
{
 my ($self,@args)=@_;
 my $attr=$AUTOLOAD;
 $attr=~s/.*:://;
 return unless $attr=~m/[^A-Z]/; ## skip DESTROY and all-cap methods

 my $drd=$self->driver(); ## This is a DRD object
 Net::DRI::Exception::method_not_implemented($attr,$drd) unless ref $drd && $drd->can($attr);
 $self->log_output('debug','core',sprintf('Calling %s from Net::DRI::Registry',$attr));
 return $drd->$attr($self,@args);
}

####################################################################################################
1;
