## Domain Registry Interface, Shell interface
##
## Copyright (c) 2008-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Shell;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK=qw(run);

use Net::DRI;
use Net::DRI::Util;
use Net::DRI::Protocol::ResultStatus;
use Term::ReadLine; ## see also Term::Shell
use Time::HiRes ();
use IO::Handle ();

our $HISTORY=(exists $ENV{HOME} && defined $ENV{HOME} && length $ENV{HOME})? $ENV{HOME}.'/.drish_history' : undef;

exit __PACKAGE__->run(@ARGV) if (!caller() || caller() eq 'PAR'); ## This is a modulino :-)

=pod

=head1 NAME

Net::DRI::Shell - Command Line Shell for Net::DRI, with batch features and autocompletion support

=head1 SYNOPSYS

 perl -I../../ ./Shell.pm
 or
 perl -MNet::DRI::Shell -e run
 or
 perl -MNet::DRI::Shell -e 'Net::DRI::Shell->run()'
 or in your programs:
 use Net::DRI::Shell;
 Net::DRI::Shell->run();

 Welcome to Net::DRI $version shell, pid $pid
 Net::DRI object created with a cache TTL of 10 seconds and logging into files in current directory

 NetDRI> add_registry registry=EURid client_id=YOURID
 NetDRI(EURid)> add_current_profile name=profile1 type=epp client_login=YOURLOGIN client_password=YOURPASSWORD
 Profile profile1 added successfully (1000/COMMAND_SUCCESSFUL) SUCCESS
 NetDRI(EURid,profile1)> domain_info example.eu
 Command completed successfully (1000/1000) SUCCESS
 NetDRI(EURid,profile1)> get_info_all

 ... all data related to the domain name queried ...

 NetDRI(EURid,profile1)> domain_check whatever.eu
 Command completed successfully (1000/1000) SUCCESS
 NetDRI(EURid,profile1)> get_info_all

 ... all data related to the domain name queried ...

 NetDRI(EURid,profile1)> show profiles
 EURid: profile1
 NetDRI(EURid,profile1)> quit


=head1 DESCRIPTION

This is a shell to be able to use Net::DRI without writing any code.

Most of the time commands are the name of methods to use on the Net::DRI object,
with some extra ones and some variations in API to make passing parameters simpler.

=head1 AVAILABLE COMMANDS

After having started this shell, the available commands are the following.

=head2 SESSION COMMANDS

=head3 add_registry registry=REGISTRYNAME client_id=YOURID

Replace REGISTRYNAME with the Net::DRI::DRD module you want to use, and YOURID
with your client identification for this registry (may be the same as the login used
to connect, or not).

=head3 add_current_profile name=profile1 type=epp client_login=YOURLOGIN client_password=YOURPASSWORD

This will really connect to the registry, replace YOURLOGIN by your client login at registry,
and YOURPASSWORD by the associated password. You may have to add parameters remote_host= and remote_port=
to connect to other endpoints than the hardcoded default which is most of the time the registry OT&E server,
and not the production one !

=head3 add registry=REGISTRYNAME client_id=YOURID name=profile1 type=epp client_login=YOURLOGIN client_password=YOURPASSWORD

This is a shortcut, doing the equivalent of add_registry, and then add_current_profile.

=head3 get_info_all

After each call to the registry, like domain_info or domain_check, this will list all available data
retrieved from registry. Things are pretty-printed as much as possible. You should call get_info_all
right after your domain_something call otherwise if you do another operation previous information
is lost. This is done automatically for you on the relevant commands, but you can also use it
manually at any time.

=head3 show profiles

Show the list of registries and associated profiles currently in use (opened in this shell with
add_registry + add_current_profile, or add).

=head3 show tlds

Show the list of TLDs handled by the currently selected registry.

=head3 show periods

Show the list of allowed periods (domain name durations) for the currently selected registry.

=head3 show objects

Show the list of managed objects types at the currently selected registry.

=head3 show types

Show the list of profile types at the currently selected registry

=head3 show status

Show the list of available status for the currently selected registry, to use
as status name in some commands below (domain_update_status_* domain_update 
host_update_status_* host_update contact_update_status_* contact_update).

=head3 show config

This will show all current config options. See C<set> command below for the list of config options.

=head3 set OPTION=VALUE

The set command can be used to change some options inside the shell.

The current list of available options is:

=head4 verbose

Set this option to 1 if you want a dump of all data retrieved from registry automatically after each operation, including failed ones, and including
all displaying raw data exchanged with registry.

=head3 target REGISTRYNAME PROFILENAME

Switch to registry REGISTRYNAME (from currently available registries) and profile PROFILENAME (from currently available
profiles in registry REGISTRYNAME).

=head3 run FILENAME

Will open the local FILENAME and read in it commands and execute all of them; you can also
start your shell with a filename as argument and its commands will be run at beginning of
session before giving the control back. They will be displayed (username and password will be
masked) with their results.

=head3 record FILENAME

If called with a filename argument, all subsequent commands, and their results will be printed in the filename given.
If called without argument, it stops a current recording session.

=head3 !cmd

All command line starting with a bang (!) will be treated as local commands to run through the local underlying OS shell.

Example: !ls -l
will display the content of the current directory.

=head3 help

Returns a succinct list of available commands.

=head3 quit

Leave the shell.

=head2 DOMAIN COMMANDS

=head3 domain_create DOMAIN [duration=X] [ns=HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...] [admin=SRID1] [registrant=SRID2] [billing=SRID3] [tech=SRID4] [auth=X]

Create the given domain name. See above for the duration format to use. Admin, registrant, billing and tech
contact ids are mandatory or optional depending on the registry. They may be repeated (except registrant)
for registries allowing multiple contacts per role.

=head3 domain_info DOMAIN

Do a domain_info call to the registry for the domain YOURDOMAIN ; most of the the registries
prohibit getting information on domain names you do not sponsor.

=head3 domain_check DOMAIN

Do a domain_check call to the registry for the domain ANYDOMAIN ; you can check any domain,
existing or not, if you are the sponsoring registrar or not.

=head3 domain_exist DOMAIN

A kind of simpler domain_check, just reply by YES or NO for the given domain name.

=head3 domain_transfer_start DOMAIN auth=AUTHCODE [duration=PERIOD]

=head3 domain_transfer_stop DOMAIN [auth=AUTHCODE]

=head3 domain_transfer_query DOMAIN [auth=AUTHCODE]

=head3 domain_transfer_accept DOMAIN [auth=AUTHCODE]

=head3 domain_transfer_refuse DOMAIN [auth=AUTHCODE]

Start, or stop an incoming transfer, query status of a current running transfer, accept or refuse an outgoing domain name transfer.

The AUTHCODE is mandatory or optional, depending on the registry.

The duration is optional and can be specified (the allowed values depend on the registry) as Ayears or Bmonths
where A and B are integers for the number of years or months (this can be abbreviated as Ay or Bm).

=head3 domain_update_ns_set DOMAIN HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...

=head3 domain_update_ns_add DOMAIN HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...

=head3 domain_update_ns_del DOMAIN HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...

Set the current list of nameservers associated to this DOMAIN, add to the current list or delete from the current list.

=head3 domain_update_status_set DOMAIN STATUS1 STATUS2 ...

=head3 domain_update_status_add DOMAIN STATUS1 STATUS2 ...

=head3 domain_update_status_del DOMAIN STATUS1 STATUS2 ...

Set the current list of status associated to this DOMAIN, add to the current
list or delete from the current list. First parameter is the domain name, then status names,
as needed.

The status names are those in the list given back by the show status command (see above).

=head3 domain_update_contact_set DOMAIN SRVID1 SRVID2 ...

=head3 domain_update_contact_add DOMAIN SRVID2 SRVID2 ...

=head3 domain_update_contact_del DOMAIN SRVID1 SRVID2 ...

Set the current list of contacts associated to this DOMAIN, add to the current list or delete from the current list
by providing the contact server ids.

=head3 domain_update DOMAIN +status=S1 -status=S2 +admin=C1 -tech=C2 -billing=C3 registrant=C4 auth=A +ns=... -ns=...

