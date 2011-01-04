use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Image::ThousandWords',
    'VERSION_FROM'	=> 'ThousandWords.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Image::Size		=> 0,	
	Image::Thumbnail	=> 0.01,
	GD			=> 0.01,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ThousandWords.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <lgoddard-at-cpan.org> and Henning Møller-Nielsen <hmn-at-datagraf.dk> ') : ()),
);
