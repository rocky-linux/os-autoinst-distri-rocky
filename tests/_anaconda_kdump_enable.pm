use base "anacondatest";
use strict;
use testapi;
use utils;
use tapnet;

sub run {
    my $self = shift;
    assert_and_click "anaconda_main_hub_kdump";
    assert_and_click "anaconda_kdump_enable";
    assert_screen "anaconda_kdump_enabled", 90;
    assert_and_click "anaconda_spoke_done";
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
