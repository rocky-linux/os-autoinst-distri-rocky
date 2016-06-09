use base "anacondatest";
use strict;
use testapi;

sub run {
    my $self = shift;
    assert_and_click "anaconda_main_hub_network_host_name";
    assert_and_click "anaconda_network_configure";
    assert_and_click "anaconda_network_ipv4";
    assert_and_click "anaconda_network_method";
    assert_and_click "anaconda_network_method_manual";
    assert_and_click "anaconda_network_address_add";
    type_string get_var('ANACONDA_STATIC');
    wait_still_screen 2;
    send_key "tab";
    # netmask is automatically set
    send_key "tab";
    # assume gateway
    wait_still_screen 2;
    type_string "10.0.2.2";
    wait_still_screen 2;
    send_key "ret";
    # move to DNS servers
    send_key "tab";
    send_key "tab";
    send_key "tab";
    wait_still_screen 2;
    # set DNS from host
    type_string join(',', $self->get_host_dns());
    send_key "tab";
    send_key "tab";
    send_key "tab";
    send_key "tab";
    send_key "tab";
    send_key "ret";
    # can take a bit of time as it seems to wait for all the pending
    # DHCP requests to time out before applying the static config
    assert_screen "anaconda_network_connected", 90;
    assert_and_click "anaconda_spoke_done";
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
