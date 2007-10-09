use ExtUtils::MakeMaker;

if ($<) {
	my $psql = `psql -l 2>&1`;
	$psql =~ /template1/
		or die "To install this module you should be postgres admin";
}

WriteMakefile(
    NAME         => 'Test::TempDatabase',
    VERSION_FROM => 'lib/Test/TempDatabase.pm', # finds $VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => 'Creates and destructs temporary database for testing purposes',
    PREREQ_PM    => {
                     'Test::More' => 0,
		     'DBD::Pg' => 0,
		     'DBI' => 0,
		     'File::Slurp' => '',
                    },
);
