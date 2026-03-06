use base "installedtest";
use strict;
use testapi;
use utils;

# This will set up the environment for the archiver test.
# It creates nine file and places them in the Documents folder.
# Then opens Nautilus (archive fce) and switches to that folder.

sub run {
    my $self = shift;
    my $username = get_var("USER_LOGIN") // "test";
    # Create the files on the CLI
    $self->root_console(tty => 3);
    assert_script_run("cd /home/$username/Documents");
    assert_script_run('for i in {1..9}; do echo $i > file$i.txt; done');
    assert_script_run("chown -R $username:$username /home/$username/Documents/");
    # Exit to the GUI
    desktop_vt;

    # Set the update notification timestamp
    set_update_notification_timestamp();

    # Start the application
    menu_launch_type("nautilus", checkstart => 1, maximize => 1);

    # Open the Documents directory
    assert_and_click("gnome_open_location_documents");
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
