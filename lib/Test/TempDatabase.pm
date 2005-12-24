use strict;
use warnings FATAL => 'all';

package Test::TempDatabase;

our $VERSION = 0.08;
use DBI;
use DBD::Pg;
use POSIX qw(setuid);

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

=head2 create

Creates temporary database. It will be dropped when the resulting
instance will go out of scope.

Arguments are passed in as a keyword-value pairs. Available keywords are:

dbname: the name of the temporary database.

rest: the rest of the database connection string.  It can be used to connect to a different host, etc.

username, password: self-explanatory

=cut

sub connect {
	my ($self, $db_name) = @_;
	my $cp = $self->connect_params;
	return DBI->connect("dbi:Pg:dbname=$db_name;" . ($cp->{rest} || ''),
				$cp->{username}, $cp->{password},
			{ RaiseError => 1, AutoCommit => 1 });
}

sub become_postgres_user {
	return if $<;
	print STDERR "# Setting postgres uid\n";
	my $p_uid = getpwnam('postgres');
	setuid($p_uid) or die "Unable to set $p_uid uid";
}

sub create {
	my ($class, %args) = @_;
	my $self = bless { connect_params => \%args }, $class;
	$self->{pid} = $$;
	$self->become_postgres_user;

	my $dbh = $self->connect('template1');

	my $arr = $dbh->selectcol_arrayref(
			"select datname from pg_database where "
			. "datname = '" . $args{dbname} . "'");
	$dbh->do("drop database \"" . $args{dbname} . "\"") if (@$arr);

	$self->try_really_hard(
			$dbh, "create database \"" . $args{dbname} . "\"");
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

sub connect_params { return shift()->{connect_params}; }
sub handle { return shift()->{db_handle}; }

sub try_really_hard {
	my ($self, $dbh, $cmd) = @_;
	$dbh->do("set client_min_messages to fatal");
	$dbh->{PrintError} = 0;
	$dbh->{PrintWarn} = 0;
	for (my $i = 0; $i < 5; $i++) {
		eval { $dbh->do($cmd); };
		last unless $@;
		sleep 1;
	}
	print STDERR "# Fatal failure $@\n" if $@;
}

sub destroy {
	my $self = shift;
	$self->handle->disconnect;
	$self->{db_handle} = undef;
	return unless $self->{pid} == $$;
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
	bobatonhu@yahoo.co.uk

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Test::More

=cut

1; 
