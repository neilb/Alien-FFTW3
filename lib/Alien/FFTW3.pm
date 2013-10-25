=head1 NAME

Alien::FFTW3 - Alien wrapper for FFTW3

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Module::Build;
  use Alien::FFTW3 3.3;

  my $cflags = Alien::FFTW3->cflags;
  my $ldflags = Alien::FFTW3->libs;

  if( Alien::FFTW3->precision('q') ) {
    # compile quad-precision library...
  }

  my $cflags_for_float = Alien::FFTW3->cflags('f');

=head1 ABSTRACT

Alien wrapper for FFTW3.  

=head1 DESCRIPTION

This module provides package validation and installation for FFTW3.
It depends on the external POSIX program pkg-config to find the FFTW3 libraries.

Because FFTW3 comes in several flavors for different levels of
numerical precision, the typical access methods 'cflags' and 'libs'
work slightly differently than the simple Alien::Base case.  You can
feed in nothing at all, in which case you get back cflags and libs
strings appropriate for compiling *all* available fftw3 libraries; or
you can specify which precision you want by passing in an allowed
precision.  The allowed precisions are currently 'f','d','l', and 'q'
for floats, doubles, long doubles, and quad doubles respecetively.

On initial use, Alien::FFTW3 checks for which precisions are available.
If more than zero are available, it succeeds.  If none are available, then
it fails.

You can query which precisions are installed on your system using the
"precision" method, documented below.

As an Alien module, Alien::FFTW3 attempts to build fftw on your system
from source if it's not found at install time.  Because I'm Lazy, I
use the existing fine infrastructure from Joel Berger to install in
that case.  But the default compile only generates the
double-precision library, so if you want more you'll have to install
it yourself with a package manager or your own source compilation.

You can validate that the FFTW3 library exists and has a certain
version number -- if you C<< use Alien::FFTW3 <version> >>, then the
FFTW3 libraries will be checked against that verison number.  Note
that you must use Perlified version numbers with that syntax --
e.g. if you want v3.3.4 of the library, you must C<< use Alien::FFTW3
3.003_004 >>.  The code translates the Perlish version to the
POSIX-style version string against which to check the library.  If you
request a particular version number, then all precision variants of
C<libfftw> available on your system must meet that version number, or
Alien::FFTW3 will throw an exception.

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

sub vcmp {
    my ($v1,$v2) = @_;
    my $a;
    for(0..2){
	$a = $v1->[$_] <=> $v2->[$_];
	return $a if($a);
    }
    return 0;
}

sub VERSION {
    my $module = shift;
    my $req_v = shift;

    # Do some DWIMming about the version, since Perl numerifies it.
    # In particular, if the subversion has at least 3 digits,
    # interpret it as modern Perl multiplexed version number.  If it
    # has less than that, treat it as a direct subversion (no point
    # version).  This will break if FFTW ever gets to version 3.10,
    # which will show up as 3.1 here.
    my @req_v;
    if($req_v =~ m/^\s*(\d+)(\.(\d\d\d)(\d*))?\s*$/) {
	@req_v = ($1, $3//0, $4//0);
    } elsif( $req_v =~ m/^\s*(\d+)(\.(\d))\s*$/) {
	@req_v = ($1, $3, 0);
    } elsif( $req_v =~ m/[vV]?(\d+)(\.(\d+)(\.(\d+))?)?/ ) {
	@req_v = ($1,$3//0,$5//0);
    } else {
	die "Alien::FFTW3 - couldn't parse requested version string '$req_v'";
    }

    my $h = precision();
    unless(defined($h)) {
	die "Alien::FFTW3 - no library found for version check";
    }

    my @pkgs = sort values %$h;
    my $pkgs = join(" ", @pkgs);
    
    my @s = map { chomp; $_ } (`pkg-config --modversion $pkgs`);
    my @versions = ();

    my $minv = undef;

    for(@s){
	$_ =~ m/(\d+)(\.(\d+)(\.(\d+))?)?/ || die "Alien::FFTW3 - couldn't parse fftw3 version string '$_'";
	push(@versions, $_);
	my @v = ($1,$3//0,$5//0);
	if( !defined($minv)  or  vcmp($minv,\@v)>0 ) {
	    $minv = [@v];
	}
    }

    if( vcmp($minv, \@req_v) < 0 ) {
	$req_v = sprintf("v%d.%d.%d",@req_v);
	die "Alien::FFTW3 - installed FFTW version is too low (looking for $req_v):\n".
	    join( "", map { sprintf("   %6.6s library has v%s\n",$pkgs[$_],$versions[$_]) } (0..$#pkgs));
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

