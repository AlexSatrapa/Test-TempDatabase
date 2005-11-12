use warnings FATAL => 'all';
use strict;

use Test::More tests => 2;
use POSIX qw(setuid);

BEGIN {
	use_ok('Test::TempDatabase');
};

Test::TempDatabase->become_postgres_user;
unlike(join('', `psql -l`), qr/test_temp_db_test/);

