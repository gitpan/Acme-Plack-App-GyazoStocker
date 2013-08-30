package Acme::Plack::App::GyazoStocker;
use strict;
use warnings;
use Carp qw/croak carp/;
use HTTP::Status qw//;
use LWP::UserAgent;
use Plack::App::File;
use parent qw/Plack::Component/;
use Plack::Request;
use Plack::Util qw//;
use Plack::Util::Accessor qw/
    image_dir
    req
    ua
    gyazo
/;

our $VERSION = '0.04';

my @ROUTE = (
    [ 'root',  qr!^/[a-f\d]{32}(?:\.png)?$!  ],
    [ 'image', qr!^/image/[a-f\d]{32}\.png$! ],
);

sub prepare_app {
    my $self = shift;

    croak 'require image dir' unless $self->image_dir;
    croak 'not exists image_dir: '. $self->image_dir unless -d $self->image_dir;

    $self->ua or $self->ua(
        LWP::UserAgent->new(
            agent   => __PACKAGE__. "/$VERSION",
            timeout => 15,
        )
    );

    $self->gyazo or $self->gyazo('http://gyazo.com/');
}

sub call {
    my ($self, $env) = @_;

    $self->req( Plack::Request->new($env) );

    my $res;
    my $not_found = 1;
    for my $route (@ROUTE) {
        my ($method, $path_regex) = @{$route};
        if ($env->{REQUEST_URI} =~ m!$path_regex!) {
            $res = $self->$method($env);
            $not_found = 0;
            last;
        }
    }

    if ($not_found) {
        return $self->_return_status(404);
    }

    if (ref $res ne 'ARRAY') {
        return $self->_return_status($res || 500);
    }

    return $res;
}

sub root {
    my ($self, $env) = @_;

    my ($image_file) = ($self->req->path_info =~ m!/([a-f\d]+(?:\.png)?)!);

    unless ($image_file =~ m!\.png$!) {
        $image_file .= '.png';
    }

    if (-e $self->image_dir. "/$image_file") {
        return $self->_redirect("/image/$image_file"); # already exists
    }

    if ( my $image = $self->_fetch_image($image_file) ) {
        open my $fh, '>', $self->image_dir. "/$image_file";
        print $fh $image;
        close $fh;
        return $self->_redirect("/image/$image_file");
    }
}

sub _fetch_image {
    my ($self, $image_file) = @_;

    my $url = $self->gyazo. $image_file;

    my $res = $self->ua->get($url);

    if ($res->is_success) {
        return $res->content;
    }
    else {
        carp $res->status_line. ": $url";
    }

    return;
}

sub image {
    my ($self, $env) = @_;

    $self->{file} ||= Plack::App::File->new({
        root => $self->image_dir,
    });

    my $path = $env->{PATH_INFO};
    $path =~ s!^/image!!;
    local $env->{PATH_INFO} = $path;

    return $self->{file}->call($env);
}

sub _redirect {
    my ($self, $path) = @_;

    my $to_url = $self->req->scheme. '://'. $self->req->uri->host. $path;

    return [ 302, [ 'Location' => $to_url ], [''] ];
}

sub _return_status {
    my $self        = shift;
    my $status_code = shift || 500;

    my $msg = HTTP::Status::status_message($status_code);

    return [
        $status_code,
        [
            'Content-Type' => 'text/plain',
            'Content-Length' => length $msg
        ],
        [$msg]
    ];
}

1;

__END__

=head1 NAME

Acme::Plack::App::GyazoStocker - save Gyazo like images to local


=head1 SYNOPSIS

    use Plack::Builder;
    use Acme::Plack::App::GyazoStocker;

    builder {
        Acme::Plack::App::GyazoStocker->new(image_dir => './image/')->to_app;
    };


=head1 DESCRIPTION

Acme::Plack::App::GyazoStocker is the stocker from Gyazo like images.

When you upload an image to Gyazo, you access to same path of C<Acme::Plack::App::GyazoStocker> app.
Then an image saves your local directory and your client is redirected to the image viewer path ( /image/***.png ) on C<Acme::Plack::App::GyazoStocker>.

See C<example/stock.psgi> for more details.


=head1 METHODS

=over 4

=item prepare_app

=item call

=item root

save an image and redirect to the image viewer path

=item image

view an image

=back


=head1 REPOSITORY

Acme::Plack::App::GyazoStocker is hosted on github
<http://github.com/bayashi/Acme-Plack-App-GyazoStocker>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

<https://gyazo.com/>

L<Plack::Component>

L<Plack::App::File>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
