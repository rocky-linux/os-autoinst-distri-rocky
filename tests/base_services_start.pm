use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty => 3);
    # "Job foo.service/start deleted to break ordering cycle"-type
    # message in the log indicates a service got taken out of the boot
    # process to resolve some kind of dependency loop, see e.g.
    # https://bugzilla.redhat.com/show_bug.cgi?id=1600823
    assert_script_run "! journalctl -b | grep 'deleted to break ordering'";
    # dump the systemctl output
    assert_script_run "systemctl --failed | tee /tmp/failed.txt";
    # if we have 0 failed services, we're good
    my $ret = script_run "grep '0 loaded units' /tmp/failed.txt";
    return if $ret == 0;
    # if only hcn-init failed, that's a soft fail, see:
    # https://bugzilla.redhat.com/show_bug.cgi?id=1894654
    $ret = script_run "grep '1 loaded units' /tmp/failed.txt";
    if ($ret != 0) {
        die "More than one services failed to start";
    }
    else {
        my $arch = get_var("ARCH");
        if ($arch eq "ppc64le") {
            # fail if it's something other than hcn-init
            assert_script_run "systemctl is-failed hcn-init.service";
            record_soft_failure "hcn-init failed - https://bugzilla.redhat.com/show_bug.cgi?id=1894654";
        }
        elsif ($arch eq "aarch64") {
            # fail if it's something other than lm_sensors
            assert_script_run "systemctl is-failed lm_sensors.service";
            record_soft_failure "lm_sensors failed - https://bugzilla.redhat.com/show_bug.cgi?id=1899896";
        }
        else {
            die "Unexpected service start failure";
        }
    }
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
