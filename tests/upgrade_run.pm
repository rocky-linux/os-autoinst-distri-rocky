use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    my $release = lc(get_var("VERSION"));
    # disable screen blanking (download can take a long time)
    script_run "setterm -blank 0";

    assert_script_run "dnf -y --nogpgcheck --releasever=${release} system-upgrade download", 6000;

    upload_logs "/var/log/dnf.log";
    upload_logs "/var/log/dnf.rpm.log";

    script_run "dnf system-upgrade reboot";
    # fail immediately if we see a DNF error message
    die "DNF reported failure" if (check_screen "upgrade_fail", 15);
    if (get_var("ENCRYPT_PASSWORD")) {
        $self->boot_decrypt(60);
    }
    # try and catch if we hit RHBZ #1349721 and work around it
    if (check_screen "bootloader") {
        # wait some secs for the screen to clear
        sleep 10;
        if (get_var("ENCRYPT_PASSWORD")) {
            $self->boot_decrypt(60);
        }
        if (check_screen "bootloader") {
            record_soft_failure;
            $self->do_bootloader(postinstall=>1, params=>"enforcing=0");
            if (get_var("ENCRYPT_PASSWORD")) {
                $self->boot_decrypt(60);
            }
        }
    }
    # in encrypted case we need to wait a bit so postinstall test
    # doesn't bogus match on the encryption prompt we just completed
    # before it disappears from view
    if (get_var("ENCRYPT_PASSWORD")) {
        sleep 5;
    }
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
