use base "installedtest";
use strict;
use testapi;
use utils;

sub run {

    my $self = shift;
    $self->root_console(tty => 3);

    # list available branches
    assert_script_run "ostree remote refs fedora-iot";

    # check arch
    my $arch = lc(get_var("ARCH"));

    # set default for rawhide or devel
    my $rebase = "stable";

    # if testing the current release, rebase to devel
    unless (script_run "rpm-ostree status -b | grep stable") {
        $rebase = "devel";
    }
    # rebase to the appropriate release, arch
    validate_script_output "rpm-ostree rebase fedora/${rebase}/${arch}/iot", sub { m/systemctl reboot/ }, 300;
    script_run "systemctl reboot", 0;

    boot_to_login_screen;
    $self->root_console(tty => 3);

    # check booted branch to make sure successful rebase
    if ($rebase eq "devel") {
        validate_script_output "rpm-ostree status -b", sub { m/devel/ }, 300;
    }
    if ($rebase eq "stable") {
        validate_script_output "rpm-ostree status -b", sub { m/stable/ }, 300;
    }

    # rollback and reboot
    validate_script_output "rpm-ostree rollback", sub { m/systemctl reboot/ }, 300;
    script_run "systemctl reboot", 0;

    boot_to_login_screen;
    $self->root_console(tty => 3);

    # check to make sure rollback successful, also account for branched (devel)
    if ($rebase eq "devel") {
        validate_script_output "rpm-ostree status -b", sub { m/stable/ }, 300;
    }
    if ($rebase eq "stable") {
        validate_script_output "rpm-ostree status -b", sub { m/rawhide|devel/ }, 300;
    }
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
