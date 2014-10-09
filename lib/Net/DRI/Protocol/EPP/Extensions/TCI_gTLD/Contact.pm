package Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Contact;
#===============================================================================
#
#         FILE:  Contact.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dmitry Belyavsky (BelDmit), <beldmit@tcinet.ru>
#      COMPANY:  tcinet.ru
#      VERSION:  1.0
#      CREATED:  06/24/2013 05:33:35 PM MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use utf8;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

####################################################################################################

sub register_commands
{
	my ($class, $version) = @_;
	my %tmp = ( 
		create => [ \&create, undef ],
		update => [ \&update, undef ],
		info   => [ undef, \&info_parse ],
	);

	return { 'contact' => \%tmp };
}

####################################################################################################
sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:contact="%s" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="%s %s"',$mes->nsattrs('tci_con')));
}

sub build_ext_data
{
 my ($epp, $contact, $mes, $op) = @_;

 my @n;
 my $eid = build_command_extension($mes, $epp, "contact:$op");

 if ($contact->person)
 {
 	my $data = $contact->person;

	push @n, ['contact:birthday', $data->{birthday}];

	push @n, ['contact:passport', $data->{passport}];
	push @n, ['contact:TIN',      $data->{TIN}] if exists $data->{TIN};

	if ($op eq 'create')
	{
		$mes->command_extension($eid, ['contact:person', @n]);
	}
	elsif ($op eq 'update')
	{
		$mes->command_extension($eid, ['contact:chg', ['contact:person', @n]]);
	}
 }
 else
 {
 	my $data = $contact->organization();
	my $addr = $data->{legalAddr};
        my (@addr_loc,@addr_int);

        my @streets_loc = (ref $addr->{street}[0]) ? @{$addr->{street}[0]} : ($addr->{street}[0]);
        my @streets_int = (ref $addr->{street}[1]) ? @{$addr->{street}[1]} : ($addr->{street}[1]);

        for my $street_loc (@streets_loc)
        {
          push @addr_loc, ['contact:street', $street_loc];
        }
        for my $street_int (@streets_int)
        {
          push @addr_int, ['contact:street', $street_int] if (defined $street_int && $street_int ne '');;
        }

        for my $key (qw(city sp pc cc))
        {
          push @addr_loc, ["contact:$key", $addr->{$key}[0]] if (defined $addr->{$key}[0] && $addr->{$key}[0] ne '');
          push @addr_int, ["contact:$key", $addr->{$key}[1]] if (defined $addr->{$key}[1] && $addr->{$key}[1] ne '');
        }

        push @n, ['contact:legalAddr', @addr_loc, {type => 'loc'}] if @addr_loc;
        push @n, ['contact:legalAddr', @addr_int, {type => 'int'}] if @addr_int;
        push @n, ['contact:TIN', $data->{TIN}];

	if ($op eq 'create')
	{
		$mes->command_extension($eid, ['contact:organization', @n]);
	}
	elsif ($op eq 'update')
	{
		$mes->command_extension($eid, ['contact:chg', ['contact:organization', @n]]);
	}
 }
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

 build_ext_data($epp, $contact, $mes, 'create');
}


sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 build_ext_data($epp, $contact, $mes, 'update');
}


sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('contact','infData');
 return unless $infdata;

 my $ns=$mes->ns('tci_con');
 $infdata=Net::DRI::Util::xml_traverse($infdata,$ns,'infData','contact');
 return unless defined $infdata;

 my $contact=$rinfo->{contact}->{$oname}->{self};

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'person')
  {
   $contact->person(parse_person($c)); 
  } 
	elsif ($name eq 'organization')
  {
   $contact->organization(parse_org($c));
  } 
	else
  {
		Net::DRI::Exception::usererr_invalid_parameters('Smthing strange from registry');
  }
 }
}

sub parse_person
{
	my $element = shift;
	my $result  = {};
	
	foreach my $el (Net::DRI::Util::xml_list_children($element))
	{
		my ($name,$c)=@$el;

		if ($name eq 'passport')
		{
			push @{$result->{$name}}, $c->textContent();
		}
		else
		{
		 $result->{$name} = $c->textContent();
		}
	}
	return $result;
}

sub parse_org
{
	my $element = shift;
	my $result  = {};

	foreach my $el (Net::DRI::Util::xml_list_children($element))
	{
		my ($name,$c)=@$el;

		if ($name eq 'legalAddr')
		{
			foreach my $a_el (Net::DRI::Util::xml_list_children($element))
			{
				my ($a_name,$a_c)=@$a_el;

				if ($a_name eq 'street')
				{
					push @{$result->{$name}{$a_name}}, $a_c->textContent();
				}
				else
				{
		 			$result->{$name}{$a_name} = $a_c->textContent();
				}
			}
		}
		else
		{
		 $result->{$name} = $c->textContent();
		}
	}

	return $result;
}

1;

