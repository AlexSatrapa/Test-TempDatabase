use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;
use File::Temp qw(tempdir);
use File::Slurp;

BEGIN { use_ok('Test::TempDatabase'); }

my $td = tempdir("/tmp/tt_setuid_XXXXXX", CLEANUP => 1);

sub do_become {
	my %env = @_;
	my $pid = fork;
	if ($pid) {
		waitpid($pid, 0);
		return;
	}
	while (my ($n, $v) = each %env) {
		$ENV{ $n } = $v;
	}
	open(STDERR, ">$td/stderr");
	Test::TempDatabase->become_postgres_user;
	exit;
}

SKIP: {
skip "Should be root to run this test", 3 if $<;
do_become(TEST_TEMP_DB_USER => "root");
like(read_file("$td/stderr"), qr/using \$ENV{TEST_TEMP_DB_USER}/);
do_become(TEST_TEMP_DB_USER => "", SUDO_USER => "root");
like(read_file("$td/stderr"), qr/using \$ENV{SUDO_USER}/);
do_become(TEST_TEMP_DB_USER => "", SUDO_USER => "");
like(read_file("$td/stderr"), qr/default postgres/);
};
