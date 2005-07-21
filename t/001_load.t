use warnings FATAL => 'all';
use strict;

use Test::More tests => 4;
use POSIX qw(setuid);

BEGIN { use_ok( 'Test::TempDatabase' ); }

unless ($<) {
	diag("Setting postgres uid");
	my $p_uid = getpwnam('postgres');
	setuid($p_uid) or die "Unable to set $p_uid uid";
}

my $test_db = Test::TempDatabase->create(dbname => 'test_temp_db_test');
like(join('', `psql -l`), qr/test_temp_db_test/);

my $dbh = $test_db->handle;
ok($dbh->do(q{ create table test_table (a integer) }));

$dbh->do(q{ create database test_temp_db_test_2 });

undef $test_db;

$test_db = Test::TempDatabase->create(dbname => 'test_temp_db_test_2');
ok($test_db);