Combination of the previous methods, plus ability to change authInfo and other parameters depending on registry.

=head3 domain_renew DOMAIN [duration=X] [current_expiration=YYYY-MM-DD]

Renew the given domain name. Duration and current expiration are optional. See above for the duration format to use.

=head3 domain_delete DOMAIN

Delete the given domain name.


=head2 HOST COMMANDS

For registries handling nameservers as separate objects.

=head3 host_create HOSTNAME IP1 IP2 ...

Create the host named HOSTNAME at the registry with the list of IP (IPv4 and IPv6
depending on registry support) given.

=head3 host_delete HOSTNAME

=head3 host_info HOSTNAME

=head3 host_check HOSTNAME

Various operations on host objects.

=head3 host_update_ip_set HOSTNAME IP1 IP2 ...

=head3 host_update_ip_add HOSTNAME IP1 IP2 ...

=head3 host_update_ip_del HOSTNAME IP1 IP2 ...

Set the current list of IP addresses associated to this HOSTNAME, add to the current
list or delete from the current list. First parameter is the nameserver hostname, then IP addresses,
as needed.

=head3 host_update_status_set HOSTNAME STATUS1 STATUS2 ...

=head3 host_update_status_add HOSTNAME STATUS1 STATUS2 ...

=head3 host_update_status_del HOSTNAME STATUS1 STATUS2 ...

Set the current list of status associated to this HOSTNAME, add to the current
list or delete from the current list. First parameter is the nameserver hostname, then status names,
as needed.

The status names are those in the list given back by the show status command (see above).

=head3 host_update HOSTNAME +ip=IP1 +ip=IP2 -ip=IP3 +status=STATUS1 -status=STATUS2 name=NEWNAME

Combines the previous operations.

=head3 host_update_name_set HOSTNAME NEWNAME

Change the current name of host objects from HOSTNAME to NEWNAME.


=head2 CONTACT COMMANDS

For registries handling contacts as separate objects.

=head3 contact_create name=X org=Y street=Z1 street=Z2 email=A voice=B ...

Create a new contact object.

The list of mandatory attributes depend on the registry. Some attributes (like street) may appear multiple times.

Some registry allow setting an ID (using srid=yourchoice), others create the ID, in which case you need
to do a get_info_all after contact_create to retrieve the given server ID.

=head3 contact_delete SRID

=head3 contact_info SRID

=head3 contact_check SRID

Various operations on contacts.

=head3 contact_update_status_set SRID STATUS1 STATUS2 ...

=head3 contact_update_status_add SRID STATUS1 STATUS2 ...

=head3 contact_update_status_del SRID STATUS1 STATUS2 ...

Set the current list of status associated to this contact SRID, add to the current
list or delete from the current list. First parameter is the contact server ID, then status names,
as needed.

The status names are those in the list given back by the show status command (see above).

=head3 contact_update SRID name=X org=Y ... +status=... -status=...

Change some contacts attributes, as well as statuses.

=head3 contact_transfer_start SRID

=head3 contact_transfer_stop SRID

=head3 contact_transfer_query SRID

=head3 contact_transfer_accept SRID

=head3 contact_transfer_refuse SRID

Start, or stop an incoming transfer, query status of a current running transfer, accept or refuse an outgoing contact transfer.


=head2 MESSAGE COMMANDS

For registries handling messages, like EPP poll features.

=head3 message_retrieve [ID]

Retrieve a message waiting at registry.

=head3 message_delete [ID]

Delete a message waiting at registry.

=head3 message_waiting

Notifies if messages are waiting at registry.

=head3 message_count

Get the numbers of messages waiting at the registry.

=head1 COMPLETION

If Term::Readline::Gnu or Term::Readline::Perl are installed, it will be automatically used by this shell 
to provide standard shell autocompletion for commands and parameters.

All commands described above will be available through autocompletion. As you use them,
all parameters (domain names, contacts, hostnames, local files) will also be stored
and provided to later autocompletion calls (with the [TAB] key).

It will also autocomplete registry= and type= parameters during add/add_registry, from
a basic default set of values: registry= values are taken from a basic Net::DRI install
without taking into account any private DRD module, and type= values are a default set,
not checked against registry= value.
Same for target calls, where registry and/or profile name will be autocompleted as possible.

It will even autocomplete TLD on domain names for your current registry after your typed
the first label and a dot (and eventually some other characters), during any domain name operation.
Same for durations and status values.

Contacts and nameservers will also be autocompleted when used in any domain_* operation.

Contacts attributes will be autocompleted during contact_create based on the current registry & profile.

Information retrieved with domain_info calls will also be used in later autocompletion tries,
regarding contact ids and hostnames. During a contact creation, the registry returned contact id
is also added for later autocompletion tries.

For autocompletion, contacts are specific to each registry. Hostnames are common to all registries,
as are domain names, but domain names are checked against the available TLDs of the current registry when used 
for autocompletion.

=head1 LOGGING

By default, all operations will have some logging information done in files stored in
the working directory. There will be a core.log file for all operations and then one
file per tuple (registry,profile).

=head1 BATCH OPERATIONS

Batch operations are available for some domain name commands: domain_create,
domain_delete, domain_renew, domain_check, domain_info, domain_transfer and
all domain_update commands. It can be used on a list of domain names for which
all other parameters needed by the command are the same.

To do that, just use the command normally as outlined above, but instead of the
domain name, put a file path, with at least one / (so for a file "batch.txt" in the
current directory, use "./batch.txt").

If you use backticks such as `command` for the domain name, the command will 
be started locally and its output will be used just like a file.

The shell will then apply the command and its parameters on the domain names
listed in the specified file: you should have one domain name per line, blank
lines and lines starting with # are ignored.

At the same place a new file is created with a name derived from the given name
in which the result of each domain name command will be written. If "input" is 
the filename used, the results will be written to "input.PID.TIME.results"
where PID is the program id of the running shell for these commands and TIME the
Unix epoch when the batch started.

As output the shell will give a summary of the number of operations done
for each possible outcome (success or error), as well as time statistics.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub run
{
 my (@args)=@_;
 my $term=Term::ReadLine->new('Net::DRI shell');
 $term->MinLine(undef); # disable implicit add_history call()
 my $ctx={ term    => $term,
           term_features => $term->Features(),
           term_attribs => $term->Attribs(),
           dprompt => 'NetDRI',
           output  => $term->OUT() || \*STDOUT,
           record_filename => undef,
           record_filehandle => undef,
           config => { verbose => 0 },
           completion => { domains => {}, contacts => {}, hosts => {}, files => {} },
         };
 if (exists $ctx->{term_features}->{ornaments}) { $term->ornaments(1); }
 $ctx->{term_attribs}->{completion_function}=sub { return complete($ctx,@_); };
 $ctx->{prompt}=$ctx->{dprompt};

 output($ctx,"Welcome to Net::DRI ${Net::DRI::VERSION} shell, pid $$\n");

 $ctx->{dri}=Net::DRI->new({cache_ttl => 10,logging=>['files',{level => 'info',sanitize_data => {session_password => 0}}]});
 output($ctx,"Net::DRI object created with a cache TTL of 10 seconds and logging into files in current directory\n\n");

 if (exists $ctx->{term_features}->{readHistory} && defined $HISTORY)
 {
  $term->ReadHistory($HISTORY);
 }

 $ctx->{file_quit}=0;
 shift(@args) if (@args && $args[0] eq 'Net::DRI::Shell');
 handle_line($ctx,'run '.$args[0]) if (@args);

 unless ($ctx->{file_quit})
 {
  delete($ctx->{file_quit});
  while (defined(my $l=$ctx->{term}->readline($ctx->{prompt}.'> '))) 
  {
   last if handle_line($ctx,$l);
  }
 }

 if (exists $ctx->{term_features}->{writeHistory} && defined $HISTORY)
 {
  $term->WriteHistory($HISTORY);
 }

 $ctx->{dri}->end();
 return 0; ## TODO : should reflect true result of last command ?
}

