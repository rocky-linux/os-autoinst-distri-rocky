use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    check_desktop;
    # If we want to check that there is a correct background used, as a part
    # of self identification test, we will do it here. For now we don't do
    # this for Rawhide as Rawhide doesn't have its own backgrounds and we
    # don't have any requirement for what background Rawhide uses.
    my $version = get_var('VERSION');
    assert_screen "${version}_background" if ($version ne "Rawhide");
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
