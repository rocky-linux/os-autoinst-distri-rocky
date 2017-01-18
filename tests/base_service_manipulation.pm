use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty=>3);
    # we could make this slightly more 'efficient' by assuming sshd
    # is always going to be enabled/running at first, but it's safer
    # to force an expected starting state.
    script_run "systemctl stop sshd.service";
    script_run "systemctl disable sshd.service";
    script_run "reboot", 0;
    boot_to_login_screen;
    $self->root_console(tty=>3);
    # note the use of ! here is a bash-ism, but it sure makes life easier
    assert_script_run '! systemctl is-enabled sshd.service';
    assert_script_run '! systemctl is-active sshd.service';
    assert_script_run '! ps -C sshd';
    script_run "systemctl start sshd.service";
    assert_script_run '! systemctl is-enabled sshd.service';
    assert_script_run 'systemctl is-active sshd.service';
    assert_script_run 'ps -C sshd';
    script_run "systemctl stop sshd.service";
    assert_script_run '! systemctl is-enabled sshd.service';
    assert_script_run '! systemctl is-active sshd.service';
    assert_script_run '! ps -C sshd';
    script_run "systemctl enable sshd.service";
    assert_script_run 'systemctl is-enabled sshd.service';
    assert_script_run '! systemctl is-active sshd.service';
    assert_script_run '! ps -C sshd';
    script_run "reboot", 0;
    boot_to_login_screen;
    $self->root_console(tty=>3);
    assert_script_run 'systemctl is-enabled sshd.service';
    assert_script_run 'systemctl is-active sshd.service';
    assert_script_run 'ps -C sshd';
    script_run "systemctl disable sshd.service";
    script_run "reboot", 0;
    boot_to_login_screen;
    $self->root_console(tty=>3);
    assert_script_run '! systemctl is-enabled sshd.service';
    assert_script_run '! systemctl is-active sshd.service';
    assert_script_run '! ps -C sshd';
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
