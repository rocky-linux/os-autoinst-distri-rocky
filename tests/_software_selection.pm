use base "anacondatest";
use strict;
use testapi;
use anaconda;
use utils;


sub run {
    my $self = shift;
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300;    #

    # Select package set.
    # If 'default' is specified, skip selection, but verify correct default
    my $packageset = get_var('PACKAGE_SET', 'default');
    if ($packageset eq 'default') {
        $self->root_console;
        my $env = "graphical-server-environment";
        if (get_var('FLAVOR') eq 'minimal-iso') {
            $env = "server-product-environment";
        }

        # In rocky 10 default Software Selection is server with GUI (and group base-graphical is hidden) so this is superfluous
        if (get_version_major() < 10) {
            assert_script_run "grep -E 'selected environment:' /tmp/anaconda.log /tmp/packaging.log | tail -1 | grep $env";
        }
        select_console "tty6-console";
        assert_screen "anaconda_main_hub", 30;
        return;
    }

    assert_and_click "anaconda_main_hub_select_packages";

    # Focus on "base environment" list
    send_key "tab";
    wait_still_screen 1;
    send_key "tab";
    wait_still_screen 1;

    # In Rocky, graphical-server starts out selected in the DVD ISO so if that's
    # what we're looking for we're done
    if (!check_screen("anaconda_" . $packageset . "_selected", 1)) {
        send_key_until_needlematch("anaconda_" . $packageset . "_highlighted", "down", 20);
        send_key "spc";
    }

    # check that desired environment is selected
    assert_screen "anaconda_" . $packageset . "_selected";
    assert_and_click "anaconda_spoke_done";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 50;    #

}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
