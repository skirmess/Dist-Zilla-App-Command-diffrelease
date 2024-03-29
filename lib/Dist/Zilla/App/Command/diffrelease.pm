# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2021-2022 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

package Dist::Zilla::App::Command::diffrelease;

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
    $self->zilla->log("distribution = $dist_name");
    my $cpan_data = MetaCPAN::Client->new->release($dist_name)->data;
    my $url       = $cpan_data->{download_url};
    $self->zilla->log("url          = $url");
    my $md5 = $cpan_data->{checksum_md5};
    $self->zilla->log("md5          = $md5");
    my $file_name = path( $cpan_data->{download_url} )->basename;
    $self->zilla->log("file name    = $file_name");

    my $cpan_release_dir = path( $self->zilla->root )->absolute->child('.release');
    $self->zilla->log("Removing $cpan_release_dir");
    $cpan_release_dir->remove_tree( { safe => 0 } );
    $self->zilla->log("Creating $cpan_release_dir");
    $cpan_release_dir->mkpath;

    my $cache = path( $self->zilla->root )->absolute->child('.release.cache')->child($md5);
    $self->zilla->log("Creating $cache");
    $cache->mkpath;

    my $file = $cache->child($file_name);
    if ( !-e $file ) {
        $self->zilla->log("Fetching $url");
        my $resp = HTTP::Tiny->new->get($url);
        $self->zilla->log_fatal( $resp->{content} ) if !$resp->{success};
        $file->spew_raw( $resp->{content} );
    }

    my $tar = Archive::Tar->new( $file->stringify );
    {
        $self->zilla->log("Extracting $file in $cpan_release_dir");
        my $wd = pushd( $cpan_release_dir->stringify );    ## no critic (Variables::ProhibitUnusedVarsStricter)
        $tar->extract;
    }

    $self->zilla->log('Building...');
    $self->zilla->ensure_built('--no-tgz');

    my ($cpan_release) = first { -d $_ } $cpan_release_dir->children();
    $self->zilla->log_fatal('no dir found in tar') if !-d $cpan_release;

    system( 'diff', '-ur', $cpan_release->stringify(), $self->zilla->built_in ) == 0 or $self->zilla->log_fatal('Diff failed');

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

=head1 SEE ALSO

L<Dist::Zilla>

=cut