sub output
{
 my (@args)=@_;
 my $ctx=shift;
 print { $ctx->{output} } @args;
 output_record($ctx,@args);
 return;
}

sub output_record
{
 my ($ctx,@args)=@_;
 return unless defined($ctx->{record_filehandle});
 return if (@args==1 && ($args[0] eq '.' || $args[0] eq "\n"));
 my $l=$ctx->{last_line};
 print { $ctx->{record_filehandle} } scalar(localtime(time)),"\n\n",(defined($l)? ($l,"\n\n") : ('')),@args,"\n\n";
 $ctx->{last_line}=undef;
 return;
}

sub handle_file
{
 my ($ctx,$file)=@_;
 output($ctx,'Executing commands from file '.$file." :\n");
 $ctx->{completion}->{files}->{$file}=time();
 open(my $ch,'<',$file) or die "Unable to open $file : $!"; ## no critic (InputOutput::RequireBriefOpen)
 while(defined(my $l=<$ch>))
 {
  chomp($l);
  next if ($l=~m/^\s*$/ || $l=~m/^#/);
  my $pl=$l;
  $pl=~s/(client_id|client_login|client_password)=\S+/$1=********/g;
  output($ctx,$pl."\n");
  if (handle_line($ctx,$l))
  {
   $ctx->{file_quit}=1;
   last;
  }
 }
 close($ch) or die $!;
 return;
}

sub handle_line
{
 my ($ctx,$l)=@_;
 return 0 if ($l=~m/^\s*$/);

 $l=~s/^\s*//;
 $l=~s/\s*$//;

 return 1 if ($l eq 'quit' || $l eq 'q' || $l eq 'exit');

 my ($rc,$msg);

 my $ok=eval
 {
  ($rc,$msg)=process($ctx,$l);
  $msg.="\n".dump_info($ctx,scalar $rc->get_data_collection()) if (defined($rc) && (($l=~m/^(?:(?:domain|contact|host)_?(?:check|info|create)|domain_renew) / && (!defined($msg) || index($msg,'on average')==-1) && $rc->is_success()) || $ctx->{config}->{verbose}==1));
  1;
 };
 $ctx->{last_line}=$l;
 if (! $ok)
 {
  my $err=$@;
  $err='XML error: '.$err->as_string() if ref $err eq 'XML::LibXML::Error';
  output($ctx,"An error happened:\n",ref $err ? $err->msg() : $err,"\n");
 } else
 {
  my @r;
  if (defined($rc))
  {
   push @r,scalar $rc->as_string(1),"\n";
  }
  push @r,$msg if (defined($msg));
  if (defined($rc) && $rc->is_closing() && $ctx->{dri}->transport()->has_state())
  {
   $ctx->{dri}->transport()->current_state(0);
   push @r,'Server connection closed, will try to reconnect during next command.'; ## TODO : this is triggered also for type=das, but shouldn't !
  }
  output($ctx,@r,"\n");
 }

 $ctx->{term}->addhistory($l);
 $ctx->{last_line}=undef;
 return 0;
}

sub complete
{
 my ($ctx,$text,$line,$start)=@_; ## $text is last space separated word, $line the whole line, $start the position of the cursor in the line

 ## Command completion
 if ($start==0) ## command completion
 {
  my @r=sort { $a cmp $b } grep { /^$text/ } qw/quit exit help run record message_retrieve message_delete domain_create domain_renew domain_delete domain_check domain_info domain_transfer_start domain_transfer_stop domain_transfer_query domain_transfer_accept domain_transfer_refuse domain_update_ns_set domain_update_ns_add domain_update_ns_del domain_update_status_set domain_update_status_add domain_update_status_del domain_update_contact_set domain_update_contact_add domain_update_contact_del domain_update host_create host_delete host_info host_check host_update_ip_set host_update_ip_add host_update_ip_del host_update_status_set host_update_status_add host_update_status_del host_update_name_set host_update contact_create contact_info contact_check contact_delete contact_update contact_update_status_set contact_update_status_add contact_update_status_del contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse set add add_registry target add_current_profile add_profile show get_info get_info_all message_waiting message_count domain_exist/;
  return @r;
 }

 ## Parameter completion
 my ($cmd)=($line=~m/^(\S+)\s/);
 if ($cmd eq 'show') { my @r=sort { $a cmp $b } grep { /^$text/ } qw/profiles tlds periods objects types status config/; return @r; }
 if ($cmd eq 'set')  { return map { $_.'=' } sort { $a cmp $b } grep { /^$text/ } keys(%{$ctx->{config}}); }
 if ($cmd eq 'run' || $cmd eq 'record') { my @r=sort { $ctx->{completion}->{files}->{$b} <=> $ctx->{completion}->{files}->{$a} || $a cmp $b } grep { /^$text/ } keys(%{$ctx->{completion}->{files}}); return @r; }

 if ($cmd eq 'add' || $cmd eq 'add_registry' || $cmd eq 'add_current_profile' || $cmd eq 'add_profile')
 {
  if (substr($line,$start-9,9) eq 'registry=')
  {
   my ($reg)=($text=~m/registry=(\S*)/);
   $reg||='';
   my @r=sort { $a cmp $b } grep { /^$reg/ } $ctx->{dri}->installed_registries();
   return @r;
  } elsif (substr($line,$start-5,5) eq 'type=')
  {
   my ($type)=($text=~m/type=(\S*)/);
   $type||='';
   my @r=sort { $a cmp $b } grep { /^$type/ } (defined $ctx->{dri}->registry_name()? $ctx->{dri}->registry()->driver()->profile_types() : qw/epp rrp rri dchk whois das ws/);
   return @r;
  } else
  {
   my @p;
   @p=qw/registry client_id/ if $cmd eq 'add_registry';
   @p=qw/type name/ if ($cmd=~m/^add_(?:current_)?profile$/);
   @p=qw/registry client_id type name/ if $cmd eq 'add';
   return map { $_.'=' } grep { /^$text/ } @p;
  }
 }

 if ($cmd eq 'target')
 {
  my $regs=$ctx->{dri}->available_registries_profiles(0);
  if (my ($reg)=($line=~m/^target\s+(\S+)\s+\S*$/))
  {
   my @r=sort { $a cmp $b } grep { /^$text/ } (exists $regs->{$reg} ? @{$regs->{$reg}} : ());
   return @r;
  } elsif ($line=~m/^target\s+\S*$/)
  {
   my @r=sort { $a cmp $b } grep { /^$text/ } keys(%$regs);
   return @r;
  }
 }

 if (substr($line,$start-9,9) eq 'duration=')
 {
  return () unless defined $ctx->{dri}->registry_name();
  my ($p)=($text=~m/duration=(\S*)/);
  $p||='';
  my %p;
  foreach my $pd ($ctx->{dri}->registry()->driver()->periods())
  {
   my $d=$pd->in_units('years');
   if ($d > 0) { $p{$d.'Y'}=12*$d; next; }
   $d=$pd->in_units('months');
   if ($d > 0) { $p{$d.'M'}=$d; next; }
  }
  my @r=sort { $p{$a} <=> $p{$b} } grep { /^$p/ } keys(%p); ## this is the correct ascending order, but it seems something else upstream is reordering it differently
  return @r;
 }

 if ($line=~m/^domain_\S+\s+\S*$/)
 {
  my @p=grep { /^$text/ } keys(%{$ctx->{completion}->{domains}});
  if (defined $ctx->{dri}->registry())
  {
   my @tlds=$ctx->{dri}->registry()->driver()->tlds();
   my $tlds=join('|',map { quotemeta($_) } @tlds);
   @p=grep { /\.(?:$tlds)$/i } @p;
   my $idx=index($text,'.');
   if ( $idx >= 0 )
   {
    my $base=substr($text,0,$idx);
    push @p,map { $base.'.'.$_ } @tlds;
   }
  }
  my @r=sort { ( $ctx->{completion}->{domains}->{$b} || 0) <=> ( $ctx->{completion}->{domains}->{$a} || 0 ) || $a cmp $b } @p;
  return @r;
 }

 my @ct=qw/registrant admin tech billing/; ## How to retrieve non core contact types ?
 my $capa;
 if ($ctx->{dri}->registry_name() && $ctx->{dri}->available_profile() && $ctx->{dri}->protocol())
 {
  @ct=('registrant',$ctx->{dri}->protocol()->core_contact_types()) if $ctx->{dri}->protocol()->can('core_contact_types');
  $capa=$ctx->{dri}->protocol()->capabilities();
 }
 my $ctre=join('|',@ct);

 if ($cmd eq 'domain_create') ## If we are here, we are sure the domain name has been completed already, due to previous test block
 {
  if (substr($line,$start-3,3) eq 'ns=')
  {
   my ($ns)=($text=~m/ns=(\S*)/);
   $ns||='';
   return _complete_hosts($ctx,$ns);
  } elsif (grep { substr($line,$start-(1+length($_)),1+length($_)) eq $_.'=' } @ct)
  {
   my ($c)=($text=~m/(?:${ctre})=(\S*)/);
   $c||='';
   return _complete_contacts($ctx,$c);
  } else
  {
   return map { $_.'=' } grep { /^$text/ } (qw/duration ns auth/,@ct);
  }
 }

 if ($cmd eq 'domain_update') ## see previous comment
 {
  if (substr($line,$start-4,4)=~m/^[-+]ns=$/)
  {
   my ($ns)=($text=~m/ns=(\S*)/);
   $ns||='';
   return _complete_hosts($ctx,$ns);
  } elsif (grep { substr($line,$start-(1+length($_)),1+length($_)) eq $_.'=' } @ct) #####
  {
   my ($c)=($text=~m/(?:${ctre})=(\S*)/);
   $c||='';
   return _complete_contacts($ctx,$c);
  } elsif (substr($line,$start-8,8)=~m/^[-+]status=$/)
  {
   my $o=$ctx->{dri}->local_object('status');
   if (! defined $o) { return (); }
   my ($s)=($text=~m/status=(\S*)/);
   $s||='';
   my @r=sort { $a cmp $b } grep { /^$s/ } map { 'no'.$_ } $o->possible_no();
   return @r;
  } else
  {
   $text=~s/\+/[+]/g;
   return map { $_.'=' } sort { $a cmp $b } grep { /^$text/ } (map { if (/^([+-])contact$/) { map { $1.$_ } @ct } else { $_; } } _complete_capa2list($capa,'domain_update'));
  }
 }

 if ($line=~m/^domain_update_ns_\S+\s+\S+\s+\S*/) { return _complete_hosts($ctx,$text); }

 if ($line=~m/^(?:domain|host|contact)_update_status_\S+\s+\S+\s+\S*/)
 {
  my $o=$ctx->{dri}->local_object('status');
  if (! defined $o) { return (); }
  my @r=sort { $a cmp $b } grep { /^$text/ } map { 'no'.$_ } $o->possible_no();
  return @r;
 }

 if ($line=~m/^domain_update_contact_\S+\s+\S+\s+\S*/) { return _complete_contacts($ctx,$text); }

 if (my ($trans)=($line=~m/^domain_transfer_(\S+)\s+\S+\s+\S*/))
 {
  my @p=qw/auth/;
  push @p,'duration' if $trans eq 'start';
  return map { $_.'=' } sort { $a cmp $b } grep { /^$text/ } @p;
 }

 if ($cmd eq 'contact_create')
 {
  return () unless (defined $ctx->{dri}->registry_name() && defined $ctx->{dri}->profile());
  my $c=$ctx->{dri}->local_object('contact');
  if (! defined $c) { return (); }
  return map { $_.'=' } sort { $a cmp $b } grep { /^$text/ } $c->attributes();
 }

 if ($line=~m/^contact_\S+\s+\S*$/) { return _complete_contacts($ctx,$text); }

 if ($cmd eq 'contact_update')
 {
  return () unless (defined $ctx->{dri}->registry_name() && defined $ctx->{dri}->profile());
  my $c=$ctx->{dri}->local_object('contact');
  $text=~s/\+/[+]/g;
  return map { $_.'=' } sort { $a cmp $b } grep { /^$text/ } (defined $c ? $c->attributes() : (),_complete_capa2list($capa,'contact_update'));
 }

 if ($line=~m/^host_\S+\s+\S*$/) { return _complete_hosts($ctx,$text); }
 if (my ($h)=($line=~m/^host_update_name_set\s+\S+\s+(\S*)$/)) { return _complete_hosts($ctx,$h); }
 if ($cmd eq 'host_update')
 {
  if (substr($line,$start-5,5) eq 'name=')
  {
   my ($ns)=($text=~m/name=(\S*)/);
   $ns||='';
   return _complete_hosts($ctx,$ns);
  } elsif ( substr($line,$start-8,8)=~m/^[-+]status=$/ )
  {
   my $o=$ctx->{dri}->local_object('status');
   if (! defined $o) { return (); }
   my ($s)=($text=~m/status=(\S*)/);
   $s||='';
   my @r=sort { $a cmp $b } grep { /^$s/ } map { 'no'.$_ } $o->possible_no();
   return @r;
  } else
  {
   $text=~s/\+/[+]/g;
   return map { $_.'=' } sort { $a cmp $b } grep { /^$text/ } (_complete_capa2list($capa,'host_update'));
  }
 }

 return ();
}

sub _complete_capa2list
{
 my ($capa,$what)=@_;
 return () unless (defined $capa && exists($capa->{$what}));
 my @r;
 while(my ($k,$ra)=each(%{$capa->{$what}}))
 {
  foreach my $t (@$ra)
  {
   if ($t eq 'add') { push @r,'+'.$k; } elsif ($t eq 'del') { push @r,'-'.$k; } elsif ($t eq 'set') { push @r,$k; }
  }
 }
 return @r;
}

sub _complete_hosts    { my ($ctx,$text)=@_; my @r=sort { $ctx->{completion}->{hosts}->{$b} <=> $ctx->{completion}->{hosts}->{$a} || $a cmp $b } grep { /^$text/ } keys(%{$ctx->{completion}->{hosts}}); return @r; }
sub _complete_contacts
{
 my ($ctx,$text)=@_;
 my @c=grep { /^$text/ } keys(%{$ctx->{completion}->{contacts}});
 my $creg=$ctx->{dri}->registry_name();
 if (defined $creg) { @c=grep { defined $ctx->{completion}->{contacts}->{$_}->[1] && $ctx->{completion}->{contacts}->{$_}->[1] eq $creg } @c; } ## Filtering per registry
 my @r=sort { $ctx->{completion}->{contacts}->{$b}->[0] <=> $ctx->{completion}->{contacts}->{$a}->[0] || $a cmp $b } @c;
 return @r;
}

sub process
{
 my ($ctx,$wl)=@_;
 my ($rc,$m);

 my ($cmd,$params)=split(/\s+/,$wl,2);
 $params='' unless defined($params);
 my @p=split(/\s+/,$params);
 my %p;
 my @g=($params=~m/\s*(\S+)=(\S[^=]*)(?:\s|$)/g);
 while (@g)
 {
  my $n=shift(@g);
  my $v=shift(@g);
  if (exists($p{$n}))
  {
   $p{$n}=[$p{$n}] unless (ref($p{$n}) eq 'ARRAY');
   push @{$p{$n}},$v;
  } else
  {
   $p{$n}=$v;
  }
 }

 foreach my $k (grep { /\./ } keys(%p))
 {
  my ($tk,$sk)=split(/\./,$k,2);
  $p{$tk}={} unless exists($p{$tk});
  $p{$tk}->{$sk}=$p{$k};
  delete($p{$k});
 }

 return do_local($ctx,$cmd,\@p,\%p) if ($cmd=~m/^!/);
 return help($ctx,$cmd,\@p,\%p) if ($cmd eq 'help');
 return handle_file($ctx,$p[0]) if ($cmd eq 'run');
 return record($ctx,$p[0])      if ($cmd eq 'record');
 return do_dri($ctx,$cmd,\@p,\%p) if ($cmd=~m/^message_(?:retrieve|delete)$/ || $cmd eq 'ping');
 return do_domain($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_(?:check)$/);
 return do_domain_transfer($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_transfer_(?:start|stop|query|accept|refuse)$/);
 return do_domain_update($ctx,$cmd,\@p,\%p) if ($cmd eq 'domain_update');
 return do_domain_update_ns($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_update_ns_(?:add|del|set)$/);
 return do_domain_update_status($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_update_status_(?:add|del|set)$/);
 return do_domain_update_contact($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_update_contact_(?:add|del|set)$/);

 if ($cmd eq 'domain_info')
 {
  my @r=do_domain($ctx,$cmd,\@p,\%p);
  if (defined $r[0] && $r[0]->is_success())
  {
   my $ns=$ctx->{dri}->get_info('ns');
   if (defined $ns) { foreach my $name ($ns->get_names()) { $ctx->{completion}->{hosts}->{$name}=time(); } }
   $ns=$ctx->{dri}->get_info('host');
   if (defined $ns) { foreach my $name ($ns->get_names()) { $ctx->{completion}->{hosts}->{$name}=time(); } }
   my $cs=$ctx->{dri}->get_info('contact');
   if (defined $cs)
   {
    foreach my $t ($cs->types())
    {
     foreach my $cc ($cs->get($t)) { $ctx->{completion}->{contacts}->{$cc->srid()}=[time(),$ctx->{dri}->registry_name()]; }
    }
   }
  }
  return @r;
 }

 if ($cmd=~m/^host_(?:create|delete|info|check|update|update_(?:ip|status|name)_(?:add|del|set))$/)
 {
  return (undef,'Registry does not support host objects') unless $ctx->{dri}->has_object('ns');
  return do_host($ctx,$cmd,\@p,\%p);
 }

 if ($cmd=~m/^contact_(?:create|delete|info|check|update|update_status_(?:add|del|set)|transfer_(?:start|stop|query|accept|refuse))$/)
 {
  return (undef,'Registry does not support contact objects') unless $ctx->{dri}->has_object('contact');
  my @r=do_contact($ctx,$cmd,\@p,\%p);
  if ($cmd eq 'contact_create' && defined $r[0] && $r[0]->is_success())
  {
   my $id=$ctx->{dri}->get_info('id');
   if (defined $id) { $ctx->{completion}->{contacts}->{$id}=[time(),$ctx->{dri}->registry_name()]; }
  }
  return @r;
 }

 {
  no strict 'refs'; ## no critic (ProhibitNoStrict)
  my $sub='do_'.$cmd;
  return $sub->($ctx,$cmd,\@p,\%p) if (exists(&$sub));
 }

 ## Fallback for all domain extension commands
 return do_domain_extension($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_\S+/);

 return (undef,'Unknown command '.$cmd);
}

sub do_local
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 $cmd=~s/^!//;
 my $s=$cmd.' '.join(' ',@$ra);
 my $out=qx($s);
 return (undef,defined($out)? $out : 'Local command failed: '.$!);
}

