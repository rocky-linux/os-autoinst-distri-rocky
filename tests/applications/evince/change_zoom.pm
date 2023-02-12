use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests that Evince can change the zoom of the document.

sub run {
    my $self = shift;


    # Click on zoom menu to open choices.
    assert_and_click("evince_change_zoom", button => "left", timeout => 30);

    # Select 200%.
    assert_and_click("evince_select_zoom_200", button => "left", timeout => 30);

    # Check that the document zoom was changed.
    assert_screen("evince_document_zoom_200");

}

sub test_flags {
    return {always_rollback => 1};
}

1;
