## Domain Registry Interface, .NO policies for Net::DRI
##
## Copyright (c) 2008-2010 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>, Trond Haugen E<lt>info@norid.noE<gt>. All rights reserved.
##           (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::NO;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;
use Net::DRI::Exception;

# let contact check support be decided by the server policy
__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_accept domain_transfer_refuse contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse/);

=pod

=head1 NAME

Net::DRI::DRD::NO - .NO policies for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Trond Haugen E<lt>info@norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2010 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>, Trond Haugen E<lt>info@norid.noE<gt>
          (c) 2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{info}->{host_as_attr} = 0;    # means make host objects
    $self->{info}->{use_null_auth}= 1;    # means using domain:null for empty authinfo password
    return $self;
}

sub periods {
    return map { DateTime::Duration->new( years => $_ ) } (1);
}
sub name         { return 'NORID'; }
sub tlds         { return ('no'); }
sub object_types { return ( 'domain', 'contact', 'ns' ); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default {
    my ($self,$type)=@_;

    return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NO',{}) if $type eq 'epp';
# suppress until whois is supported
#return ('Net::DRI::Transport::Socket',{remote_host=>'whois.norid.no'},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois';

    return;
}

####################################################################################################

=head1 verify_name_domain

.NO allows country codes in labels on the left, so we need to subclass
the verify_name_domain to avoid the CCA2 table check.

We then clone the .AT code also here, but remove the dot-count and check
in 'check_name'.

However, we do not subclass the 'is_my_tld' as .AT has done,
but we then have to call it in a non-strict mode to allow for
domain names with multiple labels.

The combination should then allow multiple labels and also
to use CC-codes in lables, like 'se.vgs.no'

=cut

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name_no_dots => 1,
                                               my_tld_not_strict => 0,
                                              });
}

sub verify_duration_renew {
    my ( $self, $ndr, $duration, $domain, $curexp ) = @_;

    if ( defined($duration) ) {
        my ( $y, $m ) = $duration->in_units( 'years', 'months' );

        ## Only 1..12m or 1y allowed in a renew
        unless ( ( $y == 1 && $m == 0 )
            || ( $y == 0 && ( $m >= 1 && $m <= 12 ) ) )
        {
            return 1;    # if exception is removed, return an error
        }
    }
    return 0;            ## everything ok
}

sub domain_operation_needs_is_mine {
    my ( $self, $ndr, $domain, $op ) = @_;
    return unless defined($op);

    return 1 if ( $op =~ m/^(?:renew|update|delete|withdraw)$/mx );
    return 0 if ( $op eq 'transfer' );
    return;
}

sub domain_withdraw {
    my ( $self, $ndr, $domain, $rd ) = @_;
    $self->enforce_domain_name_constraints($ndr,$domain,'withdraw');

    $rd=Net::DRI::Util::create_params('domain_withdraw',$rd);
    $rd->{transactionname} = 'withdraw';

    my $rc = $ndr->process( 'domain', 'withdraw', [ $domain, $rd ] );
    return $rc;
}

sub domain_transfer_execute
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_execute');

 $rd=Net::DRI::Util::create_params('domain_transfer_execute',$rd);
 $rd->{transactionname} = 'transfer_execute';

 my $rc=$ndr->process('domain','transfer_execute',[$domain,$rd]);
 return $rc;
}

# need to accept also t=contact as an element-type to be updated
#
sub host_update {
    my ( $self, $ndr, $dh, $tochange, $rh ) = @_;
    my $fp = $ndr->protocol->nameversion();

    my $name=Net::DRI::Util::is_class($dh,'Net::DRI::Data::Hosts') ? $dh->get_details(1) : $dh;
    $self->enforce_host_name_constraints($ndr,$name);
    Net::DRI::Util::check_isa( $tochange, 'Net::DRI::Data::Changes' );

    foreach my $t ( $tochange->types() ) {
        Net::DRI::Exception->die( 0, 'DRD', 6,
            "Change host_update/${t} not handled" )
            unless ( $t =~ m/^(?:ip|status|name|contact|facets)$/mx );
        next if $ndr->protocol_capable( 'host_update', $t );
        Net::DRI::Exception->die( 0, 'DRD', 5,
            "Protocol ${fp} is not capable of host_update/${t}" );
    }

    my %what = (
        'ip'     => [ $tochange->all_defined('ip') ],
        'status' => [ $tochange->all_defined('status') ],
        'name'   => [ $tochange->all_defined('name') ],
    );
    foreach ( @{ $what{ip} } ) {
        Net::DRI::Util::check_isa( $_, 'Net::DRI::Data::Hosts' );
    }
    foreach ( @{ $what{status} } ) {
        Net::DRI::Util::check_isa( $_, 'Net::DRI::Data::StatusList' );
    }
    foreach ( @{ $what{name} } ) {
	$self->enforce_host_name_constraints($ndr,$_);
    }

    foreach my $w ( keys(%what) ) {
        my @s = @{ $what{$w} };
        next unless @s;    ## no changes of that type

        my $add = $tochange->add($w);
        my $del = $tochange->del($w);
        my $set = $tochange->set($w);

        Net::DRI::Exception->die( 0, 'DRD', 5,
            "Protocol ${fp} is not capable for host_update/${w} to add" )
            if ( defined($add)
            && !$ndr->protocol_capable( 'host_update', $w, 'add' ) );
        Net::DRI::Exception->die( 0, 'DRD', 5,
            "Protocol ${fp} is not capable for host_update/${w} to del" )
            if ( defined($del)
            && !$ndr->protocol_capable( 'host_update', $w, 'del' ) );
        Net::DRI::Exception->die( 0, 'DRD', 5,
            "Protocol ${fp} is not capable for host_update/${w} to set" )
            if ( defined($set)
            && !$ndr->protocol_capable( 'host_update', $w, 'set' ) );
        Net::DRI::Exception->die( 0, 'DRD', 6,
            "Change host_update/${w} with simultaneous set and add or del not supported"
        ) if ( defined($set) && ( defined($add) || defined($del) ) );
    }

    my $rc = $ndr->process( 'host', 'update', [ $dh, $tochange, $rh ] );
    return $rc;
}

sub message_retrieve {
    my ( $self, $ndr, $rd ) = @_;

    my $rc = $ndr->process( 'message', 'noretrieve', [$rd] );
    return $rc;
}

sub message_delete {
    my ( $self, $ndr, $id, $rd ) = @_;

    my $rc = $ndr->process( 'message', 'nodelete', [$id, $rd] );
    return $rc;
}

sub message_waiting {
    my ( $self, $ndr, $rd ) = @_;

    my $c = $self->message_count($ndr, $rd);
    return ( defined($c) && $c ) ? 1 : 0;
}

sub message_count {
    my ( $self, $ndr, $rd ) = @_;

    my $count = $ndr->get_info( 'count', 'message', 'info' );
    return $count if defined($count);

    my $rc = $ndr->process( 'message', 'noretrieve',  [$rd] );

    return unless $rc->is_success();
    $count = $ndr->get_info( 'count', 'message', 'info' );
    return ( defined($count) && $count ) ? $count : 0;
}

####################################################################################################
1;
