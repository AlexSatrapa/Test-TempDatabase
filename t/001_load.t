use warnings FATAL => 'all';
use strict;

use Test::More tests => 3;

BEGIN { use_ok( 'Test::TempDatabase' ); }

my $test_db = Test::TempDatabase->create('test_temp_db_test');
like(join('', `psql -l`), qr/test_temp_db_test/);

my $dbh = $test_db->handle;
ok($dbh->do(q{ create table test_table (a integer) }));
