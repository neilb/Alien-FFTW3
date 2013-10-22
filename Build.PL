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
	location => 'download.html',
	pattern => qr/fftw-([\d\.]*).tar.gz/
    },
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
