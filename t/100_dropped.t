use warnings FATAL => 'all';
use strict;

use Test::More tests => 1;
use POSIX qw(setuid);

unless ($<) {
	diag("Setting postgres uid");
	my $p_uid = getpwnam('postgres');
	setuid($p_uid) or die "Unable to set $p_uid uid";
}

unlike(join('', `psql -l`), qr/test_temp_db_test/);

