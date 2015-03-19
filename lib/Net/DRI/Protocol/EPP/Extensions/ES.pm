## Domain Registry Interface, ES policies
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


package Net::DRI::Protocol::EPP::Extensions::ES;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;
use Net::DRI::Data::Contact::ES;

# FIXME use Net::DRI::Data::Contact::ES;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ES - .ES EPP extensions for Net::DRI

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

sub setup
{
 my ($self,$rp)=@_;
 
 use Data::Dumper;
 my $version=$self->version();
 $self->ns({ es_creds => ['urn:red.es:xml:ns:es_creds-1.0','es_creds-1.0'],
                          es_bandeja => ['urn:red.es:xml:ns:es_bandeja-1.0','es_bandeja-1.0']
          });
 $self->capabilities('host_update','name',undef); ## No change of hostnames
 $self->capabilities('domain_update','registrant',undef); # registrant cannot be changed
 $self->capabilities('contact_update','status',undef);
 $self->capabilities('domain_update','status',undef);
 $self->capabilities('domain_update','ip_maestra',[ 'add','del']);
 $self->capabilities('domain_update','marca',[ 'add','del']);
 $self->capabilities('domain_update','inscripcion',[ 'add','del']);
 $self->capabilities('domain_update','accion_comercial',[ 'add','del']);
 $self->capabilities('domain_update','codaux',[ 'add','del']);
 $self->capabilities('domain_update','auto_renew',[ 'add','del']);
 $self->capabilities('bandeja_info');
 
 $self->factories('message',sub {  # add the es_creds extension to all commands
          my $m=Net::DRI::Protocol::EPP::Message->new(@_); 
          $m->ns($self->{ns}); 
          $m->version($version);
           my @n = (['es_creds:clID',$rp->{client_login}],['es_creds:pw',$rp->{client_password}]);
           my $eid = $m->command_extension_register('es_creds','es_creds');
           $m->command_extension($eid,\@n);
           return $m;
         });
   $self->factories('contact',sub { return Net::DRI::Data::Contact::ES->new(); });

   return;
}

sub default_extensions { return qw/ES::Session ES::Domain ES::Contact ES::Tray/; }



####################################################################################################
1;
