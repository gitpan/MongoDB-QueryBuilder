# ABSTRACT: Query Builder for MongoDB

package MongoDB::QueryBuilder;

use strict;
use warnings;

use boolean;
use Hash::Flatten 'flatten', 'unflatten';
use Hash::Merge   'merge';

Hash::Merge::set_behavior('RIGHT_PRECEDENT');

our $VERSION = '0.0003'; # VERSION



sub new {

    my $class = shift;
       $class = ref $class || $class;

    my @actions  = ();

    if (scalar @_ == 1) {
        if (defined $_[0] && ref $_[0] eq 'HASH') {
            push @actions, %{(shift(@_))};
        }
    }

    elsif (@_ % 2) {
        die sprintf
            'The new() method for %s expects a hash reference or a '
          . 'key/value list. You passed an odd number of arguments',
            $class
        ;
    }

    else {
        push @actions, @_;
    }

    my $self  = bless {

        criteria   => {
            select  => {},
            where   => {},
            order   => {},
            options => {}
        },
        collection => undef,

    },  $class;

    # execute startup actions

    for (my $i=0; $i<@actions; $i++) {

        my $action = $actions[$i];
        my $values = $actions[++$i];

        $self->$action($values) unless $action eq 'cursor';

    }

    # end scene

    return $self;

}

sub _get_args_array {

    my $self = shift;

    return "ARRAY" eq ref $_[0] ? $_[0] : [@_];

}

sub _set_where_clause {

    my $self     = shift;
    my $criteria = shift;

    # collapse and explode query operators

    $criteria = flatten $criteria;

    for my $key (keys %{$criteria}) {
        if ($key =~ /\$/) {
            my $nkey = $key; $nkey =~ s/(\w)\$/$1.\$/g;
            $criteria->{$nkey} = delete $criteria->{$key};
        }
    }

    # expand and merge conditions

    $self->criteria->{where} =
        merge $self->criteria->{where}, unflatten $criteria
    ;

    return $self;

}


sub all_in {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $criteria = {$args->[0] => { '$all' => $args->[1] }};

    $self->_set_where_clause($criteria);

    return $self;

}


sub and_where {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $criteria = {};
    my $and = [];
    my $i = 0;

    while (my($key, $val) = splice @{$args}, 0, 2) {
        $and->[$i]->{$key} = $val;
        $i++;
    }

    $criteria->{'$and'} = $and;

    $self->_set_where_clause($criteria);

    return $self;

}


sub any_in {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $criteria = {$args->[0] => {'$in' => $args->[1]}};

    $self->_set_where_clause($criteria);

    return $self;

}


sub asc_sort {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    foreach my $key (@{$args}) {
        $self->criteria->{order}->{$key} = 1;
    }

    return $self;

}



sub collection {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $collection = $args->[0];

    my $die_msg = sprintf
        'The collection() method for %s requires a MongoDB::Collection object',
        ref $self
    ;

    die $die_msg
        if @_ && (!$collection || !$collection->isa('MongoDB::Collection'))
    ;

    $self->{collection} = $collection if $collection;

    return $self->{collection};

}


sub criteria {

    my ($self) = @_;

    return $self->{criteria};

}


sub criteria_where {

    my ($self) = @_;

    return $self->{criteria}->{where};

}


sub cursor {

    my $self = shift;

    my $cri = $self->criteria;
    my $col = $self->collection;
    my $cur = $col->query($cri->{where});

    $cur->fields($cri->{select})          if values %{$cri->{select}};
    $cur->sort($cri->{order})             if values %{$cri->{order}};
    $cur->limit($cri->{options}->{limit}) if $cri->{options}->{limit};
    $cur->skip($cri->{options}->{offset}) if $cri->{options}->{offset};

    return $cur;
}


sub desc_sort {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    foreach my $key (@{$args}) {
        $self->criteria->{order}->{$key} = -1;
    }

    return $self;

}


sub limit {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    $self->criteria->{options}->{limit} = $args->[0] if $args->[0];

    return $self;

}


sub near {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $criteria_nil = {$args->[0] => {'$near' => []}};
    my $criteria_set = {$args->[0] => {'$near' => $args->[1]}};

    $self->_set_where_clause($criteria_nil);
    $self->_set_where_clause($criteria_set);

    return $self;

}


sub never {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    foreach my $key (@{$args}) {
        $self->criteria->{select}->{$key} = 0;
    }

    return $self;

}


sub nor_where {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $criteria = {};
    my $nor = [];
    my $i = 0;

    while (my($key, $val) = splice @{$args}, 0, 2) {
        $nor->[$i]->{$key} = $val;
        $i++;
    }

    $criteria->{'$nor'} = $nor;

    $self->_set_where_clause($criteria);

    return $self;

}


sub not_in {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $criteria = {$args->[0] => {'$nin' => $args->[1]}};

    $self->_set_where_clause($criteria);

    return $self;

}