sub help
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $m=<<EOF;
Available commands (parameters after the first one can be in any order):

help
add registry=REGISTRYNAME type=TYPE [client_id=YOURLOGIN]
add_registry registry=REGISTRYNAME [client_id=YOURLOGIN]
add_current_profile name=PROFILENAME type=TYPE client_login=YOURLOGIN client_password=YOURPASSWORD
get_info_all
show profiles
show tlds
show periods
show objects
show status
show config
set P=X
target X Y
run FILENAME
record FILENAME
quit
domain_create DOMAIN [duration=X] [ns=HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...] [admin=SRID1] [registrant=SRID2] [billing=SRID3] [tech=SRID4] [auth=X]
domain_info DOMAIN
domain_check DOMAIN
domain_exist DOMAIN
domain_transfer_start DOMAIN auth=AUTHCODE [duration=PERIOD]
domain_transfer_stop DOMAIN [auth=AUTHCODE]
domain_transfer_query DOMAIN [auth=AUTHCODE]
domain_transfer_accept DOMAIN [auth=AUTHCODE]
domain_transfer_refuse DOMAIN [auth=AUTHCODE]
domain_update_ns_set DOMAIN HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...
domain_update_ns_add DOMAIN HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...
domain_update_ns_del DOMAIN HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...
domain_update_status_set DOMAIN STATUS1 STATUS2 ...
domain_update_status_add DOMAIN STATUS1 STATUS2 ...
domain_update_status_del DOMAIN STATUS1 STATUS2 ...
domain_update_contact_set DOMAIN SRVID1 SRVID2 ...
domain_update_contact_add DOMAIN SRVID2 SRVID2 ...
domain_update_contact_del DOMAIN SRVID1 SRVID2 ...
domain_update DOMAIN +status=S1 -status=S2 +admin=C1 -tech=C2 -billing=C3 registrant=C4 auth=A +ns=... -ns=...
domain_renew DOMAIN [duration=X] [current_expiration=YYYY-MM-DD]
domain_delete DOMAIN
host_create HOSTNAME IP1 IP2 ...
host_delete HOSTNAME
host_info HOSTNAME
host_check HOSTNAME
host_update_ip_set HOSTNAME IP1 IP2 ...
host_update_ip_add HOSTNAME IP1 IP2 ...
host_update_ip_del HOSTNAME IP1 IP2 ...
host_update_status_set HOSTNAME STATUS1 STATUS2 ...
host_update_status_add HOSTNAME STATUS1 STATUS2 ...
host_update_status_del HOSTNAME STATUS1 STATUS2 ...
host_update_name_set HOSTNAME NEWNAME
host_update HOSTNAME +ip=IP1 +ip=IP2 -ip=IP3 +status=STATUS1 -status=STATUS2 name=NEWNAME ...
contact_create name=X org=Y street=Z1 street=Z2 email=A voice=B ...
contact_delete SRID
contact_info SRID
contact_check SRID
contact_update_status_set SRID STATUS1 STATUS2 ...
contact_update_status_add SRID STATUS1 STATUS2 ...
contact_update_status_del SRID STATUS1 STATUS2 ...
contact_update SRID name=X org=Y ... +status=... -status=...
contact_transfer_start SRID
contact_transfer_stop SRID
contact_transfer_query SRID
contact_transfer_accept SRID
contact_transfer_refuse SRID
message_retrieve [ID]
message_delete [ID]
message_waiting
message_count
ping
EOF
 return (undef,$m);
}

