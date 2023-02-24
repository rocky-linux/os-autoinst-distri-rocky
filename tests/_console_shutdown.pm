use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    # this shutdown code is only to make sure the guest disk is clean
    # before uploading an image of it, we're really not "testing"
    # shutdown here. So to keep things simple and reliable, we do not
    # use the desktops' graphical shutdown methods, we just go to a
    # console and run 'poweroff'. We can write separate tests for
    # properly testing shutdown/reboot/log out from desktops.
    $self->root_console(tty => 4);
    # disable the hidden grub menu on Workstation, so post-install
    # tests that need to edit boot params will see it. Don't use
    # assert_script_run as this will fail when it's not set
    script_run("grub2-editenv - unset menu_auto_hide", 0);
    script_run("poweroff", 0);
    assert_shutdown 180;
}

# this is not 'fatal' or 'important' as all wiki test cases are passed
# even if shutdown fails. we should have a separate test for shutdown/
# logout/reboot stuff, might need some refactoring.
sub test_flags {
    return {'norollback' => 1, 'ignore_failure' => 1};
}

1;

# vim: set sw=4 et:
