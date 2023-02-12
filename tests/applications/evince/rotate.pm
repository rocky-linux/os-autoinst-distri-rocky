use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests that Evince can rotate the content.

sub rotate_content {

    # Open the application menu
    assert_and_click("gnome_burger_menu", button => "left", timeout => 30);

    # Click with the *left* button (needle click area might need some correction)
    assert_and_click("evince_menu_rotate", button => "left", timeout => 30);
}

sub run {
    my $self = shift;

    # Rotate the content once.
    rotate_content();

    # Check that the window content has been rotated.
    assert_screen("evince_content_rotated_once", timeout => 30);

    # Rotate the content again.
    rotate_content();

    # Check that the window content has been rotated.
    assert_screen("evince_content_rotated_twice", timeout => 30);
}

sub test_flags {
    return {always_rollback => 1};
}

1;
