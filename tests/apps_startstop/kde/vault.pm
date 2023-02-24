use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that Vault starts.

sub run {
    my $self = shift;
    # As there are no vaults created, we need to list
    # invisible icons.
    assert_and_click "desktop_expand_systray";

    # Now we should be able to see the Vaults icon,
    # so we will click on it.
    assert_and_click "vault_menu_open";

    # This is a new installation so there, should not be
    # any existing vaults. Let's check for it.
    assert_screen "vault_menu_not_exist";

    # Click on Create a New ... to start the vault creation
    assert_and_click "vault_menu_create_new";

    # A vault creation dialog should appear
    assert_screen "vault_dialog_runs";

    # Check that a correct backend is available
    assert_screen "vault_encfs_backend_available";

    # Enter the name of the newly created testvault
    assert_and_click "vault_enter_name";

    # Then name the vault "testvault"
    type_very_safely "testvault";

    # Click the Next button
    assert_and_click "kde_next";

    # If the security notice appears, click next it away.
    if (check_screen "vault_security_notice") {
        assert_and_click "kde_next";
    }

    # Enter a password and validate it.
    assert_and_click "vault_enter_password";
    type_very_safely "SecretVaultCode";
    send_key "tab";
    type_very_safely "SecretVaultCode";

    assert_and_click "kde_next";

    # Check that a mountpount screen appears
    assert_screen "vault_mountpoint";

    # Click Next to confirm
    assert_and_click "kde_next";

    # Click on Create to make it happen
    assert_and_click "vault_create";

    # Now the vault should be created so let us check, that it really
    # got created.
    # There should be a new small vault icon visible in the tray, so let's
    # click that to open the vault menu.
    assert_and_click "vault_tray_icon";
    # Check that the vault is listed in the overview
    assert_screen "vault_new_created";
}

sub test_flags {
    return {always_rollback => 1};
}


1;

# vim: set sw=4 et:
