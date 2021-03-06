use strict;
use warnings;
package Dist::Zilla::Plugin::Test::ChangesHasContent;
# ABSTRACT: Release test to ensure Changes has content
# VERSION

# Dependencies
use Dist::Zilla;
use autodie 2.00;
use Moose 0.99;
use namespace::autoclean 0.09;

# extends, roles, attributes, etc.

extends 'Dist::Zilla::Plugin::InlineFiles';
with qw/Dist::Zilla::Role::TextTemplate/;

has changelog => (
  is => 'ro',
  isa => 'Str',
  default => 'Changes'
);

# methods

around add_file => sub {
    my ($orig, $self, $file) = @_;
    return $self->$orig(
        Dist::Zilla::File::InMemory->new(
            name    => $file->name,
            content => $self->fill_in_string($file->content,
                {
                    changelog => $self->changelog,
                    newver => $self->zilla->version
                }
            )
        )
    );
};

__PACKAGE__->meta->make_immutable;

1;

# Pod must be before DATA

=begin wikidoc

= SYNOPSIS

  # in dist.ini

  [Test::ChangesHasContent]

= DESCRIPTION

This is an extension of [Dist::Zilla::Plugin::InlineFiles], providing the following file:

* xt/release/changes_has_content.t

This test ensures ensures that your Changes file actually has some content
since the last release.

This can be contrasted to [Dist::Zilla::Plugin::CheckChangesHasContent], which
performs the check at release time, halting the release process if content is
missing.  Performing the check as a test makes it possible to check more
frequently, and closer to the point of development.

The algorithm is very naive.  It looks for an unindented line starting with
the version to be released.  It then looks for any text from that line until
the next unindented line (or the end of the file), ignoring whitespace.

For example, in the file below, algorithm will find "- blah blah blah":

  Changes file for Foo-Bar

  {{$NEXT}}

    - blah blah blah

  0.001  Wed May 12 13:49:13 EDT 2010

    - the first release

If you had nothing but whitespace between { {{$NEXT}} } and { 0.001 },
the release would be halted.

If you name your change log something other than "Changes", you can configure
the name with the {changelog} argument:

  [Test::ChangesHasContent]
  changelog = ChangeLog

= SEE ALSO

* [Dist::Zilla::Plugin::CheckChangesHasContent]
* [Dist::Zilla]

=end wikidoc

=cut

__DATA__
___[ xt/release/changes_has_content.t ]___
#!perl

use Test::More tests => 2;

note 'Checking Changes';
my $changes_file = '{{$changelog}}';
my $newver = '{{$newver}}';

SKIP: {
    ok(-e $changes_file, "$changes_file file exists")
        or skip 'Changes is missing', 1;

    ok(_get_changes($newver), "$changes_file has content for $newver");
}

done_testing;

# _get_changes copied and adapted from Dist::Zilla::Plugin::Git::Commit
# by Jerome Quelin
sub _get_changes
{
    my $newver = shift;

    # parse changelog to find commit message
    open(my $fh, '<', $changes_file) or die "cannot open $changes_file: $!";
    my $changelog = join('', <$fh>);
    close $fh;

    my @content =
        grep { /^$newver(?:\s+|$)/ ... /^\S/ } # from newver to un-indented
        split /\n/, $changelog;
    shift @content; # drop the version line

    # drop unindented last line and trailing blank lines
    pop @content while ( @content && $content[-1] =~ /^(?:\S|\s*$)/ );

    # return number of non-blank lines
    return scalar @content;
}

__END__

