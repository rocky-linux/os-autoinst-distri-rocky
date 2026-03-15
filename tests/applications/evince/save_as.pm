use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests tests that Evince can Save the document As another document.

sub run {
    my $self = shift;

    # Open the menu.
    assert_and_click("gnome_burger_menu", button => "left", timeout => 30);

    # Select Save As
    assert_and_click("evince_menu_saveas", button => "left", timeout => 30);
    wait_still_screen(2);

    # Ensure we're in Documents directory and Select filename to edit
    assert_and_click("evince_documents");

    # Rocky 9 save-as dialog is different than Rocky 10
    if (get_var("DISTRI") eq "rocky" && (get_version_major() < 10)) {
        assert_and_dclick("evince_select_file");
    }
    else {
        assert_and_click("evince_select_file");
    }

    # Type a new name.
    type_very_safely("alternative");

    # Click on the Save button
    assert_and_click("gnome_button_save_blue", button => "left", timeout => 30);

    # Now the document is saved under a different name. We will switch to the
    # terminal console to check that it has been created.
    $self->root_console(tty => 3);
    assert_script_run("ls /home/test/Documents/alternative.pdf");

    # Now, check that the new file does not differ from the original one.
    assert_script_run("diff /home/test/Documents/evince.pdf /home/test/Documents/alternative.pdf");
}

sub test_flags {
    return {always_rollback => 1};
}

1;
