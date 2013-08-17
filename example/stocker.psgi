use strict;
use warnings;
use Plack::Builder;
use Acme::Plack::App::GyazoStocker;
use File::Temp qw/tempdir/;
use Config::Pit qw//;

my $AUTH_BASIC = Config::Pit::get('auth_basic');

my $stocker = Acme::Plack::App::GyazoStocker->new(
    image_dir => tempdir(),
)->to_app;

builder {
    enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
        'ReverseProxy';
    enable_if { $_[0]->{PATH_INFO} =~ m!^/[a-f\d]{32}(?:\.png)?$! }
        'Auth::Basic', authenticator => \&authen_cb;
    $stocker;
};

sub authen_cb {
    my($username, $password, $env) = @_;

    return $username eq $AUTH_BASIC->{username}
                && $password eq $AUTH_BASIC->{password};
}
