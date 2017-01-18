use base "installedtest";
use strict;
use testapi;
use lockapi;
use utils;
use tapnet;

sub run {
    my $self = shift;
    # clone host's /etc/hosts (for phx2 internal routing to work)
    # must come *before* setup_tap_static or else it would overwrite
    # its changes
    clone_host_file("/etc/hosts");
    # set up networking
    setup_tap_static("10.0.2.102", "client002.domain.local");
    # use FreeIPA server as DNS server
    assert_script_run "printf 'search domain.local\nnameserver 10.0.2.100' > /etc/resolv.conf";
    # wait for the server to be ready (do it now just to make sure name
    # resolution is working before we proceed)
    mutex_lock "freeipa_ready";
    mutex_unlock "freeipa_ready";
    # run firefox and login to cockpit
    # note: we can't use wait_screen_change, wait_still_screen or
    # check_type_string in cockpit because of that fucking constantly
    # scrolling graph
    start_cockpit(1);
    assert_and_click "cockpit_join_domain_button";
    assert_screen "cockpit_join_domain";
    send_key "tab";
    sleep 3;
    type_string("ipa001.domain.local", 4);
    type_string("\t\t", 4);
    type_string("admin", 4);
    send_key "tab";
    sleep 3;
    type_string("monkeys123", 4);
    sleep 3;
    assert_and_click "cockpit_join_button";
    # check we hit the progress screen, so we fail faster if it's
    # broken
    assert_screen "cockpit_join_progress";
    # join involves package installs, so it may take some time
    assert_screen "cockpit_join_complete", 300;
    # quit browser to return to console
    send_key "ctrl-q";
    # we don't get back to a prompt instantly and keystrokes while X
    # is still shutting down are swallowed, so wait_still_screen before
    # finishing (and handing off to freeipa_client_postinstall)
    wait_still_screen 5;
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1, milestone => 1 };
}

1;

# vim: set sw=4 et:
