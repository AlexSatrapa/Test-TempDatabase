use strict;
use warnings FATAL => 'all';

package Test::TempDatabase;

our $VERSION = 0.03;
use DBI;
use DBD::Pg;

=head1 NAME

Test::TempDatabase - temporary database creation and destruction.

=head1 SYNOPSIS

  use Test::TempDatabase;
  
  my $td = Test::TempDatabase->create(dbname => 'temp_db');
  my $dbh = $td->db_handle;

  ... some tests ...
  # Test::TempDatabase drops database

=head1 DESCRIPTION

This module automates creation and dropping of test databases.

=head1 USAGE

Create test database using Test::TempDatabase->create. Use db_handle
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

sub create {
	my ($class, %args) = @_;
	my $self = bless { connect_params => \%args }, $class;
	my $dbh = $self->connect('template1');
	$dbh->do("create database " . $args{dbname});
	$dbh->disconnect;
	$dbh = $self->connect($args{dbname});
	$self->{db_handle} = $dbh;
	return $self;
}

sub connect_params { return shift()->{connect_params}; }
sub handle { return shift()->{db_handle}; }

sub DESTROY {
	my $self = shift;
	$self->handle->disconnect;
	my $dn = $self->connect_params->{dbname};
	my $dbh = $self->connect('template1');
	$dbh->do("drop database $dn");
	$dbh->disconnect;
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
