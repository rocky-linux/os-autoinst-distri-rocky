use base "anacondatest";
use strict;
use testapi;
use utils;
use tapnet;

sub run {
    my $self = shift;
    assert_and_click "anaconda_main_hub_network_host_name";
    assert_and_click "anaconda_network_configure";
    assert_and_click "anaconda_network_ipv4";
    assert_and_click "anaconda_network_method";
    assert_and_click "anaconda_network_method_manual";
    assert_and_click "anaconda_network_address_add";
    type_safely get_var('ANACONDA_STATIC');
    # netmask is automatically set
    type_safely "\t\t";
    # assume gateway
    type_safely "10.0.2.2";
    # move to DNS servers
    type_safely "\n\t\t\t";
    # set DNS from host
    type_safely join(',', get_host_dns());
    type_safely "\t\t\t\t\t\n";
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
