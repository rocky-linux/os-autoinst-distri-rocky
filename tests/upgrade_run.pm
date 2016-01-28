use base "installedtest";
use strict;
use testapi;

sub run {
    my $release = $self->get_release;
    # NOTE: this doesn't actually work yet, it's a FIXME in fedorabase
    my $milestone = $self->get_milestone;
    my $args = "--releasever=${release}";
    # This is excessive - after the Bodhi activation point we don't
    # need --nogpgcheck for Branched. But that's hard to detect magically
    if ($release eq 'rawhide' or $milestone eq 'branched') {
        $args .= " --nogpgcheck";
    }
    # disable screen blanking (download can take a long time)
    script_run "setterm -blank 0";

    script_run "dnf -y system-upgrade download ${args}";

    # wait until dnf finishes its work (screen stops moving for 30 seconds)
    wait_still_screen 30, 6000; # TODO: shorter timeout, longer stillscreen?

    upload_logs "/var/log/dnf.log";
    upload_logs "/var/log/dnf.rpm.log";

    script_run "dnf system-upgrade reboot";
    # fail immediately if we see a DNF error message
    die "DNF reported failure" if (check_screen "upgrade_fail");

    # now offline upgrading starts. user doesn't have to do anything, just wait untill
    # system reboots and login screen is shown
    if (get_var('UPGRADE') eq "desktop") {
        assert_screen "graphical_login", 6000;
    } else {
        assert_screen "text_console_login", 6000;
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