sub offset {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    $self->criteria->{options}->{offset} = $args->[0] if defined $args->[0];

    return $self;

}


sub only {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    foreach my $key (@{$args}) {
        $self->criteria->{select}->{$key} = 1;
    }

    return $self;

}


sub or_where {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $criteria = {};
    my $or = [];
    my $i = 0;

    while (my($key, $val) = splice @{$args}, 0, 2) {
        $or->[$i]->{$key} = $val;
        $i++;
    }

    $criteria->{'$or'} = $or;

    $self->_set_where_clause($criteria);

    return $self;

}


sub page {

    my $self   = shift;
    my $args   = $self->_get_args_array(@_);
    my $limit  = $args->[0];
    my $page   = $args->[1] || 0;
    my $offset = $limit * $page;

    $self->limit($limit);

    $self->offset($offset);

    return $self;

}


sub sort {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    while (my($key, $val) = splice @{$args}, 0, 2) {
        $self->criteria->{order}->{$key} = $val;
    }

    return $self;

}


sub where {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $criteria = {};

    while (my($key, $val) = splice @{$args}, 0, 2) {
        $criteria->{$key} = $val;
    }

    $self->_set_where_clause($criteria);

    return $self;

}


sub where_exists {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $criteria = {};

    foreach my $key (@{$args}) {
        $criteria->{$key}->{'$exists'} = boolean::true;
    }

    $self->_set_where_clause($criteria);

    return $self;

}



sub where_not_exists {

    my $self = shift;
    my $args = $self->_get_args_array(@_);

    my $criteria = {};

    foreach my $key (@{$args}) {
        $criteria->{$key}->{'$exists'} = boolean::false;
    }

    $self->_set_where_clause($criteria);

    return $self;

}

1;

__END__
=pod

=head1 NAME

MongoDB::QueryBuilder - Query Builder for MongoDB

=head1 VERSION

version 0.0003

=head1 SYNOPSIS

    use MongoDB;
    use MongoDB::QueryBuilder;

    # build query conditions

    my $query = MongoDB::QueryBuilder->new(
        and_where  => ['cd.title'            => $some_title],
        and_where  => ['cd.released$gt$date' => $some_isodate],
        any_in     => ['cd.artist'           => $some_artist],
        page       => [25, 0],
    );

    # .. in sql
    # .. select * from cds cd where cd.title = ? and
    # .. cd.released > ? and cd.artist IN (?) limit 25 offset 0

    # connect and query

    my $client     = MongoDB::MongoClient->new(host => 'localhost:27017');
    my $database   = $client->get_database('musicbox');
    my $collection = $query->collection($database->get_collection('cds'));
    my $cursor     = $query->cursor;

    while (my $album = $cursor->next) {
        say $album->{name};
    }

=head1 DESCRIPTION

MongoDB::QueryBuilder provides an interface to query L<MongoDB> using chainable
objects for building complex and dynamic queries. This module will only hit the
database when you ask it to return a L<MongoDB::Cursor> object.

=head1 METHODS

=head2 new

The new method is the object constructor, it accepts a single hashref or list
containing action/value pairs where an action is a MongoDB::QueryBuilder class
method and a value is a scalar or arrayref. All methods that do not interact
with the database can be passed as an argument.

    my $query = MongoDB::QueryBuilder->new(
        where => ['record_label' => 'Time-Warner'],
        limit => 25
    );

=head2 all_in

The all_in method adds a criterion which returns documents where the field
specified holds an array which contains all of the values specified. The
corresponding MongoDB operation is $all.

    $query->all_in(tags => ['hip-hop', 'rap']);

    # e.g. { "tags" : { "$all" : ['hip-hop', 'rap'] } }

Please see L<http://docs.mongodb.org/manual/reference/operator/all/> for more
information.

=head2 and_where

The and_where method adds a criterion which returns documents where the clauses
specified must all match in order to return results. The corresponding MongoDB
operation is $and.

    $query->and_where('quantity$lt' => 50, status => 'available');

    # e.g. { "$and" : [ { "quantity" : { "$lt" : 50 } }, { "status" : "available" } ] }

Please see L<http://docs.mongodb.org/manual/reference/operator/and/> for more
information.

=head2 any_in

The any_in method adds a criterion which returns documents where the field
specified must holds one of the values specified in order to return results.
The corresponding MongoDB operation is $in.

    $query->any_in(tags => ['hip-hop', 'rap']);

    # e.g. { "tags" : { "$in" : ['hip-hop', 'rap'] } }

Please see L<http://docs.mongodb.org/manual/reference/operator/in/> for more
information.

=head2 asc_sort

The asc_sort method adds a criterion that instructs the L<MongoDB::Cursor>
object to sort the results on specified key(s) in ascending order.

    $query->asc_sort('artist.first_name', 'artist.last_name');

=head2 collection

