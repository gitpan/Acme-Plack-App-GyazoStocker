use strict;
use warnings;
use Test::More 0.88;
use Plack::Test;
use HTTP::Request::Common;
use File::Temp qw/tempdir/;

use Acme::Plack::App::GyazoStocker;

unless( $ENV{TEST_GYAZO_PATH} ) {
    plan skip_all => "no \$ENV{TEST_GYAZO_PATH}.";
}

my $tmp_dir = tempdir( CLEANUP => 1 );

my $app = Acme::Plack::App::GyazoStocker->new(
    image_dir => $tmp_dir,
)->to_app;

{
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/$ENV{TEST_GYAZO_PATH}");

        is $res->code, 302;
        ok -e "$tmp_dir/$ENV{TEST_GYAZO_PATH}";
    };
}

{
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/image/$ENV{TEST_GYAZO_PATH}");

        is $res->code, 200;
        is $res->content_type, 'image/png';
        like $res->content, qr/PNG/;

    };
}

done_testing;
