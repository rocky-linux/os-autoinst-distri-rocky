use base "installedtest";
use strict;
use testapi;
use utils;

# This test tests if Terminal starts and uses it to change desktop settings for all the following tests.
# Therefore, if you want to use all the tests from the APPS family, this should be the very first to do.

sub run {
    my $self = shift;
    #  Change the background to black.
    solidify_wallpaper;
}

# If this test fails, the others will probably start failing too,
# so there is no need to continue.
# Also, when subsequent tests fail, the suite will revert to this state for further testing.
sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
