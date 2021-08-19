use base "anacondatest";
use strict;
use testapi;
use utils;
use tapnet;

sub run {
    my $self = shift;
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

    assert_and_click "anaconda_main_hub_network_host_name_not_connected";
    assert_and_click "anaconda_network_connect";

    assert_screen "anaconda_network_connected", 90;
    assert_and_click "anaconda_spoke_done";
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
