use strict;
use warnings;


##############################
# Refuse to work with sufficiently broken systems
if($^O =~ m/MSWin/) {
    die "Sorry, Alien::FFTW3 doesn't work for Microsoft Windows.\n\n  Maybe someone will fix it for Microsoft systems.\n\n  Maybe that someone is you.";
}


##############################
# Microsoft is not the only group with a broken system.  Some Linuxen
# (e.g. F***ing Fedora) break the FFTW3 configure script by putting
# stuff in /usr/lib64 instead of /usr/lib or somewhere else sane.
# Similarly, the install script for FFTW3 *only* puts .pc files in
# a directory called "pkgconfig" in the same place it is putting the 
# libraries themselves.  That prevents us from specifying that it 
# put them in, say, /usr/share/pkgconfig or someplace sane like that.
#
# Since we don't want multiple .pc files floating around, the most
# straightforward way out of the dilemma is to force the libraries to be
# installed in a lib path (if available) that is in the pkg-config 
# default path.
# 
# Also, we need to ensure we stick the .pc files for this installation
# into a place where pkg-config looks by defauls, so that it will find
# them.  So try some heuristics here.

my $s = `pkg-config --variable pc_path pkg-config`;
unless($s) {
    die "Couldn't run pkg-config! I give up.";
}
chomp($s);
my @pkg_config_dirs = split /\:/,$s;

my $first_lib64 = "";
my $first_lib = "";
my $first_share_pc = "";
for my $d(@pkg_config_dirs) {
    $first_lib64    = $d if( !$first_lib64    and  $d=~ s:(.*\/lib64)\/pkgconfig$:$1: );
    $first_lib      = $d if( !$first_lib      and  $d=~ s:(.*\/lib)\/pkgconfig$:$1: );
    $first_share_pc = $d if( !$first_share_pc and  $d=~ m:.*\/share\/pkgconfig$: );
}

my $bonus_install_command = "";
my $dest_libdir = $first_lib || $first_lib64 || "";
my $prefix = "%s";

if($dest_libdir) {
    my $s = $dest_libdir;
    if( $s =~ s:(.*)\/[^\/]+:$1: ) {  # lop off the final directory (lib part)
	$prefix = $s;
    }
} else {
    if($first_share_pc) {
	$bonus_install_command = "mv %s/lib/pkgconfig/fftw*.pc $first_share_pc";
    } else {
	die "Couldn't figure out a reasonable place to stick the pkg-config files for fftw.\n  Sorry, you're on your own.";
    }
}

my $alien_install_commands = [];


unless(`pkg-config --libs fftw3`) {
    print <<"FOO";
Alien::FFTW3: fftw3 library not found.  On "Build install", I will attempt to 
fetch and build the fftw3 library and install it into the '$prefix' tree (the 
floating-point and double-precision variants only).  The libraries will get
installed into '$dest_libdir'. 

FOO

$alien_install_commands =  [
    "%pconfigure --prefix=$prefix ".($dest_libdir?"--libdir=$dest_libdir":""),
    'make',
    'make install',
    "%pconfigure --prefix=$prefix ".($dest_libdir?"--libdir=$dest_libdir":""). " --enable-single ",
    'make',
    'make install',
    $bonus_install_command || "echo 1"
]
}
    

##############################
# Finally -- do the building.

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new (
    module_name => 'Alien::FFTW3',
    license => 'perl',
    configure_requires => {
	'Alien::Base' => '0.002',
	'Module::Build' => '0.38'
    },
    requires => {
	'perl' => '5.8.1',
	'Alien::Base' => 0,
    },
    dist_author => 'Craig DeForest <deforest@boulder.swri.edu>',
    alien_name => 'fftw3',
    alien_repository => {
	protocol => 'ftp',
	host => 'www.fftw.org',
	location => '/pub/fftw/',
	pattern => qr/fftw-(3\.[\d\.]*).tar.gz/
    },

    # Do nothing on build.
    alien_build_commands => [
    ],

    install_type => 'system',

    # Do the installation on install...
    alien_install_commands =>  $alien_install_commands ,
	
    # alien_build_commands not necessary -- use default configure
    # alien_install_commands not necessary -- use default install
    
    meta_merge => {
	resources => {
	    homepage => 'https://github.com/drzowie/alien-fftw3',
	    bugtracker => 'https://github.com/drzowie/alien-fftw3/issues',
	    repository => 'git://github.com/ddrzowie/alien-fftw3.git'
	}
    }
    );


$builder->create_build_script;


__END__


use Module::Build;


my $builder = new Module::Build( 
    module_name => 'Alien::FFTW3';
    needs_compiler => 1,
    create_packlist => 1,
    dist_abstract => 'Simple installation and compatibility for FFTW3',
    dist_author => 'Craig DeForest <deforest@boulder.swri.edu>',
    dynamic_config=>1,
    installdirs => 'vendor',
    license => 'artistic_2',
    meta_merge => {
	    homepage => 'https://github.com/drzowie/alien-fftw3',
	    bugtracker => 'https://github.com/drzowie/alien-fftw3/issues',
	    repository => 'git://github.com/ddrzowie/alien-fftw3.git'
    }
    );
