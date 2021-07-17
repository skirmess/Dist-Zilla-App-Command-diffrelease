use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "diff a build with a distribution from CPAN",
  "AUTHOR" => "Sven Kirmess <sven.kirmess\@kzone.ch>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Dist-Zilla-App-Command-diffrelease",
  "LICENSE" => "open_source",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Dist::Zilla::App::Command::diffrelease",
  "PREREQ_PM" => {
    "Archive::Tar" => 0,
    "Dist::Zilla::App" => 0,
    "File::pushd" => 0,
    "HTTP::Tiny" => 0,
    "List::Util" => 0,
    "MetaCPAN::Client" => 0,
    "Path::Tiny" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88",
    "lib" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Archive::Tar" => 0,
  "Dist::Zilla::App" => 0,
  "File::pushd" => 0,
  "HTTP::Tiny" => 0,
  "List::Util" => 0,
  "MetaCPAN::Client" => 0,
  "Path::Tiny" => 0,
  "Test::More" => "0.88",
  "lib" => 0,
  "namespace::autoclean" => 0,
  "strict" => 0,
  "warnings" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
