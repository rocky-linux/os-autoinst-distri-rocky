use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check we have a node for the target. realistically speaking we
    # don't need a lot of checking here, it seems extremely unlikely
    # that the system could ever actually boot unless everything is
    # working.
    assert_script_run "test -d '/var/lib/iscsi/nodes/iqn.2016-06.local.domain:support.target1'";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
