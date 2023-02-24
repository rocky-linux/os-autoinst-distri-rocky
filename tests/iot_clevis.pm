use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # we can safely assume we're at a root console at this point
    # Verify decryption is working via TPM2
    assert_script_run "echo foo | clevis encrypt tpm2 '{}' | clevis decrypt";
    # Get the UUID of the encrypted device
    assert_script_run 'UUID=$(lsblk | grep luks | sed "s/^.*luks-//" | cut -d" " -f1)';
    assert_script_run 'DEV=$(blkid --uuid $UUID)';
    # Check encryption details of the device
    assert_script_run 'cryptsetup luksDump $DEV > /tmp/cryptsetup.log';
    upload_logs '/tmp/cryptsetup.log';
    # Setup Clevis to decrypt via TPM2 on boot
    assert_script_run 'clevis luks bind -f -k- -d $DEV tpm2 "{}" <<< ' . get_var("ENCRYPT_PASSWORD");
    # Reboot the system and see if it is booted without user intervention
    script_run "reboot", 0;
    boot_to_login_screen;
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