sub record
{
 my ($ctx,$n)=@_;
 my $m='';

 ## Need to stop the current one in all cases ! (true record stop or a new record start)
 if (defined($ctx->{record_filehandle}))
 {
  close($ctx->{record_filehandle});
  $ctx->{record_filehandle}=undef;
  $m='Stopped recording session to '.$ctx->{record_filename}."\n";
 }

 if (defined($n) && $n)
 {
  $ctx->{completion}->{files}->{$n}=time();
  open(my $fh,'>',$n) or return (undef,$m.'Unable to write local file '.$n.' : '.$!); ## no critic (InputOutput::RequireBriefOpen)
  $fh->autoflush(1); ## this is thanks to IO::Handle
  $ctx->{record_filehandle}=$fh;
  $ctx->{record_filename}=$n;
  $m.='Started recording session to '.$ctx->{record_filename};
 }
 return (undef,$m? $m : 'Usage: record FILENAME (to start recording session to local FILENAME) or record (to stop current recording)');
}

## For local options, like verbose
sub do_set
{
 my($ctx,$cmd,$ra,$rh)=@_;
 $ctx->{config}={ %{$ctx->{config}},%$rh };
 return;
}

sub do_add
{
 my($ctx,$cmd,$ra,$rh)=@_;
 return (undef,'Usage: add registry=REGISTRYNAME type=PROTOCOLTYPE [client_id=ID] [name=PROFILENAME] [...]') unless (Net::DRI::Util::has_key($rh,'registry') && Net::DRI::Util::has_key($rh,'type'));
 my %r=(registry => $rh->{registry}, client_id => $rh->{client_id});
 my @r=do_add_registry($ctx,'add_registry',$ra,\%r);
 if (! defined $r[0] || ! $r[0]->is_success()) { return @r; }
 unless (exists($rh->{name}) && defined($rh->{name}))
 {
  my @p=$ctx->{dri}->available_profiles();
  $rh->{name}=lc($rh->{registry}).(1+@p);
 }
 delete($rh->{registry});
 delete($rh->{client_id});
 return do_add_current_profile($ctx,'add_current_profile',$ra,$rh);
}

