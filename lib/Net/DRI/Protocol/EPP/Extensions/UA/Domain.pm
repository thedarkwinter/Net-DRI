package Net::DRI::Protocol::EPP::Extensions::UA::Domain;
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
 return $mes->command_extension_register($tag,sprintf('xmlns:uaepp="%s" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="%s %s"',$mes->nsattrs('uaepp')));
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 if ($domain =~ /^[^.]+\.ua$/)
 {
 Net::DRI::Exception::usererr_insufficient_parameters('license attribute is mandatory') 
         unless (exists($rd->{license}));

 my @n;
 push @n,['uaepp:license',$rd->{license}];

 my $eid=build_command_extension($mes,$epp,'uaepp:create');
 $mes->command_extension($eid,\@n);
 }
}

sub update
{
 my ($epp,$domain,$toc,$rd)=@_;
 my $mes=$epp->message();
 my @chg;
 my $chg = $toc->set('license');
 if ($chg)
 {
		push @chg, ['uaepp:license', $chg];
#use Data::Dumper; die Dumper \@chg, $chg;
	 my $eid=build_command_extension($mes,$epp,'uaepp:update');
	 $mes->command_extension($eid,['uaepp:chg', @chg]);
 }
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('uaepp','infData');
 return unless $infdata;

 my %ens;
 my $c=$infdata->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'license')
  {
   $ens{license}=$c->getFirstChild()->getData();
  }
	else
	{
		warn "Unknown name $name";
	}
 } continue { $c=$c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{license}=$ens{license};
}


1;

