package Net::DRI::Protocol::EPP::Extensions::UA::HostDelete;
#===============================================================================
#
#         FILE:  HostDelete.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dmitry Belyavsky (BelDmit), <beldmit@tcinet.ru>
#      COMPANY:  tcinet.ru
#      VERSION:  1.0
#      CREATED:  10/04/2013 04:49:33 PM MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use utf8;

sub register_commands
{
	my ($class, $version) = @_;
	my %tmp = ( 
		delete => [ \&delete, undef ],
	);

	return { 'host' => \%tmp };
}

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:uaepp="http://hostmaster.ua/epp/uaepp-1.1"'));
}

sub build_ext_data
{
 my ($epp, $host, $mes, $op) = @_;

 my @n;
 my $eid = build_command_extension($mes, $epp, "uaepp:$op");

 $mes->command_extension($eid, ['uaepp:deleteNS', undef, {confirm => "yes"}]);
}

sub delete
{
 my ($epp,$host,$rd)=@_;
 return unless Net::DRI::Util::has_key($rd,'confirm');
 Net::DRI::Exception::usererr_invalid_parameters('You should confirm the host deletion') unless ($rd->{confirm}	eq 'yes');

 my $mes=$epp->message();
 build_ext_data($epp,$host,$mes,'delete');
}

1;