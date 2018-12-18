use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that LibreOffice Impress starts.

sub run {
    my $self = shift;

    # Start the application
    start_with_launcher('apps_menu_limpress');
    # Check that is started
    assert_and_click 'apps_run_limpress_start';
    assert_screen 'apps_run_limpress';
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
