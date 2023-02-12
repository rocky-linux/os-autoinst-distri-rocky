use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests an annotation can be added to the displayed content.

sub run {
    my $self = shift;

    # Click on the Pencil button.
    assert_and_click("evince_add_annotation", button => "left", timeout => 30);

    # Click on Note text.
    assert_and_click("evince_add_annotation_text", button => "left", timeout => 30);

    # Select location to add annotation.
    assert_and_click("evince_select_annotation_place", button => "left", timeout => 30);

    # Enter some text to the annotation.
    type_very_safely("Add note");

    # Check that the annotation window has appeared with that text.
    assert_screen("evince_annotation_added");

    # Close the annotation.
    assert_and_click("evince_close_annotation", button => "left", timeout => 30);

    # Check that the annotation is still placed in the document.
    assert_screen("evince_annotation_placed");

    # Open the annotation's context menu.
    assert_and_click("evince_annotation_placed", button => "right", timeout => 30);

    # Remove the annotation.
    assert_and_click("evince_remove_annotation", button => "left", timeout => 30);

    # Check that the annotation has been removed.
    assert_screen("evince_annotation_removed");

}

sub test_flags {
    # Rollback to the starting point.
    return {always_rollback => 1};
}

1;
