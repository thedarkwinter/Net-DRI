## Domain Registry Interface, Logging into files
##
## Copyright (c) 2009,2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Logging::Files;

use strict;
use warnings;

use base qw/Net::DRI::Logging/;

use Net::DRI::Exception;

use IO::Handle; ## needed for the autoflush method on any lexical $fh
use POSIX qw /strftime/;

####################################################################################################

sub new
{
 my ($class,$data)=@_;
 my $self=$class->SUPER::new($data);
 if (! exists $self->{output_directory} || ! defined $self->{output_directory} ) { $self->{output_directory}='.'; }
 if (! -d $self->{output_directory}) { Net::DRI::Exception->die(0,'logging',1,'Directory '.$self->{output_directory}.' does not exist'); }
 if (! -w $self->{output_directory}) { Net::DRI::Exception->die(0,'logging',2,'Directory '.$self->{output_directory}.' is not writable'); }
 $self->{fh}={};
 return $self;
}

sub name { return 'files'; }

sub setup_channel
{
 my ($self,$source,$type,$data)=@_;
 my $name=$self->generate_filename($type,$data);
 if (exists $self->{fh}->{$name}) { return; }
 my $fh;
 open $fh,'>>',$name or Net::DRI::Exception->die(0,'logging',3,'File '.$name.' can not be open for writing: '.$!); ## no critic (InputOutput::RequireBriefOpen)
 $fh->autoflush(1); ## this is possible thanks to IO::Handle
 $self->{fh}->{$name}=$fh;
 return;
}

sub output
{
 my ($self,$level,$type,$data)=@_;
 if (! $self->should_log($level)) { return; }
 my $name=$self->generate_filename($type,$data);

 # check to see if the file handle exists and is valid - and attempt to set it up if not
 $self->setup_channel(undef,$type,$data) if (! exists $self->{fh}->{$name} || tell($self->{fh}->{$name}) == -1);

 # if its still not valid, then try core log
 if (! exists $self->{fh}->{$name} || tell($self->{fh}->{$name}) == -1)
 {
  my $core=$self->generate_filename('core');
  if (exists $self->{fh}->{$core} && tell($self->{fh}->{$name}) > -1)
  {
   $self->output('critical','core',sprintf('File "%s" (type "%s") has not been setup (no previous call to setup_channel or invalid type?), switching to "core" logging file',$name,$type));
   $name=$core;
  } else
  {
   Net::DRI::Exception->die(1,'logging',3,sprintf('File "%s" (type "%s") has not been setup (no previous call to setup_channel or invalid type?), and can not switch to "core" logging file',$name,$type));
  }
 }
 print { $self->{fh}->{$name} } $self->tostring($level,$type,$data),"\n";
 return;
}

####################################################################################################

sub generate_filename
{
 my ($self,$type,$ctx)=@_;
 return sprintf '%s/%s',$self->{output_directory},$self->{output_filename} if exists $self->{output_filename};
 if (exists $self->{format_filename})
 {
  my $name = $self->{format_filename};
  if ($name =~ m/%DATE\[(.*)\]/)
  {
   my $dt = strftime ($1, gmtime);
   $name =~ s/%DATE\[$1\]/$dt/;
  }
  $name =~ s/%PID/$$/;
  $name =~ s/%TYPE/$type/;
  if (defined $ctx && ref $ctx eq 'HASH')
  {
   $name =~ s/%PROTOCOL/$ctx->{protocol}/;
   $name =~ s/%PROFILE/$ctx->{profile}/;
   $name =~ s/%(REGISTRY|DRD)/$ctx->{registry}/;
  }
  else
  {
    $name =~ s/%(PROTOCOL|PROFILE|REGISTRY|DRD)//g;
  }
  $name .= "-core" if $type eq 'core' && $name !~ m/$type/; # append core if this is core
  chomp($name);
  $name =~ s/--*/-/; 
  $name =~ s/__*/_/;
  $name =~ s/^[ _-]//;
  $name =~ s/[ _-]$//;
  $name .= ".log" unless ($name =~ m/\..*$/);
  return sprintf '%s/%s',$self->{output_directory},$name;
 }
 # otherwise use the old method
 my $name=(defined $ctx && ref $ctx eq 'HASH')? sprintf('%s-%s-%s',$ctx->{registry},$ctx->{profile},$type) : $type;
 return sprintf '%s/%d-%s.log',$self->{output_directory},$$,$name;
}

sub DESTROY
{
 my ($self)=@_;
 foreach my $fh (values %{$self->{fh}})
 {
  close $fh or 1;
 }
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Logging::Files - Logging to Files for Net::DRI

=head1 SYNOPSIS

See L<Net::DRI::Logging>

=head1 DESCRIPTION

This class dumps all logging information to various files.

=head1 EXAMPLES

	$dri->new({..., logging => ['files',{output_directory => '/tmp'}] ,...});
	$dri->new({..., logging => ['files',{output_directory => '/tmp',format_filename => '%PID-%PROFILE'}] ,...}))

If not defined, the format_filename is %PID-%REGISTRY-%PROFILE-%TYPE



=head1 SUBROUTINES/METHODS

All mandated by superclass L<Net::DRI::Logging>.

Additional parameter for the Files module:

=item output_directory

If not defined, output_directory defaults to the current working directory.

=item output_filename

Optionally specify the filename

=item format_filename

Optionally specify the format to generate the filename. If not defined, the format_filename is %PID-%REGISTRY-%PROFILE-%TYPE. You can also use %DATE[posix format], eg: %DATE[%Y%m%d]-%PROFILE. Arbirtary text wont be removed, eg: %PID-%PROFILE-polling. The default extension is .log, but you can set this, eg:  %PID-%PROFILE.txt. Note, if you don't specify %TYPE, then transport and protocol will be logged together, but -core will be added to the core log.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

This modules has to be used inside the Net::DRI framework and needs the following components:

=over

=item L<Net::DRI::Logging>

=back

It also uses IO::Handle, from Perl core.

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

No known bugs. Please report problems to author (see below) or use CPAN RT system. Patches are welcome.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009,2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
