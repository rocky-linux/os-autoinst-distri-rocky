use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;

    # wait for either GDM or text login
    if (get_var('UPGRADE') eq "desktop") {
        $self->boot_to_login_screen("graphical_login", 30); # GDM takes time to load
    } else {
        $self->boot_to_login_screen();
    }
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty=>3);
    # disable screen blanking (update can take a long time)
    type_string "setterm -blank 0\n";

    # upgrader should be installed on up-to-date system

    type_string 'dnf -y update; echo $?';
    send_key "ret";

    assert_screen "console_command_success", 1800;

    type_string "reboot";
    send_key "ret";

    if (get_var('UPGRADE') eq "desktop") {
        $self->boot_to_login_screen("graphical_login", 30); # GDM takes time to load
    } else {
        $self->boot_to_login_screen();
    }
    $self->root_console(tty=>3);

    type_string 'dnf -y --enablerepo=updates-testing install dnf-plugin-system-upgrade; echo $?';
    send_key "ret";

    assert_screen "console_command_success", 1800;
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
