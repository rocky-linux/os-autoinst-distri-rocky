use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # upgrader should be installed on up-to-date system
    assert_script_run 'dnf -y update --refresh', 1800;
    script_run "reboot", 0;

    # handle bootloader, if requested
    if (get_var("GRUB_POSTINSTALL")) {
        do_bootloader(postinstall=>1, params=>get_var("GRUB_POSTINSTALL"));
    }

    # decrypt if necessary
    if (get_var("ENCRYPT_PASSWORD")) {
        boot_decrypt(60);
    }

    boot_to_login_screen;
    $self->root_console(tty=>3);

    my $update_command = 'dnf -y install dnf-plugin-system-upgrade';
    assert_script_run $update_command, 600;
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
