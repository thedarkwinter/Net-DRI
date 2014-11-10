package Net::DRI::Data::Contact::TCI_gTLD;

use strict;
use base qw(Net::DRI::Data::Contact);
use Email::Valid;
use Net::DRI::Util;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

__PACKAGE__->register_attributes(qw(organization person));

####################################################################################################
sub validate
{
  my ($self,$change)=@_;
  $change||=0;
  my @errs;

  $self->SUPER::validate($change); ## will trigger an Exception if problem

  if ($self->person && $self->organization)
  {
    Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: person and org cannot be specified at the same time');
  }

  if ($self->person)
  {
    if (!$change)
    {
      my $data = $self->person();
      for my $key (qw (birthday passport))
      {
        push @errs, "'$key' field is not specified" unless $data->{$key};
      }
    }
  }
  elsif ($self->organization)
  {
    if (!$change)
    {
      my $data = $self->organization();
      for my $key (qw (legalAddr TIN))
      {
        push @errs, "'$key' field is not specified" unless $data->{$key};
      }

      if ($data->{legalAddr})
      {
        push @errs, "legalAddr should be a hash ref" unless (ref($data->{legalAddr}) && (ref($data->{legalAddr}) eq 'HASH'));

        for my $key (qw (street city sp pc cc))
        {
          push @errs, "'legalAddr:$key' field is not specified" unless $data->{legalAddr}{$key};
        }
      }
    }
  }
  else
  {
    push @errs, 'Invalid contact information: person or org should be specified';
  }

  Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

  return 1; ## everything ok.
}

####################################################################################################
1;
