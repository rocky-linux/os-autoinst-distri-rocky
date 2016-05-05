use base "installedtest";
use strict;
use testapi;

sub run {
    my $self=shift;
    assert_screen 'graphical_desktop_clean';
    $self->menu_launch_type('terminal');
    wait_still_screen 5;
    # need to be root
    my $rootpass = get_var("ROOT_PASSWORD", "weakpassword");
    type_string "su\n";
    wait_still_screen 3;
    type_string "$rootpass\n";
    wait_still_screen 3;
    # if we can do an assert_script_run, we're at a console
    assert_script_run 'ls';
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
