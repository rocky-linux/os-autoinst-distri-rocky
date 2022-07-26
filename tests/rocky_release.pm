use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Rocky release is correctly described in /etc/rocky-release file.
# The content of the file should be: "Rocky Linux release <version> (<code_name>)"
# where "version" is a number of the current Rocky Linux version and "code_name" is the
# code_name for the release.

# At such time we are building the next release that has a new code_name we'll need
# to decide how to implement detection in rocky_release.pm.

# To maintain simplicity (at least initially) we will explicitly define our code_name
# directly. If RAWREL is required in other tests it should be defined during POST or
# in tests to be the same as VERSION.

sub run {
    my $self = shift;
    # Version as defined in the VERSION variable.
    my $expectver = get_var('VERSION');
    # Code Name as defined in the CODENAME variable or default.
    my $code_name = get_code_name();
    # Create the expected content of the release file
    # and compare it with its real counterpart.
    my $expected = "Rocky Linux release $expectver ($code_name)";
    validate_script_output 'cat /etc/rocky-release', sub { $_ eq $expected };
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
