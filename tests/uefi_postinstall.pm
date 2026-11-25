use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    if (not(check_screen "root_console", 0)) {
        $self->root_console(tty => 4);
    }
    assert_screen "root_console";

    # for aarch64 non-english tests
    console_loadkeys_us;

    # this shows if the system is booted with efi, whether or not secure boot
    # is enabled, state of PK and KEK as well as presence of Microsoft
    # Certificates.
    script_run 'curl -LOR https://pjones.fedorapeople.org/secureboot.test0.2025/show-trusted.sh';
    script_run 'bash ./show-trusted.sh';
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
