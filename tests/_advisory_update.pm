use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # do the 'repo setup' steps, which set up a repo containing the
    # update packages and run 'dnf update'
    $self->root_console(tty=>3);
    repo_setup;
    if (get_var("ADVISORY_BOOT_TEST")) {
        # to test boot stuff - in case the update touched grub2, or dracut,
        # or anything adjacent - let's force-regenerate the initramfs and
        # the bootloader config, and reinstall the bootloader on BIOS. This
        # is kinda arch-dependent, but works for the three arches currently
        # in openQA: x86_64, ppc64le, and aarch64.
        assert_script_run "dracut -f";
        assert_script_run 'grub2-mkconfig -o $(readlink -m /etc/grub2.cfg)';
        assert_script_run "grub2-install /dev/vda" unless (get_var("UEFI"));
    }
    # reboot, in case any of the updates need a reboot to apply
    script_run "reboot", 0;
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
