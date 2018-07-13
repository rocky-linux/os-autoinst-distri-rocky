use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty=>3);
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
    # if only mcelog failed, that's a soft fail
    $ret = script_run "grep '1 loaded units' /tmp/failed.txt";
    if ($ret != 0) {
        die "More than one services failed to start";
    }
    else {
        # fail if it's something other than mcelog
        assert_script_run "systemctl is-failed mcelog.service";
        record_soft_failure;
    }
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
