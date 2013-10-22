package Alien::FFTW3;

use stric;
use warnings;
our $VERSION = '0.001';
use parent 'Alien::Base';

1;

__END__

=head1 NAME

Alien::FFTW3 - Alien wrapper for FFTW3

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Module::Build;
  use Alien::FFTW3;

  my $cflags = Alien::FFTW3->cflags;
  my $ldflags = Alien::FFTW3->libs;

=head1 ABSTRACT

Alien wrapper for FFTW3

=head1 DESCRIPTION

This module provides package validation and installation for FFTW3.

=head1 SEE ALSO

Alien::Base, PDL::FFTW3, http://fftw.org

