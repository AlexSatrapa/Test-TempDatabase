use warnings FATAL => 'all';
use strict;

use Test::More tests => 1;
unlike(join('', `psql -l`), qr/test_temp_db_test/);