sub do_add_registry
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 return (undef,'Usage: add_registry registry=REGISTRYNAME [client_id=ID]') unless Net::DRI::Util::has_key($rh,'registry');
 my $reg=$rh->{registry};
 delete($rh->{registry});
 if (! grep { $reg eq $_ } $ctx->{dri}->available_registries() ) { $ctx->{dri}->add_registry($reg,$rh); }
 $ctx->{dri}->target($reg);
 $ctx->{prompt}=$ctx->{dprompt}.'('.$reg.')';
 return (Net::DRI::Protocol::ResultStatus->new_success('Registry "'.$reg.'" added successfully'),undef);
}

sub do_target
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 $ctx->{dri}->target(@$ra);
 $ctx->{prompt}=$ctx->{dprompt}.'('.join(',',@$ra).')';
 return;
}

sub do_add_current_profile
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 return (undef,'Usage: '.$cmd.' name=PROFILENAME type=SERVICENAME [client_login=YOURLOGIN] [client_password=YOURPASSWORD]') unless (Net::DRI::Util::has_key($rh,'name') && Net::DRI::Util::has_key($rh,'type'));
 my $name=$rh->{name};
 my $type=$rh->{type};
 my $rp=defined $rh->{protocol}? $rh->{protocol} : {};
 delete(@{$rh}{qw/name type protocol/});
 my $rc=$ctx->{dri}->$cmd($name,$type,$rh,$rp);
 if ($rc->is_success() && $cmd eq 'add_current_profile')
 {
  my @t=$ctx->{dri}->registry();
  $ctx->{prompt}=$ctx->{dprompt}.'('.$t[0].','.$t[1]->profile().')';
 }
 return ($rc,undef);
}

sub do_add_profile { return do_add_current_profile(@_); } ## no critic (Subroutines::RequireArgUnpacking)

sub do_show
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $m='Usage: show profiles|tlds|periods|objects|types|status|config';
 return (undef,$m) unless @$ra;
 if ($ra->[0] eq 'profiles')
 {
  my $rp=$ctx->{dri}->available_registries_profiles(1);
  $m='';
  foreach my $reg (sort(keys(%$rp)))
  {
   $m.=$reg.': '.join(' ',@{$rp->{$reg}})."\n";
  }
 } elsif ($ra->[0] eq 'tlds')
 {
  $m=join("\n",$ctx->{dri}->registry()->driver()->tlds());
 } elsif ($ra->[0] eq 'periods' || $ra->[0] eq 'durations')
 {
  $m=join("\n",map { pretty_string($_,0); } $ctx->{dri}->registry()->driver()->periods());
 } elsif ($ra->[0] eq 'objects')
 {
  $m=join("\n",$ctx->{dri}->registry()->driver()->object_types());
 } elsif ($ra->[0] eq 'types')
 {
  $m=join("\n",$ctx->{dri}->registry()->driver()->profile_types());
 } elsif ($ra->[0] eq 'status')
 {
  my $o=$ctx->{dri}->local_object('status');
  $m=defined($o)? join("\n",map { 'no'.$_ } $o->possible_no()) : 'No status objects';
 } elsif ($ra->[0] eq 'config')
 {
  $m='';
  foreach my $k (sort(keys(%{$ctx->{config}})))
  {
   $m.=$k.'='.$ctx->{config}->{$k}."\n";
  }
 }
 return (undef,$m);
}

sub do_get_info
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $m=$ctx->{dri}->get_info(@$ra); 
 return (undef,pretty_string($m,0));
}

sub do_get_info_all
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $rp=$ctx->{dri}->get_info_all(@$ra);
 my $m='';
 foreach my $k (sort(keys(%$rp)))
 {
  $m.=$k.': '.pretty_string($rp->{$k},0)."\n";
 }
 return (undef,$m);
}

sub do_dri
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 return ($ctx->{dri}->$cmd(@$ra),undef);
}

sub do_message_waiting
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $e=$ctx->{dri}->$cmd(@$ra);
 return (undef,'Unable to find if messages are waiting at the registry') unless defined($e);
 return (undef,'Messages waiting at the registry? '.($e? 'YES' : 'NO'));
}

sub do_message_count
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $e=$ctx->{dri}->$cmd(@$ra);
 return (undef,'Unable to find the number of messages waiting at the registry') unless defined($e);
 return (undef,'Number of messages waiting at the registry: '.$e);
}

## Try to handle all domain commands defined in extensions, with some heuristics
sub do_domain_extension
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 build_auth($rh);
 build_duration($ctx,$rh);
 $rh->{status}=build_status($ctx,ref $rh->{status}? $rh->{status} : [ $rh->{status} ] ) if exists($rh->{status});
 $rh->{contact}=build_contactset($ctx,$rh->{contact}) if (exists $rh->{contact});
 return wrap_command_domain($ctx,$cmd,$dom,$rh);
}

sub do_domain
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 return wrap_command_domain($ctx,$cmd,$dom,$rh);
}

sub do_domain_exist
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=lc($ra->[0]);
 $ctx->{completion}->{domains}->{$dom}=time();
 my $e=$ctx->{dri}->$cmd($dom);
 return (undef,'Unable to find if domain name '.$dom.' exists') unless defined($e);
 return (undef,'Does domain name '.$dom.' exists at registry? '.($e? 'YES' : 'NO'));
}

sub do_domain_transfer
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 build_auth($rh);
 build_duration($ctx,$rh);
 $rh->{contact}=build_contactset($ctx,$rh->{contact}) if exists $rh->{contact}; ## Some registries need contacts during transfer, this is not core EPP, but it does not create drawbacks, so we support it here
 return wrap_command_domain($ctx,$cmd,$ra->[0],$rh);
}

sub do_domain_update
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 my $toc=$ctx->{dri}->local_object('changes');
 my ($radd,$rdel,$rset)=build_update($ctx,$rh);
 foreach my $k (keys %$radd) { $toc->add($k,$radd->{$k}); }
 foreach my $k (keys %$rdel) { $toc->del($k,$rdel->{$k}); }
 foreach my $k (keys %$rset) { $toc->set($k,$rset->{$k}); }
 return wrap_command_domain($ctx,$cmd,$dom,$toc);
}

sub do_domain_update_ns
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 my $ns=build_hosts($ctx,$ra);
 return wrap_command_domain($ctx,$cmd,$dom,$ns);
}

sub do_domain_update_status
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 my $s=build_status($ctx,$ra);
 return wrap_command_domain($ctx,$cmd,$dom,$s);
}

sub do_domain_update_contact
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 my $cs=$ctx->{dri}->local_object('contactset');
 while(my ($type,$ids)=each(%$rh))
 {
  foreach my $id (ref($ids)? @$ids : ($ids))
  {
   $cs->add($ctx->{dri}->local_object('contact')->srid($id),$type);
   $ctx->{completion}->{contacts}->{$id}=[time(),$ctx->{dri}->registry_name()];
  }
 }
 return wrap_command_domain($ctx,$cmd,$dom,$cs);
}

sub do_domain_create
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 build_duration($ctx,$rh);
 build_auth($rh);
 $rh->{ns}=build_hosts($ctx,[split(/\s+/,ref $rh->{ns} ? join(' ',@{$rh->{ns}}) : $rh->{ns})]) if exists($rh->{ns});
 my @ct=qw/registrant admin tech billing/; ## How to retrieve non core contact types ?
 @ct=('registrant',$ctx->{dri}->protocol()->core_contact_types()) if ($ctx->{dri}->protocol() && $ctx->{dri}->protocol()->can('core_contact_types'));
 my %c;
 foreach my $t (@ct)
 {
  next unless exists $rh->{$t};
  $c{$t}=$rh->{$t};
  delete $rh->{$t} ;
 }
 $rh->{contact}=build_contactset($ctx,\%c) if (%c);
 $rh->{pure_create}=1;
 return wrap_command_domain($ctx,$cmd,$dom,$rh);
}

