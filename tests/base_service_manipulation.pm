use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty => 3);
    # we could make this slightly more 'efficient' by assuming chronyd
    # is always going to be enabled/running at first, but it's safer
    # to force an expected starting state.
    script_run "systemctl stop chronyd.service";
    script_run "systemctl disable chronyd.service";
    script_run "reboot", 0;
    boot_to_login_screen;
    $self->root_console(tty => 3);
    # note the use of ! here is a bash-ism, but it sure makes life easier
    assert_script_run '! systemctl is-enabled chronyd.service';
    assert_script_run '! systemctl is-active chronyd.service';
    assert_script_run '! ps -C chronyd';
    script_run "systemctl start chronyd.service";
    assert_script_run '! systemctl is-enabled chronyd.service';
    assert_script_run 'systemctl is-active chronyd.service';
    assert_script_run 'ps -C chronyd';
    script_run "systemctl stop chronyd.service";
    assert_script_run '! systemctl is-enabled chronyd.service';
    assert_script_run '! systemctl is-active chronyd.service';
    assert_script_run '! ps -C chronyd';
    script_run "systemctl enable chronyd.service";
    assert_script_run 'systemctl is-enabled chronyd.service';
    assert_script_run '! systemctl is-active chronyd.service';
    assert_script_run '! ps -C chronyd';
    script_run "reboot", 0;
    boot_to_login_screen;
    $self->root_console(tty => 3);
    assert_script_run 'systemctl is-enabled chronyd.service';
    assert_script_run 'systemctl is-active chronyd.service';
    assert_script_run 'ps -C chronyd';
    script_run "systemctl disable chronyd.service";
    script_run "reboot", 0;
    boot_to_login_screen;
    $self->root_console(tty => 3);
    assert_script_run '! systemctl is-enabled chronyd.service';
    assert_script_run '! systemctl is-active chronyd.service';
    assert_script_run '! ps -C chronyd';
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
