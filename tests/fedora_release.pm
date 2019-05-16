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
    # First, let us define some variables needed to run the program.
    my $self = shift;
    # The file to be checked
    my $filename = '/etc/fedora-release';
    # Version as defined in the RAWREL and VERSION variables. We need both values, because the release
    # string can be a combination of those two.
    my $version = get_var('VERSION');
    my $raw_version = get_var('RAWREL');

   # Read the content of the file to compare.
    my $line = script_output('cat /etc/fedora-release');
    chomp $line;

    # Create a spelt form of the version number.
    my $speltnum = "undefined";
    if ($version eq "Rawhide") {
        $speltnum = "Rawhide";
        $version = $raw_version;
    }
    else {
        $speltnum = spell_version_number($version);
    }

    # Create the ideal content of the release file
    # and compare it with its real counterpart.
    # Everything is ok, when that matches, otherwise
    # the script fails.
    my $releasenote = "Fedora release $version ($speltnum)";
    my $log = "fedora-release.log";
    if ($releasenote eq $line) {
        rec_log $log, "The content in /etc/fedora-release should be $releasenote and is $line: PASSED";
        upload_logs "/tmp/fedora-release.log", failok=> 1;
    }
    else {
        rec_log $log, "The content in /etc/fedora-release should be $releasenote but is $line: FAILED";
        upload_logs "/tmp/fedora-release.log", failok=> 1;
        die "The content in /etc/fedora-release should be $releasenote but is $line.";
    }
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
