use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Fedora release is correctly described in /etc/fedora-release file.
# The content of the file should be: "Fedora release <version> (<version_words>)"
# where "version" is a number of the current Fedora version and "version_words" is the number
# quoted in words, such as 31 = Thirty One.
# Before branching, the parenthesis contain the word "Rawhide".

sub run {
    my $self = shift;
    # Version as defined in the VERSION variable.
    my $tospell = get_var('VERSION');
    my $expectver = get_var('VERSION');
    # Rawhide release number.
    my $rawrel = get_var('RAWREL', '');
    # IoT has a branch that acts more or less like Rawhide, but has
    # its version as the Rawhide release number, not 'Rawhide'. This
    # handles that
    $tospell = 'Rawhide' if ($tospell eq $rawrel);
    # this is the Rawhide release number, which we expect to see.
    $expectver = $rawrel if ($expectver eq "Rawhide");
    # Create a spelt form of the version number.
    my $speltnum = spell_version_number($tospell);
    # Create the expected content of the release file
    # and compare it with its real counterpart.
    my $expected = "Fedora release $expectver ($speltnum)";
    validate_script_output 'cat /etc/fedora-release', sub { $_ eq $expected };
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
