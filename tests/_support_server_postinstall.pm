use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;

sub run {
    my $self=shift;
    # clone host's /etc/hosts (for phx2 internal routing to work)
    # must come *before* setup_tap_static or else it would overwrite
    # its changes
    $self->clone_host_file("/etc/hosts");
    # set up networking
    $self->setup_tap_static("10.0.2.110", "support.domain.local");
    $self->clone_host_file("/etc/resolv.conf");
    # start up iscsi target
    assert_script_run "printf '<target iqn.2016-06.local.domain:support.target1>\n    backing-store /dev/vdb\n</target>' > /etc/tgt/conf.d/openqa.conf";
    # open firewall port
    assert_script_run "firewall-cmd --add-service=iscsi-target";
    assert_script_run "systemctl start tgtd.service";
    assert_script_run 'systemctl is-active tgtd.service';
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
