use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    unless (check_screen "root_console", 0) {
        $self->root_console(tty=>4);
    }
    assert_screen "root_console";
    # check that lvmthinpool is present:
    # http://atodorov.org/blog/2015/04/14/how-to-find-if-lvm-volume-is-thinly-provisioned/
    # arguments of thinpool devices has T, t or V at the beginning of attributes
    assert_script_run "lvs -o lv_attr | grep -E '^[[:space:]]*(T|t|V)'";
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
