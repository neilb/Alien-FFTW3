=head1 NAME

Alien::FFTW3 - Alien wrapper for FFTW3

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Module::Build;
  use Alien::FFTW3;

  my $cflags = Alien::FFTW3->cflags;
  my $ldflags = Alien::FFTW3->libs;

  if( Alien::FFTW3->precision('q') ) {
    # compile quad-precision library...
  }

  my $cflags_for_float = Alien::FFTW3->cflags('f');

=head1 ABSTRACT

Alien wrapper for FFTW3.  Because FFTW3 comes in several flavors for
different levels of numerical precision, the typical access methods
'cflags' and 'libs' work slightly differently than the simple 
Alien::Base case.  You can feed in nothing at all, in which case
you get back cflags and libs strings appropriate for compiling *all* 
available fftw3 libraries; or you can specify which precision you want
by passing in an allowed precision.  The allowed precisions are currently
'f','d','l', and 'q' for floats, doubles, long doubles, and quad doubles
respecetively.

On initial use, Alien::FFTW3 checks for which precisions are available.
If more than zero are available, it succeeds.  If none are available, then
it fails.

You can query which precisions are installed on your system using the "precision" 
method, documented below.

As an Alien module, Alien::FFTW3 attempts to build fftw on your system
from source if it's not found at install time.  Because I'm Lazy, I use the
existing fine infrastructure from Joel Berger to install in that case.  
But the default compile only generates the double-precision library, so
if you want more you'll have to install it yourself with a package manager
or your own source compilation.

=head1 DESCRIPTION

This module provides package validation and installation for FFTW3.
It depends on the external POSIX program pkg-config to find the FFTW3 libraries.

=head1 SEE ALSO

Alien::Base, PDL::FFTW3, http://fftw.org

=head1 METHODS

=cut

package Alien::FFTW3;

use strict;
use warnings;

# $VERSION is here for CPAN to parse -- but there is a sub below to pull the fftw library version.
our $VERSION = '0.02';
use parent 'Alien::Base';

our $pkgconfig;
BEGIN {
   $pkgconfig = `which pkg-config`;
   chomp $pkgconfig;
   die "pkg-config not found, required for Alien::FFTW3 to work" unless($pkgconfig  and  -e $pkgconfig  and  -x $pkgconfig );
}


=head2 precision

=for ref

Test presence of fftw3 libs with different precisions.  Returns a hash ref
with keys set to TRUE for each library queried, or undef if none of the
queried libraries exist.  If you pass in no arguments, all precisions 
are tested.

The allowed precisions are 'f','d','l', and 'q'. 

You can pass them in as an array ref or as a single packed string.

=cut

our $_valid_precisions = {f=>['f'],d=>[''],l=>['l'],q=>['q']};
our $_our_precisions = join(", ",sort keys %$_valid_precisions);

sub precision {
    shift if(($_[0]//"") =~ m/Alien/ );       # discard package name or blessed ref on call

    my $precision = shift || 'fdlq';

    unless(ref($precision)) {
	$precision = [ split m//, $precision ];
    }
    
    unless(ref($precision) eq 'ARRAY') {
	die "precision: requires a scalar or an ARRAY ref";
    }
    
    my $out = {};

    for my $p(@$precision) {
	die "precision: $p is not a valid fftw precision ($_our_precisions allowed)" 
	    unless( $_valid_precisions->{$p} );
	my $pp = $_valid_precisions->{$p}->[0];
	my $s;

	chomp( $s = `$pkgconfig --silence-errors --libs fftw3$pp` );

	if($s) {
	    $out->{$p} = "fftw3$pp";
	}
    }
    
    if(keys %$out) {
	return $out;
    } else {
	return undef;
    }
}

=head2 cflags

=for ref

Returns the cflags compiler flags required for the specified precision, or for all of 'em.

=cut

sub cflags {
    shift if(($_[0]//"") =~ m/Alien/ );       # discard package name or blessed ref on call

    my $precision = shift;
    
    my $h = precision($precision);
    die "No fftw package found!" unless($h);

    my $pkgs = join(" ",sort values %$h);

    my $s = `$pkgconfig --cflags $pkgs`;
    chomp $s;
    return $s;
}

=head2 libs

=for ref

Returns the libs linker flags required for the specified precision, or for all of 'em.

=cut

sub libs {
    shift if(($_[0]//"") =~ m/Alien/);       # discard package name on call
    my $precision = shift;
    my $h =precision($precision);
    die "No fftw package found!" unless($h);
    
    my $pkgs = join(" ",sort values %$h);
    
    my $s = `$pkgconfig --libs $pkgs`;
    chomp $s;
    return $s;
}

##############################
# version checker

sub VERSION {
    my $module = shift;
    my $req_v = shift;

    my $h = precision();
    my $pkgs = join(" ", sort values %$h);
    
    my @s = map { chomp; $_ } (`pkg-config --modversion $pkgs`);
    
    my $minv = undef;

    for(@s){
	$_ =~ m/(\d+)(\.(\d+)(\.(\d+))?)?/ || die "Alien::FFTW3 - couldn't parse fftw3 version string '$_'";
	my $v = $1 + ($3//0)/1000 + ($5//0)/1000/1000;
	if( !defined($minv)  or  $minv > $v ) {
	    $minv = $v;
	}
    }

    if($minv < $req_v) {
	die "Alien::FFTW3 - requested FFTW version $req_v; found only $minv\n";
    }
}


##############################
# Run the precision test to see if fftw is even available 

do { 
    my $p = precision(); 
    unless( defined $p ) { 
	die "Alien::FFTW3: the FFTW3 library appears not to be present on your\nsystem (also check the pkg-config tool)\n"; 
    }
} while(0);

1;

__END__