sub do_domain_renew
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 build_duration($ctx,$rh);
 if (exists($rh->{current_expiration}))
 {
  my @t=split(/-/,$rh->{current_expiration});
  $rh->{current_expiration}=$ctx->{dri}->local_object('datetime','year' => $t[0], 'month' => $t[1], 'day' => $t[2]);
 }
 return wrap_command_domain($ctx,$cmd,$dom,$rh);
}

sub do_domain_delete
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 $rh->{pure_delete}=1;
 return wrap_command_domain($ctx,$cmd,$dom,$rh);
}

sub do_host
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my @p;
 if ($cmd eq 'host_create')
 {
  @p=build_hosts($ctx,$ra);
 } elsif ($cmd=~m/^host_update_ip_(?:add|del|set)$/)
 {
  my $h=shift(@$ra);
  @p=($h,build_hosts($ctx,[ $h, @$ra ]));
 } elsif ($cmd=~m/^host_update_status_(?:add|del|set)$/)
 {
  my $h=shift(@$ra);
  @p=($h,build_status($ctx,$ra));
 } elsif ($cmd eq 'host_update')
 {
  my $h=shift(@$ra);
  my $toc=$ctx->{dri}->local_object('changes');
  my ($radd,$rdel,$rset)=build_update($ctx,$rh);
  if (keys %$radd) { foreach my $k (keys %$radd) { if ($k eq 'ip') { $radd->{$k}=build_hosts($ctx,[$h,ref $radd->{$k} ? @{$radd->{$k}} : ($radd->{$k})]); } $toc->add($k,$radd->{$k}); } }
  if (keys %$rdel) { foreach my $k (keys %$rdel) { if ($k eq 'ip') { $rdel->{$k}=build_hosts($ctx,[$h,ref $rdel->{$k} ? @{$rdel->{$k}} : ($rdel->{$k})]); } $toc->del($k,$rdel->{$k}); } }
  if (keys %$rset) { foreach my $k (keys %$rset) { $toc->set($k,$rset->{$k}); } }
  $ctx->{completion}->{hosts}->{$rset->{'name'}}=time() if exists $rset->{'name'};
  @p=($h,$toc);
 } else
 {
  @p=@$ra;
 }
 $ctx->{completion}->{hosts}->{$p[0]}=time();
 $ctx->{completion}->{hosts}->{$p[1]}=time() if $cmd eq 'host_update_name_set';
 return ($ctx->{dri}->$cmd(@p),undef);
}

sub do_contact
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my @p;
 my $c=$ctx->{dri}->local_object('contact');
 build_auth($rh);
 if ($cmd eq 'contact_create')
 {
  $rh->{street}=[$rh->{street}] if (exists($rh->{street}) && !ref($rh->{street}));
  $rh->{srid}=$rh->{id} if (exists($rh->{id}) && ! exists($rh->{srid}));
  $rh->{srid}=$ra->[0] if (@$ra && $ra->[0]!~m/=/ && ! exists $rh->{srid});
  build_contact($ctx,$c,$rh);
 } elsif ($cmd=~m/^contact_update_status_(?:add|del|set)$/)
 {
  my $id=shift(@$ra);
  $c->srid($id);
  $ctx->{completion}->{contacts}->{$id}=[time(),$ctx->{dri}->registry_name()];
  @p=(build_status($ctx,$ra));
 } elsif ($cmd eq 'contact_update')
 {
  my $id=shift(@$ra);
  $c->srid($id);
  $ctx->{completion}->{contacts}->{$id}=[time(),$ctx->{dri}->registry_name()];
  my ($radd,$rdel,$rset)=build_update($ctx,$rh);
  my $toc=$ctx->{dri}->local_object('changes');
  if (keys %$rset)
  {
   my $c2=$ctx->{dri}->local_object('contact');
   build_contact($ctx,$c2,$rset);
   $toc->set('info',$c2);
  }
  if (keys %$radd) { foreach my $k (keys %$radd) { $toc->add($k,$radd->{$k}); } }
  if (keys %$rdel) { foreach my $k (keys %$rdel) { $toc->del($k,$rdel->{$k}); } }
  @p=($toc);
 } else
 {
  my $id=shift(@$ra);
  $c->srid($id);
  $ctx->{completion}->{contacts}->{$id}=[time(),$ctx->{dri}->registry_name()];
  @p=@$ra;
 }
 return ($ctx->{dri}->$cmd($c,@p),undef);
}

####################################################################################################

sub wrap_command_domain
{
 my ($ctx,$cmd,$dom,@args)=@_;
 return (undef,'Undefined domain name') unless defined $dom && length $dom;

 my ($fin,$fout,$res);
 if ($dom=~m/`.+`/) ## Local executable
 {
  $dom=~s/`(.+)`/$1/;
  $res=$cmd.'.'.$$.'.'.time().'.results'; ## TODO choose a predictable filename ? if so, use an option
  open($fin,'-|',$dom) or return (undef,'Unable to execute local command '.$dom.' : '.$!); ## no critic (InputOutput::RequireBriefOpen)
  open($fout,'>',$res) or return (undef,'Unable to write (for results) local file '.$res.' : '.$!); ## no critic (InputOutput::RequireBriefOpen)
 } elsif ($dom=~m!/!) ## Local file
 {
  return (undef,'Local file '.$dom.' does not exist or unreadable') unless (-e $dom && -r _);
  $res=$dom.'.'.$$.'.'.time().'.results'; ## see above
  open($fin,'<',$dom)  or return (undef,'Unable to read local file '.$dom.' : '.$!); ## no critic (InputOutput::RequireBriefOpen)
  open($fout,'>',$res) or return (undef,'Unable to write (for results) local file '.$res.' : '.$!); ## no critic (InputOutput::RequireBriefOpen)
 }

 unless (defined $fin && defined $fout) ## Pure unique domain name
 {
  $ctx->{completion}->{domains}->{$dom}=time();
  return (undef,'Invalid domain name: '.$dom) unless Net::DRI::Util::is_hostname($dom);
  return ($ctx->{dri}->$cmd(lc($dom),@args),undef);
 }

 my $withinfo=($cmd eq 'domain_check' || $cmd eq 'domain_info')? 1 : 0;
 my @rc;
 my $tstart=Time::HiRes::time();
 while(defined(my $l=<$fin>))
 {
  chomp($l);
  my @r=($l);
  $ctx->{completion}->{domains}->{$l}=time();
  if (Net::DRI::Util::is_hostname($l))
  {
   my $rc=$ctx->{dri}->$cmd(lc($l),@args);
   push @r,$rc->as_string(1);
   push @r,$ctx->{dri}->get_info_all() if $withinfo;
  } else
  {
   push @r,'Invalid domain name';
  }
  push @rc,\@r;
  output($ctx,'.');
 }
 my $tstop=Time::HiRes::time();
 output($ctx,"\n");
 close($fin);

 my %r;
 ## We write the whole file at the end for better performances (but we opened it right at the beginning to test its writability)
 foreach my $rc (@rc)
 {
  my $l=shift @$rc;
  my $rcm=shift @$rc;
  my ($rcms)=($rcm=~m/^([^\n]+)/);
  $rcm=~s/\n\t*/ /g;
  if ($cmd eq 'domain_check')
  {
   my $rh=shift @$rc;
   $rcm.=' | exist='.(defined $rh->{exist} ? $rh->{exist} : '?').' exist_reason='.(defined $rh->{exist_reason} ? $rh->{exist_reason} : ''); ## exist should always be defined !
  } elsif ($cmd eq 'domain_info')
  {
   my $rh=shift @$rc;
   $rcm.=' | '.join(' ',map { $_.'=['.pretty_string($rh->{$_},0).']' } qw/clID crDate exDate contact ns status auth/);
   if (exists $rh->{ns})      { foreach my $nsname ($rh->{ns}->get_names()) { $ctx->{completion}->{hosts}->{$nsname}=time(); } }
   if (exists $rh->{contact}) { foreach my $cid ($rh->{contact}->get_all()) { $ctx->{completion}->{contacts}->{$cid}=[time(),$ctx->{dri}->registry_name()]; } }
  }
  print { $fout } $l,' ',$rcm,"\n";
  $r{$rcms}++;
 }
 close($fout);

 my $t=@rc;
 my $m=join("\n",map { sprintf('%d/%d (%.02f%%) : %s',$r{$_},$t,100*$r{$_}/$t,$_) } sort { $a cmp $b } keys(%r));
 $m.="\n".sprintf('%d operations in %d seconds, on average %.2f op/s = %.3f s/op',$t,$tstop-$tstart,$t/($tstop-$tstart),($tstop-$tstart)/$t); ## Warning, substring "on average" is used in handle_line(), do not change it
 $m.="\nResults in local file: $res";
 return (undef,$m);
}

