use strict;
use warnings FATAL => 'all';

package Test::TempDatabase;

our $VERSION = 0.01;
use DBI;
use DBD::Pg;

=head1 NAME

Test::TempDatabase - temporary database creation and destruction.

=head1 SYNOPSIS

  use Test::TempDatabase;
  
  my $td = Test::TempDatabase->create('temp_db');
  my $dbh = $td->db_handle;

  ... some tests ...
  # Test::TempDatabase drops database

=head1 DESCRIPTION

This module automates creation and dropping of test databases.

=head1 USAGE

Create test database using Test::TempDatabase->create. Use db_handle
to get a handle to the database. Database will be automagically dropped
when Test::TempDatabase instance goes out of scope.

=head1 BUGS

Works with PostgreSQL database currently.

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

=head2 create

Creates temporary database. It will be dropped when the resulting
instance will go out of scope.

=cut

sub create {
	my ($class, $db_name) = @_;
	my $self = bless { db_name => $db_name }, $class;
	`createdb $db_name >& /dev/null`;
	my $dbh = DBI->connect("dbi:Pg:dbname=$db_name", "", "",
			{ RaiseError => 1, AutoCommit => 1 });
	$self->{db_handle} = $dbh;
	return $self;
}

sub name { return shift()->{db_name}; }
sub handle { return shift()->{db_handle}; }

sub DESTROY {
	my $self = shift;
	my $db_name = $self->name;
	$self->handle->disconnect;
	`dropdb $db_name >& /dev/null`;
}

1; 
