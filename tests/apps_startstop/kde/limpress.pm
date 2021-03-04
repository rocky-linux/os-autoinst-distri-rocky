use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that LibreOffice Impress starts.

sub run {
    my $self = shift;
    # Start the application
    menu_launch_type 'libreoffice impress';
    # Check that it is started
    assert_screen 'limpress_runs';
    # Close the template chooser, then the application
    send_key 'alt-f4';
    quit_with_shortcut();
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
