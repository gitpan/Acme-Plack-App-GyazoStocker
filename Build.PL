use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Acme-Plack-App-GyazoStocker',
    module_name         => 'Acme::Plack::App::GyazoStocker',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Acme/Plack/App/GyazoStocker.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Plack::Test' => 0,
        'HTTP::Request::Common' => 0,
        'File::Temp' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'Carp' => 0,
        'HTTP::Status' => 0,
        'LWP::UserAgent' => 0,
        'Plack::App::File' => 0,
        'Plack::Component' => 0,
        'Plack::Request' => 0,
        'Plack::Util' => 0,
        'Plack::Util::Accessor' => 0,
    },
    add_to_cleanup      => [ 'Acme-Plack-App-GyazoStocker-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Acme-Plack-App-GyazoStocker',
        bugtracker  => 'http://github.com/bayashi/Acme-Plack-App-GyazoStocker/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
