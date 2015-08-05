use base "anacondatest";
use strict;
use testapi;

sub run {
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

    # Select package set. Minimal is the default, if 'default' is specified, skip selection.
    my $packageset = get_var('PACKAGE_SET', 'minimal');
    if ($packageset eq 'default') {
        return
    }

    assert_and_click "anaconda_main_hub_select_packages";

    # Focus on "base environment" list
    send_key "tab";
    sleep 1;
    send_key "tab";

    # select desired environment
    # go through the list 20 times at max (to prevent infinite loop when it's missing)
    for (my $i = 0; !check_screen("anaconda_".$packageset."_highlighted", 1) && $i < 20; $i++) {
	       send_key "down";
    }

    send_key "spc";

    # check that desired environment is selected
    assert_screen "anaconda_".$packageset."_selected";

    assert_and_click "anaconda_spoke_done";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 50; #

}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
