use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;
use tapnet;
use utils;

# Adapted from Fedora's OpenQA tests, with some modifications. This will need
# to be maintained per major version as necessary.
# label@rockylinux.org

use feature "switch";

sub run {
    my $self = shift;
    # use FreeIPA server or replica as DNS server
    my $version_major = get_version_major;
    my $relnum = get_release_number;
    my $ipa_admin_password = 'b1U3OnyX!';
    my $server = 'ipa001.test.openqa.rockylinux.org';
    my $server_ip = '172.16.2.100';
    my $server_mutex = 'freeipa_ready';
    my $ipa_install_cmd;
    my @ipa_firewall_services;
    given ($version_major) {
        when ('8') {
            $ipa_install_cmd = 'dnf --assumeyes module install idm:DL1/{dns,client,server,common}';
            @ipa_firewall_services = qw(http https kerberos kpasswd ldap ldaps dns);
        }
        when ('9') {
            $ipa_install_cmd = 'dnf --assumeyes install ipa-server ipa-client ipa-server-dns sssd sssd-ipa';
            @ipa_firewall_services = qw(freeipa-4 dns);
        }
        default {
            $ipa_install_cmd = 'dnf --assumeyes install ipa-server ipa-client ipa-server-dns sssd sssd-ipa';
            @ipa_firewall_services = qw(freeipa-4 dns);
        }
    }


    if (get_var("FREEIPA_REPLICA")) {
        $server = 'ipa002.test.openqa.rockylinux.org';
        $server_ip = '172.16.2.106';
    }
    if (get_var("FREEIPA_REPLICA_CLIENT")) {
        $server = 'ipa003.test.openqa.rockylinux.org';
        $server_ip = '172.16.2.107';
        $server_mutex = 'replica_ready';
    }
    # this gets us the name of the first connection in the list,
    # which should be what we want
    my $connection = script_output "nmcli --fields NAME con show | head -2 | tail -1";
    assert_script_run "nmcli con mod '$connection' ipv4.dns '$server_ip'";
    assert_script_run "nmcli con down '$connection'";
    assert_script_run "nmcli con up '$connection'";

    # wait for the server or replica to be ready (do it now just to be
    # sure name resolution is working before we proceed)
    mutex_lock $server_mutex;
    mutex_unlock $server_mutex;
    # use compose repo, disable u-t, etc. unless this is an upgrade
    # test (in which case we're on the 'old' release at this point;
    # one of the upgrade test modules does repo_setup later)
    repo_setup() unless get_var("UPGRADE");
    # do the enrolment
    if (get_var("FREEIPA_REPLICA")) {
        # here we're enrolling not just as a client, but as a replica
        # install server packages
        assert_script_run "$ipa_install_cmd", 600;

        # we need a lot of entropy for this, and we don't care how good
        # it is, so let's use haveged
        assert_script_run "dnf --assumeyes install rng-tools", 300;
        assert_script_run 'systemctl start rngd.service';

        # configure the firewall
        for my $service (@ipa_firewall_services) {
            assert_script_run "firewall-cmd --permanent --add-service $service";
        }
        assert_script_run "systemctl restart firewalld.service";

        # deploy as a replica
        my ($ip, $hostname) = split(/ /, get_var("POST_STATIC"));
        my $args = "--ip-address=$ip --setup-dns --auto-forwarders --setup-ca --allow-zone-overlap -U --principal admin --admin-password '$ipa_admin_password'";
        assert_script_run "ipa-replica-install $args", 1500;

        # enable and start the systemd service
        assert_script_run "systemctl enable ipa.service";
        assert_script_run "systemctl start ipa.service", 300;

        # report that we're ready to go
        mutex_create('replica_ready');

        # wait for the client test
        wait_for_children;
    }
    else {
        assert_script_run "echo '$ipa_admin_password' | realm join --user=admin ${server}", 300;
    }
    # set sssd debugging level higher (useful for debugging failures)
    # optional as it's not really part of the test
    script_run "dnf -y install sssd-tools", 220;
    script_run "sss_debuglevel 9";
    # if upgrade test, report that we're enrolled
    mutex_create('client_enrolled') if get_var("UPGRADE");
    # if this is an upgrade test, wait for server to be upgraded before
    # continuing, as we rely on it for name resolution
    if (get_var("UPGRADE")) {
        mutex_lock "server_upgraded";
        mutex_unlock "server_upgraded";
    }
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
