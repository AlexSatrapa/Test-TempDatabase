use warnings FATAL => 'all';
use strict;

use Test::More tests => 5;

BEGIN { use_ok( 'Test::TempDatabase' ); }

my $test_db = Test::TempDatabase->create(dbname => 'test_temp_db_test');
like(join('', `psql -l`), qr/test_temp_db_test/);

my $dbh = $test_db->handle;
ok($dbh->do(q{ create table test_table (a integer) }));

$dbh->do(q{ create database test_temp_db_test_2 });

undef $test_db;

package FakeSchema;
sub new {
	my ($class, $dbh) = @_;
	return bless({ dbh => $dbh }, $class);
}

sub run_updates {
	my $self = shift;
	$self->{dbh}->do("create table aaa (a integer)");
}

package main;
$test_db = Test::TempDatabase->create(dbname => 'test_temp_db_test_2',
					schema => 'FakeSchema');
ok($test_db);
is_deeply($test_db->handle->selectcol_arrayref("select count(*) from aaa"), 
		[ 0 ]);

