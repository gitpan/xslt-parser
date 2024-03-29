use ExtUtils::MakeMaker;

@extras = ();

push(@extras,
     ABSTRACT_FROM => 'XSLT.pm',
     AUTHOR        => 'Geert Josten (gjosten@sci.kun.nl) and Egon Willighagen (egonw@sci.kun.nl)')
    if ($ExtUtils::MakeMaker::Version >= 5.4301);

WriteMakefile(
              NAME	=> 'XML::XSLT',
              dist      => {COMPRESS => 'gzip', SUFFIX => '.gz'},
              VERSION_FROM => 'XSLT.pm',
              PREREQ_PM => { XML::Parser => '2.26', XML::DOM => '1.25' },
	      PM => { 'XSLT.pm' => '$(INST_LIBDIR)/XSLT.pm' },
	      @extras
             );