The collection method provides an accessor for the L<MongoDB::Collection>
object used to query the database.

    my $collection = $query->collection($new_collection);

=head2 criteria

The criteria method provides an accessor for the query-specification-object used
to query the database.

    my $criteria = $query->criteria;

=head2 criteria_where

The criteria_where method is a convenience method which provides access to the
query-specification where-clause.

    my $criteria = $query->criteria_where

=head2 cursor

The cursor method analyzes the current query criteria, generates a
L<MongoDB::Cursor> object and queries the databases.

    my $cursor = $query->cursor;

=head2 desc_sort

The desc_sort method adds a criterion that instructs the L<MongoDB::Cursor>
object to sort the results on specified key(s) in ascending order.

    $query->desc_sort('artist.first_name', 'artist.last_name');

=head2 limit

The limit method adds a criterion that instructs the L<MongoDB::Cursor> object
to limit the results by the number specified.

    $query->limit(25);

=head2 near

The near method adds a criterion to find locations that are near the supplied
coordinates. This performs a MongoDB $near selection and requires a 2d index on
the field specified. The corresponding MongoDB operation is $near.

    $query->near('store.location.latlng' => [52.30, 13.25]);

    # e.g. { "store.location.latlng" : { "$near" : [52.30, 13.25] } }

Please see L<http://docs.mongodb.org/manual/reference/operator/near/> for more
information.

=head2 never

The never method adds a criterion that instructs the L<MongoDB::Cursor> object
to select all columns except the ones specified. The opposite of this is the
only() method, these two methods can't be used together.

    $query->never('password', 'apikey');

=head2 nor_where

The nor_where method adds a criterion which returns documents where none of the
clauses specified should match in order to return results. The corresponding
MongoDB operation is $nor.

    $query->nor_where('quantity$lte' => 30, 'quantity$gte' => 10);

    # e.g. { "$nor" : [ { "quantity" : { "$lte" : 30 } }, { "quantity" : { "$gte" : 10 } } ] }

Please see L<http://docs.mongodb.org/manual/reference/operator/nor/> for more
information.

=head2 not_in

The not_in method adds a criterion which returns documents where the field
specified must not hold any of the values specified in order to return results.
The corresponding MongoDB operation is $nin.

    $query->not_in('artist.last_name' => ['Jackson', 'Nelson']);

    # e.g. { "artist.last_name" : { "$nin" : ['Jackson', 'Nelson'] } }

Please see L<http://docs.mongodb.org/manual/reference/operator/nin/> for more
information.

=head2 offset

The offset method adds a criterion that instructs the L<MongoDB::Cursor> object
to offset the results by the number specified.

    $query->limit(25);

=head2 only

The only method adds a criterion that instructs the L<MongoDB::Cursor> object
to select only the columns specified. The opposite of this is the never() method,
these two methods can't be used together.

    $query->only('artist.first_name', 'artist.last_name');

=head2 or_where

The or_where method adds a criterion which returns documents where at-least one
of the clauses specified must match in order to return results. The
corresponding MongoDB operation is $or.

    $query->or_where('quantity$lte' => 30, 'quantity$gte' => 10);

    # e.g. { "$or" : [ { "quantity" : { "$lte" : 30 } }, { "quantity" : { "$gte" : 10 } } ] }

Please see L<http://docs.mongodb.org/manual/reference/operator/or/> for more
information.

=head2 page

The page method is a purely a convenience method which adds a limit and offset
criterion to the query. The page parameter is optional and defaults to 0, it
should be a number that when multiplied by the limit will represents how many
documents should be offset.

    $query->page($limit, $page); # page is optional and defaults to 0

=head2 sort

The sort method adds a criterion that instructs the L<MongoDB::Cursor>
object to sort the results on specified key(s) in the specified order.

    $query->sort('artist.first_name' => -1, 'artist.last_name' => 1);

=head2 where

The where method adds a criterion which returns documents where all or the
clauses specified must be truthful in order to return results.

    $query->where('agent.office.location$within$center' => [[0,0],10]);

    # e.g. { "agent.office.location" : { "$within" : { "$center" : [[0,0],10] } } }

=head2 where_exists

The where_exists method adds a criterion which returns documents where the
fields specified must all exist in order to return results. The corresponding
MongoDB operation is $exists.

    $query->where_exists('artist.email_address', 'artist.phone_number');

    # e.g. { "artist.email_address" : { "$exists" : true }, "artist.phone_number" : { "$exists" : true } }

Please see L<http://docs.mongodb.org/manual/reference/operator/exists/> for more
information.

=head2 where_not_exists

The where_not_exists method adds a criterion which returns documents where the
fields specified must NOT exist in order to return results. The corresponding
MongoDB operation is $exists.

    $query->where_not_exists('artist.terminated');

    # e.g. { "artist.terminated" : { "$exists" : false } }

Please see L<http://docs.mongodb.org/manual/reference/operator/exists/> for more
information.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

