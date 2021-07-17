package Dist::Zilla::App::Command::diffrelease;

use 5.006;
use warnings;
use strict;

our $VERSION = '0.001';

use Dist::Zilla::App -command;

use Archive::Tar;
use File::pushd;
use HTTP::Tiny;    # https://metacpan.org/pod/HTTP::Tiny#SSL-SUPPORT
use List::Util qw(first);
use MetaCPAN::Client;
use Path::Tiny;

use namespace::autoclean;

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $dist_name = $self->zilla->name;
    $self->log("distribution = $dist_name");
    my $cpan_data = MetaCPAN::Client->new->release($dist_name)->data;
    my $url       = $cpan_data->{download_url};
    $self->log("url          = $url");
    my $md5 = $cpan_data->{checksum_md5};
    $self->log("md5          = $md5");
    my $file_name = path( $cpan_data->{download_url} )->basename;
    $self->log("file name    = $file_name");

    my $cpan_release_dir = path( $self->zilla->root )->absolute->child('.release');
    $self->log("Removing $cpan_release_dir");
    $cpan_release_dir->remove_tree( { safe => 0 } );
    $self->log("Creating $cpan_release_dir");
    $cpan_release_dir->mkpath;

    my $cache = path( $self->zilla->root )->absolute->child('.release.cache')->child($md5);
    $self->log("Creating $cache");
    $cache->mkpath;

    my $file = $cache->child($file_name);
    if ( !-e $file ) {
        $self->log("Fetching $url");
        my $resp = HTTP::Tiny->new->get($url);
        $self->log_fatal( $resp->{content} ) if !$resp->{success};
        $file->spew_raw( $resp->{content} );
    }

    my $tar = Archive::Tar->new( $file->stringify );
    {
        $self->log("Extracting $file in $cpan_release_dir");
        my $wd = pushd( $cpan_release_dir->stringify );    ## no critic (Variables::ProhibitUnusedVarsStricter)
        $tar->extract;
    }

    $self->log('Building...');
    $self->zilla->ensure_built('--no-tgz');

    my ($cpan_release) = first { -d $_ } $cpan_release_dir->children();
    $self->log_fatal('no dir found in tar') if !-d $cpan_release;

    system( 'diff', '-u', $cpan_release->stringify(), $self->zilla->built_in ) == 0 or $self->log_fatal('Diff failed');

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::diffrelease - diff a build with a distribution from CPAN

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

  $ dzil diffrelease

=head1 DESCRIPTION

Diff a build with the latest distribution from CPAN.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Dist-Zilla-App-Command-diffrelease/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Dist-Zilla-App-Command-diffrelease>

  git clone https://github.com/skirmess/Dist-Zilla-App-Command-diffrelease.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=head1 SEE ALSO

L<Dist::Zilla>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
