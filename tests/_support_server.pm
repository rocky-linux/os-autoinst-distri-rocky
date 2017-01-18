use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;
use tapnet;

sub run {
    my $self=shift;
    # clone host's /etc/hosts (for phx2 internal routing to work)
    # must come *before* setup_tap_static or else it would overwrite
    # its changes
    clone_host_file("/etc/hosts");
    # set up networking
    setup_tap_static("10.0.2.110", "support.domain.local");
    clone_host_file("/etc/resolv.conf");

    ## DNS / DHCP (dnsmasq)
    # create config
    assert_script_run "printf 'domain=domain.local\ndhcp-range=10.0.2.112,10.0.2.199\ndhcp-option=option:router,10.0.2.2' > /etc/dnsmasq.conf";
    # open firewall ports
    assert_script_run "firewall-cmd --add-service=dhcp";
    assert_script_run "firewall-cmd --add-service=dns";
    # start server
    assert_script_run "systemctl restart dnsmasq.service";
    assert_script_run "systemctl is-active dnsmasq.service";

    ## ISCSI

    # start up iscsi target
    assert_script_run "printf '<target iqn.2016-06.local.domain:support.target1>\n    backing-store /dev/vdb\n    incominguser test weakpassword\n</target>' > /etc/tgt/conf.d/openqa.conf";
    # open firewall port
    assert_script_run "firewall-cmd --add-service=iscsi-target";
    assert_script_run "systemctl restart tgtd.service";
    assert_script_run "systemctl is-active tgtd.service";

    ## NFS

    # create the file share
    assert_script_run "mkdir -p /export";
    # get the kickstart
    assert_script_run "curl -o /export/root-user-crypted-net.ks https://jskladan.fedorapeople.org/kickstarts/root-user-crypted-net.ks";
    # create the repo share
    assert_script_run "mkdir -p /repo";
    # create a mount point for the ISO
    assert_script_run "mkdir -p /mnt/iso";
    # mount the ISO there
    assert_script_run "mount /dev/cdrom /mnt/iso";
    # copy the contents of the ISO to the repo share
    assert_script_run "cp -R /mnt/iso/* /repo", 180;
    # put the updates image in the NFS repo (for testing this update
    # image delivery method)
    assert_script_run "curl -o /repo/images/updates.img https://fedorapeople.org/groups/qa/updates/updates-openqa.img";
    # set up the exports
    assert_script_run "printf '/export 10.0.2.0/24(ro)\n/repo 10.0.2.0/24(ro)' > /etc/exports";
    # open firewall port
    assert_script_run "firewall-cmd --add-service=nfs";
    # workaround RHBZ #1402427: somehow the file is incorrectly labelled
    # even after a clean install with fixed selinux-policy
    assert_script_run "restorecon /usr/bin/rpcbind";
    # start the server
    assert_script_run "systemctl restart nfs-server.service";
    assert_script_run "systemctl is-active nfs-server.service";

    # report ready, wait for children
    mutex_create('support_ready');
    wait_for_children;
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
