use base "installedtest";
use strict;
use testapi;
use lockapi;
use utils;
use tapnet;
use cockpit;

sub run {
    my $self = shift;
    my $distri = get_var("DISTRI");
    my $desktop = get_var("DESKTOP");
    my $user_login = get_var("USER_LOGIN");

    # Test now starts with DESKTOP => "gnome" so that start_cockpit will launch
    # firefox in graphical desktop in Rocky 10+ instead of from console with
    # startx which is still used for Rocky 9-.

    # switch to TTY3 for graphical tests, console tests already using tty3
    if ($distri eq "rocky" && $desktop eq "gnome" && $user_login ne "false") {
        $self->root_console(tty => 3);
        assert_screen("root_console");
    }

    # use appropriate server IP, hostname, mutex and admin password
    # Several tests use the 'regular' FreeIPA server, so the values
    # for that are the defaults; other tests use a replica server, or
    # the AD server, so they specify this in their vars.
    my $ipa_server = get_var("REALMD_DNS_SERVER_HOST", 'ipa001.test.openqa.rockylinux.org');
    my $ipa_server_ip = get_var("REALMD_DNS_SERVER_IP", '172.16.2.100');
    my $server_mutex = get_var("REALMD_SERVER_MUTEX", 'freeipa_ready');
    my $ipa_admin_password = get_var("REALMD_ADMIN_PASSWORD", 'b1U3OnyX!');
    my $ipa_admin_user = get_var("REALMD_ADMIN_USER", 'admin');
    my $ipa_domain = get_var("REALMD_DOMAIN", "test.openqa.rockylinux.org");

    # use FreeIPA server as DNS server
    assert_script_run "printf 'search $ipa_domain\nnameserver $ipa_server_ip' > /etc/resolv.conf";

    # this gets us the name of the first connection in the list,
    # which should be what we want
    my $connection = script_output "nmcli --fields NAME con show | head -2 | tail -1";
    assert_script_run "nmcli con mod '$connection' ipv4.dns '$ipa_server_ip'";
    assert_script_run "nmcli con down '$connection'";
    assert_script_run "nmcli con up '$connection'";

    # wait for the server to be ready (do it now just to make sure name
    # resolution is working before we proceed)
    mutex_lock "$server_mutex";
    mutex_unlock "$server_mutex";

    # do repo setup
    repo_setup();

    # Cockpit in Rocky 10+ doesn't seem to know how to install ipa-client
    # while trying to meet the install-api-client requirement. As a workaround
    # install ipa-client before launching Cockpit and leave the join step
    # for the Cockpit UI.
    assert_script_run "dnf -y install ipa-client", 300;

    # set sssd debugging level higher (useful for debugging failures)
    # optional as it's not really part of the test
    script_run "dnf -y install sssd-tools", 220;
    script_run "sss_debuglevel 9";
    my $cockpitver = script_output 'rpm -q cockpit --queryformat "%{VERSION}\n"';

    # run firefox and login to cockpit
    # note: we can't use wait_screen_change, wait_still_screen or
    # check_type_string in cockpit because of that fucking constantly
    # scrolling graph
    start_cockpit(login => 1);

    # we may have to scroll down before the button is visible
    if (check_screen "cockpit_join_domain_button", 5) {
        click_lastmatch;
    }
    else {
        # to activate the right pane
        assert_and_click "cockpit_main";
        send_key "pgdn";
        # wait out scroll...
        wait_still_screen 2;
        assert_and_click("cockpit_join_domain_button", timeout => 5);
    }
    assert_screen "cockpit_join_domain";

    # we need one tab to reach "Domain address" and then one tab to
    # reach "Domain administrator name" on cockpit 255+...
    my $tabs = "\t";
    # ...but two tabs in both places on earlier versions
    $tabs = "\t\t" if ($cockpitver < 255);
    type_string($tabs, 4);
    type_string($ipa_server, 4);
    type_string($tabs, 4);
    type_string($ipa_admin_user, 4);
    send_key "tab";
    sleep 3;
    type_string("$ipa_admin_password", 4);
    sleep 3;
    assert_and_click "cockpit_join_button";

    # join involves package installs, so it may take some time
    assert_screen "cockpit_join_complete", 300;

    # quit browser to return to console
    quit_firefox;

    # switch to TTY3 for graphical tests, console tests already using tty3
    if ($distri eq "rocky" && $desktop eq "gnome" && $user_login ne "false") {
        $self->root_console(tty => 3);
        assert_screen("root_console");
    }
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
