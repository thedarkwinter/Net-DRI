package Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Domain;
#===============================================================================
#
#         FILE:  Domain.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dmitry Belyavsky (BelDmit), <beldmit@tcinet.ru>
#      COMPANY:  tcinet.ru
#      VERSION:  1.0
#      CREATED:  06/24/2013 04:24:53 PM MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use utf8;

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( 
          create => [ \&create, undef ],
          info   => [ undef, \&info_parse ],
					update => [ \&update ],
         );

 return { 'domain' => \%tmp };
}

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:domain="%s" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="%s %s"',$mes->nsattrs('tci_dom')));
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 if (exists $rd->{description})
 {
#	 Net::DRI::Exception::usererr_insufficient_parameters('description attribute is mandatory') 
#		 unless (exists($rd->{description}));

	 my @n;
	 push @n,['domain:description',$rd->{description}];

	 my $eid=build_command_extension($mes,$epp,'domain:create');
	 $mes->command_extension($eid,\@n);
 }
}

sub update
{
 my ($epp,$domain,$toc,$rd)=@_;
 my $mes=$epp->message();
 my @chg;
 my $chg = $toc->set('description');
 if ($chg)
 {
	for my $str (@$chg)
	{
		push @chg, ['domain:description', $str];
	}
#use Data::Dumper; die Dumper \@chg, $chg;
	 my $eid=build_command_extension($mes,$epp,'domain:update');
	 $mes->command_extension($eid,['domain:chg', @chg]);
 }
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('domain','infData');
 return unless $infdata;

 my %ens;
 my $c=$infdata->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'description')
  {
   $ens{description}=$c->getFirstChild()->getData();
  }

 } continue { $c=$c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{ens}=\%ens;
}


1;

