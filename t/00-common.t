use Test::More;

# load module
BEGIN {
    use_ok( 'boolean' );
    use_ok( 'MongoDB' );
    use_ok( 'MongoDB::QueryBuilder' );
}

{
    # instantiation - failure
    my $query = eval {
        MongoDB::QueryBuilder->new(
            where  => ['cd.title' => 'some_title'],
            any_in => ['cd.artist' => 'some_artist'],
            page   => [25, 0],
            'x'
        );
    };
    ok $@, 'The object isnota MongoDB::QueryBuilder: Uneven list passed to constructor';
}

{
    # instantiation - list
    my $query = MongoDB::QueryBuilder->new(
        where  => ['cd.title' => 'some_title'],
        any_in => ['cd.artist' => 'some_artist'],
        page   => [25, 0],
    );
    isa_ok $query, 'MongoDB::QueryBuilder';
}

{
    # instantiation - hashref
    my $query = MongoDB::QueryBuilder->new({
        where  => ['cd.title' => 'some_title'],
        any_in => ['cd.artist' => 'some_artist'],
        page   => [25, 0],
    });
    isa_ok $query, 'MongoDB::QueryBuilder';
}

{
    # object properties and methods existence
    my $query = MongoDB::QueryBuilder->new;
    isa_ok $query, 'MongoDB::QueryBuilder';
    ok exists $query->{collection}, "The MongoDB::QueryBuilder object has a collection property";
    ok exists $query->{criteria},   "The MongoDB::QueryBuilder object has a criteria property";
    ok exists $query->{criteria}{$_}, "The MongoDB::QueryBuilder object has a criteria/$_ property" for qw(select where order options);
    can_ok $query, qw (new all_in and_where any_in asc_sort collection criteria cursor desc_sort limit near never not_in offset only or_where page sort where where_exists where_not_exists);
}

{
    # all_in method
    my $query = MongoDB::QueryBuilder->new(
        all_in => [tags => ['hip-hop', 'rap']]
    );
    is_deeply $query->criteria->{where}, {
        tags => { '$all' => ['hip-hop', 'rap'] }
    },
    'MongoDB::QueryBuilder->all_in(...) - Usage and Criteria OK';
}

{
    # and_where method
    my $query = MongoDB::QueryBuilder->new(
        and_where => ['quantity$lt' => 50, status => 'available']
    );
    is_deeply $query->criteria->{where}, {
        '$and' => [{quantity=>{'$lt' => 50}}, {'status' => 'available'}]
    },
    'MongoDB::QueryBuilder->all_of(...) - Usage and Criteria OK';
}

{
    # any_in method
    my $query = MongoDB::QueryBuilder->new(
        any_in => [tags => ['hip-hop', 'rap']]
    );
    is_deeply $query->criteria->{where}, {
        tags => { '$in' => ['hip-hop', 'rap'] }
    },
    'MongoDB::QueryBuilder->any_in(...) - Usage and Criteria OK';
}

{
    # asc_sort method
    my $query = MongoDB::QueryBuilder->new(
        asc_sort => ['artist.first_name', 'artist.last_name']
    );
    is_deeply $query->criteria->{order}, {
        'artist.first_name' => 1, 'artist.last_name' => 1
    },
    'MongoDB::QueryBuilder->asc_sort(...) - Usage and Criteria OK';
}

{
    # desc_sort method
    my $query = MongoDB::QueryBuilder->new(
        desc_sort => ['artist.first_name', 'artist.last_name']
    );
    is_deeply $query->criteria->{order}, {
        'artist.first_name' => -1, 'artist.last_name' => -1
    },
    'MongoDB::QueryBuilder->desc_sort(...) - Usage and Criteria OK';
}

{
    # limit method
    my $query = MongoDB::QueryBuilder->new(
        limit => 25
    );
    is_deeply $query->criteria->{options}, {
        limit => 25
    },
    'MongoDB::QueryBuilder->limit(...) - Usage and Criteria OK';
}

{
    # near method
    my $query = MongoDB::QueryBuilder->new(
        near => ['store.location.latlng' => [52.30, 13.25]]
    );
    is_deeply $query->criteria->{where}, {
        'store.location.latlng' => { '$near' => [52.30, 13.25] }
    },
    'MongoDB::QueryBuilder->near(...) - Usage and Criteria OK';
}

{
    # never method
    my $query = MongoDB::QueryBuilder->new(
        never => ['password', 'apikey']
    );
    is_deeply $query->criteria->{select}, {
        'password' => 0,
        'apikey'   => 0
    },
    'MongoDB::QueryBuilder->never(...) - Usage and Criteria OK';
}

