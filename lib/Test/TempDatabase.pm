use strict;
use warnings FATAL => 'all';

package Test::TempDatabase;

our $VERSION = 0.15;
use DBI;
use DBD::Pg;
use POSIX qw(setuid);
use Carp;
use File::Slurp;

=head1 NAME

Test::TempDatabase - temporary database creation and destruction.

=head1 SYNOPSIS

  use Test::TempDatabase;
  
  my $td = Test::TempDatabase->create(dbname => 'temp_db');
  my $dbh = $td->handle;

  ... some tests ...
  # Test::TempDatabase drops database

=head1 DESCRIPTION

This module automates creation and dropping of test databases.

=head1 USAGE

Create test database using Test::TempDatabase->create. Use C<handle>
to get a handle to the database. Database will be automagically dropped
when Test::TempDatabase instance goes out of scope.

=cut
sub connect {
	my ($self, $db_name) = @_;
	my $cp = $self->connect_params;
	my $dbi_args = $cp->{dbi_args} || { RaiseError => 1, AutoCommit => 1 };
	return DBI->connect("dbi:Pg:dbname=$db_name;" . ($cp->{rest} || ''),
				$cp->{username}, $cp->{password}, $dbi_args);
}

sub find_postgres_user {
	return $< if $<;

	my $uname = $ENV{TEST_TEMP_DB_USER} || $ENV{SUDO_USER} || "postgres";
	return getpwnam($uname);
}

=head2 $class->become_postgres_user

When running as root, this function becomes different user.
It decides on the user name by probing TEST_TEMP_DB_USER, SUDO_USER environment
variables. If these variables are empty, default "postgres" user is used.

=cut
sub become_postgres_user {
	my $class = shift;
	return if $<;

	my $p_uid = $class->find_postgres_user;
	my @pw = getpwuid($p_uid);

	carp("# $class\->become_postgres_user: setting $pw[0] uid\n");
	setuid($p_uid) or die "Unable to set $p_uid uid";
	$ENV{HOME} = $pw[ $#pw - 1 ];
}

=head2 create

Creates temporary database. It will be dropped when the resulting
instance will go out of scope.

Arguments are passed in as a keyword-value pairs. Available keywords are:

dbname: the name of the temporary database.

rest: the rest of the database connection string.  It can be used to connect to
a different host, etc.

username, password: self-explanatory.

=cut
sub create {
	my ($class, %args) = @_;
	my $self = $class->new(\%args);
	$self->become_postgres_user;

	my $dbh = $self->connect('template1');

	my $arr = $dbh->selectcol_arrayref(
			"select datname from pg_database where "
			. "datname = '" . $args{dbname} . "'");
	$dbh->do("drop database \"$args{dbname}\"")
		if (!$args{no_drop} && @$arr);

	$self->try_really_hard($dbh, "create database \"$args{dbname}\"")
		unless (@$arr && $args{no_drop});
	$dbh->disconnect;
	$dbh = $self->connect($args{dbname});
	$self->{db_handle} = $dbh;

	if (my $schema = $args{schema}) {
		my $vs = $schema->new($dbh);
		$vs->run_updates;
		$self->{schema} = $vs;
	}
	return $self;
}

sub new {
	my ($class, $args) = @_;
	my $self = bless { connect_params => $args }, $class;
	$self->{pid} = $$;
	return $self;
}

sub create_cluster {
	my $self = shift;
	my $pg_conf = `pg_config | grep BINDIR`;
	my ($bdir) = ($pg_conf =~ /= (\S+)$/);
	die "No binary dir found: $pg_conf\n" unless $bdir;
	my $cdir = $self->{connect_params}->{cluster_dir};
	my $res = `$bdir/initdb -D $cdir 2>&1`;
	die $res if $?;

	append_file("$cdir/postgresql.conf"
		, "\nlisten_addresses = ''\nunix_socket_directory = '$cdir'\n");
}

sub start_server {
	my $self = shift;
	my ($bdir) = (`pg_config | grep BINDIR` =~ /= (\S+)$/);
	my $cdir = $self->{connect_params}->{cluster_dir};
	system("$bdir/pg_ctl -D $cdir -l $cdir/log start") and die;

	sleep 1;
	for (1 .. 5) {
		my $log = read_file("$cdir/log");
		return if $log =~ /ready to accept/;
		sleep 1;
	}
	die "Server did not start " . read_file("$cdir/log");
}

sub stop_server {
	my $self = shift;
	my ($bdir) = (`pg_config | grep BINDIR` =~ /= (\S+)$/);
	my $cdir = $self->{connect_params}->{cluster_dir};
	system("$bdir/pg_ctl -D $cdir -l $cdir/log stop") and die;
}

sub connect_params { return shift()->{connect_params}; }
sub handle { return shift()->{db_handle}; }

sub try_really_hard {
	my ($self, $dbh, $cmd) = @_;
	$dbh->do("set client_min_messages to fatal");
	local $dbh->{PrintError};
	local $dbh->{PrintWarn};
	local $dbh->{RaiseError};
	local $dbh->{HandleError};
	my $res;
	for (my $i = 0; $i < 5; $i++) {
		$res = $dbh->do($cmd) and last;
		sleep 1;
	}
	printf STDERR "# Fatal failure %s doing $cmd\n", $dbh->errstr
		unless $res;
}

sub destroy {
	my $self = shift;
	return if $self->handle->{InactiveDestroy};
	$self->handle->disconnect;
	$self->{db_handle} = undef;
	return unless $self->{pid} == $$;
	return if $self->connect_params->{no_drop};
	my $dn = $self->connect_params->{dbname};
	my $dbh = $self->connect('template1');
	$self->try_really_hard($dbh, "drop database \"$dn\"");
	$dbh->disconnect;
}

sub DESTROY {
	my $self = shift;
	$self->destroy if $self->handle;
}

=head1 BUGS

* Works with PostgreSQL database currently.

=head1 AUTHOR

	Boris Sukholitko
	boriss@gmail.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Test::More

=cut

1; 
