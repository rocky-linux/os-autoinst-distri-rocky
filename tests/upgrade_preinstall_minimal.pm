use base "fedoralog";
use strict;
use testapi;

sub run {
    my $self = shift;

    $self->boot_and_login();

    type_string 'yum -y update; echo $?';
    send_key "ret";

    assert_screen "console_command_success", 1800;

    type_string "reboot";
    send_key "ret";

    $self->boot_and_login();

    type_string 'yum -y install fedup; echo $?';
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
