## Domain Registry Interface, .JOBS contact extension
##
## Copyright (c) 2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##                    All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::JobsContact;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::JobsContact - .JOBS EPP contact extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> and
E<lt>http://oss.bdsprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %contacttmp=(
	   create =>		[ \&create, undef ],
	   update =>		[ \&update, undef ],
	   info =>		[ undef, \&info_parse ]
	 );

 return { 'contact' => \%contacttmp };
}

our @NS=('http://www.verisign.com/epp/jobsContact-1.0','http://www.verisign.com/epp/jobsContact-1.0 jobsContact-1.0.xsd');

####################################################################################################

############ Transform commands

sub add_job
{
	my ($cmd, $epp, $contact, $rd) = @_;
	my $mes = $epp->message();
	my $info;
	my @jobdata;

	return unless Net::DRI::Util::isa_contact($contact, 'Net::DRI::Data::Contact::JOBS');
	$info = $contact->jobinfo();
        return unless (defined($info) && (ref($info) eq 'HASH') && keys(%$info));
	push(@jobdata, ['jobsContact:title', $info->{title}])
		if (defined($info->{title}) && length($info->{title}));
	push(@jobdata, ['jobsContact:website', $info->{website}])
		if (defined($info->{website}) && length($info->{website}));
	push(@jobdata, ['jobsContact:industryType', $info->{industry}])
		if (defined($info->{industry}) && length($info->{industry}));
	push(@jobdata, ['jobsContact:isAdminContact',
		(defined($info->{admin}) && $info->{admin} ? 'Yes' : 'No')])
		if (defined($info->{admin}) && length($info->{admin}));
	push(@jobdata, ['jobsContact:isAssociationMember',
		(defined($info->{member}) && $info->{member} ? 'Yes' : 'No')])
		if (defined($info->{member}) && length($info->{member}));

	return unless (@jobdata);

	my $eid = $mes->command_extension_register('jobsContact:' . $cmd,sprintf('xmlns:jobsContact="%s" xsi:schemaLocation="%s"',@NS));
	$mes->command_extension($eid, \@jobdata);
	return;
}

sub create
{
	my (@args)=@_;
	return add_job('create', @args);
}

sub update
{
	my (@args)=@_;
	return add_job('update', @args);
}

sub info_parse
{
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
	my $mes = $po->message();
	my $infdata = $mes->get_extension($NS[0],'infData');
        return unless (defined($infdata));

	my $jobinfo = {};
	my $c;

	$c = $infdata->getChildrenByTagNameNS($NS[0], 'title');
	$jobinfo->{title} = $c->shift()->getFirstChild()->getData() if ($c);

	$c = $infdata->getChildrenByTagNameNS($NS[0], 'website');
	$jobinfo->{website} = $c->shift()->getFirstChild()->getData() if ($c);

	$c = $infdata->getChildrenByTagNameNS($NS[0], 'industryType');
	$jobinfo->{industry} = $c->shift()->getFirstChild()->getData() if ($c);

	$c = $infdata->getChildrenByTagNameNS($NS[0], 'isAdminContact');
	$jobinfo->{admin} = (lc($c->shift()->getFirstChild()->getData()) eq 'yes')? 1 : 0 if ($c);

	$c = $infdata->getChildrenByTagNameNS($NS[0], 'isAssociationMember');
	$jobinfo->{member} = (lc($c->shift()->getFirstChild()->getData()) eq 'yes')? 1 : 0 if ($c);

        my $contact = $rinfo->{$otype}->{$oname}->{self};
	$contact->jobinfo($jobinfo);
	return;
}

####################################################################################################
1;
