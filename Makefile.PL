use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Test::TempDatabase',
    VERSION_FROM => 'lib/Test/TempDatabase.pm', # finds $VERSION
    AUTHOR       => 'Boris Sukholitko (bobatonhu@yahoo.co.uk)',
    ABSTRACT     => 'Creates and destructs temporary database for testing purposes',
    PREREQ_PM    => {
                     'Test::More' => 0,
		     'DBD::Pg' => 0,
		     'DBI' => 0,
                    },
);
