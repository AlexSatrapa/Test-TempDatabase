use warnings FATAL => 'all';
use strict;

use Test::More tests => 5;
use File::Temp qw(tempdir);

BEGIN { use_ok( 'Test::TempDatabase' ); }

SKIP: {
skip "Should not be root to run this test", 4 unless $<;
my $td = tempdir('/tmp/temp_db_300_XXXXXX', CLEANUP => 1);

my $test_db = Test::TempDatabase->new({ dbname => 'test_temp_db_test'
			, cluster_dir => $td });
isa_ok($test_db, 'Test::TempDatabase');
$test_db->create_cluster;
isnt(-f "$td/postgresql.conf", undef);

my @ns = `netstat -l | grep PG`;
$test_db->start_server;
my @ns2 = `netstat -l | grep PG`;
is(@ns2, @ns + 1);

$test_db->stop_server;
my @ns3 = `netstat -l | grep PG`;
is(@ns3, @ns);
};
