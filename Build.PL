use strict;
use warnings;

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
	protocol => 'http',
	host => 'www.fftw.org',
	location => '/download.html',
	pattern => qr/fftw-([\d\.]*).tar.gz/
    },
    # alien_build_commands not necessary -- use default configure
    # alien_install_commands not necessary -- use default install
    # alien_version_check not necessary -- use pkg-config
    
    meta_merge => {
	resources => {
	    homepage => 'https://github.com/drzowie/alien-fftw3',
	    bugtracker => 'https://github.com/drzowie/alien-fftw3/issues',
	    repository => 'git://github.com/ddrzowie/alien-fftw3.git'
	}
    }
    );

$builder->create_build_script;
