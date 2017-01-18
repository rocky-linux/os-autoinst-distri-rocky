use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self=shift;
    assert_screen 'graphical_desktop_clean';
    menu_launch_type('terminal');
    wait_still_screen 5;
    # need to be root
    my $rootpass = get_var("ROOT_PASSWORD", "weakpassword");
    type_string "su\n", 20;
    wait_still_screen 3;
    # can't use type_safely for now as current implementation relies
    # on screen change checks, and there is no screen change here
    type_string "$rootpass\n", 1;
    wait_still_screen 3;
    # if we can run something successfully, we're at a console;
    # we're reinventing assert_script_run instead of using it so
    # we can type safely
    type_very_safely "ls && echo 'ls OK' > /dev/ttyS0\n";
    wait_serial "ls OK" || die "terminal command failed";
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
