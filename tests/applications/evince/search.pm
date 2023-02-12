use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests the ability to search string in the text.

sub run {
    my $self = shift;

    # Click on the Search button to search for text
    assert_and_click("evince_search_button", button => "left", timeout => 30);

    # Type *pages*.
    type_very_safely("pages");
    # Press Enter.
    send_key("ret");

    # Check that the typed text has been found.
    assert_screen("evince_search_found", timeout => 30);

}

sub test_flags {
    return {always_rollback => 1};
}

1;
