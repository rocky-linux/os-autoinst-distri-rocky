use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Boxes starts.

sub run {
    my $self = shift;
    
    # Start the application
    start_with_launcher('apps_menu_boxes');
    # handling 'auth required' screen appearing as a soft fail,
    # check that is started
    # https://bugzilla.redhat.com/show_bug.cgi?id=1692972
    assert_screen ['apps_run_boxes', 'auth_required'];
    if (match_has_tag 'auth_required') {
        record_soft_failure "Firewall authentication screen appeared - RHBZ #1692972";
        my $user_password = get_var("USER_PASSWORD") || "weakpassword";
        type_very_safely $user_password;
        send_key 'ret';
        assert_screen 'apps_run_boxes';
    }
    # Close the application
    quit_with_shortcut();
    
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
