use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that LibreOffice Calc starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('apps_menu_lcalc');
    # Dismiss 'tip of the day' if necessary
    lo_dismiss_tip;
    # Check that is started
    assert_screen 'apps_run_lcalc';
    # Register application
    register_application("libreoffice-calc");
    # Close the application
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