{
    # nor_where method
    my $query = MongoDB::QueryBuilder->new(
        nor_where => ['quantity$lte' => 30, 'quantity$gte' => 10]
    );
    is_deeply $query->criteria->{where}, {
        '$nor' => [{quantity=>{'$lte' => 30}}, {quantity=>{'$gte' => 10}}]
    },
    'MongoDB::QueryBuilder->nor_where(...) - Usage and Criteria OK';
}

{
    # not_in method
    my $query = MongoDB::QueryBuilder->new(
        not_in => ['artist.last_name' => ['Jackson', 'Nelson']]
    );
    is_deeply $query->criteria->{where}, {
        'artist.last_name' => { '$nin' => ['Jackson', 'Nelson'] }
    },
    'MongoDB::QueryBuilder->never(...) - Usage and Criteria OK';
}

{
    # offset method
    my $query = MongoDB::QueryBuilder->new(
        offset => 1
    );
    is_deeply $query->criteria->{options}, {
        offset => 1
    },
    'MongoDB::QueryBuilder->offset(...) - Usage and Criteria OK';
}

{
    # only method
    my $query = MongoDB::QueryBuilder->new(
        only => ['artist.first_name', 'artist.last_name']
    );
    is_deeply $query->criteria->{select}, {
        'artist.first_name' => 1,
        'artist.last_name'  => 1
    },
    'MongoDB::QueryBuilder->only(...) - Usage and Criteria OK';
}

{
    # or_where method
    my $query = MongoDB::QueryBuilder->new(
        or_where => ['quantity$lte' => 30, 'quantity$gte' => 10]
    );
    is_deeply $query->criteria->{where}, {
        '$or' => [{quantity=>{'$lte' => 30}}, {quantity=>{'$gte' => 10}}]
    },
    'MongoDB::QueryBuilder->or_where(...) - Usage and Criteria OK';
}

{
    # page method
    my $query = MongoDB::QueryBuilder->new(
        page => [25,1]
    );
    is_deeply $query->criteria->{options}, {
        limit  => 25,
        offset => 25
    },
    'MongoDB::QueryBuilder->page(...) - Usage and Criteria OK';
}

{
    # sort method
    my $query = MongoDB::QueryBuilder->new(
        sort => ['artist.first_name' => 1, 'artist.last_name' => -1]
    );
    is_deeply $query->criteria->{order}, {
        'artist.first_name' =>  1,
        'artist.last_name'  => -1
    },
    'MongoDB::QueryBuilder->sort(...) - Usage and Criteria OK';
}

{
    # where method
    my $query;
    $query = MongoDB::QueryBuilder->new(
        where => ['agent.office.location$within$center' => [[0,0],10]]
    );
    is_deeply $query->criteria->{where}, {
        'agent.office.location' => {'$within' => {'$center' => [[0,0],10]}}
    },
    'MongoDB::QueryBuilder->where(...) - Usage and Criteria OK';
}

{
    # where_exists method
    my $query;
    $query = MongoDB::QueryBuilder->new(
        where_exists => ['artist.phone_number']
    );
    is_deeply $query->criteria->{where}, {
        'artist.phone_number' => {'$exists' => boolean::true}
    },
    'MongoDB::QueryBuilder->where_exists(...) - Usage and Criteria OK';
}

{
    # where_not_exists method
    my $query = MongoDB::QueryBuilder->new(
        where_not_exists => ['artist.phone_number']
    );
    is_deeply $query->criteria->{where}, {
        'artist.phone_number' => {'$exists' => boolean::false}
    },
    'MongoDB::QueryBuilder->where_not_exists(...) - Usage and Criteria OK';
}

{
    my $client;

    eval {
        my $host = $ENV{MONGOD} || "localhost";
        $client  = MongoDB::MongoClient->new(host=>$host,ssl=>$ENV{MONGO_SSL});
    };

    # synopsis example method
    unless ($@) {

        my $database   = $client->get_database('musicbox');
        my $collection = $database->get_collection('cds');

        my $query = MongoDB::QueryBuilder->new(
            collection => $collection,
            and_where  => ['cd.title'            => 'Pokey Shuffle'],
            and_where  => ['cd.released$gt$date' => time()],
            any_in     => ['cd.artist'           => 'Gummy Bear'],
            page       => [25, 0],
        );

        my $cursor = $query->cursor;

        isa_ok $cursor, 'MongoDB::Cursor';

    }
}

done_testing;