####################################################################################################

sub build_contactset
{
 my ($ctx,$rh)=@_;
 my $cs=$ctx->{dri}->local_object('contactset');
 while(my ($t,$ids)=each(%$rh))
 {
  foreach my $c (ref($ids)? @{$ids} : ($ids))
  {
   $cs->add($ctx->{dri}->local_object('contact')->srid($c),$t);
   $ctx->{completion}->{contacts}->{$c}=[time(),$ctx->{dri}->registry_name()];
  }
 }
 return $cs;
}

sub build_contact
{
 my ($ctx,$c,$rh)=@_;
 while(my ($m,$v)=each(%$rh))
 {
  $c->$m($v);
 }
 if (exists $rh->{srid}) { $ctx->{completion}->{contacts}->{$rh->{srid}}=[time(),$ctx->{dri}->registry_name()]; }
 if (exists $rh->{id})   { $ctx->{completion}->{contacts}->{$rh->{id}}  =[time(),$ctx->{dri}->registry_name()]; }

 return $c;
}

sub build_status
{
 my ($ctx,$ra)=@_;
 my $s=$ctx->{dri}->local_object('status');
 foreach (@$ra) { s/^no//; $s->no($_); }
 return $s;
}

sub build_hosts
{
 my ($ctx,$ra)=@_;
 my $ns=$ctx->{dri}->local_object('hosts');
 my $i=-1;
 my @r;
 foreach my $o (@$ra)
 {
  $r[++$i]=[] if ($o=~m/[a-z]/i); ## new hostname (safe since at least the TLD is not numeric)
  push @{$r[$i]},$o if $i >= 0; ## the test here makes us skip IP addresses at beginning before first name (a situation that should not happen anyway)
 }
 foreach my $rns (@r)
 {
  my $name=shift(@$rns);
  $ns->add($name,$rns);
  $ctx->{completion}->{hosts}->{$name}=time();
 }
 return $ns;
}

sub build_auth
{
 my $rd=shift;
 return unless (exists($rd->{auth}) && ! ref($rd->{auth}));
 $rd->{auth}={ pw => $rd->{auth} };
 return;
}

sub build_duration
{
 my ($ctx,$rd)=@_;
 return unless exists($rd->{duration});
 my ($v,$u)=($rd->{duration}=~m/^(\d+)(\S+)$/);
 $rd->{duration}=$ctx->{dri}->local_object('duration','years'  => $v) if ($u=~m/^y(?:ears?)?$/i);
 $rd->{duration}=$ctx->{dri}->local_object('duration','months' => $v) if ($u=~m/^m(?:onths?)?$/i);
 return;
}

sub build_update
{
 my ($ctx,$rd)=@_;
 my (%add,%rem);

 ## Some normalizations
 foreach my $k (grep { /^[+-]?status$/ } keys(%$rd)) { $rd->{$k}=build_status($ctx,ref $rd->{$k} ? $rd->{$k} : [ $rd->{$k} ]); }
 foreach my $k (grep { /^[+-]?ns$/ }     keys(%$rd)) { $rd->{$k}=build_hosts($ctx,[ map { split(/\s+/,$_) } ref $rd->{$k} ? @{$rd->{$k}} : ($rd->{$k})]); }
 build_auth($rd);

 my @ct=qw/admin tech billing/; ## How to retrieve non core contact types ?
 @ct=$ctx->{dri}->protocol()->core_contact_types() if ($ctx->{dri}->protocol() && $ctx->{dri}->protocol()->can('core_contact_types'));
 my $ctr=join('|',@ct);
 foreach my $op (qw/+ -/)
 {
  my %c;
  foreach my $k (grep { /^[${op}](?:${ctr})$/ } keys(%$rd) )
  {
   $c{substr($k,1)}=$rd->{$k};
   delete($rd->{$k});
  }
  next unless %c;
  $rd->{$op.'contact'}=build_contactset($ctx,\%c);
 }
 $rd->{registrant}=build_contact($ctx,$ctx->{dri}->local_object('contact'),{srid => $rd->{registrant}}) if exists $rd->{registrant};

 ## Now split in two hashes
 foreach my $k (grep { /^\+/ } keys(%$rd))
 {
  $add{substr($k,1)}=$rd->{$k};
  delete($rd->{$k});
 }
 foreach my $k (grep { /^-/ } keys(%$rd))
 {
  $rem{substr($k,1)}=$rd->{$k};
  delete($rd->{$k});
 }

 return (\%add,\%rem,$rd);
}

sub pretty_string
{
 my ($v,$full)=@_;
 $full||=0;
 unless(ref($v))
 {
  return '<undef>' unless defined($v);
  $v=~s/\s*$//;
  return $v unless ($v=~m/^<\?xml /);
  my $vi=Net::DRI::Util::xml_indent($v);
  $vi=~s/\n/\n\t\t/g;
  return $vi;
 }
 return join(' ',@$v) if (ref($v) eq 'ARRAY');
 return join(' ',map { $_.'='.$v->{$_} } keys(%$v)) if (ref($v) eq 'HASH');
 return ($full? "Ns:\n": '').$v->as_string(1) if ($v->isa('Net::DRI::Data::Hosts'));
 return ($full? "Contact:\n" : '').$v->as_string() if ($v->isa('Net::DRI::Data::Contact'));
 if ($v->isa('Net::DRI::Data::ContactSet'))
 {
  my @v;
  foreach my $t ($v->types())
  {
   push @v,$t.'='.join(',',map { pretty_string($_,$full) } $v->get($t));
  }
  return ($full? "ContactSet:\n" : '').join(' ',@v);
 }
 return ($full? "Status:\n" : '').join(' + ',$v->list_status(1)) if ($v->isa('Net::DRI::Data::StatusList'));
 return ($full? "Command result:\n" : '').$v->as_string(1) if ($v->isa('Net::DRI::Protocol::ResultStatus'));
 return ($full? "Date:\n" : '').$v->set_time_zone('UTC')->strftime('%Y-%m-%d %T').' UTC' if ($v->isa('DateTime'));
 return ($full? "Duration:\n" : '').sprintf('P%dY%dM%dDT%dH%dM%dS',$v->in_units(qw/years months days hours minutes seconds/)) if ($v->isa('DateTime::Duration')); ## ISO8601
 return $v;
}

sub dump_info
{
 my ($ctx,$rh)=@_;
 my @r;
 foreach my $k1 (sort(keys(%$rh)))
 {
  foreach my $k2 (sort(keys(%{$rh->{$k1}})))
  {
   next if ($k1 eq 'session' && $k2 eq 'exchange' && $ctx->{config}->{verbose}==0);
   push @r,$k1.','.$k2;
   foreach my $k3 (sort(keys(%{$rh->{$k1}->{$k2}})))
   {
    push @r,"\t".$k3.': '.pretty_string($rh->{$k1}->{$k2}->{$k3},0);
   }
   push @r,'';
  }
 }
 return join("\n",@r);
}

####################################################################################################
1;
